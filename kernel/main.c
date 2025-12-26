// kernel/main.c
#include "defs.h"
#include "riscv.h"
#include "power.h"

void main_task(void)
{
    run_lab6_tests();
}

void kmain(void)
{
    clear_screen();
    printf("===== Kernel Booting =====\n");
    kinit();
    kvminit();
    kvminithart();
    procinit();
    trap_init();
    clock_init();
    binit();
    fileinit();
    virtio_disk_init();
    iinit();
    initlog(ROOTDEV, &sb);
    if (create_process(main_task) < 0)
    {
        printf("kmain: failed to create main_task\n");
        while (1)
            ;
    }
    scheduler();
}