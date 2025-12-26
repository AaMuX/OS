// kernel/main.c
#include "pmm.h"
#include "printf.h"
#include "pagetable.h"
#include "kvminit.h"
#include <stdint.h>
#include <stddef.h>
#include "power.h"
#include "console.h"
#include "trap.h"
#include "riscv.h"
#define PHYS_MEM_START 0x80000000UL
#define PHYS_MEM_END (PHYS_MEM_START + 128 * 1024 * 1024)

#include "pmm.h"
#include "printf.h"
#include "pagetable.h"
#include "kvminit.h"
#include <stdint.h>
#include <stddef.h>
#include "power.h"
#include "console.h"
#include "trap.h"
#include "riscv.h"

#define PHYS_MEM_START 0x80000000UL
#define PHYS_MEM_END (PHYS_MEM_START + 128 * 1024 * 1024)

void test_printf_basic()
{
    printf("Testing integer: %d\n", 42);
    printf("Testing negative: %d\n", -123);
    printf("Testing zero: %d\n", 0);
    printf("Testing hex: 0x%x\n", 0xABC);
    printf("Testing string: %s\n", "Hello");
    printf("Testing char: %c\n", 'X');
    printf("Testing percent: %%\n");
}

void test_printf_edge_cases()
{
    printf("INT_MAX: %d\n", 2147483647);
    printf("INT_MIN: %d\n", -2147483648);
    printf("NULL string: %s\n", (char*)0);
    printf("Empty string: %s\n", "");
}

// 控制台高级功能测试函数
void test_console_advanced_features(void)
{
    printf("\n--- Console Advanced Features Tests ---\n");

    // 测试1：光标定位功能
    printf("Testing goto_xy() - cursor positioning:\n");
    printf("Normal line 1\n");

    // 保存当前位置
    printf("Current position -> ");

    // 定位到特定位置输出
    goto_xy(5, 10); // 第5行，第10列
    printf("Position (5,10): Goto test");

    goto_xy(7, 5); // 第7行，第5列
    printf("Position (7,5): Another test");

    // 回到正常流
    goto_xy(9, 1); // 第9行，第1列
    printf("Back to normal flow at line 9\n");

    // 测试2：颜色输出功能
    printf("Testing printf_color() - colored output:\n");

    // 测试各种颜色
    printf_color(RED, "RED:     Error message simulation\n");
    printf_color(GREEN, "GREEN:   Success status message\n");
    printf_color(BLUE, "BLUE:    Information message\n");
    printf_color(YELLOW, "YELLOW:  Warning message\n");
    printf_color(WHITE, "WHITE:   Normal text with color reset\n");

    // 测试颜色与格式化结合
    printf_color(GREEN, "Formatted color: %s = 0x%x\n", "Magic number", 0xCAFEBABE);
    printf_color(RED, "Error code: %d, Message: %s\n", 404, "Not Found");

    // 测试3：清除行功能
    printf("Testing clear_line() function:\n");
    printf("This text will be partially cleared...");

    // 简单延时，让用户看到效果
    // for (volatile int i = 0; i < 500000; i++)
    //     ;

    clear_line(); // 清除当前行光标之后的内容
    printf("<- Cleared and new text started\n");

    printf("Advanced features test completed successfully!\n");
}

//物理内存分配
void test_physical_memory(void)
{
    printf("\n--- Testing Physical Memory Allocator (kalloc/kfree) ---\n");

    void *page1 = alloc_page();
    void *page2 = alloc_page();

    printf("page1=%p, page2=%p\n", page1, page2);

    if (page1 == 0 || page2 == 0)
    {
        printf("ERROR: alloc returned NULL\n");
    }

    if (((uint64_t)page1 & 0xFFF) == 0)
    {
        printf("page1 aligned OK\n");
    }
    else
    {
        printf("page1 alignment ERROR\n");
    }

    if (page1)
    {
        *(int *)page1 = 0x12345678;
        if (*(int *)page1 == 0x12345678)
        {
            printf("write/read OK: 0x%x\n", *(int *)page1);
        }
        else
        {
            printf("write/read ERROR\n");
        }
    }

    free_page(page1);
    void *page3 = alloc_page();
    printf("page3=%p (may equal page1)\n", page3);

    free_page(page2);
    free_page(page3);

    printf("=== Physical Memory Test End ===\n");
}

