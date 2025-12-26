#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "interrupt.h"
#include "trap.h"
#include "proc.h"

// 中断向量表，用于存储中断处理函数
static interrupt_handler_t interrupt_vector[64];
// 全局陷阱帧结构，在汇编代码中被引用用于保存/恢复上下文
struct trapframe _trapframe; // referenced by assembly entry

// 性能统计：上下文切换开销
static volatile uint64 total_context_switch_time = 0;  // 累计上下文切换时间
static volatile uint64 context_switch_count = 0;       // 上下文切换次数
static volatile uint64 max_context_switch_time = 0;    // 最长上下文切换时间
static volatile uint64 min_context_switch_time = ~0UL; // 最短上下文切换时间
// 暴露性能统计接口
uint64 trap_get_context_switch_count(void) { return context_switch_count; }
uint64 trap_get_total_context_switch_time(void) { return total_context_switch_time; }
uint64 trap_get_max_context_switch_time(void) { return max_context_switch_time; }
uint64 trap_get_min_context_switch_time(void) { return min_context_switch_time == ~0UL ? 0 : min_context_switch_time; }
void trap_reset_stats(void)
{
    total_context_switch_time = 0;
    context_switch_count = 0;
    max_context_switch_time = 0;
    min_context_switch_time = ~0UL;
}

static inline uint64 instruction_length(uint64 mepc)
{
    // RISC-V C extension: if low 2 bits != 3, it's 16-bit; otherwise 32-bit
    uint16 first_half = *(volatile uint16 *)mepc;
    if ((first_half & 0x3) != 0x3)
        return 2;
    return 4;
}

// 默认中断处理函数
static void default_handler(void)
{
    printf("Unhandled interrupt\n");
}
// 注册中断处理函数，用于注册中断处理函数
void register_interrupt(int irq, interrupt_handler_t h)
{
    if (irq < 0 || irq >= 64)
        return;
    interrupt_vector[irq] = h ? h : default_handler;
}

// 注销中断处理函数，将中断处理函数重置为默认处理函数
void unregister_interrupt(int irq)
{
    if (irq < 0 || irq >= 64)
        return;
    interrupt_vector[irq] = default_handler;
    // 注意：不会自动禁用硬件中断，需要手动调用 disable_interrupt
}

// 启用中断，用于启用中断
// MIE_MTIE：机器模式定时器中断使能
// MIE_MSIE：机器模式软件中断使能
// MIE_MEIE：机器模式外部中断使能
void enable_interrupt(int irq)
{
    uint64 mie = r_mie();
    if (irq == IRQ_M_TIMER)
        mie |= MIE_MTIE;
    else if (irq == IRQ_M_SOFT)
        mie |= MIE_MSIE;
    else if (irq == IRQ_M_EXT)
        mie |= MIE_MEIE;
    w_mie(mie);
}

void disable_interrupt(int irq)
{
    uint64 mie = r_mie();
    if (irq == IRQ_M_TIMER)
        mie &= ~MIE_MTIE;
    else if (irq == IRQ_M_SOFT)
        mie &= ~MIE_MSIE;
    else if (irq == IRQ_M_EXT)
        mie &= ~MIE_MEIE;
    w_mie(mie);
}

extern void kernelvec(void);

void trap_init(void)
{
    // set mtvec to point to kernelvec in direct mode
    w_mtvec((uint64)kernelvec);
    // init vector table
    for (int i = 0; i < 64; i++)
        interrupt_vector[i] = default_handler;
    // enable global interrupt in mstatus (mie bits are enabled per interrupt)
    uint64 m = r_mstatus(); // 读取当前机器状态
    m |= MSTATUS_MIE;       // 设置机器模式中断使能位
    w_mstatus(m);           // 写入机器状态
}
// 检查mcause最高位判断是中断还是异常
// 如果最高位为1，则是中断，否则是异常
static inline int is_interrupt(uint64 mcause)
{
    return (mcause >> 63) != 0;
}

// 检查地址是否在内核范围内
static inline int is_kernel_address(uint64 addr)
{
    // 内核地址范围：0x80000000 以上（物理地址映射）
    return addr >= 0x80000000UL;
}

