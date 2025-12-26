#ifndef _RISCV_H
#define _RISCV_H

// Machine Status Register, mstatus

#define MSTATUS_MPP_MASK (3 << 11)
#define MSTATUS_MPP_M (3 << 11)
#define MSTATUS_MPP_S (1 << 11)
#define MSTATUS_MPP_U (0 << 11)
#define MSTATUS_MIE (1 << 3)

#define MIE_MSIE (1 << 3)
#define MIE_MTIE (1 << 7)
#define MIE_MEIE (1 << 11)

static inline uint64
r_mstatus()
{
    uint64 x;
    asm volatile("csrr %0, mstatus" : "=r"(x));
    return x;
}

static inline void
w_mstatus(uint64 x)
{
    asm volatile("csrw mstatus, %0" : : "r"(x));
}

// machine exception program counter, holds the
// instruction address to which a return from
// exception will go.
static inline void
w_mepc(uint64 x)
{
    asm volatile("csrw mepc, %0" : : "r"(x));
}

// machine trap handler base address
static inline void
w_mtvec(uint64 x)
{
    asm volatile("csrw mtvec, %0" : : "r"(x));
}

static inline uint64 r_mie()
{
    uint64 x;
    asm volatile("csrr %0, mie" : "=r"(x));
    return x;
}
static inline void w_mie(uint64 x)
{
    asm volatile("csrw mie, %0" : : "r"(x));
}
static inline uint64 r_mip()
{
    uint64 x;
    asm volatile("csrr %0, mip" : "=r"(x));
    return x;
}
static inline uint64 r_mepc()
{
    uint64 x;
    asm volatile("csrr %0, mepc" : "=r"(x));
    return x;
}
static inline uint64 r_mcause()
{
    uint64 x;
    asm volatile("csrr %0, mcause" : "=r"(x));
    return x;
}
static inline uint64 r_mtval()
{
    uint64 x;
    asm volatile("csrr %0, mtval" : "=r"(x));
    return x;
}
static inline uint64 r_time()
{
    uint64 x;
    asm volatile("csrr %0, time" : "=r"(x));
    return x;
}

#endif