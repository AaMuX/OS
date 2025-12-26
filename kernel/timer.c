#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "interrupt.h"
#include "sbi.h"
#include "timer.h"
#include "proc.h"

static volatile int timer_ticks;//记录系统启动以来的定时器滴答数
//定时器间隔，默认1000000个时钟周期触发一次中断
static uint64 timer_interval = 1000000; // cycles per tick (adjust as needed)

// 性能统计
static volatile uint64 total_interrupt_time = 0;//累计中断处理时间
static volatile uint64 interrupt_count = 0;//中断处理次数
static volatile uint64 max_interrupt_time = 0;//最长中断处理时间
static volatile uint64 min_interrupt_time = ~0UL;//最短中断处理时间

int timer_get_ticks(void) { return timer_ticks; }

uint64 timer_get_interrupt_count(void) { return interrupt_count; }
uint64 timer_get_total_interrupt_time(void) { return total_interrupt_time; }
uint64 timer_get_max_interrupt_time(void) { return max_interrupt_time; }
uint64 timer_get_min_interrupt_time(void) { return min_interrupt_time == ~0UL ? 0 : min_interrupt_time; }
void timer_reset_stats(void) {
    total_interrupt_time = 0;
    interrupt_count = 0;
    max_interrupt_time = 0;
    min_interrupt_time = ~0UL;
}


//核心功能函数
static void program_next_timer(void) {
    uint64 now = get_time();
    sbi_set_timer(now + timer_interval);//通过SBI调用设置机器模式定时器
}

void timer_interrupt(void) {
    // 记录中断进入时间（在trap entry中已记录，这里只统计处理时间）
    uint64 start = get_time();
    
    // 1. 更新系统时间（这里简单计数）
    timer_ticks++;
    // 2. 处理定时器事件（占位）
    // 3. 触发任务调度（占位）
    // 4. 设置下次中断时间
    program_next_timer();

    // MLFQ: 处理当前运行进程的时间片
    struct proc *p = myproc();
    if (p && p->state == RUNNING) {
        acquire(&p->lock);
        
        // 减少时间片
        if (p->time_slice > 0) {
            p->time_slice--;
            p->ticks++;
            
            // 如果时间片用完了
            if (p->time_slice == 0) {
                p->time_slice_used++;
                p->consecutive_slices++;
                printf("[MLFQ] PID %d time slice exhausted (consecutive_slices: %d/%d)\n", 
                       p->pid, p->consecutive_slices, CPU_INTENSIVE_THRESHOLD);
                
                // 检查是否需要降级（CPU密集型）
                if (p->consecutive_slices >= CPU_INTENSIVE_THRESHOLD) {
                    if (p->priority > PRIORITY_MIN) {
                        p->priority--;
                        p->consecutive_slices = 0;
                        // 重置等待时间，防止立即被 aging 提升回去
                        // CPU 密集型任务被降级后，需要重新等待 aging 阈值才能提升
                        p->wait_time = 0;
                        printf("[MLFQ] PID %d demoted to priority %d (CPU-intensive, wait_time reset)\n", 
                               p->pid, p->priority);
                    }
                }
                
                // 时间片用完，设置进程状态为 RUNNABLE
                // 注意：不能在中断处理函数中直接调用 yield()，因为 yield() 会进行上下文切换
                // 这会导致栈损坏。改为设置状态，让 trap 返回后自然进入调度器
                p->state = RUNNABLE;
            }
        }
        
        release(&p->lock);
    }
    
    // 统计处理时间（不包括上下文保存/恢复）---性能度量的一些处理
    uint64 end = get_time();
    uint64 duration = end - start;
    total_interrupt_time += duration;
    interrupt_count++;
    if (duration > max_interrupt_time) max_interrupt_time = duration;
    if (duration < min_interrupt_time) min_interrupt_time = duration;
}

void timer_set_interval(uint64 interval) {
    timer_interval = interval;
}

uint64 timer_get_interval(void) {
    return timer_interval;
}

void timer_init(void) {
    register_interrupt(IRQ_M_TIMER, timer_interrupt);
    enable_interrupt(IRQ_M_TIMER);
    program_next_timer();
}

