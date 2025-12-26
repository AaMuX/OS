#include "types.h"
typedef unsigned long uint64;

// QEMU virt: CLINT base 0x02000000
//CLINT (Core Local Interruptor) 是RISC-V平台的中断控制器
#define CLINT_BASE   0x02000000UL //在QEMU的virt机器定义中，这个地址是固定的
#define CLINT_MTIMECMP(hart) (CLINT_BASE + 0x4000 + 8*(hart))//机器模式定时器比较寄存器(MTIMECMP)
#define CLINT_MTIME  (CLINT_BASE + 0xBFF8)//机器模式定时器寄存器(MTIME)

static inline void write64(volatile uint64 *addr, uint64 val) {
    *(addr) = val;//写入64位值到指定地址
}

static inline uint64 read64(volatile uint64 *addr) {
    return *(addr);//读取64位值从指定地址
}

void sbi_set_timer(uint64 time) {
    volatile uint64 *mtimecmp = (volatile uint64*)CLINT_MTIMECMP(0);
    write64(mtimecmp, time);//写入时间戳到MTIMECMP寄存器
}//当MTIME >= MTIMECMP时，会触发定时器中断
//获取当前时间戳的函数
uint64 get_time(void) {
    volatile uint64 *mtime = (volatile uint64*)CLINT_MTIME;
    return read64(mtime);
}

