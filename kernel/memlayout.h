#ifndef _MEMLAYOUT_H
#define _MEMLAYOUT_H

#define RAMBASE 0x80000000
#define RAMSIZE (128 * 1024 * 1024) // 128MB
#define PHYSTOP (RAMBASE + RAMSIZE) // 物理内存顶部
#define PHYSICAL_TOP PHYSTOP        // 别名
#define KERNBASE RAMBASE            // 内核基地址

#define UART0 0x10000000
#define VIRTIO0 0x10001000

// CLINT (Core Local Interruptor) 地址
#define CLINT_BASE 0x02000000UL
#define CLINT_MTIMECMP(hart) (CLINT_BASE + 0x4000 + 8 * (hart))
#define CLINT_MTIME (CLINT_BASE + 0xBFF8)

// PLIC (Platform-Level Interrupt Controller) 地址
#define PLIC_BASE 0x0c000000UL
#define PLIC_PRIORITY(id) (PLIC_BASE + (id) * 4)
#define PLIC_PENDING(id) (PLIC_BASE + 0x1000 + ((id) / 32) * 4)
#define PLIC_ENABLE(hart, id) (PLIC_BASE + 0x2000 + (hart) * 0x100 + ((id) / 32) * 4)
#define PLIC_CLAIM(hart) (PLIC_BASE + 0x200004 + (hart) * 0x1000)
#define PLIC_COMPLETE(hart, id) PLIC_CLAIM(hart)

// UART中断ID（在QEMU virt中通常是10）
#define UART_IRQ 10

// 外部符号声明（在 kernel.ld 中定义）
extern char etext[]; // 代码段结束
extern char end[];   // 内核结束（BSS段之后）

#endif