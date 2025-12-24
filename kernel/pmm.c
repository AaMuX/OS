// 物理内存管理器的简化实现, 负责管理物理内存页的分配和释放
#include "pmm.h"
#include "printf.h"
#include <stdint.h>
#include <stddef.h>

#define MAX_PAGES 64   // 定义内存池最大页数（64页)
#define PAGE_SIZE 4096 // 定义页大小（4KB，标准内存页大小）
// 静态内存池定义
static unsigned char memory_pool[MAX_PAGES * PAGE_SIZE] __attribute__((aligned(4096)));
// 空闲页管理数据结构
static void *free_list[MAX_PAGES]; // 存储空闲页指针的栈结构
static int free_count = 0;         // 记录当前空闲页数量，也作为栈顶指针

// 初始化函数
void pmm_init(uint64_t start, uint64_t end)
{
    // 忽略传入的内存范围参数，使用固定的静态内存池
    (void)start;
    (void)end;

    free_count = 0;

    // 内存池初始化
    for (int i = 0; i < MAX_PAGES; i++)
    {
        void *page = (void *)&memory_pool[i * PAGE_SIZE]; // 计算每个页的起始地址：&memory_pool[i * 4096]
        free_list[free_count++] = page;                   // 将所有页指针加入空闲列表（栈）
    }

    printf("PMM initialized: %d pages (%d KB)\n",
           MAX_PAGES, (MAX_PAGES * PAGE_SIZE) / 1024);
}

// 单页分配函数
void *alloc_page(void)
{
    // 检查是否有空闲页可用,内存耗尽时返回NULL并输出错误信息
    if (free_count <= 0)
    {
        printf("pmm: out of memory!\n");
        return NULL;
    }
    // 从栈顶取出一个空闲页指针（LIFO策略）
    void *page = free_list[--free_count]; // 先减量再使用，栈顶指针下移
    // 内存清零,将分配的4KB页面全部清零
    for (int i = 0; i < PAGE_SIZE; i++)
    {
        ((unsigned char *)page)[i] = 0;
    }
    printf("pmm: alloc_page -> %p (remain=%d)\n", page, free_count);
    return page;
}

// 单页释放函数
void free_page(void *page)
{
    // 空指针检查，避免释放NULL指针
    if (!page)
        return;

    uintptr_t addr = (uintptr_t)page;
    uintptr_t pool_start = (uintptr_t)memory_pool;
    uintptr_t pool_end = pool_start + (MAX_PAGES * PAGE_SIZE);

    // 地址范围验证，确保释放的地址在内存池范围内，防止释放非法地址
    if (addr < pool_start || addr >= pool_end)
    {
        printf("pmm: free_page: address %p out of pool\n", page);
        return;
    }

    // 地址对齐检查，检查是否为4KB对齐的地址，不对齐的地址不是有效的页边界
    if (addr % PAGE_SIZE != 0)
    {
        printf("pmm: free_page: address %p not aligned\n", page);
        return;
    }

    // 双重释放检测，检查空闲列表是否已满（可能发生双重释放）
    if (free_count >= MAX_PAGES)
    {
        printf("pmm: free_page: free list full (double free?)\n");
        return;
    }

    free_list[free_count++] = page; // 页回收，将页指针压回空闲栈
    printf("pmm: free_page <- %p (remain=%d)\n", page, free_count);
}

// 多页分配函数
void *alloc_pages(int n)
{
    // 参数验证，检查请求页数是否有效
    if (n <= 0)
        return NULL;
    // 检查是否有足够空闲页
    if (free_count < n)
    {
        printf("pmm: alloc_pages(%d) failed (only %d free)\n", n, free_count);
        return NULL;
    }

    // 分配与回滚机制
    void *first = NULL;
    // 循环分配单个页，记录第一个页的地址作为返回值，如果中间分配失败，回滚之前分配的所有页
    for (int i = 0; i < n; i++)
    {
        void *p = alloc_page();
        if (!p)
        {

            for (int j = 0; j < i; j++)
            {
                free_page(((void **)free_list)[free_count]);
            }
            return NULL;
        }
        if (i == 0)
            first = p;
    }
    return first;
}
