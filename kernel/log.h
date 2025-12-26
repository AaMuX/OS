#ifndef _LOG_H
#define _LOG_H

#include "types.h"
#include "param.h"
#include "spinlock.h"

// 日志头结构
struct logheader
{
    int n;              // 日志中的块数
    int block[LOGSIZE]; // 每个块在文件系统中的位置
};

// 日志系统状态
struct log
{
    struct spinlock lock;
    int start;           // 日志区起始块号
    int size;            // 日志区大小
    int outstanding;     // 未完成的系统调用数
    int committing;      // 是否正在提交
    int dev;             // 设备号
    struct logheader lh; // 日志头
};

// 日志系统函数
void initlog(int dev, struct superblock *sb);
void initlog_wrapper(int dev, struct superblock *sb);
void begin_op(void);
void end_op(void);
void log_write(struct buf *b);
void recover_from_log(void);

#endif // _LOG_H
