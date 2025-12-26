// 通过 QEMU poweroff 设备退出
#include "power.h"

static volatile unsigned int *const VIRT_TEST = (unsigned int *)0x100000;

void poweroff(void)
{
    // QEMU virt: 写入 0x5555 到 virt-test 设备触发退出
    *VIRT_TEST = 0x5555;
}
