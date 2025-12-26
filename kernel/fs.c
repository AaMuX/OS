#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "bio.h"
#include "log.h"
#include "sleeplock.h"
#include "proc.h"

#define FSMAGIC 0x10203040

extern struct log log;

#define min(a, b) ((a) < (b) ? (a) : (b))

// 宏定义
#define IBLOCK(i, sb) ((i) / IPB + sb.inodestart)
#define BBLOCK(b, sb) (b / BPB + sb.bmapstart)
#define BPB (BSIZE * 8) // 每块的位数
#define MAXFILE ((NDIRECT + NINDIRECT) * BSIZE)
#define NDIRECT 12
#define NINDIRECT (BSIZE / sizeof(uint))

// 前向声明
struct inode *iget(uint dev, uint inum);
static char *skipelem(char *path, char *name);
static int namecmp(const char *s, const char *t);
static char *strncpy(char *s, const char *t, int n);
static int strncmp(const char *p, const char *q, uint n);
static void *memmove(void *dst, const void *src, uint n);
static void *memset(void *dst, int c, uint n);
static int either_copyout(int user_dst, uint64 dst, void *src, uint64 len);
static int either_copyin(void *dst, int user_src, uint64 src, uint64 len);
static void bzero(int dev, int bno);

// 内存中的inode缓存
struct
{
    struct spinlock lock;
    struct inode inode[NINODE];
} icache;

void iinit(void)
{
    int i = 0;

    initlock(&icache.lock, "icache");
    for (i = 0; i < NINODE; i++)
    {
        initsleeplock(&icache.inode[i].lock, "inode");
    }
}

// 分配一个新的inode
struct inode *
ialloc(uint dev, short type)
{
    int inum;
    struct buf *bp;
    struct dinode *dip;

    // 检查超级块是否已初始化
    if (sb.magic != FSMAGIC)
    {
        panic("ialloc: superblock not initialized");
    }

    for (inum = 1; inum < sb.ninodes; inum++)
    {
        bp = bread(dev, IBLOCK(inum, sb));
        dip = (struct dinode *)bp->data + (inum % IPB);
        if (dip->type == 0)
        { // 空闲inode
            memset(dip, 0, sizeof(*dip));
            dip->type = type;
            // 如果日志系统已初始化，使用日志；否则直接写入
            extern struct log log;
            if (log.dev != 0)
            {
                log_write(bp);
            }
            else
            {
                bwrite(bp);
            }
            brelse(bp);
            return iget(dev, inum);
        }
        brelse(bp);
    }
    panic("ialloc: no inodes");
}

// 将inode信息复制到内存inode
void ilock(struct inode *ip)
{
    struct buf *bp;
    struct dinode *dip;

    if (ip == 0 || ip->ref < 1)
        panic("ilock");

    acquiresleep(&ip->lock);

    if (ip->valid == 0)
    {
        bp = bread(ip->dev, IBLOCK(ip->inum, sb));
        dip = (struct dinode *)bp->data + (ip->inum % IPB);
        ip->type = dip->type;
        ip->mode = dip->mode;
        ip->uid = dip->uid;
        ip->size = dip->size;
        ip->blocks = dip->blocks;
        ip->atime = dip->atime;
        ip->mtime = dip->mtime;
        ip->ctime = dip->ctime;
        memmove(ip->direct, dip->direct, sizeof(ip->direct));
        ip->indirect = dip->indirect;
        ip->double_indirect = dip->double_indirect;
        ip->nlink = dip->nlink;
        ip->type = dip->type;
        brelse(bp);
        ip->valid = 1;
    }
}

// 释放inode锁
void iunlock(struct inode *ip)
{
    if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
        panic("iunlock");

    releasesleep(&ip->lock);
}

// 获取inode（增加引用计数）
struct inode *
iget(uint dev, uint inum)
{
    struct inode *ip, *empty;

    acquire(&icache.lock);

    // 查找是否已在缓存中
    empty = 0;
    for (ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++)
    {
        if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
        {
            ip->ref++;
            release(&icache.lock);
            return ip;
        }
        if (empty == 0 && ip->ref == 0)
            empty = ip;
    }

    // 未找到，分配新的
    if (empty == 0)
        panic("iget: no inodes");

    ip = empty;
    ip->dev = dev;
    ip->inum = inum;
    ip->ref = 1;
    ip->valid = 0;
    release(&icache.lock);

    return ip;
}

