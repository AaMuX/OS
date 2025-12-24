#机器模式异常/中断入口
#当CPU运行在最高特权级（M模式）时发生以下情况，CPU会自动跳转到machinevec

.section .text           # 指定代码段
    .align 2                 # 4字节对齐（2^2=4），RISC-V要求跳转地址对齐
    .globl machinevec        # 声明machinevec为全局符号，可供其他文件调用
    .type machinevec, @function  # 指定machinevec是一个函数

# machinevec: 机器模式异常/中断入口函数
# 作用：当CPU运行在机器模式（M-mode）时发生异常或中断，
#       CPU会自动跳转到此函数执行
machinevec:
    # 保存返回地址到栈中，保护现场
    addi    sp, sp, -16      # 分配栈空间（16字节），向下生长
    sd      ra, 0(sp)        # 将返回地址(ra)保存到栈顶
    
    # 读取异常/中断相关信息，为C处理函数准备参数
    csrr    a0, mcause       # 读取mcause寄存器到a0（异常原因代码）
    csrr    a1, mepc         # 读取mepc寄存器到a1（异常发生时PC值）
    
    # 调用C语言异常处理函数
    call    machine_trap     # 跳转到C函数machine_trap(cause, epc)
    
    # 恢复现场
    ld      ra, 0(sp)        # 从栈中恢复返回地址
    addi    sp, sp, 16       # 释放栈空间
    
    # 从异常/中断返回
    mret                     # 机器模式异常返回，恢复mstatus，返回mepc指向的位置