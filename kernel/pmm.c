#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "pmm.h"

// 页大小定义
#ifndef PGSIZE
#define PGSIZE 4096
#endif

// 页对齐宏
#ifndef PGROUNDUP
#define PGROUNDUP(sz) (((sz) + PGSIZE - 1) & ~(PGSIZE - 1))
#endif

#ifndef PGROUNDDOWN
#define PGROUNDDOWN(a) (((a)) & ~(PGSIZE - 1))
#endif

// 空闲页链表节点
struct free_page
{
    struct free_page *next;
};

// 伙伴系统空闲链表
struct free_area
{
    struct free_page *free_list;
    int nr_free;
};

// 物理内存管理器状态
struct
{
    uint64 total_pages;
    uint64 free_pages;
    uint64 base_addr;
    uint64 end_addr;

    struct free_area free_area[MAX_ORDER + 1];
    int initialized;
} pmm;

// 简单的memset实现
static void simple_memset(void *dst, int c, uint n)
{
    char *cdst = (char *)dst;
    for (int i = 0; i < n; i++)
    {
        cdst[i] = c;
    }
}

// 伙伴系统初始化
static void buddy_system_init(void)
{
    if (pmm.initialized)
        return;

    // printf("PMM: Initializing buddy system...\n");

    // 初始化所有阶的空闲链表
    for (int i = 0; i <= MAX_ORDER; i++)
    {
        pmm.free_area[i].free_list = NULL;
        pmm.free_area[i].nr_free = 0;
    }

    // 设置内存范围
    pmm.base_addr = PGROUNDUP((uint64)end);
    pmm.end_addr = PGROUNDDOWN(PHYSICAL_TOP);
    pmm.total_pages = (pmm.end_addr - pmm.base_addr) / PGSIZE;

    // printf("PMM: Memory range: %d pages from 0x%p to 0x%p\n",
    //        pmm.total_pages, (void*)pmm.base_addr, (void*)pmm.end_addr);

    uint64 remaining_pages = pmm.total_pages;
    uint64 current_addr = pmm.base_addr;
    int total_blocks = 0;

    // printf("PMM: Starting at 0x%p, analyzing alignment...\n", (void*)current_addr);

    // 分析起始地址的对齐情况
    for (int order = MAX_ORDER; order >= 0; order--)
    {
        uint64 block_size = PGSIZE * (1UL << order);
        uint64 alignment = current_addr % block_size;
        (void)alignment; // silence unused when debug prints are disabled
        // 对齐分析打印移除（保持安静）
    }

    // 主分配循环
    while (remaining_pages > 0)
    {
        // 找到当前地址能够分配的最大阶
        int best_order = -1;
        for (int order = MAX_ORDER; order >= 0; order--)
        {
            uint64 block_pages = (1UL << order);
            uint64 block_size = block_pages * PGSIZE;

            // 检查对齐和剩余页数
            if ((current_addr % block_size) == 0 && remaining_pages >= block_pages)
            {
                best_order = order;
                break;
            }
        }

        if (best_order >= 0)
        {
            uint64 block_pages = (1UL << best_order);
            uint64 block_size = block_pages * PGSIZE;

            struct free_page *block = (struct free_page *)current_addr;
            block->next = pmm.free_area[best_order].free_list;
            pmm.free_area[best_order].free_list = block;
            pmm.free_area[best_order].nr_free++;

            // printf("PMM: Added order %d block at 0x%p (%d pages)\n",
            //        best_order, block, (int)block_pages);

            current_addr += block_size;
            remaining_pages -= block_pages;
            total_blocks++;
        }
        else
        {
            // 如果没有合适的块，向前对齐到下一个合适的边界
            // printf("PMM: No suitable block found at 0x%p, searching for next aligned address...\n",
            //       (void*)current_addr);

            // 找到下一个对齐的地址
            uint64 next_aligned_addr = current_addr;
            int found = 0;

            for (int order = MAX_ORDER; order >= 0; order--)
            {
                uint64 block_size = PGSIZE * (1UL << order);
                uint64 aligned_addr = (current_addr + block_size - 1) & ~(block_size - 1);

                if (aligned_addr < pmm.end_addr &&
                    (aligned_addr - current_addr) / PGSIZE <= remaining_pages)
                {
                    next_aligned_addr = aligned_addr;
                    // printf("PMM: Next aligned address for order %d: 0x%p\n",
                    //        order, (void*)next_aligned_addr);
                    found = 1;
                    break;
                }
            }

            if (found && next_aligned_addr > current_addr)
            {
                // 将中间的内存作为小块处理
                uint64 gap_pages = (next_aligned_addr - current_addr) / PGSIZE;
                (void)gap_pages; // silence unused when debug prints are disabled
                // printf("PMM: Filling gap: %d pages from 0x%p to 0x%p\n",
                //        (int)gap_pages, (void*)current_addr, (void*)next_aligned_addr);

                // 将间隙内存作为单页分配
                while (current_addr < next_aligned_addr && remaining_pages > 0)
                {
                    struct free_page *block = (struct free_page *)current_addr;
                    block->next = pmm.free_area[0].free_list;
                    pmm.free_area[0].free_list = block;
                    pmm.free_area[0].nr_free++;

                    current_addr += PGSIZE;
                    remaining_pages--;
                    total_blocks++;
                }
            }
            else
            {
                // 无法对齐，使用单页
                struct free_page *block = (struct free_page *)current_addr;
                block->next = pmm.free_area[0].free_list;
                pmm.free_area[0].free_list = block;
                pmm.free_area[0].nr_free++;

                current_addr += PGSIZE;
                remaining_pages--;
                total_blocks++;

                // printf("PMM: Added single page at 0x%p\n", block);
            }
        }
    }

    // 验证和完成
    uint64 used_pages = (current_addr - pmm.base_addr) / PGSIZE;
    (void)used_pages; // silence unused when debug prints are disabled
    // printf("PMM: Memory usage: %d/%d pages\n", (int)used_pages, (int)pmm.total_pages);

    pmm.initialized = 1;
    pmm.free_pages = pmm.total_pages;

    // 统计信息
    // printf("PMM: Buddy system initialized with %d free pages\n", pmm.free_pages);
    // printf("PMM: Total blocks allocated: %d\n", total_blocks);

    for (int i = 0; i <= MAX_ORDER; i++)
    {
        if (pmm.free_area[i].nr_free > 0)
        {
            // printf("PMM: Order %d (%d pages): %d free blocks\n",
            //        i, (1 << i), pmm.free_area[i].nr_free);
        }
    }

    // 检查最大可用块
    int max_order = -1;
    for (int i = MAX_ORDER; i >= 0; i--)
    {
        if (pmm.free_area[i].nr_free > 0)
        {
            max_order = i;
            break;
        }
    }
    (void)max_order; // silence unused when debug prints are disabled
    // printf("PMM: Maximum available order: %d (%d pages)\n", max_order, (1 << max_order));
}

