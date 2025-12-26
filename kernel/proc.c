#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "pmm.h"
#include "proc.h"
#include "spinlock.h"
#include "timer.h"

static struct spinlock pid_lock; // 保护pid分配的锁
static int nextpid = 1;          // 下一个可用的pid

struct proc proc[NPROC]; // 进程表，最大NPROC个进程
struct cpu cpus[NCPU];   // CPU表，支持多核

extern int timer_get_ticks(void);
// 内存清零函数
static void kzero(void *dst, int n)
{
    if (n <= 0)
    {
        return;
    }
    uchar *d = (uchar *)dst;
    for (int i = 0; i < n; i++)
    {
        d[i] = 0;
    }
}
// 安全字符串拷贝函数
static void safestrcpy(char *dst, const char *src, int n)
{
    if (n <= 0)
    {
        return;
    }
    int i = 0;
    if (src)
    {
        for (; i < n - 1 && src[i]; i++)
        {
            dst[i] = src[i];
        }
    }
    for (; i < n; i++)
    {
        dst[i] = 0;
    }
}
// PID分配函数
static int allocpid(void)
{
    acquire(&pid_lock);
    int pid = nextpid++;
    release(&pid_lock);
    return pid;
}

static int clamp_priority(int priority)
{
    if (priority < PRIORITY_MIN)
    {
        return PRIORITY_MIN;
    }
    if (priority > PRIORITY_MAX)
    {
        return PRIORITY_MAX;
    }
    return priority;
}
// 获取当前CPU指针函数
struct cpu *mycpu(void)
{
    return &cpus[0]; // 单核实现，总是返回第一个CPU
}

// 获取当前进程指针函数
struct proc *myproc(void)
{
    push_off();               // 禁用中断
    struct cpu *c = mycpu();  // 获取当前CPU指针
    struct proc *p = c->proc; // 获取当前进程指针
    pop_off();                // 启用中断
    return p;
}

void set_proc_name(struct proc *p, const char *name)
{
    if (!p)
    {
        return;
    }
    safestrcpy(p->name, name, sizeof(p->name));
}
// 初始化进程表和CPU表
void proc_init(void)
{
    initlock(&pid_lock, "nextpid"); // 初始化pid锁
    for (int i = 0; i < NCPU; i++)
    {
        cpus[i].proc = 0;                                // 当前无进程运行
        cpus[i].noff = 0;                                // 初始化CPU中断次数
        cpus[i].intena = 0;                              // 初始化CPU中断使能
        kzero(&cpus[i].context, sizeof(struct context)); // 初始化CPU上下文
        // 初始化 Round-Robin 索引
        for (int j = 0; j <= PRIORITY_MAX; j++)
        {
            cpus[i].last_scheduled_index[j] = 0;
        }
    }
    for (int i = 0; i < NPROC; i++)
    {
        initlock(&proc[i].lock, "proc");                   // 初始化进程锁
        proc[i].state = UNUSED;                            // 初始化进程状态，标记为未使用
        proc[i].pid = 0;                                   // 初始化进程ID，pid为0表示无效
        proc[i].parent = 0;                                // 初始化进程父进程，无父进程
        proc[i].kstack = 0;                                // 初始化进程栈，无内核栈
        proc[i].chan = 0;                                  // 初始化等待通道
        safestrcpy(proc[i].name, 0, sizeof(proc[i].name)); // 初始化进程名称，清空名称
        kzero(&proc[i].context, sizeof(struct context));   // 初始化进程上下文，清零上下文
        proc[i].priority = PRIORITY_DEFAULT;               // 初始化优先级
        proc[i].ticks = 0;                                 // 初始化 CPU 时间
        proc[i].wait_time = 0;                             // 初始化等待时间
        proc[i].time_slice = 0;                            // 初始化时间片
        proc[i].time_slice_used = 0;                       // 初始化已用时间片
        proc[i].consecutive_slices = 0;                    // 初始化连续时间片计数
    }
}

