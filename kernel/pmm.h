#ifndef _PMM_H
#define _PMM_H

#include "types.h"

// 页大小定义
#ifndef PGSIZE
#define PGSIZE 4096
#endif

// 伙伴系统最大阶数（最大连续分配 2^MAX_ORDER 页）
#define MAX_ORDER 10 // 最大连续分配 1024 页 = 4MB

// 物理内存管理器接口
void pmm_init(void);
void *alloc_page(void);
void free_page(void *page);
void *alloc_pages(int n);
// 内存统计信息
void pmm_stats(void);
uint64 get_free_memory(void);
uint64 get_total_memory(void);

// 测试函数
void test_4page_allocation(void);
void test_buddy_system_comprehensive(void);
#endif