// 增加inode引用计数
struct inode *
idup(struct inode *ip)
{
    acquire(&icache.lock);
    ip->ref++;
    release(&icache.lock);
    return ip;
}

// 释放inode引用
void iput(struct inode *ip)
{
    acquire(&icache.lock);

    if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    {
        // inode没有链接，可以删除
        // 需要先释放所有数据块
        // 先释放 icache.lock，然后获取 inode 锁
        release(&icache.lock);
        ilock(ip);
        itrunc(ip);
        ip->type = 0;
        iupdate(ip);
        iunlock(ip);
        acquire(&icache.lock);
        ip->valid = 0;
    }

    ip->ref--;
    release(&icache.lock);
}

// 更新磁盘上的inode
void iupdate(struct inode *ip)
{
    struct buf *bp;
    struct dinode *dip;

    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    dip = (struct dinode *)bp->data + (ip->inum % IPB);
    dip->type = ip->type;
    dip->nlink = ip->nlink;
    dip->mode = ip->mode;
    dip->uid = ip->uid;
    dip->size = ip->size;
    dip->blocks = ip->blocks;
    dip->atime = ip->atime;
    dip->mtime = ip->mtime;
    dip->ctime = ip->ctime;
    memmove(dip->direct, ip->direct, sizeof(ip->direct));
    dip->indirect = ip->indirect;
    dip->double_indirect = ip->double_indirect;
    // 如果日志系统已初始化，使用日志；否则直接写入
    if (log.dev != 0)
    {
        log_write(bp);
    }
    else
    {
        bwrite(bp);
    }
    brelse(bp);
}

// 从inode读取数据
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
    uint tot, m;
    struct buf *bp;

    if (off > ip->size || off + n < off)
        return -1;
    if (off + n > ip->size)
        n = ip->size - off;

    for (tot = 0; tot < n; tot += m, off += m, dst += m)
    {
        bp = bread(ip->dev, bmap(ip, off / BSIZE));
        m = min(n - tot, BSIZE - off % BSIZE);
        if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
        {
            brelse(bp);
            tot = -1;
            break;
        }
        brelse(bp);
    }
    return tot;
}

// 向inode写入数据
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
    uint tot, m;
    struct buf *bp;

    if (off > ip->size || off + n < off)
        return -1;
    if (off + n > MAXFILE * BSIZE)
        return -1;

    for (tot = 0; tot < n; tot += m, off += m, src += m)
    {
        bp = bread(ip->dev, bmap(ip, off / BSIZE));
        m = min(n - tot, BSIZE - off % BSIZE);
        if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
        {
            brelse(bp);
            break;
        }
        log_write(bp);
        brelse(bp);
    }

    if (off > ip->size)
        ip->size = off;

    iupdate(ip);
    return tot;
}

// 查找inode中的块号
uint bmap(struct inode *ip, uint bn)
{
    uint addr, *a;
    struct buf *bp;

    if (bn < 12)
    {
        if ((addr = ip->direct[bn]) == 0)
            ip->direct[bn] = addr = balloc(ip->dev);
        return addr;
    }
    bn -= 12;

    if (bn < BSIZE / sizeof(uint))
    {
        if ((addr = ip->indirect) == 0)
            ip->indirect = addr = balloc(ip->dev);
        bp = bread(ip->dev, addr);
        a = (uint *)bp->data;
        if ((addr = a[bn]) == 0)
        {
            a[bn] = addr = balloc(ip->dev);
            log_write(bp);
        }
        brelse(bp);
        return addr;
    }
    panic("bmap: out of range");
}