// 释放进程函数
static void free_proc_locked(struct proc *p)
{
    if (p->kstack)
    {
        free_page(p->kstack);
        p->kstack = 0;
    }
    p->pid = 0;
    p->parent = 0;
    p->entry = 0;
    p->exit_status = 0;
    p->killed = 0;
    p->chan = 0;
    safestrcpy(p->name, 0, sizeof(p->name));
    p->state = UNUSED;
    p->priority = PRIORITY_DEFAULT;
    p->ticks = 0;
    p->wait_time = 0;
    kzero(&p->context, sizeof(struct context));
}

// 分配进程函数
struct proc *alloc_process(void)
{
    for (int i = 0; i < NPROC; i++)
    {
        struct proc *p = &proc[i];
        acquire(&p->lock);
        if (p->state == UNUSED)
        {
            p->state = USED;
            p->pid = allocpid();
            p->parent = 0;
            p->entry = 0;
            p->exit_status = 0;
            p->killed = 0;
            safestrcpy(p->name, "proc", sizeof(p->name));
            p->kstack = alloc_page();
            if (p->kstack == 0)
            {
                free_proc_locked(p);
                release(&p->lock);
                return 0;
            }
            kzero(&p->context, sizeof(struct context));
            p->chan = 0;
            p->context.sp = (uint64)p->kstack + PGSIZE; // 栈顶地址
            extern void process_start(void);            // 进程启动函数
            p->context.ra = (uint64)process_start;      // 返回地址
            p->priority = PRIORITY_DEFAULT;
            p->ticks = 0;
            p->wait_time = 0;
            p->time_slice = 0;
            p->time_slice_used = 0;
            p->consecutive_slices = 0;
            return p;
        }
        release(&p->lock);
    }
    return 0;
}

void free_process(struct proc *p)
{
    if (p == 0)
    {
        return;
    }
    acquire(&p->lock);
    free_proc_locked(p);
    release(&p->lock);
}

__attribute__((noreturn)) void exit_process(int status);

static void process_start_trampoline(void) __attribute__((noreturn));

int create_process(void (*entry)(void))
{
    return create_process_with_priority(entry, PRIORITY_DEFAULT);
}

int create_process_with_priority(void (*entry)(void), int priority)
{
    struct proc *p = alloc_process(); // 分配进程结构
    if (p == 0)
    {
        return -1;
    }
    struct proc *parent = myproc(); // 获取当前进程作为父进程
    p->parent = parent;             // 设置父进程
    p->entry = entry;               // 设置入口函数
    set_proc_name(p, "kthread");    // 设置进程名
    p->priority = clamp_priority(priority);
    p->state = RUNNABLE; // 设置进程状态为可运行
    int pid = p->pid;
    release(&p->lock);
    return pid;
}
// 进程启动跳板函数
static void process_start_trampoline(void)
{
    struct proc *p = myproc();
    release(&p->lock); // 释放进程锁
    intr_on();         // 启用中断
    if (p->entry)
    {
        p->entry(); // 执行进程入口函数
    }
    exit_process(0);
}
// 进程启动入口（由上下文切换调用）
//__attribute__((noreturn))---用于告诉编译器：这个函数永远不会返回到调用者。
__attribute__((noreturn)) void process_start(void)
{
    process_start_trampoline();
}

void sched(void)
{
    struct proc *p = myproc();
    struct cpu *c = mycpu();
    if (!holding(&p->lock))
    {
        panic("sched p->lock");
    }
    if (intr_get())
    {
        panic("sched interruptible");
    }
    // 保存中断状态并切换上下文
    int intena = c->intena;
    swtch(&p->context, &c->context); // 切换到调度器上下文
    c->intena = intena;              // 恢复中断状态
}

void yield(void)
{
    struct proc *p = myproc();
    if (p == 0)
    {
        return;
    }
    acquire(&p->lock);

    // MLFQ: 如果进程主动让出CPU（交互式行为），重置连续时间片计数
    if (p->time_slice > 0)
    {
        p->consecutive_slices = 0; // 重置连续时间片计数，表示交互式行为
    }

    p->state = RUNNABLE;
    sched();
    release(&p->lock);
}

