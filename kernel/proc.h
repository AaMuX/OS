#ifndef _PROC_H
#define _PROC_H

#include "types.h"
#include "param.h"
#include "spinlock.h"

struct context
{
    uint64 ra;
    uint64 sp;
    uint64 s0;
    uint64 s1;
    uint64 s2;
    uint64 s3;
    uint64 s4;
    uint64 s5;
    uint64 s6;
    uint64 s7;
    uint64 s8;
    uint64 s9;
    uint64 s10;
    uint64 s11;
};

#define PRIORITY_MIN 1
#define PRIORITY_MAX 10
#define PRIORITY_DEFAULT 5
#define AGING_THRESHOLD 1000 // aging 固定阈值：等待超过此 ticks 后提升优先级
// 使用固定阈值，所有优先级使用相同的等待时间
// 设置为较大的值，避免进程被降级后很快被提升回去
// 确保测试能够正确展示优先级调度和 MLFQ 降级的效果

// MLFQ 相关常量
#define TIME_SLICE_BASE 3         // 基础时间片长度（tick数）- 减小以便更容易用完时间片
#define TIME_SLICE_MULTIPLIER 2   // 高优先级队列的时间片倍数
#define CPU_INTENSIVE_THRESHOLD 3 // CPU密集型判断阈值：连续使用时间片次数

enum procstate
{
    UNUSED = 0,
    USED,
    SLEEPING,
    RUNNABLE,
    RUNNING,
    ZOMBIE
};

struct proc
{
    struct spinlock lock;
    enum procstate state;

    int pid;
    struct proc *parent;

    void *kstack;
    struct context context;

    void *chan;
    void (*entry)(void); // 进程入口函数

    int exit_status;
    int killed;

    int priority;  // 进程优先级 (1~10)
    int ticks;     // 已用 CPU 时间（tick 数）
    int wait_time; // 等待时长（用于 aging）

    // MLFQ 相关字段
    int time_slice;         // 当前时间片剩余量
    int time_slice_used;    // 已用时间片总数
    int consecutive_slices; // 连续使用完整时间片的次数（用于MLFQ降级）

    char name[16];
};

struct cpu
{
    struct proc *proc;
    struct context context;
    int noff;
    int intena;
    int last_scheduled_index[PRIORITY_MAX + 1]; // 记录每个优先级上次调度的进程索引（用于 Round-Robin）
};

extern struct proc proc[NPROC];
extern struct cpu cpus[NCPU];

struct proc *alloc_process(void);
void free_process(struct proc *p);
int create_process(void (*entry)(void));
int create_process_with_priority(void (*entry)(void), int priority);
void exit_process(int status) __attribute__((noreturn));
int wait_process(int *status);
void scheduler(void) __attribute__((noreturn));
void yield(void);
void sched(void);
void proc_init(void);
struct cpu *mycpu(void);
struct proc *myproc(void);
void set_proc_name(struct proc *p, const char *name);
void ksleep(int ticks);
void process_start(void) __attribute__((noreturn));
void swtch(struct context *old, struct context *new);
void sleep(void *chan, struct spinlock *lk);
void wakeup(void *chan);

// 优先级调度相关系统调用
int sys_setpriority(int pid, int priority);
int sys_getpriority(int pid);

#endif
