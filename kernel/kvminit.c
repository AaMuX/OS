#include "kvminit.h"
#include "pmm.h"
#include "printf.h"
#include <stdint.h>

#ifndef KERNBASE
#define KERNBASE 0x80000000UL
#endif
#ifndef MEMSIZE
#define MEMSIZE (128UL * 1024 * 1024)
#endif
#ifndef UART0
#define UART0 0x10000000UL
#endif

pagetable_t kernel_pagetable = 0;

static inline void w_satp(uint64_t satp)
{
    asm volatile("csrw satp, %0" ::"r"(satp));
}

static inline void sfence_vma(void)
{
    asm volatile("sfence.vma" ::: "memory");
}

int map_region(pagetable_t pt, uint64_t va, uint64_t pa, uint64_t size, int perm)
{
    if (!pt)
        return -1;

    uint64_t va_start = PAGE_ROUND_DOWN(va);
    uint64_t pa_start = PAGE_ROUND_DOWN(pa);
    uint64_t va_end = PAGE_ROUND_UP(va + size);

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

void kvminit(void)
{
    kernel_pagetable = create_pagetable();
    if (!kernel_pagetable)
    {
        printf("kvminit: create_pagetable failed\n");
        return;
    }

    extern char _text[], _etext[], _rodata[], _erodata[];
    extern char _data[], _edata[], _end[];

    uint64_t text = (uint64_t)_text;
    uint64_t etext = (uint64_t)_etext;
    uint64_t rodata = (uint64_t)_rodata;
    uint64_t erodata = (uint64_t)_erodata;
    uint64_t data = (uint64_t)_data;
    uint64_t edata = (uint64_t)_edata;
    uint64_t end = (uint64_t)_end;

    map_region(kernel_pagetable, text, text, (uint64_t)(etext - text), PTE_R | PTE_X);

    if (erodata > rodata)
        map_region(kernel_pagetable, rodata, rodata, (uint64_t)(erodata - rodata), PTE_R);

    map_region(kernel_pagetable, data, data, (uint64_t)(end - data), PTE_R | PTE_W);

    map_region(kernel_pagetable, end, end, PAGE_SIZE * 10, PTE_R | PTE_W);

    map_region(kernel_pagetable, UART0, UART0, PAGE_SIZE, PTE_R | PTE_W);

    printf("kvminit: kernel_pagetable created and regions mapped\n");
}

void kvminithart(void)
{
    if (!kernel_pagetable)
    {
        printf("kvminithart: kernel_pagetable is NULL\n");
        return;
    }
    uint64_t satp = MAKE_SATP(kernel_pagetable);

    w_satp(satp);

    sfence_vma();

    printf("kvminithart: satp set %p\n", (void *)satp);
}