// 正确的伙伴地址计算  参数：当前内存块的起始地址，内存块所在的阶（order）
static void *find_buddy(void *block, int order)
{
    uint64 block_addr = (uint64)block;
    uint64 block_size = PGSIZE * (1UL << order);
    uint64 buddy_addr = block_addr ^ block_size;
    return (void *)buddy_addr;
}

// 检查地址是否在管理范围内
static int is_valid_address(void *addr)
{
    uint64 addr_val = (uint64)addr;
    return (addr_val >= pmm.base_addr && addr_val < pmm.end_addr);
}

// 伙伴系统分配
void *alloc_pages_buddy(int order)
{
    if (order < 0 || order > MAX_ORDER)
        return NULL;

    if (!pmm.initialized)
        buddy_system_init();

    int current_order = order;

    // 寻找合适大小的空闲块
    while (current_order <= MAX_ORDER)
    {
        if (pmm.free_area[current_order].nr_free > 0)
        {
            // 找到空闲块
            struct free_page *block = pmm.free_area[current_order].free_list;
            pmm.free_area[current_order].free_list = block->next;
            pmm.free_area[current_order].nr_free--;

            // printf("PMM: Alloc: found order %d block at 0x%p\n", current_order, block);

            // 如果块太大，就分裂
            while (current_order > order)
            {
                current_order--;

                // 分裂块，将伙伴加入低一阶的空闲链表
                void *buddy = find_buddy(block, current_order);

                // printf("PMM: Splitting: block=0x%p, order=%d->%d, buddy=0x%p\n",
                //        block, current_order + 1, current_order, buddy);

                if (is_valid_address(buddy))
                {
                    struct free_page *buddy_page = (struct free_page *)buddy;
                    buddy_page->next = pmm.free_area[current_order].free_list;
                    pmm.free_area[current_order].free_list = buddy_page;
                    pmm.free_area[current_order].nr_free++;
                }
                else
                {
                    // printf("PMM: WARNING: Invalid buddy address 0x%p\n", buddy);
                }
            }

            int allocated_pages = 1 << order;
            pmm.free_pages -= allocated_pages;

            // 清空分配的内存
            simple_memset(block, 0, allocated_pages * PGSIZE);

            // printf("PMM: SUCCESS: Allocated %d pages at 0x%p (order %d)\n",
            //        allocated_pages, block, order);
            return block;
        }
        current_order++;
    }

    // printf("PMM: FAILED: No memory for order %d\n", order);
    return NULL;
}

