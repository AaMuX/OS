// kernel/sbi.h
// SBI (Supervisor Binary Interface)​ 是RISC-V架构中的主管二进制接口
// 相当于操作系统与M-mode固件之间的"系统调用"，运行在S-mode的操作系统通过SBI请求M-mode的服务
#pragma once // 防止头文件重复包含

#include <stdint.h> // 包含标准整数类型

// sbi_call: 通用的SBI(Supervisor Binary Interface)调用函数
// 作用：通过ecall指令从S-mode(主管模式)陷入M-mode(机器模式)，
//       调用M-mode固件提供的服务
// 参数：
//   extension - SBI扩展ID，标识要调用的SBI服务类别
//   function  - 扩展内的具体功能编号
//   arg0, arg1, arg2 - 传递给SBI服务的参数
// 返回值：
//   long - SBI服务的执行结果，通常成功返回0，失败返回错误码
static inline long sbi_call(long extension, long function, long arg0,
                            long arg1, long arg2)
{
    // 按照RISC-V SBI规范，将参数放到特定寄存器：
    // a0-a2: 功能参数
    // a6: 功能号
    // a7: 扩展ID
    register long a0 asm("a0") = arg0;      // 参数0，也作为返回值寄存器
    register long a1 asm("a1") = arg1;      // 参数1
    register long a2 asm("a2") = arg2;      // 参数2
    register long a6 asm("a6") = function;  // 功能号
    register long a7 asm("a7") = extension; // 扩展ID

    // 执行ecall指令，从S-mode陷入M-mode
    // "+r"(a0): a0既是输入也是输出（返回结果）
    // "r"(a1)...: 输入寄存器
    // "memory": 告诉编译器内存可能被修改
    asm volatile("ecall"
                 : "+r"(a0)                           // 输出：a0包含返回值
                 : "r"(a1), "r"(a2), "r"(a6), "r"(a7) // 输入：参数
                 : "memory");                         // 可能修改内存
    return a0;                                        // 返回SBI调用结果
}

// sbi_set_timer: 设置定时器比较值的便捷函数
// 作用：通过SBI定时器扩展设置下一次定时器中断的时间
// 参数：
//   stime_value - 绝对时间值，当time >= stime_value时触发定时器中断
static inline void sbi_set_timer(uint64_t stime_value)
{
    const long SBI_EXT_TIMER = 0x54494D45; // 扩展ID: "TIME"的ASCII码
    const long SBI_TIMER_SET_TIMER = 0;    // 功能号: 设置定时器
    sbi_call(SBI_EXT_TIMER, SBI_TIMER_SET_TIMER, (long)stime_value, 0, 0);
}