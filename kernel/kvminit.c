// 虚拟内存初始化模块，负责内核页表的创建、内存映射和虚拟内存系统的激活
#include "kvminit.h"
#include "pmm.h"
#include "printf.h"
#include <stdint.h>
// 内核基地址
#ifndef KERNBASE
#define KERNBASE 0x80000000UL
#endif
// 内存大小
#ifndef MEMSIZE
#define MEMSIZE (128UL * 1024 * 1024)
#endif
// 串口设备地址
#ifndef UART0
#define UART0 0x10000000UL
#endif

pagetable_t kernel_pagetable = 0;
// 设置页表基地址和分页模式
static inline void w_satp(uint64_t satp)
{
    asm volatile("csrw satp, %0" ::"r"(satp)); // RISC-V特权指令，写入satp寄存器
}
// 内存屏障指令，刷新TLB，确保页表更改对所有后续内存访问可见
static inline void sfence_vma(void)
{
    asm volatile("sfence.vma" ::: "memory");
}
// 内存映射区域函数
int map_region(pagetable_t pt, uint64_t va, uint64_t pa, uint64_t size, int perm)
{
    if (!pt)
        return -1;

    uint64_t va_start = PAGE_ROUND_DOWN(va);    // 向下页对齐
    uint64_t pa_start = PAGE_ROUND_DOWN(pa);    // 向下页对齐
    uint64_t va_end = PAGE_ROUND_UP(va + size); // 向上页对齐
                                                // 逐页映射整个区域，检查是否已存在有效映射（PTE_V标志），调用map_page建立单个页面的映射
    for (uint64_t a = va_start, p = pa_start; a < va_end; a += PAGE_SIZE, p += PAGE_SIZE)
    {

        pte_t *existing = walk_lookup(pt, a);
        if (existing && (*existing & PTE_V))
        {

            continue;
        }

        if (map_page(pt, a, p, perm) != 0)
        {
            printf("map_region: map_page failed va=%p pa=%p\n", (void *)a, (void *)p);
            return -1;
        }
    }
    return 0;
}
// 内核页表初始化函数
void kvminit(void)
{

    // 调用create_pagetable()创建空的页表结构
    kernel_pagetable = create_pagetable();
    // 确保页表创建成功
    if (!kernel_pagetable)
    {
        printf("kvminit: create_pagetable failed\n");
        return;
    }

    // 获取段边界符号，这些符号由链接脚本（kernel.ld）定义
    extern char _text[], _etext[], _rodata[], _erodata[];
    extern char _data[], _edata[], _end[];

    uint64_t text = (uint64_t)_text;
    uint64_t etext = (uint64_t)_etext;
    uint64_t rodata = (uint64_t)_rodata;
    uint64_t erodata = (uint64_t)_erodata;
    uint64_t data = (uint64_t)_data;
    uint64_t edata = (uint64_t)_edata;
    uint64_t end = (uint64_t)_end;

    // 内存映射建立
    // 代码段映射：可读+可执行权限，保护代码不被修改
    map_region(kernel_pagetable, text, text, (uint64_t)(etext - text), PTE_R | PTE_X);
    // 只读数据段：仅可读权限，保护常量数据
    if (erodata > rodata)
        map_region(kernel_pagetable, rodata, rodata, (uint64_t)(erodata - rodata), PTE_R);

    // 数据段映射：可读+可写权限，允许数据修改
    map_region(kernel_pagetable, data, data, (uint64_t)(end - data), PTE_R | PTE_W);

    // 额外空间映射：为内核堆或动态分配预留空间
    map_region(kernel_pagetable, end, end, PAGE_SIZE * 10, PTE_R | PTE_W);

    // 设备映射：映射UART设备，用于串口通信
    map_region(kernel_pagetable, UART0, UART0, PAGE_SIZE, PTE_R | PTE_W);

    printf("kvminit: kernel_pagetable created and regions mapped\n");
}
// 虚拟内存激活函数
void kvminithart(void)
{
    if (!kernel_pagetable)
    {
        printf("kvminithart: kernel_pagetable is NULL\n");
        return;
    }

    uint64_t satp = MAKE_SATP(kernel_pagetable); // 将页表物理地址转换为satp值，Sv39模式(8) + 页表基地址

    // 激活流程
    w_satp(satp); // 设置SATP寄存器：启用分页，指定页表

    sfence_vma(); // 执行sfence.vma：刷新TLB，确保新页表立即生效

    printf("kvminithart: satp set %p\n", (void *)satp); // 打印调试信息：确认分页已启用
}