__attribute__((noreturn)) void exit_process(int status)
{
    struct proc *p = myproc();
    if (p == 0)
    {
        panic("exit_process without proc");
    }
    acquire(&p->lock);
    p->exit_status = status;
    p->state = ZOMBIE;
    p->chan = 0;
    if (p->parent)
    {
        wakeup(p->parent);
    }
    sched();
    panic("zombie exit");
}

int wait_process(int *status)
{
    struct proc *p = myproc();
    if (p == 0)
    {
        return -1;
    }
    acquire(&p->lock);
    for (;;)
    {
        int have_child = 0;
        for (int i = 0; i < NPROC; i++)
        {
            struct proc *child = &proc[i];
            if (child == p)
            {
                continue;
            }
            acquire(&child->lock);
            if (child->parent == p)
            {
                have_child = 1;
                if (child->state == ZOMBIE)
                {
                    int pid = child->pid;
                    if (status)
                    {
                        *status = child->exit_status;
                    }
                    free_proc_locked(child);
                    release(&child->lock);
                    release(&p->lock);
                    return pid;
                }
            }
            release(&child->lock);
        }
        if (!have_child)
        {
            release(&p->lock);
            return -1;
        }
        sleep(p, &p->lock);
    }
}

// 计算时间片长度（根据优先级）
// MLFQ 设计：高优先级时间片短（快速响应），低优先级时间片长（减少切换开销）
static int calculate_time_slice(int priority)
{
    // 优先级越高，时间片越短
    // 优先级越低，时间片越长
    // 公式：time_slice = BASE * (PRIORITY_MAX - priority + 1) * MULTIPLIER
    int multiplier = (PRIORITY_MAX - priority + 1) * TIME_SLICE_MULTIPLIER;
    return TIME_SLICE_BASE * multiplier;
}

// 不再需要计算 aging 阈值，使用固定阈值

void scheduler(void)
{
    struct cpu *c = mycpu();
    for (;;)
    {
        intr_on(); // 开启中断

        // MLFQ + Aging 机制
        for (int i = 0; i < NPROC; i++)
        {
            struct proc *p = &proc[i];
            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
                p->wait_time++;
                // 如果等待时间超过固定阈值，提升优先级（但不超过最大值）
                // 使用固定阈值，所有优先级使用相同的等待时间（1000 ticks）
                // 确保进程在低优先级运行足够长时间，避免频繁提升
                if (p->wait_time > AGING_THRESHOLD && p->priority < PRIORITY_MAX)
                {
                    int waited_ticks = p->wait_time; // 保存等待时间用于日志
                    p->priority++;
                    p->wait_time = 0;          // 重置等待时间，避免持续提升
                    p->consecutive_slices = 0; // 重置连续时间片计数（aging 提升时重置）
                    printf("[MLFQ] PID %d promoted to priority %d (aging, waited %d ticks, threshold was %d)\n",
                           p->pid, p->priority, waited_ticks, AGING_THRESHOLD);
                }
            }
            else if (p->state == RUNNING)
            {
                // 运行中的进程重置等待时间
                // p->ticks++ 现在在 timer_interrupt 中处理
                p->wait_time = 0;
            }
            release(&p->lock);
        }

        // 选择最高优先级的可运行进程（支持 Round-Robin）
        struct proc *best = 0;
        int best_priority = PRIORITY_MIN - 1;
        int best_index = -1;

        // 第一遍：找到最高优先级（不持有锁）
        for (int i = 0; i < NPROC; i++)
        {
            struct proc *p = &proc[i];
            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
                if (p->priority > best_priority)
                {
                    best_priority = p->priority;
                }
            }
            release(&p->lock);
        }

        // 第二遍：在最高优先级中实现 Round-Robin
        if (best_priority >= PRIORITY_MIN)
        {
            // 从上次调度的下一个位置开始查找
            int start_index = c->last_scheduled_index[best_priority];
            int found = 0;

            // 从 start_index 开始查找
            for (int offset = 0; offset < NPROC; offset++)
            {
                int i = (start_index + offset) % NPROC;
                struct proc *p = &proc[i];
                acquire(&p->lock);
                if (p->state == RUNNABLE && p->priority == best_priority)
                {
                    if (best)
                    {
                        release(&best->lock);
                    }
                    best = p;
                    best_index = i;
                    found = 1;
                    // 继续持有锁，稍后释放
                    break;
                }
                release(&p->lock);
            }

            // 如果没找到（不应该发生），从 0 开始查找
            if (!found)
            {
                for (int i = 0; i < NPROC; i++)
                {
                    struct proc *p = &proc[i];
                    acquire(&p->lock);
                    if (p->state == RUNNABLE && p->priority == best_priority)
                    {
                        if (best)
                        {
                            release(&best->lock);
                        }
                        best = p;
                        best_index = i;
                        break;
                    }
                    release(&p->lock);
                }
            }

            // 更新 Round-Robin 索引（下次从下一个进程开始）
            if (best)
            {
                c->last_scheduled_index[best_priority] = (best_index + 1) % NPROC;
            }
        }

        if (best)
        {
            best->state = RUNNING;
            best->wait_time = 0; // 被选中后重置等待时间

            // MLFQ: 如果进程没有时间片或时间片用完了，分配新的时间片
            if (best->time_slice <= 0)
            {
                best->time_slice = calculate_time_slice(best->priority);
                printf("[MLFQ] PID %d allocated time slice: %d (priority %d, consecutive_slices: %d)\n",
                       best->pid, best->time_slice, best->priority, best->consecutive_slices);
            }

            c->proc = best;
            swtch(&c->context, &best->context);
            c->proc = 0;
            release(&best->lock);
        }
    }
}

