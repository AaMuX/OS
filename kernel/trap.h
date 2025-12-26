#ifndef _TRAP_H
#define _TRAP_H

#include "types.h"

// 系统调用号定义
#define SYS_SETPRIORITY 1
#define SYS_GETPRIORITY 2

struct trapframe
{
    // 第一部分：基本控制寄存器
    uint64 ra; // 返回地址寄存器 (x1)
    uint64 sp; // 栈指针寄存器 (x2)
    uint64 gp; // 全局指针寄存器 (x3)
    uint64 tp; // 线程指针寄存器 (x4)
               // 第二部分：临时寄存器
    uint64 t0;
    uint64 t1;
    uint64 t2; // 临时寄存器 (x5-x7)
               // 第三部分：保存寄存器
    uint64 s0;
    uint64 s1; // 保存寄存器 (x8-x9)
               // 第四部分：参数寄存器
    uint64 a0;
    uint64 a1;
    uint64 a2;
    uint64 a3;
    uint64 a4;
    uint64 a5;
    uint64 a6;
    uint64 a7; // 参数寄存器 (x10-x17)
    uint64 s2;
    uint64 s3;
    uint64 s4;
    uint64 s5;
    uint64 s6;
    uint64 s7;
    uint64 s8;
    uint64 s9;
    uint64 s10;
    uint64 s11; // 保存寄存器 (x18-x27)
    uint64 t3;
    uint64 t4;
    uint64 t5;
    uint64 t6;      // 临时寄存器 (x28-x31)
                    // 第五部分：控制状态寄存器
    uint64 mepc;    // 机器模式异常程序计数器
    uint64 mstatus; // 机器模式状态寄存器
};

void kerneltrap(void);
void handle_exception(struct trapframe *tf);
void handle_syscall(struct trapframe *tf);
void handle_instruction_page_fault(struct trapframe *tf);
void handle_load_page_fault(struct trapframe *tf);
void handle_store_page_fault(struct trapframe *tf);
void handle_illegal_instruction(struct trapframe *tf);
void handle_load_access_fault(struct trapframe *tf);
void handle_store_access_fault(struct trapframe *tf);
void set_test_mode(int mode); // 设置测试模式

#endif
