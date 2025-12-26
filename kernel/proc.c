#include "proc.h"   // 进程管理相关定义
#include "riscv.h"  // RISC-V架构相关定义
#include <stddef.h> // 标准定义
#include "printf.h" // 格式化输出函数

// 外部函数声明
extern void swtch(struct context *old, struct context *new); // 上下文切换函数
extern volatile uint64_t kernel_ticks;                       // 内核时钟滴答计数器

/* 全局数据结构定义 */
struct proc proc_table[NPROC];              // 进程表，最多NPROC个进程
static uint8_t kstacks[NPROC][KSTACK_SIZE]; // 每个进程的内核栈
static struct cpu cpus = {0};               // CPU结构体（单核系统）
static int nextpid = 1;                     // 下一个可分配的PID
static uint8_t scheduler_stack[4096];       // 调度器的专用栈

/* 自旋锁相关函数 */
void init_lock(struct spinlock *lk) { lk->locked = 0; } // 初始化锁
void acquire(struct spinlock *lk) { (void)lk; }         // 获取锁（暂未实现）
void release(struct spinlock *lk) { (void)lk; }         // 释放锁（暂未实现）

/* 获取当前CPU和当前进程 */
struct cpu *mycpu(void) { return &cpus; }           // 返回当前CPU指针
struct proc *myproc(void) { return mycpu()->proc; } // 返回当前运行进程指针

/* 分配新的进程ID */
static int allocpid(void) { return nextpid++; } // 分配PID并递增计数器

/* 分配进程控制块 */
static struct proc *alloc_process(void);

/* 初始化进程系统 */
void proc_init(void)
{
    for (int i = 0; i < NPROC; ++i)
    {
        init_lock(&proc_table[i].lock);        // 初始化每个进程的锁
        proc_table[i].state = UNUSED;          // 标记进程为未使用
        proc_table[i].kstack = &kstacks[i][0]; // 设置进程内核栈起始地址
        proc_table[i].parent = NULL;           // 父进程指针置空
    }
}

/* 创建引导进程（系统第一个进程） */
struct proc *init_bootproc(void)
{
    struct proc *p = alloc_process(); // 分配进程控制块
    if (!p)
    {
        return NULL; // 分配失败返回NULL
    }
    acquire(&p->lock);                          // 获取进程锁
    p->state = RUNNING;                         // 状态设为运行中
    p->parent_pid = 0;                          // 父进程ID为0
    p->parent = NULL;                           // 父进程为空
    snprintf(p->name, sizeof(p->name), "boot"); // 设置进程名为"boot"
    release(&p->lock);                          // 释放进程锁
    mycpu()->proc = p;                          // 设为当前运行进程
    return p;                                   // 返回引导进程指针
}

/* 分配一个空闲进程控制块 */
static struct proc *alloc_process(void)
{
    for (int i = 0; i < NPROC; ++i)
    {
        struct proc *p = &proc_table[i]; // 遍历进程表
        acquire(&p->lock);               // 获取进程锁
        if (p->state == UNUSED)          // 找到空闲槽位
        {
            p->state = RUNNABLE;                        // 状态设为可运行
            p->pid = allocpid();                        // 分配PID
            p->killed = 0;                              // 未标记为被杀死
            p->chan = NULL;                             // 等待通道为空
            p->entry = NULL;                            // 入口函数为空
            p->xstate = 0;                              // 退出状态为0
            p->parent_pid = 0;                          // 父进程ID为0
            p->parent = NULL;                           // 父进程为空
            memset(&p->context, 0, sizeof(p->context)); // 清空上下文
            release(&p->lock);                          // 释放锁
            return p;                                   // 返回新进程指针
        }
        release(&p->lock); // 不是空闲槽位则释放锁
    }
    return NULL; // 没有空闲槽位
}

/* 进程执行的跳板函数 */
static void process_trampoline(void)
{
    struct proc *p = myproc(); // 获取当前进程
    if (p && p->entry)         // 检查进程和入口函数
    {
        p->entry(); // 执行进程入口函数
    }
    exit_process(0); // 进程退出
}

/* 创建新进程 */
int create_process(void (*entry)(void))
{
    struct proc *parent = myproc();   // 获取当前进程（父进程）
    struct proc *p = alloc_process(); // 分配新进程控制块
    if (!p)
    {
        return -1; // 分配失败返回-1
    }
    p->entry = entry;                                     // 设置入口函数
    p->parent_pid = parent ? parent->pid : 0;             // 设置父进程ID
    p->parent = parent;                                   // 设置父进程指针
    snprintf(p->name, sizeof(p->name), "proc%d", p->pid); // 设置进程名

    // 设置栈和上下文
    uint64_t sp = (uint64_t)(p->kstack + KSTACK_SIZE); // 栈顶地址
    p->context.sp = sp;                                // 设置栈指针
    p->context.ra = (uint64_t)process_trampoline;      // 设置返回地址
    return p->pid;                                     // 返回新进程PID
}

/* 初始化调度器 */
void scheduler_init(void)
{
    struct cpu *c = mycpu();                                               // 获取CPU结构
    memset(&c->context, 0, sizeof(c->context));                            // 清空CPU上下文
    c->context.sp = (uint64_t)(scheduler_stack + sizeof(scheduler_stack)); // 设置调度器栈指针
    c->context.ra = (uint64_t)scheduler;                                   // 设置调度器入口地址
}

