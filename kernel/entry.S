.section .text           # 指定后续代码属于.text段（代码段）
    .globl _start           # 声明_start为全局符号，可供链接器使用
    .align 2                # 按2^2=4字节对齐，确保指令地址对齐
_start:                     # 程序入口点标签，操作系统加载后从此处开始执行
    
    # 初始化栈指针：为C代码运行准备栈空间
    la      sp, _stack_top  # 将栈顶地址_load address到sp寄存器

    # 清零BSS段：确保未初始化的全局变量初始值为0
    la      t0, __bss_start # 将BSS段起始地址加载到t0临时寄存器
    la      t1, __bss_end   # 将BSS段结束地址加载到t1临时寄存器
1:  beq     t0, t1, 2f      # 循环开始：如果t0 == t1（BSS段为空），跳转到标签2
    sb      x0, 0(t0)       # 将零寄存器x0的值(0)存储到t0指向的字节
    addi    t0, t0, 1       # t0指针自增1，指向下一个字节
    j       1b              # 无条件跳转回标签1（b=backward），继续循环
2:                          # BSS段清零完成标签
    
    # 跳转到C主函数：将控制权交给内核主程序
    call    main          # 调用main函数，同时将返回地址存入ra寄存器

    # 主函数返回处理：防御性设计，防止系统失控
3:                          # 无限循环标签
    wfi                     # Wait For Interrupt：进入低功耗等待状态，等待中断
    j       3b              # 跳转回标签3，形成死循环（b=backward）