// kernel/trap.c
// 中断和异常处理核心，负责处理所有来自硬件和软件的异步事件（中断）和同步错误（异常）。
#include "riscv.h"   // RISC-V硬件寄存器访问
#include "trap.h"    // 陷阱处理相关定义
#include <stdbool.h> // 布尔类型
#include <stddef.h>  // NULL和size_t定义
// #include <stdio.h>  // 标准IO（被注释掉）

// 最大中断号定义
#define MAX_IRQ 64

// 中断向量表（Interrupt Vector Table）：存储中断处理函数指针
static interrupt_handler_t ivt[MAX_IRQ];

// 系统滴答计数（从启动开始经历的定时器中断次数）
static volatile uint64_t ticks = 0;

// 中断计数（用于测试和调试）
volatile int interrupt_count = 0;
static volatile int *counter_ptr = &interrupt_count; // 指向中断计数的指针

// 中断优先级表：按优先级从高到低排列
static const int irq_priority[] = {
    SCAUSE_SUPERVISOR_TIMER,    // 定时器中断（最高优先级）
    SCAUSE_SUPERVISOR_EXTERNAL, // 外部中断
    SCAUSE_SUPERVISOR_SOFTWARE, // 软件中断（最低优先级）
};

// 外部函数声明：来自sched.c
extern bool should_yield(void);
extern void yield(void);

// 验证中断号是否有效
static inline bool valid_irq(int irq)
{
    return irq >= 0 && irq < MAX_IRQ;
}

// 将中断号转换为SIE（中断使能）寄存器对应的位
static inline uint64_t irq_to_sie_bit(int irq)
{
    switch (irq)
    {
    case SCAUSE_SUPERVISOR_SOFTWARE:
        return SIE_SSIE; // 软件中断使能位
    case SCAUSE_SUPERVISOR_TIMER:
        return SIE_STIE; // 定时器中断使能位
    case SCAUSE_SUPERVISOR_EXTERNAL:
        return SIE_SEIE; // 外部中断使能位
    default:
        return 0; // 未知中断类型
    }
}

// 将中断号转换为SIP（中断挂起）寄存器对应的位
static inline uint64_t irq_to_sip_bit(int irq)
{
    switch (irq)
    {
    case SCAUSE_SUPERVISOR_SOFTWARE:
        return SIP_SSIP; // 软件中断挂起位
    case SCAUSE_SUPERVISOR_TIMER:
        return SIP_STIP; // 定时器中断挂起位
    case SCAUSE_SUPERVISOR_EXTERNAL:
        return SIP_SEIP; // 外部中断挂起位
    default:
        return 0; // 未知中断类型
    }
}

// 分发中断：根据中断号调用相应的中断处理函数
static bool dispatch_irq(int irq)
{
    if (!valid_irq(irq))
    {
        return false; // 无效中断号
    }
    interrupt_handler_t handler = ivt[irq]; // 从IVT获取处理函数
    if (handler)
    {
        handler(); // 调用中断处理函数
        return true;
    }
    return false; // 没有注册处理函数
}

// 选择中断：根据scause和中断优先级选择要处理的中断
static int choose_irq(uint64_t scause)
{
    // 检查是否是中断（最高位为1表示中断）
    if ((scause & SCAUSE_INTR_MASK) == 0)
    {
        return -1; // 不是中断，是异常
    }

    const int cause = (int)SCAUSE_CODE(scause);        // 获取中断原因码
    const uint64_t pending = r_sip() & r_sie();        // 获取已使能且挂起的中断
    const uint64_t cause_mask = irq_to_sip_bit(cause); // 当前原因对应的挂起位

    // 如果当前原因的中断已使能且挂起，优先处理
    if (cause_mask && (pending & cause_mask))
    {
        return cause;
    }

    // 按优先级遍历中断类型
    for (size_t i = 0; i < sizeof(irq_priority) / sizeof(irq_priority[0]); ++i)
    {
        const int candidate = irq_priority[i];
        const uint64_t mask = irq_to_sip_bit(candidate);
        if (mask && (pending & mask))
        {
            return candidate; // 找到优先级最高的挂起中断
        }
    }

    // 如果都不是，返回原因码（如果有效）
    return valid_irq(cause) ? cause : -1;
}

