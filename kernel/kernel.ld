/* Linker script for minimal bare-metal RISC-V kernel */
/* 链接器脚本注释：用于最小化RISC-V裸机内核 */

/* 指定程序入口点为 _start 符号 */
ENTRY(_start)

/* 定义栈顶地址为 0x80020000（128KB偏移） */
PROVIDE(_stack_top = 0x80020000);

/* SECTIONS 命令开始定义内存布局 */
SECTIONS
{
    /* 设置当前位置计数器为 0x80000000，这是内核的加载地址 */
    /* QEMU virt 机器使用 -kernel 选项时会自动加载到此地址 */
    . = 0x80000000;

    /* 定义代码段起始位置标记 */
    _text = .;
    /* .text 段：存放所有代码 */
    .text : {
        *(.text*)          /* 通配符匹配所有.text开头的段 */
    }
    /* 定义代码段结束位置标记 */
    _etext = .;

    /* 定义只读数据段起始位置 */
    _rodata = .;
    /* .rodata 段：存放常量数据 */
    .rodata : {
        *(.rodata*)        /* 匹配所有.rodata开头的段 */
    }
    /* 定义只读数据段结束位置 */
    _erodata = .;

    /* 定义已初始化数据段起始位置 */
    _data = .;
    /* .data 段：存放已初始化的全局变量和静态变量 */
    .data : {
        *(.data*)          /* 匹配所有.data开头的段 */
    }
    /* 定义已初始化数据段结束位置 */
    _edata = .;

    /* .bss 段：存放未初始化的全局变量和静态变量 */
    /* NOLOAD 标记表示该段在可执行文件中不占空间，只在运行时分配内存 */
    .bss (NOLOAD) : {
        /* 定义BSS段起始符号，供启动代码清零使用 */
        __bss_start = .;
        *(.bss*)           /* 匹配所有.bss开头的段 */
        *(COMMON)          /* 匹配COMMON段（未初始化的全局变量） */
        /* 定义BSS段结束符号，供启动代码清零使用 */
        __bss_end = .;
    }
    
    /* 定义程序结束位置，可用于内存分配器的起始地址 */
    _end = .;  
}