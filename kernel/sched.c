// kernel/sched.c
#include <stdbool.h> // 包含布尔类型定义

// 时间片计数器（静态变量，仅本文件可见）
static int slice = 0;

// should_yield: 检查是否应该让出CPU
// 作用：实现简单的时间片轮转调度策略
// 返回：true表示应该让出CPU，false表示可以继续运行
bool should_yield(void)
{
    // 每10个定时器tick让出一次CPU
    return (++slice % 10) == 0;
    // ++slice: 每次调用计数器加1
    // % 10: 取模10，结果为0时返回true
    // 这意味着当前任务运行了10个时间片
}

// yield: 让出CPU控制权（调度器占位函数）
// 作用：理论上应该进行上下文切换，但当前只是占位符
void yield(void)
{
}