// 注册中断处理函数
void register_interrupt(int irq, interrupt_handler_t handler)
{
    if (valid_irq(irq))
    {
        ivt[irq] = handler; // 将处理函数存入IVT
    }
}

// 注销中断处理函数
void unregister_interrupt(int irq)
{
    if (valid_irq(irq))
    {
        ivt[irq] = NULL; // 清空IVT对应项
    }
}

// 使能特定类型的中断
void enable_interrupt(int irq)
{
    const uint64_t mask = irq_to_sie_bit(irq);
    if (!mask)
    {
        return; // 无效中断类型
    }
    uint64_t sie = r_sie(); // 读取当前中断使能状态
    sie |= mask;            // 设置对应位
    w_sie(sie);             // 写回寄存器
}

// 禁用特定类型的中断
void disable_interrupt(int irq)
{
    const uint64_t mask = irq_to_sie_bit(irq);
    if (!mask)
    {
        return; // 无效中断类型
    }
    uint64_t sie = r_sie(); // 读取当前中断使能状态
    sie &= ~mask;           // 清除对应位
    w_sie(sie);             // 写回寄存器
}

// 获取当前时间（读取time寄存器）
uint64_t get_time(void) { return r_time(); }

// 定时器相关常量
#define TIMEBASE_HZ 10000000ULL        // 时钟基频：10MHz
#define HZ 100ULL                      // 定时器中断频率：100Hz
#define TICK_CYCLES (TIMEBASE_HZ / HZ) // 每个tick的周期数：100,000

// 设置下一次定时器中断时间
static void set_next_timer(void)
{
    const uint64_t now = get_time();         // 当前时间
    const uint64_t next = now + TICK_CYCLES; // 下一次中断时间
    volatile uint64_t *mtimecmp = (volatile uint64_t *)CLINT_MTIMECMP(0);
    *mtimecmp = next; // 设置定时器比较寄存器
}

// 定时器中断处理函数
void timer_interrupt(void)
{
    ++ticks; // 增加系统滴答计数
    if (counter_ptr)
    {
        ++(*counter_ptr); // 增加中断计数
    }

    // 检查是否应该让出CPU（时间片调度）
    if (should_yield())
    {
        yield();
    }

    set_next_timer(); // 设置下一次中断
}

// 软件中断处理函数
static void software_interrupt(void)
{
    w_sip(r_sip() & ~SIP_SSIP); // 清除软件中断挂起位
    timer_interrupt();          // 调用定时器处理（软件中断用作定时器转发）
}

// 设置中断计数器指针（用于测试）
void timer_set_counter(volatile int *counter)
{
    if (counter)
    {
        counter_ptr = counter; // 使用外部计数器
    }
    else
    {
        interrupt_count = 0; // 重置内部计数器
        counter_ptr = &interrupt_count;
    }
}

// 外部声明：S-mode异常向量入口
extern void kernelvec(void);

// 陷阱系统初始化
void trap_init(void)
{
    intr_off(); // 关闭全局中断

    // 清空中断向量表
    for (int i = 0; i < MAX_IRQ; ++i)
    {
        ivt[i] = NULL;
    }
    ticks = 0;           // 重置滴答计数
    interrupt_count = 0; // 重置中断计数

    // 清除所有中断挂起位
    w_sip(r_sip() & ~(SIP_SSIP | SIP_STIP | SIP_SEIP));

    // 设置异常向量基地址
    w_stvec((uint64_t)kernelvec);

    // 注册并使能定时器中断处理
    register_interrupt(SCAUSE_SUPERVISOR_TIMER, timer_interrupt);
    enable_interrupt(SCAUSE_SUPERVISOR_TIMER);

    // 注册并使能软件中断处理
    register_interrupt(SCAUSE_SUPERVISOR_SOFTWARE, software_interrupt);
    enable_interrupt(SCAUSE_SUPERVISOR_SOFTWARE);

    set_next_timer(); // 设置第一个定时器中断
    intr_on();        // 开启全局中断
}

