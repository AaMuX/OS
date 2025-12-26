#ifndef _TIMER_H
#define _TIMER_H

#include "types.h"

void timer_init(void);
int timer_get_ticks(void);
uint64 timer_get_interrupt_count(void);
uint64 timer_get_total_interrupt_time(void);
uint64 timer_get_max_interrupt_time(void);
uint64 timer_get_min_interrupt_time(void);
void timer_reset_stats(void);
void timer_set_interval(uint64 interval);
uint64 timer_get_interval(void);

#endif

