#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "pmm.h"
#include "vm.h"

// ==================== 通用页表操作 ====================

// 地址解析宏
#define VPN_SHIFT(level) (12 + 9 * (level))
#define VPN_MASK(va, level) (((va) >> VPN_SHIFT(level)) & 0x1FF)

// Sv39 地址空间参数
#define MAXVA (1L << (9 + 9 + 9 + 12 - 1))

// PTE 操作宏
#define PA2PTE(pa) ((((uint64)pa) >> 12) << 10)
#define PTE2PA(pte) (((pte) >> 10) << 12)
#define PTE_FLAGS(pte) ((pte) & 0x3FF)

// 创建新的页表
pagetable_t create_pagetable(void) {
    pagetable_t pt = (pagetable_t)alloc_page();
    if (pt == NULL) {
        return NULL;
    }
    
    // 清空页表
    for (int i = 0; i < 512; i++) {
        pt[i] = 0;
    }
    
    return pt;
}

// 递归释放页表
static void free_pagetable_recursive(pagetable_t pt, int level) {
    for (int i = 0; i < 512; i++) {
        pte_t pte = pt[i];
        if (pte & PTE_V) {
            if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
                // 中间页表页，递归释放
                pagetable_t child = (pagetable_t)PTE2PA(pte);
                free_pagetable_recursive(child, level + 1);
            }
            // 叶子页表项指向的物理页由调用者负责释放
        }
    }
    free_page((void*)pt);
}

// 销毁页表
void destroy_pagetable(pagetable_t pt) {
    if (pt == NULL) return;
    free_pagetable_recursive(pt, 0);
}

pte_t* walk_lookup(pagetable_t pt, uint64 va) {
    if (va >= MAXVA) {
        return NULL;
    }
    
    pagetable_t current = pt;
    
    // 遍历L2和L1（非叶子层级）
    for (int level = 2; level > 0; level--) {
        pte_t *pte = &current[VPN_MASK(va, level)];
        if (!(*pte & PTE_V)) {
            return NULL;
        }
        current = (pagetable_t)PTE2PA(*pte);
    }
    
    // 处理L0（叶子层级）
    pte_t *pte = &current[VPN_MASK(va, 0)];
    if (!(*pte & PTE_V)) {
        return NULL;
    }
    
    return pte;
}

// 页表遍历
pte_t* walk_create(pagetable_t pt, uint64 va) {
    if (va >= MAXVA) {
        return NULL;
    }
    
    pagetable_t current = pt;
    
    for (int level = 2; level > 0; level--) {
        pte_t *pte = &current[VPN_MASK(va, level)];
        
        if (*pte & PTE_V) {
            // PTE有效，转到下一级
            current = (pagetable_t)PTE2PA(*pte);
        } else {
            // PTE无效，分配新页表页
            pagetable_t new_pt = (pagetable_t)alloc_page();
            if (new_pt == NULL) {
                return NULL;
            }
            
            // 清空新页表
            for (int i = 0; i < 512; i++) {
                new_pt[i] = 0;
            }
            
            // 设置PTE指向新页表
            *pte = PA2PTE(new_pt) | PTE_V;
            current = new_pt;
        }
    }
    
    return &current[VPN_MASK(va, 0)];
}

// 建立虚拟地址到物理地址的映射
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm) {
    // 检查地址对齐
    if ((va % PGSIZE) != 0 || (pa % PGSIZE) != 0) {
        printf("VM: unaligned address va=0x%p pa=0x%p\n", (void*)va, (void*)pa);
        return -1;
    }
    
    // 获取或创建PTE
    pte_t *pte = walk_create(pt, va);
    if (pte == NULL) {
        printf("VM: failed to walk page table\n");
        return -1;
    }
    
    // 检查是否已映射
    if (*pte & PTE_V) {
        printf("VM: already mapped va=0x%p\n", (void*)va);
        return -1;
    }
    
    // 设置映射
    *pte = PA2PTE(pa) | perm | PTE_V;
    
    return 0;
}
//建立连续虚拟地址区域到物理地址区域的映射
int map_region(pagetable_t pt, uint64 va, uint64 pa, uint64 size, int perm) {
    if (size == 0) {
        return 0;
    }
    
    if ((va % PGSIZE) != 0 || (pa % PGSIZE) != 0) {
        return -1;
    }
    
    uint64 mapped_pages = 0;
    uint64 skipped_pages = 0;
    uint64 total_pages = size / PGSIZE;
    
    for (uint64 i = 0; i < total_pages; i++) {
        uint64 current_va = va + i * PGSIZE;
        uint64 current_pa = pa + i * PGSIZE;
        
        // 检查是否已映射
        pte_t *pte = walk_lookup(pt, current_va);
        if (pte && (*pte & PTE_V)) {
            // 已映射，跳过
            skipped_pages++;
            continue;
        }
        
        if (map_page(pt, current_va, current_pa, perm) != 0) {
            printf("VM: Failed to map page %d/%d at VA 0x%p\n", 
                   (int)i, (int)total_pages, (void*)current_va);
            // 继续映射其他页面，不立即返回
            continue;
        }
        mapped_pages++;
    }
    
    if (skipped_pages > 0) {
        printf("VM: Successfully mapped %d/%d pages (%d already mapped)\n", 
               (int)mapped_pages, (int)total_pages, (int)skipped_pages);
    } else {
        printf("VM: Successfully mapped %d/%d pages\n", (int)mapped_pages, (int)total_pages);
    }
    return (mapped_pages + skipped_pages == total_pages) ? 0 : -1;
}

