// kernel/start.c

// 启动引导代码，负责从机器模式（M-mode）切换到主管模式（S-mode），并初始化基本的硬件设施
#include "riscv.h"  // RISC-V硬件寄存器访问
#include "trap.h"   // 陷阱处理
#include <stdint.h> // 标准整数类型

// 外部函数声明
extern void machinevec(void);         // 机器模式异常向量
extern void timervec(void);           // 定时器中断向量
extern void kernelvec(void);          // 主管模式异常向量
extern void uart_init(void);          // 串口初始化
extern void uart_puts(const char *s); // 串口输出字符串
extern void uart_putc(char c);        // 串口输出字符
void kmain(void);                     // 主函数（C入口点）

// 声明无返回函数
static void sstart(void) __attribute__((noreturn));

/* 设置物理内存保护（PMP）
 * 作用：配置物理内存访问权限，保护关键内存区域
 * 在当前实现中，配置为允许所有内存区域访问
 */
static void setup_pmp(void)
{
    // 设置PMP地址寄存器0：允许访问所有物理地址
    // ~0ULL >> 2 创建最大的64位地址范围
    w_pmpaddr0(~0ULL >> 2);

    // 配置PMP寄存器0：R=1,W=1,X=1,A=3 (TOR模式)
    // 0x0f = 0b1111: R/W/X/A全设为1
    uint64_t cfg = 0x0f;
    w_pmpcfg0(cfg);
}

/* 串口输出十六进制数值
 * 参数：value - 要输出的64位十六进制值
 */
static void uart_put_hex(uint64_t value)
{
    static const char digits[] = "0123456789abcdef"; // 十六进制字符表
    uart_puts("0x");                                 // 输出前缀

    // 从高4位到低4位依次输出
    for (int shift = 60; shift >= 0; shift -= 4)
    {
        uart_putc(digits[(value >> shift) & 0xf]);
    }
    uart_puts("\n"); // 换行
}

/* 机器模式陷阱处理函数
 * 作用：当发生机器模式异常时调用，用于调试和错误处理
 * 参数：cause - 异常原因码
 *       epc   - 异常发生时PC值
 */
void machine_trap(uint64_t cause, uint64_t epc)
{
    uart_init(); // 初始化串口
    uart_puts("Machine trap!\n");
    uart_puts(" cause=");
    uart_put_hex(cause); // 输出异常原因
    uart_puts(" mepc=");
    uart_put_hex(epc); // 输出异常PC
    uart_puts("Halting.\n");

    // 进入死循环，等待中断
    while (1)
    {
        asm volatile("wfi"); // 等待中断
    }
}

/* 委托陷阱处理
 * 作用：将大部分陷阱（异常和中断）从M模式委托给S模式处理
 */
static void delegate_traps(void)
{
    // 委托同步异常（常见异常）
    // 0xffff = 0b1111111111111111，委托前16种异常
    uint64_t medeleg = r_medeleg();
    medeleg |= 0xffff; // 委托常见同步异常
    w_medeleg(medeleg);

    // 委托中断
    // 将S模式的中断委托给S模式处理
    uint64_t mideleg = r_mideleg();
    mideleg |= (1UL << SCAUSE_SUPERVISOR_SOFTWARE) | // 软件中断
               (1UL << SCAUSE_SUPERVISOR_TIMER) |    // 定时器中断
               (1UL << SCAUSE_SUPERVISOR_EXTERNAL);  // 外部中断
    w_mideleg(mideleg);
}

/* 设置定时器MMIO
 * 作用：配置CLINT定时器比较寄存器，设置第一次定时器中断
 */
static void setup_timer_mmio(void)
{
    // 获取当前硬件线程ID
    uint64_t hart = r_mhartid();

    // 获取当前hart的定时器比较寄存器地址
    // CLINT_MTIMECMP(hart) = 0x02004000 + 8*hart
    volatile uint64_t *mtimecmp = (volatile uint64_t *)CLINT_MTIMECMP(hart);

    // 获取全局时间计数器地址
    volatile uint64_t *mtime = (volatile uint64_t *)CLINT_MTIME;

    // 计算下一次中断时间
    const uint64_t now = *mtime;                      // 当前时间
    const uint64_t interval = (10000000ULL / 100ULL); // 100,000周期 = 100Hz
    *mtimecmp = now + interval;                       // 设置下一次中断
}

/* S模式启动函数
 * 作用：这是M模式切换到S模式后的入口点
 */
static void sstart(void)
{
    uart_init(); // 初始化串口
    trap_init(); // 初始化陷阱处理系统
    // kmain();     // 进入C语言主函数

    // 主函数不应返回，如果返回则在此等待
    while (1)
    {
        asm volatile("wfi"); // 等待中断
    }
}

/* 系统启动入口函数
 * 作用：这是CPU启动后执行的第一个C函数（在汇编_entry之后调用）
 */
void start(void)
{
    // 设置机器模式定时器中断向量
    w_mtvec((uint64_t)timervec);

    // 设置主管模式陷阱向量
    w_stvec((uint64_t)kernelvec);

    // 委托陷阱给S模式处理
    delegate_traps();

    // 设置物理内存保护
    setup_pmp();

    // 启用S模式的时间计数器访问
    w_mcounteren(r_mcounteren() | (1UL << 1));

    // 禁用虚拟内存（启动阶段使用物理地址）
    w_satp(0);

    // 使能中断
    // 机器模式中断使能
    w_mie(r_mie() | MIE_MSIE | MIE_MTIE | MIE_MEIE | // M模式
          MIE_SSIE | MIE_STIE | MIE_SEIE);           // S模式
    // 主管模式中断使能
    w_sie(r_sie() | SIE_STIE | SIE_SSIE | SIE_SEIE);

    // 初始化定时器
    setup_timer_mmio();

    // 配置mstatus寄存器，准备切换到S模式
    uint64_t mstatus = r_mstatus();
    mstatus &= ~MSTATUS_MPP_MASK; // 清除之前的特权级
    mstatus |= MSTATUS_MPP_S;     // 设置返回特权级为S模式
    mstatus |= MSTATUS_MPIE;      // 使能返回后中断
    mstatus &= ~MSTATUS_MIE;      // 在M模式中禁用中断
    w_mstatus(mstatus);

    // 调试输出
    uart_init();
    uart_puts("Booting into S-mode...\n");
    uart_puts(" mstatus=");
    uart_put_hex(r_mstatus());

    // 设置返回地址为sstart，通过mret进入S模式
    w_mepc((uint64_t)sstart);

    // 从M模式返回到S模式
    asm volatile("mret");
}