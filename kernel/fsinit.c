#include "types.h"
#include "param.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "bio.h"
#include "log.h"

#define FSMAGIC 0x10203040

extern struct superblock sb;

// 前向声明
struct inode* iget(uint dev, uint inum);
uint balloc(uint dev);
void ilock(struct inode *ip);
void iunlockput(struct inode *ip);
void iupdate(struct inode *ip);
static char* strncpy(char *s, const char *t, int n);

// 宏定义（从fs.c复制）
#define IBLOCK(i, sb)     ((i) / IPB + sb.inodestart)
#define BBLOCK(b, sb) (b/BPB + sb.bmapstart)
#define BPB (BSIZE*8)  // 每块的位数
#define IPB INODES_PER_BLOCK

// 内存复制
static void*
memmove(void *dst, const void *src, uint n)
{
    const char *s;
    char *d;

    s = src;
    d = dst;
    if(s < d && s + n > d){
        s += n;
        d += n;
        while(n-- > 0)
            *--d = *--s;
    } else
        while(n-- > 0)
            *d++ = *s++;
    return dst;
}

// 内存设置
static void*
memset(void *dst, int c, uint n)
{
    char *cdst = (char *) dst;
    for(int i = 0; i < n; i++){
        cdst[i] = c;
    }
    return dst;
}

// 字符串复制
static char*
strncpy(char *s, const char *t, int n)
{
    char *os = s;
    while(n-- > 0 && (*s++ = *t++) != 0)
        ;
    while(n-- > 0)
        *s++ = 0;
    return os;
}

// 读取超级块
static void
readsb(int dev, struct superblock *sb)
{
    struct buf *bp;

    bp = bread(dev, SUPERBLOCK_NUM);
    memmove(sb, bp->data, sizeof(*sb));
    brelse(bp);
}

// 前向声明
static void mkfs(int dev);

// 文件系统初始化
void
fsinit(int dev)
{
    readsb(dev, &sb);
    if(sb.magic != FSMAGIC) {
        // 文件系统未格式化，进行初始化
        printf("Filesystem not formatted, initializing...\n");
        mkfs(dev);
        readsb(dev, &sb);
        if(sb.magic != FSMAGIC)
            panic("invalid file system after mkfs");
    }
    initlog_wrapper(dev, &sb);
}

// 创建文件系统
static void
mkfs(int dev)
{
    struct buf *bp;
    int nblocks = FSSIZE;
    int ninodes = 200;
    int nlog = LOG_SIZE;
    
    // 计算布局
    int logstart = LOG_START;
    int inodestart = logstart + nlog;
    int bmapstart = inodestart + (ninodes / IPB) + 1;
    int nmeta = bmapstart + (nblocks / BPB) + 1;
    int nblocks_data = nblocks - nmeta;
    
    printf("mkfs: creating filesystem with %d blocks, %d inodes\n", nblocks, ninodes);
    printf("  log: %d blocks at %d\n", nlog, logstart);
    printf("  inodes: %d at %d\n", ninodes, inodestart);
    printf("  bitmap: at %d\n", bmapstart);
    
    // 初始化超级块
    struct buf *sbp_buf = bread(dev, SUPERBLOCK_NUM);
    struct superblock *sbp = (struct superblock*)sbp_buf->data;
    sbp->magic = FSMAGIC;
    sbp->size = nblocks;
    sbp->nblocks = nblocks_data;
    sbp->ninodes = ninodes;
    sbp->nlog = nlog;
    sbp->logstart = logstart;
    sbp->inodestart = inodestart;
    sbp->bmapstart = bmapstart;
    bwrite(sbp_buf);
    brelse(sbp_buf);
    
    // 更新全局超级块变量（供ialloc等函数使用）
    sb.magic = FSMAGIC;
    sb.size = nblocks;
    sb.nblocks = nblocks_data;
    sb.ninodes = ninodes;
    sb.nlog = nlog;
    sb.logstart = logstart;
    sb.inodestart = inodestart;
    sb.bmapstart = bmapstart;
    
    // 清零日志区
    for(int i = 0; i < nlog; i++) {
        bp = bread(dev, logstart + i);
        memset(bp->data, 0, BSIZE);
        bwrite(bp);
        brelse(bp);
    }
    
    // 清零inode区
    for(int i = 0; i < (ninodes / IPB) + 1; i++) {
        bp = bread(dev, inodestart + i);
        memset(bp->data, 0, BSIZE);
        bwrite(bp);
        brelse(bp);
    }
    
    // 初始化位图（所有块都标记为已使用）
    for(int i = 0; i < (nblocks / BPB) + 1; i++) {
        bp = bread(dev, bmapstart + i);
        memset(bp->data, 0xFF, BSIZE);  // 全部标记为已使用
        bwrite(bp);
        brelse(bp);
    }
    
    // 标记元数据块为已使用（引导块、超级块、日志区、inode区、位图区）
    // 块0: 引导块（已使用）
    // 块1: 超级块（已使用）
    // 块2-31: 日志区（已使用）
    // 块32-36: inode区（已使用）
    // 块37+: 位图区（已使用）
    // 从nmeta开始的数据块标记为空闲
    
    // 标记数据块为空闲
    for(int i = 0; i < nblocks_data; i++) {
        uint b = nmeta + i;
        bp = bread(dev, BBLOCK(b, sb));
        int bi = b % BPB;
        int m = 1 << (bi % 8);
        bp->data[bi/8] &= ~m;  // 标记为空闲
        bwrite(bp);
        brelse(bp);
    }
    
    // 创建根目录（需要先初始化inode缓存）
    // 注意：这里需要确保iinit已经调用
    // 在mkfs中，我们直接写入磁盘，不使用日志系统
    // 因为日志系统还没有初始化
    
    // 直接分配inode 1作为根目录
    int inum = 1;
    bp = bread(dev, IBLOCK(inum, sb));
    struct dinode *dip = (struct dinode*)bp->data + (inum % IPB);
    memset(dip, 0, sizeof(*dip));
    dip->type = T_DIR;
    dip->nlink = 2;  // . 和 ..
    bwrite(bp);  // 直接写入，不使用日志
    brelse(bp);
    
    // 获取inode并创建目录项
    struct inode *root = iget(dev, inum);
    ilock(root);
    
    // 先分配数据块
    uint bno = balloc(dev);
    root->direct[0] = bno;
    root->size = 2 * sizeof(struct dirent);
    root->blocks = 1;
    iupdate(root);  // 更新inode（会检查日志系统）
    
    // 创建 . 和 .. 目录项（直接写入，不使用日志）
    bp = bread(dev, bno);
    struct dirent *de = (struct dirent*)bp->data;
    
    // . 目录项
    de[0].inum = inum;
    strncpy(de[0].name, ".", DIRSIZ);
    
    // .. 目录项
    de[1].inum = inum;
    strncpy(de[1].name, "..", DIRSIZ);
    
    // 清零其余目录项
    for(int i = 2; i < BSIZE/sizeof(struct dirent); i++) {
        de[i].inum = 0;
    }
    
    bwrite(bp);  // 直接写入
    brelse(bp);
    
    iunlockput(root);
    
    printf("mkfs: filesystem created successfully\n");
}