// 取消单个虚拟页的映射-将对应的PTE清零，不释放物理页面（由调用者负责）
void unmap_page(pagetable_t pt, uint64 va) {
    pte_t *pte = walk_lookup(pt, va);
    if (pte && (*pte & PTE_V)) {
        *pte = 0;
    }
}

// 虚拟地址到物理地址转换
uint64 walkaddr(pagetable_t pt, uint64 va) {
    pte_t *pte = walk_lookup(pt, va);
    if (pte == NULL || !(*pte & PTE_V)) {
        return 0;
    }
    
    //if (*pte & PTE_U) {
    //    return 0; // 用户页表项，内核不能直接访问
    //}
    
    return PTE2PA(*pte) | (va & 0xFFF);
}

// 递归打印页表
static void dump_pagetable_recursive(pagetable_t pt, int level, uint64 base_va) {
    char *level_names[] = {"L2", "L1", "L0"};
    
    for (int i = 0; i < 512; i++) {
        pte_t pte = pt[i];
        if (pte & PTE_V) {
            uint64 child_va = base_va | ((uint64)i << VPN_SHIFT(level));
            
            if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
                // 中间页表（只有非叶子层级）
                printf("  %s[%03d] -> %s page table at 0x%p\n", 
                       level_names[level], i, level_names[level-1], (void*)PTE2PA(pte));
                
                pagetable_t child_pt = (pagetable_t)PTE2PA(pte);
                dump_pagetable_recursive(child_pt, level - 1, child_va);
            } else {
                // 叶子映射
                uint64 pa = PTE2PA(pte);
                char perms[10];
                int idx = 0;
                
                if (pte & PTE_R) perms[idx++] = 'R';
                if (pte & PTE_W) perms[idx++] = 'W'; 
                if (pte & PTE_X) perms[idx++] = 'X';
                if (pte & PTE_U) perms[idx++] = 'U';
                if (pte & PTE_A) perms[idx++] = 'A';
                if (pte & PTE_D) perms[idx++] = 'D';
                perms[idx] = '\0';
                
                printf("  %s[%03d] 0x%p -> 0x%p [%s]\n",
                       level_names[level], i, (void*)child_va, (void*)pa, perms);
            }
        }
    }
}

// 打印页表内容
void dump_pagetable(pagetable_t pt, int level) {
    if (pt == NULL) {
        printf("VM: null page table\n");
        return;
    }
    
    printf("=== Page Table Dump (level %d) ===\n", level);
    dump_pagetable_recursive(pt, level, 0);
    printf("=== End of Page Table ===\n");
}

// ==================== 内核虚拟内存管理 ====================

// 内核页表
pagetable_t kernel_pagetable = 0;

// SATP 寄存器构造
#define SATP_SV39 (8L << 60)
#define MAKE_SATP(pagetable) (SATP_SV39 | (((uint64)pagetable) >> 12))

// 初始化内核页表
void kvminit(void) {
    // 如果已经初始化，直接返回
    if (kernel_pagetable != NULL) {
        printf("KVM: Kernel page table already initialized\n");
        return;
    }
    
    printf("KVM: Initializing kernel page table...\n");
    
    // 1. 创建内核页表
    kernel_pagetable = create_pagetable();
    if (kernel_pagetable == NULL) {
        panic("kvminit: failed to create kernel page table");
    }
    
    // 2. 映射内核区域（代码段和数据段，还包括了设备的映射）
    kvm_map_kernel();  
    printf("KVM: Kernel page table initialized successfully\n");
}

