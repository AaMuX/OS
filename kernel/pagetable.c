// 页表管理的核心实现
// 实现了 RISC-V Sv39 页表系统的完整管理功能，包括页表的创建、遍历、映射建立、销毁和调试输出。
#include "pagetable.h"
#include "pmm.h"
#include "printf.h"
#include <stddef.h>
#include <stdint.h>

#define NPTE (PAGE_SIZE / sizeof(pte_t)) // 计算每页可以存放的页表项数量

// 页表项操作工具函数，从页表项中提取下一级页表的物理地址
static inline pagetable_t pte_to_table(pte_t pte)
{
    uint64_t ppn = (pte >> PPN_SHIFT); // 提取物理页号（PPN）
    uint64_t addr = (ppn << 12);       // 将页号转换为物理地址（乘以4KB）
    return (pagetable_t)addr;
}

// 创建中间级页表项，创建指向页表页的页表项（非叶子节点）
// 只设置PTE_V（有效位），不设置R/W/X权限位
static inline pte_t make_pte_for_table(void *child_page)
{
    uint64_t ppn = ((uint64_t)child_page) >> 12;
    return (ppn << PPN_SHIFT) | PTE_V;
}

// 创建叶子页表项（指向实际内存页），建立最终的虚拟到物理地址映射
// 设置PTE_V和相应的权限位（R/W/X）
static inline pte_t make_leaf_pte(uint64_t pa, int perm)
{
    uint64_t ppn = pa >> 12;
    return (ppn << PPN_SHIFT) | (uint64_t)(perm) | PTE_V;
}

// 页表页分配和初始化，分配并清零一个页表页
static void *alloc_pagetable_page(void)
{
    void *p = alloc_page();
    if (!p)
        return NULL;
    unsigned char *b = (unsigned char *)p;
    for (size_t i = 0; i < PAGE_SIZE; i++)
        b[i] = 0;
    return p;
}

// 创建空的根页表，为新的地址空间创建页表根目录
pagetable_t create_pagetable(void)
{
    void *p = alloc_pagetable_page(); // 返回分配并清零的页表页指针
    return (pagetable_t)p;
}

// 核心页表遍历算法
pte_t *walk_create(pagetable_t pt, uint64_t va)
{
    if (!pt)
        return NULL;
    pagetable_t table = pt;

    // 层级循环：从第2级到第0级逐级处理
    for (int level = 2; level > 0; level--)
    {

        uint64_t idx = VPN_MASK(va, level); // VPN_MASK(va, level)提取指定级别的虚拟页号
        pte_t pte = table[idx];

        if (pte & PTE_V) // 检查PTE_V位判断页表项是否有效
        {

            if (pte & (PTE_R | PTE_W | PTE_X)) // 中间页表项不能有R/W/X权限
            {

                return NULL;
            }

            table = pte_to_table(pte);
        }
        else // 如果页表不存在则动态分配
        {

            void *child = alloc_pagetable_page();
            if (!child)
                return NULL;

            table[idx] = make_pte_for_table(child);

            table = (pagetable_t)child;
        }
    }

    return &table[VPN_MASK(va, 0)];
}

// 查找虚拟地址对应的页表项（只读），用于地址转换和权限检查
pte_t *walk_lookup(pagetable_t pt, uint64_t va)
{
    if (!pt)
        return NULL;
    pagetable_t table = pt;

    for (int level = 2; level > 0; level--)
    {
        uint64_t idx = VPN_MASK(va, level);
        pte_t pte = table[idx];

        if (!(pte & PTE_V))
            return NULL;

        if (pte & (PTE_R | PTE_W | PTE_X))
        {

            return &table[idx];
        }

        table = pte_to_table(pte);
    }

    return &table[VPN_MASK(va, 0)];
}

// 页面映射函数
int map_page(pagetable_t pt, uint64_t va, uint64_t pa, int perm)
{

    // 检查虚拟地址和物理地址是否4KB对齐，不对齐会导致映射错
    if ((va & (PAGE_SIZE - 1)) || (pa & (PAGE_SIZE - 1)))
    {
        printf("map_page: addresses must be page aligned\n");
        return -1;
    }

    // 页表遍历：调用walk_create确保页表路径存在
    pte_t *pte = walk_create(pt, va);
    if (!pte)
    {
        printf("map_page: walk_create failed for va %p\n", (void *)va);
        return -1;
    }

    // 冲突检查：检查是否已存在有效映射
    if ((*pte & PTE_V) && (*pte & (PTE_R | PTE_W | PTE_X)))
    {
        printf("map_page: VA %p already mapped\n", (void *)va);
        return -1;
    }

    // 设置页表项：创建叶子页表项，建立映射关系
    *pte = make_leaf_pte(pa, perm);
    return 0;
}

// 页表销毁功能，只释放页表页：不释放被映射的物理内存页，递归销毁：深度优先遍历整个页表树，先清空页表项再递归
static void destroy_level(pagetable_t table, int level)
{
    if (!table)
        return;
    for (int i = 0; i < NPTE; i++)
    {
        pte_t pte = table[i];
        if (!(pte & PTE_V))
            continue;

        // /* 如果是叶子节点（有R/W/X权限），跳过不释放物理内存 */
        if ((pte & (PTE_R | PTE_W | PTE_X)))
        {
            table[i] = 0; //// 清空页表项
            continue;
        }

        /* 非叶子节点：递归销毁子页表 */
        pagetable_t child = pte_to_table(pte);
        // 先清空避免重入问题
        table[i] = 0;
        // 递归销毁
        destroy_level(child, level - 1);
        free_page((void *)child); // 释放页表页本身
    }
}

void destroy_pagetable(pagetable_t pt)
{
    if (!pt)
        return;
    destroy_level(pt, 2);  // 从根页表开始递归销毁
    free_page((void *)pt); // 释放根页表页
}

// 调试输出功能
static void dump_level(pagetable_t table, int level, uint64_t va_base)
{
    if (!table)
        return;
    // 深度优先遍历：完整输出整个页表树结构
    for (int i = 0; i < NPTE; i++)
    {
        pte_t pte = table[i];
        if (!(pte & PTE_V))
            continue;
        uint64_t va = va_base | ((uint64_t)i << VPN_SHIFT(level)); // 通过va_base和当前索引计算完整虚拟地址
        if (pte & (PTE_R | PTE_W | PTE_X))
        {
            // 叶子节点：输出映射关系
            uint64_t pa = (pte >> PPN_SHIFT) << 12;
            int perm = pte & (PTE_R | PTE_W | PTE_X); // 显示每个映射的访问权限
            printf("MAP: va=%p -> pa=%p perm=0x%x\n", (void *)va, (void *)pa, perm);
        }
        else
        {
            // 非叶子节点：递归输出子页表
            pagetable_t child = pte_to_table(pte);
            dump_level(child, level - 1, va);
        }
    }
}

void dump_pagetable(pagetable_t pt)
{
    printf("Dump pagetable:\n");
    dump_level(pt, 2, 0UL); // 从根页表开始，虚拟地址基数为0
}