// 检查当前是否在内核模式
static inline int is_kernel_mode(void)
{
    uint64 mstatus = r_mstatus();
    uint64 mpp = (mstatus >> 11) & 3;
    return mpp == 3; // M-mode
}

// 系统调用处理（参考xv6）
void handle_syscall(struct trapframe *tf)
{
    uint64 syscall_num = tf->a7;
    // uint64 args[6] = {tf->a0, tf->a1, tf->a2, tf->a3, tf->a4, tf->a5};

    // 检查是否在内核模式（当前只有内核模式）
    if (!is_kernel_mode())
    {
        printf("Syscall from non-kernel mode not supported yet\n");
        tf->a0 = -1; // 返回错误
        tf->mepc += instruction_length(tf->mepc);
        return;
    }

    // 系统调用分发
    switch (syscall_num)
    {
    case 0: // 占位：未来可以添加实际系统调用
        printf("Syscall 0: syscall framework ready\n");
        tf->a0 = 0; // 成功
        break;
    case SYS_SETPRIORITY: // 设置进程优先级
        tf->a0 = sys_setpriority((int)tf->a0, (int)tf->a1);
        break;
    case SYS_GETPRIORITY: // 获取进程优先级
        tf->a0 = sys_getpriority((int)tf->a0);
        break;
    default:
        printf("Unknown syscall: num=%lu\n", syscall_num);
        tf->a0 = -1; // 返回错误
        break;
    }

    tf->mepc += instruction_length(tf->mepc);
}