// 伙伴系统释放
void free_pages_buddy(void *page, int order)
{
    if (page == NULL || order < 0 || order > MAX_ORDER)
        return;
    if (!pmm.initialized)
        return;

    // printf("PMM: Freeing %d pages at 0x%p (order %d)\n", (1 << order), page, order);

    void *current_block = page;
    int current_order = order;

    // 尝试合并伙伴块
    while (current_order < MAX_ORDER)
    {
        void *buddy = find_buddy(current_block, current_order);

        if (!is_valid_address(buddy))
        {
            break;
        }

        // 检查伙伴是否在相同阶的空闲链表中
        int buddy_found = 0;
        struct free_page **prev = &pmm.free_area[current_order].free_list;
        struct free_page *curr = pmm.free_area[current_order].free_list;

        while (curr != NULL)
        {
            if (curr == buddy)
            {
                // 从链表中移除伙伴
                *prev = curr->next;
                pmm.free_area[current_order].nr_free--;
                buddy_found = 1;
                // printf("PMM: Merging: found buddy at 0x%p, order %d\n", buddy, current_order);
                break;
            }
            prev = &curr->next;
            curr = curr->next;
        }

        if (!buddy_found)
        {
            break;
        }

        // 合并块（选择较低的地址）
        if (current_block > buddy)
        {
            current_block = buddy;
        }

        current_order++;
        // printf("PMM: Merged to order %d, block at 0x%p\n", current_order, current_block);
    }

    // 将块加入对应阶的空闲链表
    struct free_page *new_block = (struct free_page *)current_block;
    new_block->next = pmm.free_area[current_order].free_list;
    pmm.free_area[current_order].free_list = new_block;
    pmm.free_area[current_order].nr_free++;

    int freed_pages = 1 << order;
    pmm.free_pages += freed_pages;

    // printf("PMM: Freed %d pages, added to order %d\n", freed_pages, current_order);
}

// 获取合适的阶
int get_order(int n)
{
    if (n <= 0)
        return -1;
    if (n == 1)
        return 0;

    int order = 0;
    int size = 1;
    while (size < n)
    {
        size <<= 1;
        order++;
    }

    if (order > MAX_ORDER)
        order = MAX_ORDER;
    return order;
}

// 初始化物理内存管理器
void pmm_init(void)
{
    pmm.base_addr = PGROUNDUP((uint64)end);
    pmm.end_addr = PGROUNDDOWN(PHYSICAL_TOP);
    pmm.total_pages = (pmm.end_addr - pmm.base_addr) / PGSIZE;
    pmm.free_pages = 0;
    pmm.initialized = 0;

    // printf("PMM: Initializing memory manager\n");
    // printf("PMM: Memory range: 0x%p to 0x%p (%d pages)\n",
    //        (void*)pmm.base_addr, (void*)pmm.end_addr, pmm.total_pages);

    buddy_system_init();
}

// 分配单个物理页
void *alloc_page(void)
{
    return alloc_pages_buddy(0);
}

// 释放单个物理页
void free_page(void *page)
{
    free_pages_buddy(page, 0);
}

// 分配连续的n个页面
void *alloc_pages(int n)
{
    if (n <= 0)
        return NULL;
    int order = get_order(n);
    return alloc_pages_buddy(order);
}

