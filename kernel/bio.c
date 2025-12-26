#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "bio.h"
#include "pmm.h"

// 内存文件系统：使用内存数组存储所有块，无需磁盘实现
#define RAMDISK_SIZE (1000 * BSIZE) // 支持1000个块（约4MB）

static char ramdisk[RAMDISK_SIZE];
static struct spinlock ramdisk_lock;

// 简单的memmove实现
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

struct
{
    struct spinlock lock;
    struct buf buf[NBUF];

    // LRU链表
    struct buf head;
} bcache;

void binit(void)
{
    struct buf *b;

    initlock(&bcache.lock, "bcache");
    initlock(&ramdisk_lock, "ramdisk");

    // 创建LRU链表
    bcache.head.prev = &bcache.head;
    bcache.head.next = &bcache.head;
    for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    {
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        initlock(&b->lock, "buffer");
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }

    // 初始化内存文件系统（清零所有块）
    // 注意：ramdisk 是静态数组，已经初始化为0
    printf("Memory filesystem initialized (%d blocks, %d KB)\n",
           RAMDISK_SIZE / BSIZE, RAMDISK_SIZE / 1024);
}

// 查找指定设备和块号的缓存
static struct buf *
bget(uint dev, uint blockno)
{
    struct buf *b;

    acquire(&bcache.lock);

    // 查找是否已缓存
    for (b = bcache.head.next; b != &bcache.head; b = b->next)
    {
        if (b->dev == dev && b->blockno == blockno)
        {
            b->refcnt++;
            release(&bcache.lock);
            acquire(&b->lock);
            return b;
        }
    }

    // 未找到，使用LRU策略分配
    // 允许重用任何设备的缓冲区（移除设备限制以提高并发性能）
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev)
    {
        if (b->refcnt == 0)
        {
            b->dev = dev;
            b->blockno = blockno;
            b->valid = 0;
            b->refcnt = 1;
            release(&bcache.lock);
            acquire(&b->lock);
            return b;
        }
    }
    panic("bget: no buffers");
}

// 返回一个已缓存的块，必要时从内存文件系统读取
struct buf *
bread(uint dev, uint blockno)
{
    struct buf *b;

    b = bget(dev, blockno);
    if (!b->valid)
    {
        // 从内存文件系统读取
        if (blockno * BSIZE >= RAMDISK_SIZE)
        {
            panic("bread: blockno out of range");
        }
        acquire(&ramdisk_lock);
        memmove(b->data, &ramdisk[blockno * BSIZE], BSIZE);
        release(&ramdisk_lock);
        b->valid = 1;
    }
    return b;
}

// 将缓存块写回内存文件系统
void bwrite(struct buf *b)
{
    if (!holding(&b->lock))
        panic("bwrite");
    b->disk = 1;
    // 写入到内存文件系统
    if (b->blockno * BSIZE >= RAMDISK_SIZE)
    {
        panic("bwrite: blockno out of range");
    }
    acquire(&ramdisk_lock);
    memmove(&ramdisk[b->blockno * BSIZE], b->data, BSIZE);
    release(&ramdisk_lock);
}

// 释放对缓存块的引用
void brelse(struct buf *b)
{
    if (!holding(&b->lock))
        panic("brelse");

    release(&b->lock);

    acquire(&bcache.lock);
    b->refcnt--;
    if (b->refcnt == 0)
    {
        // 移动到LRU链表头部（最近使用）
        b->next->prev = b->prev;
        b->prev->next = b->next;
        b->next = bcache.head.next;
        b->prev = &bcache.head;
        bcache.head.next->prev = b;
        bcache.head.next = b;
    }
    release(&bcache.lock);
}

// 增加引用计数（防止被LRU淘汰）
void bpin(struct buf *b)
{
    acquire(&bcache.lock);
    b->refcnt++;
    release(&bcache.lock);
}

// 减少引用计数
void bunpin(struct buf *b)
{
    acquire(&bcache.lock);
    b->refcnt--;
    release(&bcache.lock);
}
