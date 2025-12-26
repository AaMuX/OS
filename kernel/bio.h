#ifndef _BIO_H
#define _BIO_H

#include "types.h"
#include "param.h"
#include "spinlock.h"

#define BSIZE BLOCK_SIZE

// 块缓存结构（参考xv6的bio.c）
struct buf
{
    int valid;            // 缓存是否有效
    int disk;             // 是否需要写回磁盘
    uint dev;             // 设备号
    uint blockno;         // 块号
    struct spinlock lock; // 保护缓存内容
    uint refcnt;          // 引用计数
    struct buf *prev;     // LRU链表前驱
    struct buf *next;     // LRU链表后继
    uchar data[BSIZE];    // 实际数据
};

// 块缓存管理函数
void binit(void);
struct buf *bread(uint dev, uint blockno);
void bwrite(struct buf *b);
void brelse(struct buf *b);
void bpin(struct buf *b);
void bunpin(struct buf *b);

#endif // _BIO_H