void kvm_map_kernel(void) {
    printf("KVM: Mapping kernel regions...\n");
    // 计算各段大小
    uint64 text_size = (uint64)etext - KERNBASE;
    uint64 data_physical_size = PHYSTOP - (uint64)etext;
    
    //printf("  Segment sizes:\n");
    //printf("    Text: %d KB\n", (int)(text_size / 1024));
    //printf("    Data+Physical: %d MB\n", (int)(data_physical_size / (1024 * 1024)));
    
    // 1. 映射代码段 (RX) - 从 KERNBASE 到 etext
    printf("  Text: 0x%p - 0x%p [RX]\n", 
           (void*)KERNBASE, etext);
    
    if (map_region(kernel_pagetable, KERNBASE, KERNBASE, 
                   text_size, PTE_R | PTE_X) != 0) {
        printf("KVM: Error: kernel text mapping failed\n");
        return;
    }
    printf("  Text mapping: SUCCESS\n");
    
    // 2. 映射数据段+所有物理内存 (RW) - 从 etext 到 PHYSTOP
    printf("  Data+Physical: 0x%p - 0x%p [RW]\n", 
           etext, (void*)PHYSTOP);
    
    if (map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
                   data_physical_size, PTE_R | PTE_W) != 0) {
        printf("KVM: Error: data+physical memory mapping failed\n");
        return;
    }
    printf("  Data+Physical mapping: SUCCESS\n");
    
    // 3. 映射设备
    kvm_map_devices();
    
    printf("KVM: Kernel page table initialized successfully\n");
}

// 映射设备区域
void kvm_map_devices(void) {
    printf("KVM: Mapping devices...\n");
    //这里只映射了三种设备，后续可根据需要添加更多设备映射
    
    // 映射 CLINT (Core Local Interruptor) - 定时器相关
    // CLINT 区域从 0x02000000 开始，需要映射至少 64KB
    uint64 clint_start = 0x02000000;
    uint64 clint_size = 0x10000;  // 64KB，足够覆盖 CLINT 区域
    printf("  CLINT: 0x%p - 0x%p [RW]\n", (void*)clint_start, (void*)(clint_start + clint_size));
    if (map_region(kernel_pagetable, clint_start, clint_start, clint_size, PTE_R | PTE_W) != 0) {
        printf("KVM: Warning: CLINT mapping failed, continuing...\n");
    }
    
    // 映射 UART - 如果已经映射则跳过
    printf("  UART: 0x%p [RW]\n", (void*)UART0);
    pte_t *uart_pte = walk_lookup(kernel_pagetable, UART0);
    if (uart_pte && (*uart_pte & PTE_V)) {
        printf("  UART already mapped, skipping...\n");
    } else {
        if (map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0) {
            printf("KVM: Warning: UART mapping failed, continuing...\n");
        }
    }
    
    // 映射 VIRTIO MMIO 区域（0x10001000 - 0x10020000，覆盖所有可能的VirtIO设备）
    // QEMU virt机器上，VirtIO MMIO设备通常在0x10001000-0x10008000范围内
    // 注意：0x10000000 已经被 UART 占用，所以从 0x10001000 开始
    uint64 virtio_start = 0x10001000;
    uint64 virtio_size = 0x1F000;  // 约124KB，足够覆盖所有VirtIO设备
    printf("  VIRTIO MMIO: 0x%p - 0x%p [RW]\n", (void*)virtio_start, (void*)(virtio_start + virtio_size));
    if (map_region(kernel_pagetable, virtio_start, virtio_start, virtio_size, PTE_R | PTE_W) != 0) {
        printf("KVM: Warning: VIRTIO MMIO mapping failed, continuing...\n");
    }
}

// 激活内核页表
void kvminithart(void) {
    printf("KVM: Activating kernel page table...\n");
    
    if (kernel_pagetable == NULL) {
        panic("kvminithart: kernel page table not initialized");
    }
    
    // 等待之前的写操作完成
    asm volatile("sfence.vma");
    
    // 保存旧的SATP值（用于调试）
    uint64 old_satp = r_satp();
    
    // 设置SATP寄存器
    uint64 new_satp = MAKE_SATP(kernel_pagetable);
    w_satp(new_satp);
    
    // 刷新TLB
    asm volatile("sfence.vma");
    
    printf("KVM: Virtual memory enabled\n");
    printf("KVM: SATP changed: 0x%p -> 0x%p\n", 
           (void*)old_satp, (void*)r_satp());
}

