#include "types.h"
#include "param.h"
#include "riscv.h"
#include "defs.h"
#include "pmm.h"
#include "interrupt.h"
#include "sbi.h"
#include "timer.h"
#include "proc.h"
#include "vm.h"

extern void run_process_tests(void);

void main()
{
    // 初始化系统组件
    console_init();
    printf("=== RISC-V OS: Priority Scheduling ===\n\n");

    pmm_init();

    // 初始化虚拟内存
    kvminit();
    kvminithart();

    proc_init();
    trap_init();
    timer_init();

    printf("System initialization completed.\n");
    printf("Starting priority scheduling tests...\n\n");

    // 运行优先级调度测试
    run_process_tests();

    // 等待测试完成
    ksleep(100);

    // 测试完成后进入调度器
    printf("\nAll tests completed. Entering scheduler...\n");
    scheduler();

    // 永远不会到达这里
    panic("scheduler returned");
}