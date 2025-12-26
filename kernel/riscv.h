// kernel/riscv.h
#pragma once
#include <stdint.h>

// 注意：这是一个RISC-V体系结构相关的头文件
// 作用：为RISC-V架构提供控制状态寄存器(CSR)的读写接口和常量定义
//      是操作系统内核与硬件交互的桥梁

// ---------------- Machine CSR helpers ----------------
// 机器模式控制状态寄存器读写函数
// 机器模式(M-mode)是最高特权级，可以直接访问所有硬件资源

// 读取机器状态寄存器 mstatus
static inline uint64_t r_mstatus(void)
{
    uint64_t x;
    asm volatile("csrr %0, mstatus" : "=r"(x));
    return x;
}
// 写入机器状态寄存器 mstatus
static inline void w_mstatus(uint64_t x) { asm volatile("csrw mstatus, %0" ::"r"(x)); }

// 读取机器模式中断使能寄存器 mie
static inline uint64_t r_mie(void)
{
    uint64_t x;
    asm volatile("csrr %0, mie" : "=r"(x));
    return x;
}
// 写入机器模式中断使能寄存器 mie
static inline void w_mie(uint64_t x) { asm volatile("csrw mie, %0" ::"r"(x)); }

// 读取机器模式中断挂起寄存器 mip
static inline uint64_t r_mip(void)
{
    uint64_t x;
    asm volatile("csrr %0, mip" : "=r"(x));
    return x;
}
// 写入机器模式中断挂起寄存器 mip
static inline void w_mip(uint64_t x) { asm volatile("csrw mip, %0" ::"r"(x)); }

// 读取机器模式异常委托寄存器 medeleg
static inline uint64_t r_medeleg(void)
{
    uint64_t x;
    asm volatile("csrr %0, medeleg" : "=r"(x));
    return x;
}
// 写入机器模式异常委托寄存器 medeleg
static inline void w_medeleg(uint64_t x) { asm volatile("csrw medeleg, %0" ::"r"(x)); }

// 读取机器模式中断委托寄存器 mideleg
static inline uint64_t r_mideleg(void)
{
    uint64_t x;
    asm volatile("csrr %0, mideleg" : "=r"(x));
    return x;
}
// 写入机器模式中断委托寄存器 mideleg
static inline void w_mideleg(uint64_t x) { asm volatile("csrw mideleg, %0" ::"r"(x)); }

// 读取机器模式异常向量基址寄存器 mtvec
static inline uint64_t r_mtvec(void)
{
    uint64_t x;
    asm volatile("csrr %0, mtvec" : "=r"(x));
    return x;
}
// 写入机器模式异常向量基址寄存器 mtvec
static inline void w_mtvec(uint64_t x) { asm volatile("csrw mtvec, %0" ::"r"(x)); }

// 读取机器模式异常程序计数器 mepc
static inline uint64_t r_mepc(void)
{
    uint64_t x;
    asm volatile("csrr %0, mepc" : "=r"(x));
    return x;
}
// 写入机器模式异常程序计数器 mepc
static inline void w_mepc(uint64_t x) { asm volatile("csrw mepc, %0" ::"r"(x)); }

// 读取机器模式异常原因寄存器 mcause
static inline uint64_t r_mcause(void)
{
    uint64_t x;
    asm volatile("csrr %0, mcause" : "=r"(x));
    return x;
}

// 读取机器模式硬件线程ID mhartid
static inline uint64_t r_mhartid(void)
{
    uint64_t x;
    asm volatile("csrr %0, mhartid" : "=r"(x));
    return x;
}

// 写入机器模式临时寄存器 mscratch
static inline void w_mscratch(uint64_t x) { asm volatile("csrw mscratch, %0" ::"r"(x)); }

// 读取机器模式计数器使能寄存器 mcounteren
static inline uint64_t r_mcounteren(void)
{
    uint64_t x;
    asm volatile("csrr %0, mcounteren" : "=r"(x));
    return x;
}
// 写入机器模式计数器使能寄存器 mcounteren
static inline void w_mcounteren(uint64_t x) { asm volatile("csrw mcounteren, %0" ::"r"(x)); }

// 写入物理内存保护地址寄存器0 pmpaddr0
static inline void w_pmpaddr0(uint64_t x) { asm volatile("csrw pmpaddr0, %0" ::"r"(x)); }

// 写入物理内存保护配置寄存器0 pmpcfg0
static inline void w_pmpcfg0(uint64_t x) { asm volatile("csrw pmpcfg0, %0" ::"r"(x)); }

// ---------------- Supervisor CSR helpers ----------------
// 主管模式控制状态寄存器读写函数
// 主管模式(S-mode)是操作系统运行的特权级，可以运行内核代码

// 读取主管状态寄存器 sstatus
static inline uint64_t r_sstatus(void)
{
    uint64_t x;
    asm volatile("csrr %0, sstatus" : "=r"(x));
    return x;
}
// 写入主管状态寄存器 sstatus
static inline void w_sstatus(uint64_t x) { asm volatile("csrw sstatus, %0" ::"r"(x)); }