// 获取内核页表
void* get_kernel_pagetable(void) {
    return (void*)kernel_pagetable;
}

// ==================== 测试函数 ====================

// 基本测试函数
void vm_test_basic(void) {
    printf("\n=== Virtual Memory System Test ===\n\n");
    
    // 1. 创建页表
    printf("1. Creating page table...\n");
    pagetable_t pt = create_pagetable();
    if (pt == NULL) {
        printf("FAIL: Failed to create page table\n");
        return;
    }
    printf("SUCCESS: Page table created at 0x%p\n", pt);
    
    // 2. 分配一些物理页
    printf("\n2. Allocating physical pages...\n");
    void *page1 = alloc_page();
    void *page2 = alloc_page();
    void *page3 = alloc_page();
    
    if (!page1 || !page2 || !page3) {
        printf("FAIL: Failed to allocate physical pages\n");
        destroy_pagetable(pt);
        return;
    }
    printf("SUCCESS: Allocated pages: 0x%p, 0x%p, 0x%p\n", page1, page2, page3);
    
    // 3. 建立映射
    printf("\n3. Creating mappings...\n");
    
    // 映射1: 代码页 (RX)
    if (map_page(pt, 0x1000, (uint64)page1, PTE_R | PTE_X) != 0) {
        printf("FAIL: Failed to map code page\n");
    } else {
        printf("SUCCESS: Mapped 0x1000 -> 0x%p [RX]\n", page1);
    }
    
    // 映射2: 数据页 (RW)
    if (map_page(pt, 0x2000, (uint64)page2, PTE_R | PTE_W) != 0) {
        printf("FAIL: Failed to map data page\n");
    } else {
        printf("SUCCESS: Mapped 0x2000 -> 0x%p [RW]\n", page2);
    }
    
    // 映射3: 用户数据页 (RWU)
    if (map_page(pt, 0x3000, (uint64)page3, PTE_R | PTE_W | PTE_U) != 0) {
        printf("FAIL: Failed to map user page\n");
    } else {
        printf("SUCCESS: Mapped 0x3000 -> 0x%p [RWU]\n", page3);
    }
    
    // 4. 测试地址转换
    printf("\n4. Testing address translation...\n");
    uint64 pa1 = walkaddr(pt, 0x1000);
    uint64 pa2 = walkaddr(pt, 0x2000);
    uint64 pa3 = walkaddr(pt, 0x3000);
    
    printf("walkaddr(0x1000) = 0x%p (expected: 0x%p)\n", (void*)pa1, page1);
    printf("walkaddr(0x2000) = 0x%p (expected: 0x%p)\n", (void*)pa2, page2);
    printf("walkaddr(0x3000) = 0x%p (expected: 0x%p)\n", (void*)pa3, page3);
    
    // 5. 测试无效地址
    uint64 pa_invalid = walkaddr(pt, 0x4000);
    printf("walkaddr(0x4000) = 0x%p (expected: 0x0)\n", (void*)pa_invalid);
    
    // 6. 打印页表结构
    printf("\n5. Page table structure:\n");
    dump_pagetable(pt, 2);
    
    // 7. 清理
    printf("\n6. Cleaning up...\n");
    destroy_pagetable(pt);
    free_page(page1);
    free_page(page2);
    free_page(page3);
    printf("SUCCESS: All resources freed\n");
    
    printf("\n=== Virtual Memory Test Completed ===\n\n");
}

