#include "types.h"
#include "defs.h"

// 数字字符映射表
static char digits[] = "0123456789ABCDEF";

// 简单的字符输出函数
static void putc(char c)
{
    console_putc(c);
}

// 字符串输出
static void puts(const char *s)
{
    console_puts(s);
}

// 数字转换核心算法
static void print_int(long long num, int base, int sign, int width, int zero_pad)
{
    char buf[32];
    int i = 0;
    unsigned long long unum;
    int is_negative = 0;
    int num_digits = 0; // 纯数字部分的位数

    // 1. 处理符号和数值转换
    if (sign && num < 0)
    {
        unum = -num;
        is_negative = 1;
    }
    else
    {
        unum = num;
    }

    // 2. 数字转换（反向存储）
    if (unum == 0)
    {
        buf[i++] = '0';
        num_digits = 1;
    }
    else
    {
        while (unum > 0)
        {
            buf[i++] = digits[unum % base];
            unum /= base;
            num_digits++;
        }
    }

    // 3. 计算总宽度需求
    int total_width = num_digits;
    if (is_negative)
    {
        total_width += 1; // 负号占一位
    }

    // 4. 宽度填充逻辑
    if (width > total_width)
    {
        int padding = width - total_width;
        char pad_char = ' ';

        // 零填充的特殊处理
        if (zero_pad)
        {
            pad_char = '0';
            // 零填充时先输出符号
            if (is_negative)
            {
                putc('-');
                is_negative = 0; // 标记符号已输出
            }
        }

        // 输出填充字符
        while (padding-- > 0)
        {
            putc(pad_char);
        }
    }

    // 5. 输出符号（如果不是零填充情况）
    if (is_negative)
    {
        putc('-');
    }

    // 6. 输出数字（正向）
    while (--i >= 0)
    {
        putc(buf[i]);
    }
}

// 指针输出
static void print_ptr(uint64 ptr)
{
    putc('0');
    putc('x');

    if (ptr == 0)
    {
        putc('0');
        return;
    }

    // 输出64位指针（16个十六进制数字）
    int started = 0;
    for (int i = 60; i >= 0; i -= 4)
    {
        int digit = (ptr >> i) & 0xF;
        if (digit != 0 || started || i == 0)
        {
            putc(digits[digit]);
            started = 1;
        }
    }
}

// 格式化字符串解析核心
int printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    for (int i = 0; fmt[i] != '\0'; i++)
    {
        if (fmt[i] != '%')
        {
            putc(fmt[i]);
            continue;
        }

        // 解析格式说明符
        i++;
        int width = 0;
        int zero_pad = 0;
        int length_l = 0; // 是否存在 'l' 长度修饰符

        // 解析标志和宽度
        if (fmt[i] == '0')
        {
            zero_pad = 1;
            i++;
        }

        while (fmt[i] >= '0' && fmt[i] <= '9')
        {
            width = width * 10 + (fmt[i] - '0');
            i++;
        }
        // 解析长度修饰符（仅支持 'l'）
        if (fmt[i] == 'l')
        {
            length_l = 1;
            i++;
        }

        // 处理格式字符
        switch (fmt[i])
        {
        case 'd': // 有符号十进制
            if (length_l)
            {
                print_int(va_arg(ap, long), 10, 1, width, zero_pad);
            }
            else
            {
                print_int(va_arg(ap, int), 10, 1, width, zero_pad);
            }
            break;

        case 'u': // 无符号十进制
            if (length_l)
            {
                unsigned long v = va_arg(ap, unsigned long);
                print_int((long long)v, 10, 0, width, zero_pad);
            }
            else
            {
                print_int(va_arg(ap, unsigned int), 10, 0, width, zero_pad);
            }
            break;

        case 'x': // 十六进制
            if (length_l)
            {
                unsigned long v = va_arg(ap, unsigned long);
                print_int((long long)v, 16, 0, width, zero_pad);
            }
            else
            {
                print_int(va_arg(ap, unsigned int), 16, 0, width, zero_pad);
            }
            break;

        case 'p': // 指针
            print_ptr(va_arg(ap, uint64));
            break;

        case 'c': // 字符
            putc(va_arg(ap, int));
            break;

        case 's':
        { // 字符串
            char *s = va_arg(ap, char *);
            if (s == NULL)
                s = "(null)";
            puts(s);
            break;
        }

        case '%': // 百分号
            putc('%');
            break;

        default: // 未知格式
            putc('%');
            putc(fmt[i]);
            break;
        }
    }

    va_end(ap);
    return 0;
}

// 简化版sprintf（基础实现）
int sprintf(char *buf, const char *fmt, ...)
{
    // 简化实现：暂时直接调用printf
    // 完整实现需要重定向输出到缓冲区
    va_list ap;
    va_start(ap, fmt);
    printf(fmt, ap); // 注意：这需要修改printf支持缓冲区
    va_end(ap);

    // 返回估计的长度
    int len = 0;
    while (fmt[len])
        len++;
    return len;
}