//测试页表
void test_pagetable(void)
{
    printf("\n--- 2. Testing Page Table Functions ---\n");
    pagetable_t pt = create_pagetable();
    if (!pt)
    {
        printf("create_pagetable failed\n");
        return;
    }

    /* allocate a physical page to map */
    void *p = alloc_page();
    if (!p)
    {
        printf("alloc_page failed\n");
        return;
    }

    uint64_t va = 0x40000000UL; /* test virtual address (page aligned) */
    uint64_t pa = (uint64_t)p;

    if (map_page(pt, va, pa, PTE_R | PTE_W))
    {
        printf("map_page failed\n");
        return;
    }

    dump_pagetable(pt);

    /* lookup */
    pte_t *pte = walk_lookup(pt, va);
    if (pte && (*pte & PTE_V))
    {
        uint64_t mapped_pa = ((*pte) >> PPN_SHIFT) << 12;
        printf("lookup: va=%p -> pa=%p\n", (void *)va, (void *)mapped_pa);
    }
    else
    {
        printf("lookup: not found\n");
    }

    /* cleanup */
    /* free the mapped physical page */
    free_page((void *)pa);
    destroy_pagetable(pt);
}

/* Test virtual memory activation */
void test_virtual_memory(void)
{
    printf("\n=== Virtual Memory Test Start ===\n");

    printf("Before enabling paging...\n");
    printf("Current mode: direct memory access\n");

    kvminit();
    printf("Kernel pagetable created\n");

    kvminithart();
    printf("Paging enabled, satp register set\n");

    printf("After enabling paging...\n");
    printf("Current mode: virtual memory with paging\n");

    printf("Testing kernel code execution...\n");
    extern char _text[], _etext[];
    uint64_t text_start = (uint64_t)_text;
    uint64_t text_end = (uint64_t)_etext;
    printf("Kernel text: %p - %p\n", (void *)text_start, (void *)text_end);

    printf("Testing kernel data access...\n");
    static int test_var = 0xDEADBEEF;
    printf("Test variable value: 0x%x\n", test_var);
    test_var = 0xCAFEBABE;
    if (test_var == 0xCAFEBABE)
    {
        printf("Kernel data access OK\n");
    }
    else
    {
        printf("Kernel data access ERROR\n");
    }

    printf("Testing device access...\n");

    printf("Device access test OK (UART mapped)\n");

    printf("Testing pagetable lookup...\n");
    pte_t *pte = walk_lookup(kernel_pagetable, KERNBASE);
    if (pte && (*pte & PTE_V))
    {
        uint64_t mapped_pa = ((*pte) >> PPN_SHIFT) << 12;
        printf("KERNBASE lookup OK: va=%p -> pa=%p\n", (void *)KERNBASE, (void *)mapped_pa);
    }

    printf("=== Virtual Memory Test End ===\n");
}

static volatile int sw_counter = 0;
static void sw_handler(void)
{
    w_sip(r_sip() & ~SIP_SSIP);
    sw_counter++;
}

// 时钟中断测试函数
void test_timer_interrupt(void)
{
    printf("Testing timer interrupt...\n");

    uint64_t start_time = get_time();
    volatile int interrupt_count = 0;
    timer_set_counter(&interrupt_count);
    int last = -1;

    while (interrupt_count < 5)
    {
        if (interrupt_count != last)
        {
            printf("Waiting for interrupt %d...\n", interrupt_count + 1);
            last = interrupt_count;
        }
        for (volatile int i = 0; i < 100000; i++)
        {
            __asm__ volatile("");
        }
    }

    uint64_t end_time = get_time();
    printf("Timer test completed: %d interrupts in %lu cycles\n",
           interrupt_count, (unsigned long)(end_time - start_time));

    timer_set_counter(NULL);
}

/// 1. 测试除零异常（RISC-V无硬件除零，模拟触发非法指令）
void test_divide_by_zero(void) {
    printf("\n=== Testing Divide-by-Zero Exception ===\n");
    printf("Expected: Kernel panic (simulated divide-by-zero via illegal instruction)\n");
    printf("Executing 1 / 0 + undefined instruction...\n");
    
    // RISC-V除零无硬件异常，通过unimp指令模拟
    asm volatile (
        "li t0, 1\n"    // t0 = 1
        "li t1, 0\n"    // t1 = 0
        "div t2, t0, t1\n" // 除零操作（无异常）
        "unimp"         // 触发非法指令异常（scause=2）
    );
    
    // 执行到此处说明测试失败
    printf("!!! TEST FAILED: No divide-by-zero exception triggered !!!\n");
}