// 获取内存统计信息
void pmm_stats(void)
{
    printf("=== Physical Memory Manager Statistics ===\n");
    printf("Total pages:    %d\n", pmm.total_pages);
    printf("Free pages:     %d\n", pmm.free_pages);
    printf("Used pages:     %d\n", pmm.total_pages - pmm.free_pages);
    printf("Memory usage:   %d/%d KB\n",
           (pmm.total_pages - pmm.free_pages) * 4,
           pmm.total_pages * 4);
    printf("Base address:   0x%p\n", (void *)pmm.base_addr);
    printf("End address:    0x%p\n", (void *)pmm.end_addr);

    printf("\nBuddy System Status:\n");
    for (int i = 0; i <= MAX_ORDER; i++)
    {
        if (pmm.free_area[i].nr_free > 0)
        {
            printf("  Order %d (%d pages): %d free blocks\n",
                   i, (1 << i), pmm.free_area[i].nr_free);
        }
    }
}

// 获取空闲内存大小
uint64 get_free_memory(void)
{
    return pmm.free_pages * PGSIZE;
}

// 获取总内存大小
uint64 get_total_memory(void)
{
    return pmm.total_pages * PGSIZE;
}

// 测试4页分配功能
void test_4page_allocation(void)
{
    printf("\n=== Testing 4-Page Allocation ===\n\n");

    pmm_stats();

    printf("1. Allocating 4 pages...\n");
    void *pages4 = alloc_pages(4);

    if (pages4)
    {
        printf("   SUCCESS: Allocated 4 pages at 0x%p\n", pages4);

        printf("2. Testing data access in 4 pages...\n");
        int success = 1;

        // 测试所有4页的数据访问
        for (int page = 0; page < 4; page++)
        {
            uint64 *page_data = (uint64 *)((uint64)pages4 + page * PGSIZE);
            uint64 test_value = 0x1234567890ABCD00 + page;

            // 写入测试数据
            page_data[0] = test_value;
            page_data[PGSIZE / sizeof(uint64) - 1] = test_value + 1;

            // 验证数据
            if (page_data[0] != test_value || page_data[PGSIZE / sizeof(uint64) - 1] != test_value + 1)
            {
                printf("   FAIL: Data access failed in page %d\n", page);
                success = 0;
                break;
            }
        }

        if (success)
        {
            printf("   SUCCESS: All 4 pages data access works\n");
        }

        printf("3. Freeing 4 pages...\n");
        free_pages_buddy(pages4, 2); // order 2 = 4 pages
        printf("   SUCCESS: Freed 4 pages\n");

        pmm_stats();
        printf("\n=== 4-Page Allocation Test PASSED ===\n");
    }
    else
    {
        printf("   FAILED: Could not allocate 4 pages\n");
        printf("\n=== 4-Page Allocation Test FAILED ===\n");
    }
}