// 截断inode（释放所有块）
void itrunc(struct inode *ip)
{
    int i, j;
    struct buf *bp;
    uint *a;
    uint indirect;

    for (i = 0; i < 12; i++)
    {
        if (ip->direct[i])
        {
            bfree(ip->dev, ip->direct[i]);
            ip->direct[i] = 0;
        }
    }

    indirect = ip->indirect;
    ip->indirect = 0;
    if (indirect)
    {
        bp = bread(ip->dev, indirect);
        a = (uint *)bp->data;
        for (j = 0; j < BSIZE / sizeof(uint); j++)
        {
            if (a[j])
                bfree(ip->dev, a[j]);
        }
        brelse(bp);
        bfree(ip->dev, indirect);
    }

    ip->size = 0;
    iupdate(ip);
}

// 目录查找
struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    uint off, inum;
    struct dirent de;

    if (dp->type != T_DIR)
        panic("dirlookup not DIR");

    for (off = 0; off < dp->size; off += sizeof(de))
    {
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
            panic("dirlookup read");
        if (de.inum == 0)
            continue;
        if (namecmp(name, de.name) == 0)
        {
            if (poff)
                *poff = off;
            inum = de.inum;
            return iget(dp->dev, inum);
        }
    }

    return 0;
}

// 在目录中添加链接
int dirlink(struct inode *dp, char *name, uint inum)
{
    int off;
    struct dirent de;
    struct inode *ip;

    if ((ip = dirlookup(dp, name, 0)) != 0)
    {
        iput(ip);
        return -1;
    }

    for (off = 0; off < dp->size; off += sizeof(de))
    {
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
            panic("dirlink read");
        if (de.inum == 0)
            break;
    }

    strncpy(de.name, name, DIRSIZ);
    de.inum = inum;
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
        panic("dirlink");

    return 0;
}

// 从目录中删除链接
int dirunlink(struct inode *dp, char *name)
{
    struct dirent de;
    struct inode *ip;
    uint off, inum;

    if ((ip = dirlookup(dp, name, &off)) == 0)
        return -1;

    inum = ip->inum;
    iput(ip);

    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
        panic("dirunlink read");
    if (de.inum != inum)
        panic("dirunlink: name mismatch");

    de.inum = 0; // 标记为空闲
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
        panic("dirunlink write");

    return 0;
}

// 路径解析（参考xv6实现）
static struct inode *
namex(char *path, int nameiparent, char *name)
{
    struct inode *ip, *next;

    if (*path == '/')
        ip = iget(ROOTDEV, ROOTINO);
    else
        ip = iget(ROOTDEV, ROOTINO);

    while ((path = skipelem(path, name)) != 0)
    {
        // 必须先锁定 inode 以加载数据
        ilock(ip);
        if (ip->type != T_DIR)
        {
            iunlockput(ip);
            return 0;
        }
        if (nameiparent && *path == '\0')
        {
            // 停止在最后一个元素，返回父目录（解锁后返回，调用者会重新锁定）
            iunlock(ip);
            return ip;
        }
        if ((next = dirlookup(ip, name, 0)) == 0)
        {
            // 对于 nameiparent，如果找不到，返回父目录（解锁后返回，调用者会重新锁定）
            if (nameiparent)
            {
                iunlock(ip);
                return ip;
            }
            iunlockput(ip);
            return 0;
        }
        iunlockput(ip);
        ip = next;
    }
    if (nameiparent)
    {
        // 循环没有执行，说明路径为空
        // name 没有被设置，返回 0
        iput(ip);
        return 0;
    }
    return ip;
}

struct inode *
namei(char *path)
{
    char name[DIRSIZ];
    return namex(path, 0, name);
}

struct inode *
nameiparent(char *path, char *name)
{
    return namex(path, 1, name);
}

// 辅助函数
static char *
skipelem(char *path, char *name)
{
    char *s;
    int len;

    while (*path == '/')
        path++;
    if (*path == 0)
        return 0;
    s = path;
    while (*path != '/' && *path != 0)
        path++;
    len = path - s;
    if (len >= DIRSIZ)
        memmove(name, s, DIRSIZ);
    else
    {
        memmove(name, s, len);
        name[len] = 0;
    }
    while (*path == '/')
        path++;
    return path;
}

