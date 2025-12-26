#机器模式定时器中断处理程序，负责：
#重新设置定时器：计算并设置下一次中断时间
#中断转发：将M-mode定时器中断转发给S-mode处理
#多核支持：为每个硬件线程（hart）独立设置定时器

.section .text           # 指定代码段
    .align 2                 # 4字节对齐
    .globl timervec          # 声明为全局符号，可被其他文件引用
    .type timervec, @function  # 指定timervec是一个函数

/* Machine-mode timer interrupt handler: 机器模式定时器中断处理程序
   - Program next mtimecmp: 编程下一次定时器比较值
   - Set SIP.STIP to forward interrupt to S-mode: 设置SIP.STIP位，将中断转发给S模式
   - Return with mret to resume S-mode execution: 通过mret返回，恢复S模式执行
*/

# timervec: 定时器中断处理程序
# 作用：处理机器模式定时器中断，设置下一次中断时间，并将中断转发给主管模式
timervec:
    # 保存现场：为被调用者保存的寄存器分配栈空间
    addi    sp, sp, -32      # 分配32字节栈空间
    sd      ra, 0(sp)        # 保存返回地址
    sd      t0, 8(sp)        # 保存临时寄存器t0
    sd      t1, 16(sp)       # 保存临时寄存器t1
    sd      t2, 24(sp)       # 保存临时寄存器t2

    /* 读取当前时间 */
    li      t0, 0x0200bff8   /* CLINT_MTIME内存映射地址 = CLINT_BASE + 0xbff8 */
    ld      t1, 0(t0)        /* t1 = mtime当前计数值 */

    /* 计算下一次中断时间：当前时间 + 间隔 */
    /* 时间间隔 = 10,000,000 / 100 = 100,000 周期（假设时钟10MHz，需要100Hz中断） */
    li      t2, 100000       /* 每次中断间隔100,000个时钟周期 */
    add     t1, t1, t2       /* t1 = 下一次中断的绝对时间 */

    /* 写入mtimecmp寄存器：设置下一次定时器中断时间 */
    /* 每个hart有自己的mtimecmp寄存器：地址 = 0x02004000 + 8 * hart_id */
    csrr    t0, mhartid      /* 读取当前硬件线程ID */
    slli    t0, t0, 3        /* 乘以8（每个mtimecmp是8字节） */
    li      t2, 0x02004000   /* CLINT_MTIMECMP基地址 = CLINT_BASE + 0x4000 */
    add     t2, t2, t0       /* t2 = 当前hart的mtimecmp地址 */
    sd      t1, 0(t2)        /* 设置下一次中断时间 */

    /* 设置主管模式软件中断挂起位：SIP.SSIP（第1位） */
    /* 目的：将中断转发给S模式，让S模式的中断处理程序处理定时器中断 */
    csrr    t0, sip          /* 读取当前SIP寄存器 */
    ori     t0, t0, 0x2      /* 设置第1位（二进制10 = 0x2） */
    csrw    sip, t0          /* 写回SIP寄存器 */

    /* 恢复现场 */
    ld      t2, 24(sp)       # 恢复临时寄存器t2
    ld      t1, 16(sp)       # 恢复临时寄存器t1
    ld      t0, 8(sp)        # 恢复临时寄存器t0
    ld      ra, 0(sp)        # 恢复返回地址
    addi    sp, sp, 32       # 释放栈空间
    
    /* 从机器模式中断返回 */
    mret                     # 返回到被中断的S模式代码