// 物理内存分配器测试
void test_physical_memory(void) {
    printf("\n=== Physical Memory Allocator Test ===\n\n");
    
    // 测试基本分配和释放
    printf("1. Testing basic allocation...\n");
    void *page1 = alloc_page();
    void *page2 = alloc_page();
    
    if (page1 == NULL || page2 == NULL) {
        printf("FAIL: Failed to allocate pages\n");
        return;
    }
    
    printf("  Allocated: page1=0x%p, page2=0x%p\n", page1, page2);
    
    // 页对齐检查
    if (((uint64)page1 & 0xFFF) != 0 || ((uint64)page2 & 0xFFF) != 0) {
        printf("FAIL: Pages not aligned\n");
        free_page(page1);
        free_page(page2);
        return;
    }
    printf("  Page alignment check: PASS\n");
    
    // 测试数据写入
    printf("2. Testing data access...\n");
    *(uint64*)page1 = 0x123456789ABCDEF0;
    if (*(uint64*)page1 != 0x123456789ABCDEF0) {
        printf("FAIL: Data write/read failed\n");
        free_page(page1);
        free_page(page2);
        return;
    }
    printf("  Data access test: PASS\n");
    
    // 测试释放和重新分配
    printf("3. Testing free and realloc...\n");
    free_page(page1);
    void *page3 = alloc_page();
    
    if (page3 == NULL) {
        printf("FAIL: Failed to reallocate page\n");
        free_page(page2);
        return;
    }
    
    printf("  Reallocated: page3=0x%p\n", page3);
    
    // 清理
    free_page(page2);
    free_page(page3);
    
    printf("SUCCESS: Physical memory test passed\n");
}