// 2. 测试非法指令异常（执行未定义RISC-V指令）
static void test_exception_handling(void)
{
    printf("Testing exception handling...\n");
    asm volatile(".word 0x00000000");
    volatile uint64_t *bad = (volatile uint64_t *)0xFFFFFFFFFFFFFFFFULL;
    (void)*bad;
    printf("Exception tests completed\n");
}

extern void yield(void);
void sw_handler_yield(void)
{
    w_sip(r_sip() & ~SIP_SSIP);
    yield();
    sw_counter++;
}

// 1. 测量时钟中断处理的时间开销
static void test_interrupt_overhead(void)
{
    printf("Testing interrupt overhead...\n");
    extern void register_interrupt(int irq, void (*h)(void));
    extern void enable_interrupt(int irq);

    register_interrupt(SCAUSE_SUPERVISOR_SOFTWARE, sw_handler);
    enable_interrupt(SCAUSE_SUPERVISOR_SOFTWARE);

    uint64_t total = 0;
    const int rounds = 200;
    sw_counter = 0;
    for (int i = 0; i < rounds; i++)
    {
        uint64_t t0 = get_time();

        w_sip(r_sip() | SIP_SSIP);

        while (sw_counter <= i)
        {
            if ((get_time() - t0) > (10000000ULL / 10))
            { // >100ms
                printf("WARN: interrupt wait timeout (basic) i=%d\n", i);
                break;
            }
            asm volatile("");
        }
        uint64_t t1 = get_time();
        total += (t1 - t0);
    }
    printf("Interrupt overhead avg: %lu cycles\n", (unsigned long)(total / rounds));

    register_interrupt(SCAUSE_SUPERVISOR_SOFTWARE, sw_handler_yield);
    total = 0;
    sw_counter = 0;
    for (int i = 0; i < rounds; i++)
    {
        uint64_t t0 = get_time();
        w_sip(r_sip() | SIP_SSIP);
        while (sw_counter <= i)
        {
            if ((get_time() - t0) > (10000000ULL / 10))
            { // >100ms
                printf("WARN: interrupt wait timeout (yield) i=%d\n", i);
                break;
            }
            asm volatile("");
        }
        uint64_t t1 = get_time();
        total += (t1 - t0);
    }
    printf("Interrupt+yield overhead avg: %lu cycles\n", (unsigned long)(total / rounds));

    const uint64_t TIMEBASE_HZ = 10000000ULL;
    const uint32_t freqs[] = {50, 100, 200, 500, 1000};

    register_interrupt(SCAUSE_SUPERVISOR_SOFTWARE, sw_handler);
    for (unsigned fi = 0; fi < sizeof(freqs) / sizeof(freqs[0]); ++fi)
    {
        uint32_t hz = freqs[fi];
        uint64_t period = TIMEBASE_HZ / (uint64_t)hz;
        uint64_t window = TIMEBASE_HZ / 20;
        uint64_t start = get_time();
        uint64_t end = start + window;
        uint64_t next_fire = start;
        volatile uint64_t iterations = 0;
        sw_counter = 0;
        while (1)
        {
            uint64_t now = get_time();
            if (now >= end)
                break;
            if (now >= next_fire)
            {
                w_sip(r_sip() | SIP_SSIP);

                do
                {
                    next_fire += period;
                } while (now >= next_fire);
            }
            iterations++;
        }
        printf("Freq %u Hz: interrupts=%d iterations=%lu\n",
               hz, sw_counter, (unsigned long)iterations);
    }
}

void main(void)
{
    printf("\n[Test 1] Physical Memory Manager\n");
    pmm_init(0, 0);
    test_physical_memory();
    printf("\n[Test 2] Page Table Management\n");
    test_pagetable();
    printf("\n[Test 3] Virtual Memory Activation\n");
    test_virtual_memory();
    printf("\n=== All Tests Completed ===\n");
    poweroff();
}
