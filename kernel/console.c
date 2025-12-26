// 实现了操作系统的控制台功能，是内核输出系统的重要组成部分
// 提供了ANSI转义序列支持、颜色输出、光标控制等高级终端功能。
#include <stdarg.h>
#include "console.h"

extern void uart_putc(char c);                               // uart.c底层串口字符输出函
extern int vsprintf(char *buf, const char *fmt, va_list ap); // printf.c可变参数字符串格式化函数
extern int sprintf(char *buf, const char *fmt, ...);         // 字符串格式化函数

void console_putc(char c) { uart_putc(c); } // 控制台的字符输出委托给底层的UART驱动uart_putc(c)
// 字符串输出
void console_puts(const char *s)
{
    if (!s)
        s = "(null)";
    while (*s)
        console_putc(*s++);
}
// ANSI转义序列，实现终端清屏功能
void clear_screen(void) { console_puts("\033[2J\033[H"); }
// 将光标定位到指定的行和列位置
void goto_xy(int row, int col)
{
    char buf[16];                          // 分配16字节的缓冲区用于构建转义序列
    sprintf(buf, "\033[%d;%dH", row, col); // 格式化生成光标定位序列
    console_puts(buf);
}
// 清除当前行的部分内容
void clear_line(void) { console_puts("\033[K"); }

int printf_color(enum COLOR color, const char *fmt, ...)
{
    // 处理像printf一样的可变参数，生成格式化字符串
    char buf[256];
    va_list ap;
    va_start(ap, fmt);
    int len = vsprintf(buf, fmt, ap);
    va_end(ap);

    // 发送颜色开始标记，设置后续文本的颜色
    char color_buf[8];
    sprintf(color_buf, "\033[%dm", color);
    console_puts(color_buf);
    // 输出
    console_puts(buf);
    console_puts("\033[0m");
    return len;
}