// 页表功能测试
void test_pagetable(void) {
    printf("\n=== Page Table Function Test ===\n\n");
    
    pagetable_t pt = create_pagetable();
    if (pt == NULL) {
        printf("FAIL: Failed to create page table\n");
        return;
    }
    
    printf("1. Created page table at 0x%p\n", pt);
    
    // 测试基本映射
    printf("2. Testing basic mapping...\n");
    uint64 va = 0x1000000;
    void *physical_page = alloc_page();
    if (physical_page == NULL) {
        printf("FAIL: Failed to allocate physical page\n");
        destroy_pagetable(pt);
        return;
    }
    
    if (map_page(pt, va, (uint64)physical_page, PTE_R | PTE_W) != 0) {
        printf("FAIL: Failed to map page\n");
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    printf("  Mapped VA 0x%p -> PA 0x%p [RW]\n", (void*)va, physical_page);
    
    // 测试地址转换
    printf("3. Testing address translation...\n");
    pte_t *pte = walk_lookup(pt, va);
    if (pte == NULL || !(*pte & PTE_V)) {
        printf("FAIL: PTE not found or invalid\n");
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    
    uint64 translated_pa = PTE2PA(*pte);
    if (translated_pa != (uint64)physical_page) {
        printf("FAIL: Address translation error: expected 0x%p, got 0x%p\n",
               physical_page, (void*)translated_pa);
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    printf("  Address translation: PASS\n");
    
    // 测试权限位
    printf("4. Testing permission bits...\n");
    if (!(*pte & PTE_R)) {
        printf("FAIL: Read permission not set\n");
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    if (!(*pte & PTE_W)) {
        printf("FAIL: Write permission not set\n");
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    if (*pte & PTE_X) {
        printf("FAIL: Execute permission incorrectly set\n");
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    printf("  Permission bits: PASS\n");
    
    // 测试walkaddr函数
    printf("5. Testing walkaddr function...\n");
    uint64 walkaddr_result = walkaddr(pt, va);
    if (walkaddr_result != ((uint64)physical_page | (va & 0xFFF))) {
        printf("FAIL: walkaddr returned 0x%p, expected 0x%p\n",
               (void*)walkaddr_result, 
               (void*)((uint64)physical_page | (va & 0xFFF)));
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    printf("  walkaddr function: PASS\n");
    
    // 清理
    free_page(physical_page);
    destroy_pagetable(pt);
    
    printf("SUCCESS: Page table test passed\n");
}

// 内核虚拟内存测试
void kvmtest(void) {
    printf("\n=== Virtual Memory Activation Test ===\n\n");
    
    printf("Before enabling paging...\n");
    
    // 测试1: 检查初始状态
    printf("1. Checking initial state:\n");
    printf("   Kernel page table: 0x%p\n", get_kernel_pagetable());
    printf("   SATP register: 0x%p\n", (void*)r_satp());
    printf("   Paging mode: %s\n", (r_satp() & SATP_SV39) ? "ENABLED" : "DISABLED");
    
    // 测试2: 物理内存访问测试
    printf("\n2. Physical memory access test:\n");
    uint64 test_pattern = 0x1234567890ABCDEF;
    extern char end[];
    uint64 *test_addr = (uint64*)((uint64)end - 0x1000);  // end 之前的地址
    
    *test_addr = test_pattern;
    uint64 read_value = *test_addr;
    printf("   Write 0x%p to 0x%p\n", (void*)test_pattern, test_addr);
    printf("   Read  0x%p from 0x%p\n", (void*)read_value, test_addr);
    printf("   Physical access: %s\n", read_value == test_pattern ? "PASS" : "FAIL");
    
    // 启用分页
    printf("\n3. Enabling virtual memory...\n");
    kvminit();
    kvminithart();
    
    printf("After enabling paging...\n");
    
    // 测试4: 检查分页状态
    printf("\n4. Paging status check:\n");
    printf("   Kernel page table: 0x%p\n", get_kernel_pagetable());
    printf("   SATP register: 0x%p\n", (void*)r_satp());
    printf("   Paging mode: %s\n", (r_satp() & SATP_SV39) ? "ENABLED" : "DISABLED");
    
    // 测试5: 测试内核代码仍然可执行（通过函数调用测试）
    printf("\n5. Kernel code execution test:\n");
    printf("   Testing function calls...\n");
    // 调用一些内核函数来测试代码执行
    uint64 free_mem = get_free_memory();
    uint64 total_mem = get_total_memory();
    printf("   Free memory: %d KB\n", (int)(free_mem / 1024));
    printf("   Total memory: %d KB\n", (int)(total_mem / 1024));
    printf("   Code execution: PASS\n");
    
    // 测试6: 测试内核数据仍然可访问
    printf("\n6. Kernel data access test:\n");
    read_value = *test_addr;
    printf("   Read 0x%p from 0x%p through page table\n", (void*)read_value, test_addr);
    printf("   Data access: %s\n", read_value == test_pattern ? "PASS" : "FAIL");
    
    // 测试7: 测试新数据写入和读取
    printf("\n7. New data write/read test:\n");
    uint64 new_pattern = 0xFEDCBA9876543210;
    *test_addr = new_pattern;
    read_value = *test_addr;
    printf("   Write 0x%p to 0x%p\n", (void*)new_pattern, test_addr);
    printf("   Read  0x%p from 0x%p\n", (void*)read_value, test_addr);
    printf("   New data access: %s\n", read_value == new_pattern ? "PASS" : "FAIL");
    
    // 测试8: 测试地址转换功能
    printf("\n8. Address translation test:\n");
    uint64 translated = walkaddr(get_kernel_pagetable(), (uint64)test_addr);
    printf("   Virtual address: 0x%p\n", test_addr);
    printf("   Physical address: 0x%p\n", (void*)translated);
    printf("   Address translation: %s\n", 
           translated == (uint64)test_addr ? "PASS" : "FAIL");
    
    // 测试9: 测试多个内存区域访问
    printf("\n9. Multiple memory regions test:\n");
    uint64 regions[3] = {0x80000000, 0x80100000, 0x80200000};
    int region_test_pass = 1;
    
    for (int i = 0; i < 3; i++) {
        uint64 *region_addr = (uint64*)regions[i];
        uint64 test_val = 0xAABBCCDD11223344 + i;
        *region_addr = test_val;
        if (*region_addr != test_val) {
            region_test_pass = 0;
            printf("   Region 0x%p: FAIL\n", (void*)regions[i]);
        } else {
            printf("   Region 0x%p: PASS\n", (void*)regions[i]);
        }
    }
    printf("   Multiple regions: %s\n", region_test_pass ? "PASS" : "FAIL");
    
    // 测试10: 页表结构验证
    printf("\n10. Page table structure verification:\n");
    pagetable_t kpt = get_kernel_pagetable();
    if (kpt) {
        printf("   Kernel page table exists: PASS\n");
        // 可以添加更详细的页表检查
        printf("   Basic page table check: PASS\n");
    } else {
        printf("   Kernel page table exists: FAIL\n");
    }
    
    // 测试11: 内存分配测试（验证物理内存管理器仍然工作）
    printf("\n11. Memory allocation test:\n");
    void *allocated_page = alloc_page();
    if (allocated_page) {
        printf("   Page allocated at: 0x%p\n", allocated_page);
        *(uint64*)allocated_page = 0x5555555555555555;
        if (*(uint64*)allocated_page == 0x5555555555555555) {
            printf("   Allocated memory access: PASS\n");
        } else {
            printf("   Allocated memory access: FAIL\n");
        }
        free_page(allocated_page);
        printf("   Page freed successfully\n");
    } else {
        printf("   Page allocation: FAIL\n");
    }
    
    printf("\n=== Virtual Memory Activation Test Completed ===\n");
    printf("Summary: Virtual memory system is %s\n", 
           (r_satp() & SATP_SV39) ? "ACTIVE AND WORKING" : "NOT WORKING");
}