// 读取主管模式中断使能寄存器 sie
static inline uint64_t r_sie(void)
{
    uint64_t x;
    asm volatile("csrr %0, sie" : "=r"(x));
    return x;
}
// 写入主管模式中断使能寄存器 sie
static inline void w_sie(uint64_t x) { asm volatile("csrw sie, %0" ::"r"(x)); }

// 写入主管模式异常向量基址寄存器 stvec
static inline void w_stvec(uint64_t x) { asm volatile("csrw stvec, %0" ::"r"(x)); }

// 读取主管模式异常原因寄存器 scause
static inline uint64_t r_scause(void)
{
    uint64_t x;
    asm volatile("csrr %0, scause" : "=r"(x));
    return x;
}

// 读取主管模式异常程序计数器 sepc
static inline uint64_t r_sepc(void)
{
    uint64_t x;
    asm volatile("csrr %0, sepc" : "=r"(x));
    return x;
}
// 写入主管模式异常程序计数器 sepc
static inline void w_sepc(uint64_t x) { asm volatile("csrw sepc, %0" ::"r"(x)); }

// 读取主管模式异常值寄存器 stval
static inline uint64_t r_stval(void)
{
    uint64_t x;
    asm volatile("csrr %0, stval" : "=r"(x));
    return x;
}

// 读取主管模式中断挂起寄存器 sip
static inline uint64_t r_sip(void)
{
    uint64_t x;
    asm volatile("csrr %0, sip" : "=r"(x));
    return x;
}
// 写入主管模式中断挂起寄存器 sip
static inline void w_sip(uint64_t x) { asm volatile("csrw sip, %0" ::"r"(x)); }

// 读取时间计数器 time
static inline uint64_t r_time(void)
{
    uint64_t x;
    asm volatile("rdtime %0" : "=r"(x));
    return x;
}

// 写入地址转换和保护寄存器 satp
static inline void w_satp(uint64_t x) { asm volatile("csrw satp, %0" ::"r"(x)); }

// ---------------- SSTATUS/SIE/SIP bits ----------------
// 主管状态寄存器位定义
#define SSTATUS_SIE (1UL << 1) // 全局S模式中断使能位

// 主管中断使能寄存器位定义
#define SIE_SEIE (1UL << 9) // 外部中断使能
#define SIE_STIE (1UL << 5) // 定时器中断使能
#define SIE_SSIE (1UL << 1) // 软件中断使能

// 主管中断挂起寄存器位定义
#define SIP_SEIP (1UL << 9) // 外部中断挂起
#define SIP_STIP (1UL << 5) // 定时器中断挂起
#define SIP_SSIP (1UL << 1) // 软件中断挂起

// ---------------- MSTATUS/MIE bits ----------------
// 机器状态寄存器位定义
#define MSTATUS_MIE (1UL << 3)       // 机器模式中断使能
#define MSTATUS_SIE (1UL << 1)       // 主管模式中断使能
#define MSTATUS_MPIE (1UL << 7)      // 之前的机器模式中断使能
#define MSTATUS_SPIE (1UL << 5)      // 之前的监督模式中断使能
#define MSTATUS_SPP (1UL << 8)       // 异常前的特权级(1=S-mode, 0=U-mode)
#define MSTATUS_MPP_MASK (3UL << 11) // 机器模式前特权级掩码
#define MSTATUS_MPP_U (0UL << 11)    // 来自用户模式
#define MSTATUS_MPP_S (1UL << 11)    // 来自监督模式
#define MSTATUS_MPP_M (3UL << 11)    // 来自机器模式

// 机器中断使能寄存器位定义
#define MIE_MSIE (1UL << 3)  // 机器软件中断使能
#define MIE_MTIE (1UL << 7)  // 机器定时器中断使能
#define MIE_MEIE (1UL << 11) // 机器外部中断使能
#define MIE_SSIE (1UL << 1)  // 主管软件中断使能
#define MIE_STIE (1UL << 5)  // 主管定时器中断使能
#define MIE_SEIE (1UL << 9)  // 主管外部中断使能

// ---------------- scause decoding ----------------
// 主管异常原因解码宏
#define SCAUSE_INTR_MASK (1ULL << 63)   // 最高位为1表示中断，0表示异常
#define SCAUSE_CODE(x) ((x) & 0xfffULL) // 获取异常/中断编码
#define SCAUSE_SUPERVISOR_SOFTWARE 1    // 主管软件中断
#define SCAUSE_SUPERVISOR_TIMER 5       // 主管定时器中断
#define SCAUSE_SUPERVISOR_EXTERNAL 9    // 主管外部中断

// ---------------- convenience ----------------
// 便捷函数：开启中断
static inline void intr_on(void) { w_sstatus(r_sstatus() | SSTATUS_SIE); }
// 便捷函数：关闭中断
static inline void intr_off(void) { w_sstatus(r_sstatus() & ~SSTATUS_SIE); }

// ---------------- CLINT MMIO layout ----------------
// 核本地中断控制器(CLINT)内存映射I/O布局
// CLINT是RISC-V平台上的中断控制器，用于定时器和软件中断
#define CLINT_BASE 0x02000000UL
#define CLINT_MTIMECMP(hart) (CLINT_BASE + 0x4000 + 8 * (hart)) // 每个硬件线程的定时器比较值
#define CLINT_MTIME (CLINT_BASE + 0xbff8)                       // 全局时间计数器