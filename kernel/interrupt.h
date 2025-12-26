#ifndef _INTERRUPT_H
#define _INTERRUPT_H

#include "types.h"

typedef void (*interrupt_handler_t)(void);

void trap_init(void);
void register_interrupt(int irq, interrupt_handler_t h);
void unregister_interrupt(int irq); // 注销中断处理函数
void enable_interrupt(int irq);
void disable_interrupt(int irq);

// 性能统计接口
uint64 trap_get_context_switch_count(void);
uint64 trap_get_total_context_switch_time(void);
uint64 trap_get_max_context_switch_time(void);
uint64 trap_get_min_context_switch_time(void);
void trap_reset_stats(void);

#define IRQ_M_SOFT 3
#define IRQ_M_TIMER 7
#define IRQ_M_EXT 11

#endif
