#ifndef _VM_H
#define _VM_H

#include "types.h"

// 页表类型定义
typedef uint64* pagetable_t;
typedef uint64 pte_t;

// 页表项标志位
#define PTE_V (1L << 0) // 有效位
#define PTE_R (1L << 1) // 可读
#define PTE_W (1L << 2) // 可写  
#define PTE_X (1L << 3) // 可执行
#define PTE_U (1L << 4) // 用户模式可访问
#define PTE_A (1L << 6) // 已访问
#define PTE_D (1L << 7) // 已修改

// 权限组合
#define PTE_RW (PTE_R | PTE_W)
#define PTE_RX (PTE_R | PTE_X)
#define PTE_RWX (PTE_R | PTE_W | PTE_X)

// ==================== 通用页表操作 ====================
pagetable_t create_pagetable(void);
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm);
int map_region(pagetable_t pt, uint64 va, uint64 pa, uint64 size, int perm);
void unmap_page(pagetable_t pt, uint64 va);
void destroy_pagetable(pagetable_t pt);
uint64 walkaddr(pagetable_t pt, uint64 va);

// 辅助函数
pte_t* walk_create(pagetable_t pt, uint64 va);
pte_t* walk_lookup(pagetable_t pt, uint64 va);

// ==================== 内核虚拟内存管理 ====================
extern pagetable_t kernel_pagetable;
void kvminit(void);
void kvminithart(void);
void kvm_map_kernel(void);
void kvm_map_devices(void);
void* get_kernel_pagetable(void);

// ==================== 测试函数 ====================
void vm_test_basic(void);
void test_physical_memory(void);
void test_pagetable(void);
void kvmtest(void);

// 调试功能
void dump_pagetable(pagetable_t pt, int level);

#endif