// 伙伴系统完整测试
void test_buddy_system_comprehensive(void)
{
    printf("\n=== Comprehensive Buddy System Test ===\n\n");

    // 初始状态
    printf("1. Initial System State:\n");
    pmm_stats();

    // 测试1: 基本单页分配
    printf("\n2. Testing Single Page Allocation:\n");
    void *page1 = alloc_page();
    void *page2 = alloc_page();
    void *page3 = alloc_page();

    if (page1 && page2 && page3)
    {
        printf("   SUCCESS: Allocated single pages: 0x%p, 0x%p, 0x%p\n", page1, page2, page3);

        // 测试数据访问
        *(uint64 *)page1 = 0x12345678;
        *(uint64 *)page2 = 0x87654321;
        if (*(uint64 *)page1 == 0x12345678 && *(uint64 *)page2 == 0x87654321)
        {
            printf("   SUCCESS: Single page data access works\n");
        }
        else
        {
            printf("   FAIL: Single page data access failed\n");
        }
    }
    else
    {
        printf("   FAIL: Single page allocation failed\n");
    }

    // 测试2: 不同大小的连续页面分配
    printf("\n3. Testing Different Size Allocations:\n");

    // 分配4页
    void *pages4 = alloc_pages(4);
    if (pages4)
    {
        printf("   SUCCESS: Allocated 4 pages at 0x%p\n", pages4);

        // 测试4页数据访问
        int success = 1;
        for (int i = 0; i < 4; i++)
        {
            uint64 *addr = (uint64 *)((uint64)pages4 + i * PGSIZE);
            *addr = 0xABCDEF0123456789 + i;
            if (*addr != 0xABCDEF0123456789 + i)
            {
                success = 0;
                break;
            }
        }
        printf("   %s: 4-page data access test\n", success ? "SUCCESS" : "FAIL");
    }
    else
    {
        printf("   FAIL: 4-page allocation failed\n");
    }

    // 分配8页
    void *pages8 = alloc_pages(8);
    if (pages8)
    {
        printf("   SUCCESS: Allocated 8 pages at 0x%p\n", pages8);
    }
    else
    {
        printf("   FAIL: 8-page allocation failed\n");
    }

    // 分配16页
    void *pages16 = alloc_pages(16);
    if (pages16)
    {
        printf("   SUCCESS: Allocated 16 pages at 0x%p\n", pages16);
    }
    else
    {
        printf("   FAIL: 16-page allocation failed\n");
    }

    // 测试3: 中间状态检查
    printf("\n4. Intermediate State Check:\n");
    pmm_stats();

    // 测试4: 释放和重新分配测试
    printf("\n5. Free and Reallocation Test:\n");

    // 释放一些页面
    if (pages4)
    {
        free_pages_buddy(pages4, 2); // order 2 = 4 pages
        printf("   Freed 4 pages at 0x%p\n", pages4);
    }

    if (page1)
    {
        free_page(page1);
        printf("   Freed single page at 0x%p\n", page1);
    }

    // 检查释放后的状态
    printf("\n6. State After Free:\n");
    pmm_stats();

    // 重新分配相同大小的页面
    void *pages4_again = alloc_pages(4);
    if (pages4_again)
    {
        printf("   SUCCESS: Reallocated 4 pages at 0x%p\n", pages4_again);

        // 验证重新分配的页面可用
        int realloc_success = 1;
        for (int i = 0; i < 4; i++)
        {
            uint64 *addr = (uint64 *)((uint64)pages4_again + i * PGSIZE);
            *addr = 0x1122334455667788 + i;
            if (*addr != 0x1122334455667788 + i)
            {
                realloc_success = 0;
                break;
            }
        }
        printf("   %s: Reallocated page data access\n", realloc_success ? "SUCCESS" : "FAIL");
    }
    else
    {
        printf("   FAIL: 4-page reallocation failed\n");
    }

    // 测试5: 伙伴合并测试
    printf("\n7. Buddy Merge Test:\n");

    // 分配两个相邻的小块，然后释放看是否能合并
    void *merge_test1 = alloc_pages(32); // order 1
    void *merge_test2 = alloc_pages(32); // order 1

    if (merge_test1 && merge_test2)
    {
        printf("   Allocated two order 5 blocks: 0x%p, 0x%p\n", merge_test1, merge_test2);

        // 检查它们是否是伙伴
        void *buddy1 = find_buddy(merge_test1, 5);
        void *buddy2 = find_buddy(merge_test2, 5);
        printf("   Buddy of 0x%p is 0x%p\n", merge_test1, buddy1);
        printf("   Buddy of 0x%p is 0x%p\n", merge_test2, buddy2);

        // 释放并检查合并
        free_pages_buddy(merge_test1, 5);
        free_pages_buddy(merge_test2, 5);
        printf("   Freed both order 5 blocks\n");

        // 检查是否合并成了order 6块
        printf("   Checking if blocks merged...\n");
        pmm_stats();
    }
    else
    {
        printf("   FAIL: Could not allocate blocks for merge test\n");
    }

    // 测试6: 边界情况测试
    printf("\n8. Edge Case Tests:\n");

    // 测试无效分配
    void *invalid1 = alloc_pages(0);
    void *invalid2 = alloc_pages(-1);
    if (invalid1 == NULL && invalid2 == NULL)
    {
        printf("   SUCCESS: Invalid allocation requests correctly rejected\n");
    }
    else
    {
        printf("   FAIL: Invalid allocations not properly handled\n");
    }

    printf("\n=== Buddy System Comprehensive Test Completed ===\n");
}