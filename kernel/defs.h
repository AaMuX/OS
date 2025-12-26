#ifndef _DEFS_H
#define _DEFS_H

#include "types.h"

// UART函数
void uartinit(void);
void uartputc(int c);
int uartgetc(void);
void uart_puts(const char *s);
void uart_flush(void);
int uart_has_char(void);
int uart_rx_available(void);
int uart_readline(char *buf, int maxlen);

// 控制台函数
void console_init(void);
void console_putc(char c);
void console_puts(const char *s);
void console_clear(void);

// ANSI控制功能
void console_clear_line(void);      // 清除当前行
void console_clear_to_end(void);    // 清除到屏幕末尾
void console_goto_xy(int x, int y); // 光标定位
void console_cursor_home(void);     // 光标回家
void console_cursor_save(void);     // 保存光标位置
void console_cursor_restore(void);  // 恢复光标位置
void console_cursor_show(int show); // 显示/隐藏光标

// 颜色输出函数
int printf_color(int color, const char *fmt, ...);
void console_set_color(int color); // 设置颜色
void console_reset_color(void);    // 重置颜色

// printf函数
int printf(const char *fmt, ...);
int sprintf(char *buf, const char *fmt, ...);

// 可变参数支持
typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_end(ap) __builtin_va_end(ap)
// 颜色定义
#define COLOR_BLACK 0
#define COLOR_RED 1
#define COLOR_GREEN 2
#define COLOR_YELLOW 3
#define COLOR_BLUE 4
#define COLOR_MAGENTA 5
#define COLOR_CYAN 6
#define COLOR_WHITE 7
#define COLOR_DEFAULT 9

#define COLOR_FG_BLACK 30
#define COLOR_FG_RED 31
#define COLOR_FG_GREEN 32
#define COLOR_FG_YELLOW 33
#define COLOR_FG_BLUE 34
#define COLOR_FG_MAGENTA 35
#define COLOR_FG_CYAN 36
#define COLOR_FG_WHITE 37
#define COLOR_FG_DEFAULT 39

#define COLOR_BG_BLACK 40
#define COLOR_BG_RED 41
#define COLOR_BG_GREEN 42
#define COLOR_BG_YELLOW 43
#define COLOR_BG_BLUE 44
#define COLOR_BG_MAGENTA 45
#define COLOR_BG_CYAN 46
#define COLOR_BG_WHITE 47
#define COLOR_BG_DEFAULT 49

// 属性定义
#define ATTR_RESET 0
#define ATTR_BOLD 1
#define ATTR_DIM 2
#define ATTR_UNDERLINE 4
#define ATTR_BLINK 5
#define ATTR_REVERSE 7
#define ATTR_HIDDEN 8

// 添加panic函数声明
void panic(const char *s) __attribute__((noreturn));
// interrupt / trap
#include "interrupt.h"
#include "sbi.h"
// Physical Memory Manager
void pmm_init(void);
void *alloc_page(void);
void free_page(void *page);
void *alloc_pages(int n);
void pmm_stats(void);
uint64 get_free_memory(void);
uint64 get_total_memory(void);
void test_pmm_basic(void);

// Virtual Memory Manager - 只声明函数，不包含类型定义
void vm_test_basic(void);
void test_physical_memory(void);
void test_pagetable(void);

// RISC-V CSR 操作函数
static inline uint64 r_satp()
{
    uint64 x;
    asm volatile("csrr %0, satp" : "=r"(x));
    return x;
}

static inline void w_satp(uint64 x)
{
    asm volatile("csrw satp, %0" : : "r"(x));
}

// 文件系统
#include "fs.h"
#include "bio.h"
#include "log.h"
#include "file.h"
#include "sleeplock.h"

#endif