#pragma once // 防止头文件被重复包含

#include <stdint.h> // 标准整数类型
#include "trap.h"   // 陷阱/中断处理相关定义

/* 系统常量定义 */
#define NPROC 16         // 系统支持的最大进程数
#define KSTACK_SIZE 4096 // 每个进程的内核栈大小（4KB）

/* 进程状态枚举 */
enum procstate
{
    UNUSED = 0, // 进程槽位未使用
    RUNNABLE,   // 进程可运行（就绪状态）
    RUNNING,    // 进程正在运行
    SLEEPING,   // 进程正在等待（阻塞状态）
    ZOMBIE,     // 进程已终止但父进程尚未回收
};

/* 进程上下文结构体 - 保存寄存器状态 */
struct context
{
    uint64_t ra; // 返回地址寄存器 (return address)
    uint64_t sp; // 栈指针寄存器 (stack pointer)
    uint64_t s0; // 保存寄存器 s0-s11
    uint64_t s1; // 这些寄存器在函数调用时需要被调用者保存
    uint64_t s2; // 遵循RISC-V调用约定
    uint64_t s3;
    uint64_t s4;
    uint64_t s5;
    uint64_t s6;
    uint64_t s7;
    uint64_t s8;
    uint64_t s9;
    uint64_t s10;
    uint64_t s11;
};
/* 注意：这里只保存了被调用者保存寄存器
   因为上下文切换发生在函数调用中
   调用者保存寄存器已由编译器自动保存 */

/* 自旋锁结构体 - 用于同步 */
struct spinlock
{
    volatile int locked; // 锁状态：0表示未锁定，1表示已锁定
};
/* volatile 关键字防止编译器优化锁访问
   确保每次访问都从内存读取/写入 */

/* 进程控制块结构体 - 进程的所有信息 */
struct proc
{
    struct spinlock lock;   // 进程锁，保护进程结构体的并发访问
    enum procstate state;   // 进程当前状态
    void *chan;             // 等待通道指针，用于sleep/wakeup同步
    int killed;             // 进程是否被杀死标志
    int xstate;             // 进程退出状态码
    int pid;                // 进程标识符
    char name[16];          // 进程名称
    struct context context; // 进程上下文（寄存器保存区）
    void (*entry)(void);    // 进程入口函数指针
    int parent_pid;         // 父进程PID
    struct proc *parent;    // 指向父进程的指针
    uint8_t *kstack;        // 内核栈起始地址指针
};
/* 每个进程都有独立的内核栈
   用于内核态执行时的栈空间 */

/* CPU结构体 - 单核系统中的CPU信息 */
struct cpu
{
    struct proc *proc;      // 当前在CPU上运行的进程
    struct context context; // 调度器上下文，用于切换到调度器
};
/* context字段：当从进程切换到调度器时
   保存调度器的上下文以便切换回来 */

/* 全局变量声明 */
extern struct proc proc_table[NPROC]; // 全局进程表

/* 进程管理函数声明 */

/* 初始化进程系统 */
void proc_init(void);

/* 创建新进程
   entry: 进程入口函数指针
   返回值: 新进程的PID，失败返回-1 */
int create_process(void (*entry)(void));

/* 终止当前进程
   status: 进程退出状态码 */
void exit_process(int status);

/* 等待任意子进程结束
   status: 用于接收子进程退出状态的指针
   返回值: 结束的子进程PID，无子进程返回-1 */
int wait_process(int *status);

/* 调度器主函数 - 永不返回 */
void scheduler(void) __attribute__((noreturn));

/* 主动让出CPU给其他进程 */
void yield(void);

/* 获取当前运行进程
   返回值: 当前进程指针 */
struct proc *myproc(void);

/* 获取当前CPU
   返回值: 当前CPU指针 */
struct cpu *mycpu(void);

/* 创建并初始化引导进程
   返回值: 引导进程指针，失败返回NULL */
struct proc *init_bootproc(void);

/* 锁操作函数 */
void init_lock(struct spinlock *lk); // 初始化锁
void acquire(struct spinlock *lk);   // 获取锁
void release(struct spinlock *lk);   // 释放锁

/* 进程同步函数 */
void sleep_on(void *chan, struct spinlock *lk); // 在指定通道上睡眠
void wakeup(void *chan);                        // 唤醒指定通道上的所有进程

/* 获取系统时钟滴答数
   返回值: 自系统启动以来的滴答数 */
uint64_t ticks_since_boot(void);

/* 初始化调度器 */
void scheduler_init(void);

/* 调试函数：打印进程表信息 */
void debug_proc_table(void);