// 字符串比较
static int
namecmp(const char *s, const char *t)
{
    return strncmp(s, t, DIRSIZ);
}

// 字符串复制
static char *
strncpy(char *s, const char *t, int n)
{
    char *os;

    os = s;
    while (n-- > 0 && (*s++ = *t++) != 0)
        ;
    while (n-- > 0)
        *s++ = 0;
    return os;
}

// 字符串比较
static int
strncmp(const char *p, const char *q, uint n)
{
    while (n > 0 && *p && *p == *q)
        n--, p++, q++;
    if (n == 0)
        return 0;
    return (uchar)*p - (uchar)*q;
}

// 内存复制
static void *
memmove(void *dst, const void *src, uint n)
{
    const char *s;
    char *d;

    s = src;
    d = dst;
    if (s < d && s + n > d)
    {
        s += n;
        d += n;
        while (n-- > 0)
            *--d = *--s;
    }
    else
        while (n-- > 0)
            *d++ = *s++;
    return dst;
}

// 内存设置
static void *
memset(void *dst, int c, uint n)
{
    char *cdst = (char *)dst;
    for (int i = 0; i < n; i++)
    {
        cdst[i] = c;
    }
    return dst;
}

// 数据复制函数（用户空间和内核空间之间）
static int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    // 简化实现：直接复制（实际应该通过页表转换）
    memmove((void *)dst, src, len);
    return 0;
}

static int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    // 简化实现：直接复制（实际应该通过页表转换）
    memmove(dst, (void *)src, len);
    return 0;
}

// 块分配和释放（需要实现）
uint balloc(uint dev)
{
    int b, bi, m;
    struct buf *bp;

    bp = 0;
    // 从数据块开始查找（跳过元数据块）
    // 元数据块包括：引导块(0)、超级块(1)、日志区、inode区、位图区
    // 数据块从 nmeta 开始，nmeta = bmapstart + (size / BPB) + 1
    int nmeta = sb.bmapstart + (sb.size / BPB) + 1;
    for (b = nmeta; b < sb.size; b += BPB)
    {
        bp = bread(dev, BBLOCK(b, sb));
        for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
        {
            m = 1 << (bi % 8);
            if ((bp->data[bi / 8] & m) == 0)
            {                          // 空闲块
                bp->data[bi / 8] |= m; // 标记为已使用
                // 如果日志系统已初始化，使用日志；否则直接写入
                extern struct log log;
                if (log.dev != 0)
                {
                    log_write(bp);
                }
                else
                {
                    bwrite(bp);
                }
                brelse(bp);
                bzero(dev, b + bi);
                return b + bi;
            }
        }
        brelse(bp);
    }
    panic("balloc: out of blocks");
}

void bfree(int dev, uint b)
{
    struct buf *bp;
    int bi, m;

    bp = bread(dev, BBLOCK(b, sb));
    bi = b % BPB;
    m = 1 << (bi % 8);
    if ((bp->data[bi / 8] & m) == 0)
    {
        // 块已经被释放，可能是重复调用，直接返回
        brelse(bp);
        return;
    }
    bp->data[bi / 8] &= ~m;
    log_write(bp);
    brelse(bp);
}

static void
bzero(int dev, int bno)
{
    struct buf *bp;

    bp = bread(dev, bno);
    memset(bp->data, 0, BSIZE);
    // 如果日志系统已初始化，使用日志；否则直接写入
    extern struct log log;
    if (log.dev != 0)
    {
        log_write(bp);
    }
    else
    {
        bwrite(bp);
    }
    brelse(bp);
}

// 全局超级块
struct superblock sb;

// 需要添加iunlockput（已在fs.h中声明）
void iunlockput(struct inode *ip)
{
    iunlock(ip);
    iput(ip);
}

// 需要添加stati（已在fs.h中声明）
void stati(struct inode *ip, struct stat *st)
{
    st->dev = ip->dev;
    st->ino = ip->inum;
    st->type = ip->type;
    st->nlink = ip->nlink;
    st->size = ip->size;
}

// 需要添加nlink字段到inode
// 在fs.h中已定义，这里需要确保使用