// 设备中断处理入口
int devintr(struct trapframe *tf)
{
    const int irq = choose_irq(tf->scause); // 选择要处理的中断
    if (irq < 0)
    {
        return 0; // 不是中断或无效中断
    }
    if (dispatch_irq(irq))
    {
        return 1; // 成功处理中断
    }
    return 0; // 没有处理函数
}

// 内核模式陷阱处理
void kerneltrap(struct trapframe *tf)
{
    // 保存当前陷阱上下文
    tf->sepc = r_sepc();
    tf->sstatus = r_sstatus();
    tf->stval = r_stval();
    tf->scause = r_scause();
    tf->reserved = 0;

    // 调试输出：如果中断被启用
    if (tf->sstatus & SSTATUS_SIE)
    {
        printf("kerneltrap: interrupts enabled\n");
    }

    // 判断是中断还是异常
    if (tf->scause & SCAUSE_INTR_MASK)
    {
        // 中断处理
        if (!devintr(tf))
        {
            printf("kerneltrap: unexpected interrupt cause=%lu\n",
                   (unsigned long)SCAUSE_CODE(tf->scause));
        }
    }
    else
    {
        // 异常处理
        handle_exception(tf);
    }

    // 恢复sepc（可能被异常处理修改）
    w_sepc(tf->sepc);
}

// 用户模式陷阱处理（当前直接调用内核处理）
void usertrap(struct trapframe *tf)
{
    kerneltrap(tf);
}

// 跳过导致异常的指令
static inline void advance_sepc(struct trapframe *tf, int bytes)
{
    tf->sepc += (uint64_t)bytes; // 跳过指定字节数
}

// 系统崩溃处理
void panic(const char *msg)
{
    printf("PANIC: %s\n", msg ? msg : "(null)");
    while (1)
    {
        asm volatile("wfi"); // 等待中断（死循环）
    }
}

// 系统调用处理（占位实现）
static void handle_syscall(struct trapframe *tf)
{
    advance_sepc(tf, 4); // 跳过ecall指令（4字节）
}

// 非法指令异常处理
static void handle_illegal_instruction(struct trapframe *tf)
{
    printf("Illegal instruction at sepc=%#lx\n", (unsigned long)tf->sepc);
    advance_sepc(tf, 4); // 跳过非法指令
}

// 加载访问错误处理
static void handle_load_access_fault(struct trapframe *tf)
{
    printf("Load access fault at sepc=%#lx addr=%#lx\n",
           (unsigned long)tf->sepc, (unsigned long)tf->stval);
    advance_sepc(tf, 4); // 跳过导致错误的指令
}

// 存储访问错误处理
static void handle_store_access_fault(struct trapframe *tf)
{
    printf("Store access fault at sepc=%#lx addr=%#lx\n",
           (unsigned long)tf->sepc, (unsigned long)tf->stval);
    advance_sepc(tf, 4); // 跳过导致错误的指令
}

// 异常分发处理
void handle_exception(struct trapframe *tf)
{
    const uint64_t cause = SCAUSE_CODE(tf->scause); // 获取异常原因码
    switch (cause)
    {
    case 2: // 非法指令
        handle_illegal_instruction(tf);
        break;
    case 5: // 加载访问错误
        handle_load_access_fault(tf);
        break;
    case 7: // 存储访问错误
        handle_store_access_fault(tf);
        break;
    case 8: // 用户模式系统调用
    case 9: // 主管模式系统调用
        handle_syscall(tf);
        break;
    case 12: // 指令页错误
        handle_illegal_instruction(tf);
        break;
    case 13: // 加载页错误
        handle_load_access_fault(tf);
        break;
    case 15: // 存储页错误
        handle_store_access_fault(tf);
        break;
    default: // 未处理的异常
        printf("Unhandled exception: scause=%lu sepc=%#lx stval=%#lx\n",
               (unsigned long)tf->scause,
               (unsigned long)tf->sepc,
               (unsigned long)tf->stval);
        panic("Unknown exception");
        break;
    }
}