// 页故障处理（如果有分页支持）
void handle_instruction_page_fault(struct trapframe *tf)
{
    uint64 va = r_mtval();
    uint64 mepc = tf->mepc;

    printf("Instruction page fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)mepc);

    // 如果是内核地址且启用了分页，这是严重错误
    if (is_kernel_address(va))
    {
        printf("Kernel instruction page fault - this should not happen!\n");
        panic("Kernel instruction page fault");
    }

    // 用户态页故障处理（当前未实现用户态）
    printf("User instruction page fault not supported yet\n");
    tf->mepc += instruction_length(tf->mepc);
}

void handle_load_page_fault(struct trapframe *tf)
{
    uint64 va = r_mtval();

    printf("Load page fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)tf->mepc);

    // 内核地址的页故障应该panic
    if (is_kernel_address(va))
    {
        printf("Kernel load page fault - this should not happen!\n");
        panic("Kernel load page fault");
    }

    // 用户态页故障处理（当前未实现）
    printf("User load page fault not supported yet\n");
    tf->mepc += instruction_length(tf->mepc);
}

void handle_store_page_fault(struct trapframe *tf)
{
    uint64 va = r_mtval();

    printf("Store page fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)tf->mepc);

    // 内核地址的页故障应该panic
    if (is_kernel_address(va))
    {
        printf("Kernel store page fault - this should not happen!\n");
        panic("Kernel store page fault");
    }

    // 用户态页故障处理（当前未实现）
    printf("User store page fault not supported yet\n");
    tf->mepc += instruction_length(tf->mepc);
}

// 非法指令处理：内核中的非法指令应该panic
// 但在测试场景中，我们允许跳过（测试故意触发的异常）
static int in_test_mode = 0; // 测试模式标志

void set_test_mode(int mode)
{
    in_test_mode = mode;
}

void handle_illegal_instruction(struct trapframe *tf)
{
    uint64 mepc = tf->mepc;
    uint64 mtval = r_mtval();

    printf("Illegal instruction: mtval=0x%p mepc=0x%p\n", (void *)mtval, (void *)mepc);

    // 内核代码中的非法指令是严重错误
    if (is_kernel_address(mepc))
    {
        if (in_test_mode)
        {
            // 测试模式：只打印警告，不panic
            printf("  [TEST MODE] Kernel illegal instruction detected, skipping...\n");
        }
        else
        {
            // 正常模式：panic
            printf("Kernel illegal instruction at 0x%p - system error!\n", (void *)mepc);
            panic("Kernel illegal instruction");
        }
    }
    else
    {
        // 用户态非法指令（当前未实现用户态，暂时跳过）
        printf("User illegal instruction handling not implemented yet\n");
    }

    tf->mepc += instruction_length(tf->mepc);
}

// 访问故障处理：内核地址出错应该panic
void handle_load_access_fault(struct trapframe *tf)
{
    uint64 va = r_mtval();
    uint64 mepc = tf->mepc;

    printf("Load access fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)mepc);

    // 内核地址的访问故障通常是严重错误
    if (is_kernel_address(va) || is_kernel_address(mepc))
    {
        if (in_test_mode)
        {
            // 测试模式：只打印警告，不panic
            printf("  [TEST MODE] Kernel load access fault detected, skipping...\n");
        }
        else
        {
            // 正常模式：panic
            printf("Kernel load access fault - memory protection violation!\n");
            panic("Kernel load access fault");
        }
    }
    else
    {
        // 用户态访问故障（当前未实现）
        printf("User load access fault not supported yet\n");
    }

    tf->mepc += instruction_length(tf->mepc);
}

void handle_store_access_fault(struct trapframe *tf)
{
    uint64 va = r_mtval();
    uint64 mepc = tf->mepc;

    printf("Store access fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)mepc);

    // 内核地址的访问故障通常是严重错误
    if (is_kernel_address(va) || is_kernel_address(mepc))
    {
        if (in_test_mode)
        {
            // 测试模式：只打印警告，不panic
            printf("  [TEST MODE] Kernel store access fault detected, skipping...\n");
        }
        else
        {
            // 正常模式：panic
            printf("Kernel store access fault - memory protection violation!\n");
            panic("Kernel store access fault");
        }
    }
    else
    {
        // 用户态访问故障（当前未实现）
        printf("User store access fault not supported yet\n");
    }

    tf->mepc += instruction_length(tf->mepc);
}

void handle_exception(struct trapframe *tf)
{
    uint64 raw = r_mcause();
    uint64 cause = raw & 0xfff;
    switch (cause)
    {
    case 2: // illegal instruction
        handle_illegal_instruction(tf);
        break;
    case 5: // load access fault
        handle_load_access_fault(tf);
        break;
    case 7: // store/AMO access fault
        handle_store_access_fault(tf);
        break;
    case 8:  // ecall from U
    case 9:  // ecall from S
    case 11: // ecall from M
        handle_syscall(tf);
        break;
    case 12: // instruction page fault
        handle_instruction_page_fault(tf);
        break;
    case 13: // load page fault
        handle_load_page_fault(tf);
        break;
    case 15: // store page fault
        handle_store_page_fault(tf);
        break;
    default:
        printf("Unknown exception: mcause=%lu mtval=0x%p mepc=0x%p\n", raw, (void *)r_mtval(), (void *)tf->mepc);
        panic("Unknown exception");
    }
}

void kerneltrap(void)
{
    uint64 trap_start = get_time();

    uint64 mcause = r_mcause();
    if (is_interrupt(mcause))
    {
        int irq = (int)(mcause & 0xfff);
        if (irq >= 0 && irq < 64 && interrupt_vector[irq])
        {
            interrupt_vector[irq]();
        }
        else
        {
            default_handler();
        }
    }
    else
    {
        handle_exception(&_trapframe);
    }

    // 统计上下文切换开销（保存+恢复+处理）
    uint64 trap_end = get_time();
    uint64 context_time = trap_end - trap_start;

    total_context_switch_time += context_time;
    context_switch_count++;
    if (context_time > max_context_switch_time)
        max_context_switch_time = context_time;
    if (context_time < min_context_switch_time)
        min_context_switch_time = context_time;

    // 检查当前进程是否需要让出 CPU（时间片用完）
    // 在 trap 返回前检查，这样可以安全地触发调度
    struct proc *p = myproc();
    if (p)
    {
        acquire(&p->lock);
        // 如果进程状态是 RUNNABLE 且时间片用完，需要让出 CPU
        if (p->state == RUNNABLE && p->time_slice == 0)
        {
            // 调用 yield() 触发调度
            // 注意：yield() 会释放锁并调用 sched()
            p->state = RUNNABLE; // 确保状态是 RUNNABLE
            release(&p->lock);
            yield(); // 这会触发调度，不会返回
        }
        else
        {
            release(&p->lock);
        }
    }
}
