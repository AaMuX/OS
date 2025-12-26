#include "types.h"
#include "defs.h"

extern void uart_flush(void); // 声明在uart.c中定义的函数

// 控制台初始化
void console_init(void)
{
    // 初始化UART
    uartinit();
}

// 输出单个字符（带特殊字符处理）
void console_putc(char c)
{
    // 处理特殊控制字符
    switch (c)
    {
    case '\n': // 换行 = 回车 + 换行
        uartputc('\r');
        uartputc('\n');
        uart_flush(); // 刷新输出
        break;
    case '\t': // 制表符（用4个空格代替）
        for (int i = 0; i < 4; i++)
        {
            uartputc(' ');
        }
        break;
    case '\b': // 退格键
        uartputc('\b');
        uartputc(' ');
        uartputc('\b');
        break;
    default: // 普通字符
        uartputc(c);
        break;
    }
}

// 输出字符串
void console_puts(const char *s)
{
    while (*s)
    {
        console_putc(*s++);
    }
    uart_flush(); // 字符串输出完成后刷新
}

// 清屏功能（通过发送ANSI转义序列）
void console_clear(void)
{
    // ANSI清屏序列：ESC[2J
    console_puts("\x1B[2J");
    // 光标复位：ESC[H
    console_puts("\x1B[H");
}

// 以下是新添加的一些拓展功能
//  清除当前行
void console_clear_line(void)
{
    console_puts("\x1B[K"); // 清除从光标到行尾
}

// 清除从光标到屏幕末尾
void console_clear_to_end(void)
{
    console_puts("\x1B[J"); // 清除从光标到屏幕末尾
}

// 光标定位：goto_xy(int x, int y)
void console_goto_xy(int x, int y)
{
    char buf[16];
    char *p = buf;

    // 构建ANSI序列：\x1B[y;xH
    *p++ = '\x1B';
    *p++ = '[';

    // 处理行号
    if (y >= 10)
    {
        *p++ = '0' + (y / 10);
        *p++ = '0' + (y % 10);
    }
    else
    {
        *p++ = '0' + y;
    }

    *p++ = ';';

    // 处理列号
    if (x >= 10)
    {
        *p++ = '0' + (x / 10);
        *p++ = '0' + (x % 10);
    }
    else
    {
        *p++ = '0' + x;
    }

    *p++ = 'H';
    *p = '\0';

    console_puts(buf);
}

// 光标回家（左上角）
void console_cursor_home(void)
{
    console_puts("\x1B[H");
}

// 保存光标位置
void console_cursor_save(void)
{
    console_puts("\x1B[s");
}

// 恢复光标位置
void console_cursor_restore(void)
{
    console_puts("\x1B[u");
}

// 显示/隐藏光标
void console_cursor_show(int show)
{
    if (show)
    {
        console_puts("\x1B[?25h"); // 显示光标
    }
    else
    {
        console_puts("\x1B[?25l"); // 隐藏光标
    }
}

// ==================== 颜色控制功能 ====================

// 设置颜色属性
void console_set_color(int color)
{
    char buf[16];
    char *p = buf;

    *p++ = '\x1B';
    *p++ = '[';

    if (color == 0)
    {
        // 重置所有属性
        *p++ = '0';
    }
    else
    {
        // 设置具体颜色/属性
        if (color >= 30 && color <= 37)
        {
            // 前景色
            if (color >= 10)
            {
                *p++ = '0' + (color / 10);
                *p++ = '0' + (color % 10);
            }
            else
            {
                *p++ = '0' + color;
            }
        }
        else
        {
            // 简化处理：直接使用数字
            if (color >= 10)
            {
                *p++ = '0' + (color / 10);
                *p++ = '0' + (color % 10);
            }
            else
            {
                *p++ = '0' + color;
            }
        }
    }

    *p++ = 'm';
    *p = '\0';

    console_puts(buf);
}

// 重置颜色
void console_reset_color(void)
{
    console_puts("\x1B[0m");
}

// 带颜色的printf
int printf_color(int color, const char *fmt, ...)
{
    va_list ap;

    // 设置颜色
    console_set_color(color);

    // 直接使用现有的printf功能
    va_start(ap, fmt);

    // 简化实现：先设置颜色，然后调用普通输出
    // 这里我们直接处理字符串，不进行复杂格式化
    for (int i = 0; fmt[i] != '\0'; i++)
    {
        if (fmt[i] != '%')
        {
            console_putc(fmt[i]);
            continue;
        }

        // 简单处理 %s 和 %c
        i++;
        switch (fmt[i])
        {
        case 's':
        {
            char *s = va_arg(ap, char *);
            if (!s)
                s = "(null)";
            console_puts(s);
            break;
        }
        case 'c':
        {
            char c = va_arg(ap, int);
            console_putc(c);
            break;
        }
        case '%':
            console_putc('%');
            break;
        default:
            // 对于复杂格式，回退到普通输出
            console_putc('%');
            console_putc(fmt[i]);
            break;
        }
    }

    va_end(ap);

    // 重置颜色
    console_reset_color();

    return 0; // 简化返回
}
