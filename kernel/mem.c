#include <stddef.h> // 标准定义，包含size_t类型

/* 用指定值填充内存区域 */
void *memset(void *s, int c, size_t n)
{
    unsigned char *ptr = (unsigned char *)s; // 将指针转换为unsigned char*以便按字节操作
    for (size_t i = 0; i < n; i++)
    {
        ptr[i] = (unsigned char)c; // 将每个字节设置为指定值
    }
    return s; // 返回原始指针
}
/* 这是标准C库函数memset的内核实现
   用于在无标准库环境中提供内存初始化功能
   将内存区域s的前n个字节设置为值c
   返回原始指针s以支持链式调用 */