void ksleep(int ticks)
{
    int start = timer_get_ticks(); // 获取起始时间
                                   // 忙等待，期间主动让出CPU
    while (timer_get_ticks() - start < ticks)
    {
        yield();
    }
}

void sleep(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc();
    if (p == 0)
    {
        panic("sleep without proc");
    }
    if (lk == 0)
    {
        panic("sleep without lock");
    }
    if (chan == 0)
    {
        panic("sleep without chan");
    }
    if (lk != &p->lock)
    {
        acquire(&p->lock);
        release(lk);
    }
    p->chan = chan;
    p->state = SLEEPING;
    sched();
    p->chan = 0;
    if (lk != &p->lock)
    {
        release(&p->lock);
        acquire(lk);
    }
}

void wakeup(void *chan)
{
    if (chan == 0)
    {
        return;
    }
    for (int i = 0; i < NPROC; i++)
    {
        struct proc *p = &proc[i];
        if (holding(&p->lock))
        {
            if (p->state == SLEEPING && p->chan == chan)
            {
                p->state = RUNNABLE;
                p->chan = 0;
            }
            continue;
        }
        acquire(&p->lock);
        if (p->state == SLEEPING && p->chan == chan)
        {
            p->state = RUNNABLE;
            p->chan = 0;
        }
        release(&p->lock);
    }
}

// 根据 PID 查找进程
static struct proc *find_proc_by_pid(int pid)
{
    if (pid <= 0)
    {
        return 0;
    }
    for (int i = 0; i < NPROC; i++)
    {
        struct proc *p = &proc[i];
        acquire(&p->lock);
        if (p->pid == pid && p->state != UNUSED)
        {
            return p; // 注意：调用者需要释放锁
        }
        release(&p->lock);
    }
    return 0;
}

// 设置进程优先级
int sys_setpriority(int pid, int priority)
{
    // 验证优先级范围
    if (priority < PRIORITY_MIN || priority > PRIORITY_MAX)
    {
        return -1;
    }

    struct proc *p = find_proc_by_pid(pid);
    if (p == 0)
    {
        return -1; // 进程不存在
    }

    p->priority = clamp_priority(priority);
    release(&p->lock);
    return 0;
}

// 获取进程优先级
int sys_getpriority(int pid)
{
    struct proc *p = find_proc_by_pid(pid);
    if (p == 0)
    {
        return -1; // 进程不存在
    }

    int priority = p->priority;
    release(&p->lock);
    return priority;
}
