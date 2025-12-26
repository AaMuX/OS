// kernel/string.c
#include <stdarg.h> // 可变参数支持
#include <stddef.h> // 标准定义，包含size_t类型

/* 将整数转换为字符串
   参数说明：
   num: 要转换的整数
   buf: 目标缓冲区
   buf_size: 缓冲区大小
   返回值: 写入缓冲区的字符数，缓冲区不足时返回0 */
static int int_to_str(int num, char *buf, size_t buf_size)
{
    if (buf_size == 0) // 缓冲区大小为0，无法写入
        return 0;

    int is_negative = 0; // 负数标志
    size_t len = 0;      // 数字字符串长度
    char temp[20];       // 临时缓冲区，用于反向存储数字字符

    if (num < 0) // 处理负数
    {
        is_negative = 1; // 标记为负数
        num = -num;      // 转换为正数处理
    }

    if (num == 0) // 处理数字0的特殊情况
    {
        temp[len++] = '0'; // 直接存储'0'
    }
    else // 处理非零数字
    {
        while (num > 0 && len < sizeof(temp) - 1) // 逐位提取数字
        {
            temp[len++] = '0' + (num % 10); // 获取个位数并转换为字符
            num /= 10;                      // 去掉个位
        }
    }

    size_t total_len = len + is_negative; // 总长度 = 数字长度 + 负号
    if (total_len >= buf_size)            // 检查缓冲区是否足够
    {
        return 0; // 缓冲区不足，返回0
    }

    int buf_idx = 0; // 目标缓冲区索引

    if (is_negative) // 如果是负数，添加负号
    {
        buf[buf_idx++] = '-';
    }

    for (int i = len - 1; i >= 0; i--) // 反转数字顺序（从低位到高位）
    {
        buf[buf_idx++] = temp[i]; // 存储到目标缓冲区
    }

    return buf_idx; // 返回写入的字符数
}
/* 转换示例：
   int_to_str(123, buf, 10)  -> "123"  (返回3)
   int_to_str(-45, buf, 10)  -> "-45"  (返回3)
   int_to_str(0, buf, 10)    -> "0"    (返回1) */

/* 带长度限制的格式化输出函数
   参数说明：
   buf: 输出缓冲区
   size: 缓冲区大小
   fmt: 格式化字符串
   ...: 可变参数列表
   返回值: 实际写入的字符数（不包括结尾的空字符） */
int snprintf(char *buf, size_t size, const char *fmt, ...)
{
    if (buf == NULL || size == 0) // 检查参数有效性
        return 0;

    va_list args;        // 可变参数列表
    va_start(args, fmt); // 初始化可变参数

    size_t buf_idx = 0;  // 缓冲区索引
    const char *f = fmt; // 格式化字符串指针

    while (*f != '\0' && buf_idx < size - 1) // 遍历格式化字符串
    {
        if (*f == '%') // 遇到格式说明符
        {
            f++;        // 跳过'%'
            switch (*f) // 根据格式字符处理
            {
            case 'd': // 整数格式
            {
                int num = va_arg(args, int);                             // 获取整数参数
                char int_buf[20];                                        // 整数转换缓冲区
                int int_len = int_to_str(num, int_buf, sizeof(int_buf)); // 转换整数
                for (int i = 0; i < int_len && buf_idx < size - 1; i++)
                {
                    buf[buf_idx++] = int_buf[i]; // 复制转换结果
                }
                break;
            }
            case 's': // 字符串格式
            {
                char *str = va_arg(args, char *); // 获取字符串参数
                if (str == NULL)                  // 处理空指针
                    str = "(null)";
                while (*str != '\0' && buf_idx < size - 1) // 复制字符串
                {
                    buf[buf_idx++] = *str++;
                }
                break;
            }
            case 'c': // 字符格式
            {
                char c = (char)va_arg(args, int); // 获取字符参数
                buf[buf_idx++] = c;               // 存储字符
                break;
            }
            case '%': // 转义'%'
            {
                buf[buf_idx++] = '%'; // 输出'%'
                break;
            }
            default: // 无效格式说明符
            {
                buf[buf_idx++] = '%'; // 输出'%'
                buf[buf_idx++] = *f;  // 输出无效字符
                break;
            }
            }
            f++; // 移动到下一个字符
        }
        else // 普通字符
        {
            buf[buf_idx++] = *f++; // 直接复制到缓冲区
        }
    }

    buf[buf_idx] = '\0'; // 添加字符串结束符
    va_end(args);        // 清理可变参数
    return buf_idx;      // 返回写入的字符数
}
