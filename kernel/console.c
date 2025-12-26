// 这是一个嵌入式系统中的控制台输出模块，通过UART（串口）提供基本的文本输出功能。
// 它封装了底层硬件操作，提供了更友好的控制台接口。

#include <stdarg.h>  // 可变参数支持
#include "console.h" // 控制台相关的函数声明和常量定义

// 外部函数声明（在其他文件中实现）
extern void uart_putc(char c);                               // 向UART发送单个字符
extern int vsprintf(char *buf, const char *fmt, va_list ap); // 格式化字符串到缓冲区
extern int sprintf(char *buf, const char *fmt, ...);         // 格式化字符串

/* 向控制台输出单个字符 */
void console_putc(char c) { uart_putc(c); }

/* 向控制台输出字符串 */
void console_puts(const char *s)
{
    if (!s) // 处理空指针
        s = "(null)";
    while (*s)              // 遍历字符串直到结束符
        console_putc(*s++); // 输出每个字符
}

/* 清屏：使用ANSI转义序列 */
void clear_screen(void) { console_puts("\033[2J\033[H"); }
/* \033[2J 清除整个屏幕
   \033[H  将光标移动到左上角(1,1)位置 */

/* 移动光标到指定行列 */
void goto_xy(int row, int col)
{
    char buf[16];
    sprintf(buf, "\033[%d;%dH", row, col); // 生成ANSI光标定位序列
    console_puts(buf);
}
/* \033[row;colH 移动光标到第row行第col列 */

/* 清除当前行（从光标位置到行尾） */
void clear_line(void) { console_puts("\033[K"); }
/* \033[K 清除从光标到行尾的内容 */

/* 带颜色的格式化输出 */
int printf_color(enum COLOR color, const char *fmt, ...)
{
    char buf[256]; // 格式化文本缓冲区
    va_list ap;    // 可变参数列表

    // 处理格式化字符串
    va_start(ap, fmt);                // 初始化可变参数
    int len = vsprintf(buf, fmt, ap); // 格式化到缓冲区
    va_end(ap);                       // 清理可变参数

    // 设置输出颜色
    char color_buf[8];
    sprintf(color_buf, "\033[%dm", color); // 生成ANSI颜色序列
    console_puts(color_buf);               // 输出颜色控制码

    // 输出格式化的文本
    console_puts(buf);

    // 重置颜色（恢复默认）
    console_puts("\033[0m"); // \033[0m 重置所有属性

    return len; // 返回输出的字符数
}