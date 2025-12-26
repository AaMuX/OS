#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "bio.h"
#include "log.h"

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

static void install_trans(int recovering);
static void read_head(void);
static void write_head(void);
static void commit(void);

extern struct superblock sb;

struct log log;

void initlog(int dev, struct superblock *sb)
{
    if (sizeof(struct logheader) >= BSIZE)
        panic("initlog: too big logheader");

    initlock(&log.lock, "log");
    log.start = sb->logstart;
    log.size = sb->nlog;
    log.dev = dev;
    recover_from_log();
}

// 从日志中恢复
void recover_from_log(void)
{
    read_head();
    install_trans(1); // 如果是恢复，标记为1
    log.lh.n = 0;
    write_head(); // 清除日志
}

// 读取日志头
static void
read_head(void)
{
    struct buf *buf = bread(log.dev, log.start);
    struct logheader *lh = (struct logheader *)(buf->data);
    int i;
    log.lh.n = lh->n;
    for (i = 0; i < log.lh.n; i++)
    {
        log.lh.block[i] = lh->block[i];
    }
    brelse(buf);
}

// 写入日志头
static void
write_head(void)
{
    struct buf *buf = bread(log.dev, log.start);
    struct logheader *lh = (struct logheader *)(buf->data);
    int i;
    lh->n = log.lh.n;
    for (i = 0; i < log.lh.n; i++)
    {
        lh->block[i] = log.lh.block[i];
    }
    bwrite(buf);
    brelse(buf);
}

// 安装事务：将日志中的块写入文件系统
static void
install_trans(int recovering)
{
    int tail;

    for (tail = 0; tail < log.lh.n; tail++)
    {
        struct buf *lbuf = bread(log.dev, log.start + tail + 1); // 日志块
        struct buf *dbuf = bread(log.dev, log.lh.block[tail]);   // 目标块
        memmove(dbuf->data, lbuf->data, BSIZE);
        bwrite(dbuf); // 写入磁盘
        brelse(lbuf);
        brelse(dbuf);
    }
}

// 开始一个系统调用的事务
void begin_op(void)
{
    acquire(&log.lock);
    while (1)
    {
        if (log.committing)
        {
            // 等待提交完成 - 在单进程环境中，这不应该发生
            release(&log.lock);
            acquire(&log.lock);
            // 如果还在 committing，说明有bug，但继续尝试
            if (log.committing)
                continue;
        }
        else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE)
        {
            // 日志空间不足，等待 - 在单进程环境中，这不应该发生
            release(&log.lock);
            acquire(&log.lock);
            // 如果空间还是不足，说明有bug，但继续尝试
            if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE)
                continue;
        }
        else
        {
            log.outstanding += 1;
            release(&log.lock);
            break;
        }
    }
}

// 结束一个系统调用的事务
void end_op(void)
{
    int do_commit = 0;

    acquire(&log.lock);
    log.outstanding -= 1;
    if (log.committing)
        panic("log.committing");
    if (log.outstanding == 0)
    {
        do_commit = 1;
        log.committing = 1;
    }
    else
    {
        // 唤醒等待的进程
    }
    release(&log.lock);

    if (do_commit)
    {
        commit();
        acquire(&log.lock);
        log.committing = 0;
        // 唤醒等待的进程
        release(&log.lock);
    }
}

// 将块写入日志
void log_write(struct buf *b)
{
    int i;

    if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
        panic("too big a transaction");
    if (log.outstanding < 1)
        panic("log_write outside of trans");

    acquire(&log.lock);
    for (i = 0; i < log.lh.n; i++)
    {
        if (log.lh.block[i] == b->blockno)
        { // 块已在日志中
            // 更新日志块中的数据（因为块内容可能已改变）
            struct buf *lbuf = bread(log.dev, log.start + i + 1);
            memmove(lbuf->data, b->data, BSIZE);
            bwrite(lbuf);
            brelse(lbuf);
            release(&log.lock);
            return;
        }
    }
    log.lh.block[i] = b->blockno;
    if (i == log.lh.n)
    { // 新块
        bpin(b);
        log.lh.n++;
        // 将数据复制到日志块（参考xv6实现）
        struct buf *lbuf = bread(log.dev, log.start + i + 1);
        memmove(lbuf->data, b->data, BSIZE);
        bwrite(lbuf);
        brelse(lbuf);
    }
    release(&log.lock);
}

// 提交事务
static void
commit(void)
{
    if (log.lh.n > 0)
    {
        write_head();     // 写入日志头
        install_trans(0); // 安装到文件系统
        // 释放所有固定的缓冲区（必须在清除log.lh.n之前）
        int n = log.lh.n;
        for (int i = 0; i < n; i++)
        {
            struct buf *b = bread(log.dev, log.lh.block[i]);
            bunpin(b);
            brelse(b);
        }
        log.lh.n = 0;
        write_head(); // 清除日志
    }
}

// 公共接口
void initlog_wrapper(int dev, struct superblock *sbp)
{
    memmove(&sb, sbp, sizeof(sb));
    initlog(dev, &sb);
}