/* 调度器主循环 */
void scheduler(void)
{
    struct cpu *c = mycpu(); // 获取CPU结构
    for (;;)                 // 无限循环
    {
        intr_on();                      // 开启中断
        for (int i = 0; i < NPROC; ++i) // 遍历进程表
        {
            struct proc *p = &proc_table[i]; // 获取进程
            acquire(&p->lock);               // 获取进程锁
            if (p->state == RUNNABLE)        // 进程可运行
            {
                p->state = RUNNING;              // 设为运行状态
                c->proc = p;                     // 设置为当前运行进程
                swtch(&c->context, &p->context); // 切换到进程上下文
                c->proc = NULL;                  // 清除当前进程
            }
            release(&p->lock); // 释放进程锁
        }
    }
}

/* 执行上下文切换 */
static void sched(void)
{
    struct proc *p = myproc(); // 获取当前进程
    struct cpu *c = mycpu();   // 获取CPU
    if (!p)
    {
        return; // 无进程则返回
    }
    swtch(&p->context, &c->context); // 切换到调度器上下文
}

/* 主动让出CPU */
void yield(void)
{
    struct proc *p = myproc(); // 获取当前进程
    if (!p)
    {
        return; // 无进程则返回
    }
    acquire(&p->lock);   // 获取进程锁
    p->state = RUNNABLE; // 设为可运行状态
    sched();             // 切换到调度器
    release(&p->lock);   // 释放进程锁
}

/* 进程退出 */
void exit_process(int status)
{
    struct proc *p = myproc(); // 获取当前进程
    if (!p)
    {
        return; // 无进程则返回
    }
    acquire(&p->lock);  // 获取进程锁
    p->xstate = status; // 设置退出状态
    p->state = ZOMBIE;  // 设为僵尸状态
    if (p->parent)      // 如果有父进程
    {
        wakeup(p->parent); // 唤醒父进程
    }
    sched(); // 切换到调度器
    // 不应返回到这里
    release(&p->lock); // 释放锁
    while (1)          // 无限循环
    {
    }
}

/* 等待子进程退出 */
int wait_process(int *status)
{
    struct proc *p = myproc(); // 获取当前进程

    for (;;) // 无限循环
    {
        int found = 0; // 标记是否有子进程

        // 查找僵尸子进程
        for (int i = 0; i < NPROC; ++i)
        {
            struct proc *cp = &proc_table[i]; // 检查每个进程
            acquire(&cp->lock);               // 获取进程锁

            if (cp->state == ZOMBIE && cp->parent == p) // 找到僵尸子进程
            {
                // 找到僵尸子进程
                int pid = cp->pid; // 获取子进程PID
                if (status)
                {
                    *status = cp->xstate; // 返回退出状态
                }
                // 清理进程资源
                cp->state = UNUSED; // 设为未使用状态
                cp->parent = NULL;  // 清除父进程指针
                cp->pid = 0;        // 清除PID
                release(&cp->lock); // 释放锁
                return pid;         // 返回子进程PID
            }

            // 检查是否有子进程
            if (cp->parent == p && cp->state != UNUSED)
            {
                found = 1; // 有子进程
            }
            release(&cp->lock); // 释放锁
        }

        if (!found)
        {
            // 没有子进程
            return -1; // 返回-1
        }

        // 有子进程但都不是僵尸状态，让出CPU
        yield(); // 主动让出CPU
    }
}

/* 在指定通道上睡眠 */
void sleep_on(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc(); // 获取当前进程
    if (!p)
        return;               // 无进程则返回
    if (lk && lk != &p->lock) // 如果提供了锁且不是进程锁
    {
        acquire(&p->lock); // 获取进程锁
        release(lk);       // 释放传入的锁
    }
    else if (lk == NULL) // 没有提供锁
    {
        acquire(&p->lock); // 获取进程锁
    }
    p->chan = chan;           // 设置等待通道
    p->state = SLEEPING;      // 设为睡眠状态
    sched();                  // 切换到调度器
    p->chan = NULL;           // 清除等待通道
    if (lk && lk != &p->lock) // 恢复锁状态
    {
        release(&p->lock); // 释放进程锁
        acquire(lk);       // 重新获取传入的锁
    }
    else
    {
        release(&p->lock); // 释放进程锁
    }
}

/* 唤醒指定通道上的所有进程 */
void wakeup(void *chan)
{
    for (int i = 0; i < NPROC; ++i) // 遍历所有进程
    {
        struct proc *p = &proc_table[i];             // 获取进程
        acquire(&p->lock);                           // 获取进程锁
        if (p->state == SLEEPING && p->chan == chan) // 检查是否在等待该通道
        {
            p->state = RUNNABLE; // 设为可运行状态
        }
        release(&p->lock); // 释放锁
    }
}

// 暴露滴答计数，供测试使用
extern volatile uint64_t kernel_ticks;
uint64_t ticks_since_boot(void) { return kernel_ticks; } // 返回自启动以来的滴答数

/* 调试：打印进程表 */
void debug_proc_table(void)
{
    printf("=== Process Table ===\n");
    for (int i = 0; i < NPROC; ++i) // 遍历进程表
    {
        struct proc *p = &proc_table[i]; // 获取进程
        if (p->state != UNUSED)          // 只显示使用的进程
        {
            printf("PID:%d State:%d Name:%s\n", p->pid, p->state, p->name);
        }
    }
}
/* 进程状态说明：
   UNUSED    = 0  // 未使用
   RUNNABLE  = 1  // 可运行
   RUNNING   = 2  // 运行中
   SLEEPING  = 3  // 睡眠中
   ZOMBIE    = 4  // 僵尸状态
*/