#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "bio.h"
#include "pmm.h"
#include "memlayout.h"

// 简单的memset实现（如果defs.h中没有）
static void* memset(void *dst, int c, uint n) {
    char *cdst = (char *) dst;
    for(int i = 0; i < n; i++){
        cdst[i] = c;
    }
    return dst;
}

// VirtIO块设备寄存器地址（QEMU virt机器）
// RISC-V virt机器上，VirtIO MMIO设备从VIRTIO0开始，每个设备间隔0x200
// 使用memlayout.h中定义的VIRTIO0地址
#define VIRTIO_BASE VIRTIO0  // 使用memlayout.h中的定义
#define VIRTIO_SIZE 0x200
#define VIRTIO_MAGIC 0x74726976
#define VIRTIO_VERSION 2

// VirtIO寄存器偏移
static uint64 virtio_base_addr = 0;  // 在virtio_disk_init中设置

// 辅助函数：获取寄存器地址
static inline volatile uint32* virtio_reg(uint32 offset) {
    if(virtio_base_addr == 0)
        panic("virtio_reg: virtio_base_addr not initialized");
    return (volatile uint32 *)(virtio_base_addr + offset);
}

// 为了兼容，保留R宏，但使用函数
#define R(r) virtio_reg(r)
#define VIRTIO_MMIO_MAGIC_VALUE        0x000
#define VIRTIO_MMIO_VERSION            0x004
#define VIRTIO_MMIO_DEVICE_ID          0x008
#define VIRTIO_MMIO_VENDOR_ID          0x00c
#define VIRTIO_MMIO_DEVICE_FEATURES    0x010
#define VIRTIO_MMIO_DRIVER_FEATURES    0x020
#define VIRTIO_MMIO_QUEUE_SEL          0x030
#define VIRTIO_MMIO_QUEUE_NUM_MAX      0x034
#define VIRTIO_MMIO_QUEUE_NUM          0x038
#define VIRTIO_MMIO_QUEUE_ALIGN        0x03c
#define VIRTIO_MMIO_QUEUE_PFN          0x040
#define VIRTIO_MMIO_QUEUE_READY        0x044
#define VIRTIO_MMIO_QUEUE_NOTIFY       0x050
#define VIRTIO_MMIO_INTERRUPT_STATUS   0x060
#define VIRTIO_MMIO_INTERRUPT_ACK      0x064
#define VIRTIO_MMIO_STATUS             0x070

// Legacy VirtIO registers (for compatibility with xv6)
#define VIRTIO_MMIO_QUEUE_DESC_LOW     0x080
#define VIRTIO_MMIO_QUEUE_DESC_HIGH    0x084
#define VIRTIO_MMIO_DRIVER_DESC_LOW    0x090
#define VIRTIO_MMIO_DRIVER_DESC_HIGH   0x094
#define VIRTIO_MMIO_DEVICE_DESC_LOW    0x0a0
#define VIRTIO_MMIO_DEVICE_DESC_HIGH   0x0a4

#define VIRTIO_STATUS_ACKNOWLEDGE      1
#define VIRTIO_STATUS_DRIVER           2
#define VIRTIO_STATUS_FAILED           128
#define VIRTIO_STATUS_FEATURES_OK      8
#define VIRTIO_STATUS_DRIVER_OK        4

// VirtIO描述符标志
#define VRING_DESC_F_NEXT  1
#define VRING_DESC_F_WRITE 2

// VirtIO队列大小
#define NUM 8

struct virtq_desc {
    uint64 addr;
    uint32 len;
    uint16 flags;
    uint16 next;
};

struct virtq_avail {
    uint16 flags;
    uint16 idx;
    uint16 ring[NUM];
    uint16 unused;
};

struct virtq_used_elem {
    uint32 id;
    uint32 len;
};

struct virtq_used {
    uint16 flags;
    uint16 idx;
    struct virtq_used_elem ring[NUM];
};

// 请求结构
#define VIRTIO_BLK_T_IN  0
#define VIRTIO_BLK_T_OUT 1

struct virtio_blk_req {
    uint32 type;
    uint32 reserved;
    uint64 sector;
    char padding[48];
    uint8 status;
};

static struct virtq_desc *desc;
static struct virtq_avail *avail;
static struct virtq_used *used;
static char free_desc[NUM];
static int used_idx = 0;

// 请求结构（参考xv6实现）
static struct virtio_blk_req ops[NUM];

static int virtio_disk_available = 0;

// 查找一个空闲描述符（参考xv6实现）
static int
alloc_desc()
{
    for(int i = 0; i < NUM; i++){
        if(free_desc[i]){
            free_desc[i] = 0;
            return i;
        }
    }
    return -1;
}

// 释放描述符（参考xv6实现）
static void
free_desc_func(int i)
{
    if(i >= NUM)
        panic("free_desc 1");
    if(free_desc[i])
        panic("free_desc 2");
    desc[i].addr = 0;
    desc[i].len = 0;
    desc[i].flags = 0;
    desc[i].next = 0;
    free_desc[i] = 1;
}

// 释放描述符链（参考xv6实现）
static void
free_chain(int i)
{
    while(1){
        int flag = desc[i].flags;
        int nxt = desc[i].next;
        free_desc_func(i);
        if(flag & VRING_DESC_F_NEXT)
            i = nxt;
        else
            break;
    }
}

// 分配三个描述符（参考xv6实现）
static int
alloc3_desc(int *idx)
{
    for(int i = 0; i < 3; i++){
        idx[i] = alloc_desc();
        if(idx[i] < 0){
            for(int j = 0; j < i; j++)
                free_desc_func(idx[j]);
            return -1;
        }
    }
    return 0;
}

static void
virtio_disk_init(void)
{
    uint32 status = 0;
    uint64 features;
    uint64 found_addr = 0;
    
    // 扫描可能的VirtIO设备地址，查找块设备（Device ID = 2）
    // QEMU virt机器上，VirtIO MMIO设备通常从0x10001000开始
    for(uint64 addr = VIRTIO_BASE; addr < VIRTIO_BASE + 10 * VIRTIO_SIZE; addr += VIRTIO_SIZE) {
        volatile uint32 *magic = (volatile uint32 *)(addr + VIRTIO_MMIO_MAGIC_VALUE);
        volatile uint32 *version = (volatile uint32 *)(addr + VIRTIO_MMIO_VERSION);
        volatile uint32 *device_id = (volatile uint32 *)(addr + VIRTIO_MMIO_DEVICE_ID);
        
        if(*magic == VIRTIO_MAGIC && *version == VIRTIO_VERSION && *device_id == 2) {
            found_addr = addr;
            printf("Found VirtIO block device at 0x%x\n", (uint32)found_addr);
            break;
        }
    }
    
    if(found_addr == 0) {
        printf("VirtIO block device not found. Scanned addresses:\n");
        for(uint64 addr = VIRTIO_BASE; addr < VIRTIO_BASE + 10 * VIRTIO_SIZE; addr += VIRTIO_SIZE) {
            volatile uint32 *magic = (volatile uint32 *)(addr + VIRTIO_MMIO_MAGIC_VALUE);
            volatile uint32 *device_id = (volatile uint32 *)(addr + VIRTIO_MMIO_DEVICE_ID);
            if(*magic == VIRTIO_MAGIC) {
                printf("  0x%x: Device ID = %d\n", (uint32)addr, *device_id);
            }
        }
        panic("VirtIO block device required but not found");
    }
    
    // 设置全局地址变量
    virtio_base_addr = found_addr;
    
    virtio_disk_available = 1;
    printf("VirtIO disk found, initializing...\n");

    // 重置设备
    *R(VIRTIO_MMIO_STATUS) = 0;
    status |= VIRTIO_STATUS_ACKNOWLEDGE;
    *R(VIRTIO_MMIO_STATUS) = status;
    status |= VIRTIO_STATUS_DRIVER;
    *R(VIRTIO_MMIO_STATUS) = status;

    // 协商features（简化：接受所有特性）
    features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    *R(VIRTIO_MMIO_DRIVER_FEATURES) = features & 0x1;  // 只接受基本特性
    status |= VIRTIO_STATUS_FEATURES_OK;
    *R(VIRTIO_MMIO_STATUS) = status;
    
    // 检查features是否被接受
    status = *R(VIRTIO_MMIO_STATUS);
    if(!(status & VIRTIO_STATUS_FEATURES_OK)) {
        printf("VirtIO: features not accepted\n");
        virtio_disk_available = 0;
        return;
    }

    // 设置队列
    *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    if(max == 0) {
        printf("VirtIO: cannot find virtio disk queue\n");
        virtio_disk_available = 0;
        return;
    }
    if(max < NUM) {
        printf("VirtIO: queue too small (%d < %d)\n", max, NUM);
        virtio_disk_available = 0;
        return;
    }

    // 分配描述符表、可用队列和已用队列（参考xv6实现）
    // xv6分别分配三个页面，而不是一个连续的块
    desc = (struct virtq_desc*)alloc_page();
    avail = (struct virtq_avail*)alloc_page();
    used = (struct virtq_used*)alloc_page();
    
    if(!desc || !avail || !used) {
        printf("VirtIO: failed to allocate virtqueue memory\n");
        virtio_disk_available = 0;
        return;
    }
    
    // 清零内存（参考xv6实现）
    memset(desc, 0, PGSIZE);
    memset(avail, 0, PGSIZE);
    memset(used, 0, PGSIZE);
    
    // 初始化free_desc数组
    for(int i = 0; i < NUM; i++) {
        free_desc[i] = 1;
    }

    // 设置队列大小（参考xv6实现）
    *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    
    // 写入物理地址（参考xv6实现，使用legacy接口）
    // 注意：在identity mapping下，虚拟地址 = 物理地址
    *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)desc;
    *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)desc >> 32;
    *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)avail;
    *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)avail >> 32;
    *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)used;
    *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)used >> 32;
    
    printf("VirtIO: queue addresses - desc=%p, avail=%p, used=%p\n", 
           desc, avail, used);
    
    // 队列就绪（参考xv6实现）
    *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    
    // 验证队列就绪标志（参考xv6实现）
    uint32 queue_ready = *R(VIRTIO_MMIO_QUEUE_READY);
    if(queue_ready != 1) {
        printf("VirtIO: ERROR - queue ready flag not set correctly (got %d)\n", queue_ready);
        printf("VirtIO: This indicates the device did not accept the queue configuration\n");
        virtio_disk_available = 0;
        return;
    }
    
    printf("VirtIO: queue ready flag set (verified=%d)\n", queue_ready);

    status |= VIRTIO_STATUS_DRIVER_OK;
    *R(VIRTIO_MMIO_STATUS) = status;
    __sync_synchronize();
    
    // 验证最终状态
    status = *R(VIRTIO_MMIO_STATUS);
    printf("VirtIO: final device status=0x%x\n", status);
    
    if(!(status & VIRTIO_STATUS_DRIVER_OK)) {
        printf("VirtIO: ERROR - DRIVER_OK not set in final status\n");
        virtio_disk_available = 0;
        return;
    }
    
    printf("VirtIO disk initialized successfully\n");
}

static void
virtio_disk_rw(struct buf *b, int write)
{
    uint64 sector = b->blockno * (BSIZE / 512);
    
    // 分配三个描述符（参考xv6实现）
    int idx[3];
    while(1){
        if(alloc3_desc(idx) == 0) {
            break;
        }
        // 检查是否有完成的请求
        if(used->idx != used_idx) {
            int id = used->ring[used_idx % NUM].id;
            free_chain(id);
            used_idx++;
        }
    }

    // 格式化三个描述符（参考xv6实现）
    struct virtio_blk_req *buf0 = &ops[idx[0]];
    if(write)
        buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    else
        buf0->type = VIRTIO_BLK_T_IN; // read the disk
    buf0->reserved = 0;
    buf0->sector = sector;
    
    desc[idx[0]].addr = (uint64) buf0;
    // 描述符0的长度应该是请求头的大小（不包括status字段）
    // 根据VirtIO规范，请求头是：type(4) + reserved(4) + sector(8) + padding(48) = 64字节
    desc[idx[0]].len = sizeof(struct virtio_blk_req) - 1; // 不包括status字段
    desc[idx[0]].flags = VRING_DESC_F_NEXT;
    desc[idx[0]].next = idx[1];

    desc[idx[1]].addr = (uint64) b->data;
    desc[idx[1]].len = BSIZE;
    if(write)
        desc[idx[1]].flags = 0; // device reads b->data
    else
        desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    desc[idx[1]].next = idx[2];

    ops[idx[0]].status = 0xff; // device writes 0 on success
    desc[idx[2]].addr = (uint64) &ops[idx[0]].status;
    desc[idx[2]].len = 1;
    desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    desc[idx[2]].next = 0;

    printf("virtio_disk_rw: desc chain: %d->%d->%d\n", idx[0], idx[1], idx[2]);
    printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
           idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);

    // 告诉设备第一个描述符索引（参考xv6实现）
    avail->ring[avail->idx % NUM] = idx[0];
    __sync_synchronize();
    
    // 告诉设备另一个可用环条目可用（参考xv6实现）
    avail->idx += 1; // not % NUM ...
    __sync_synchronize();

    printf("virtio_disk_rw: added to avail ring[%d]=%d, avail->idx=%d\n", 
           (avail->idx - 1) % NUM, idx[0], avail->idx);

    *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    printf("virtio_disk_rw: notified device\n");

    // 等待完成（参考xv6实现，使用轮询）
    // 在等待期间，也要处理其他已完成的请求
    int poll_count = 0;
    while(ops[idx[0]].status == 0xff) {
        // 检查是否有其他请求完成
        while(used->idx != used_idx) {
            __sync_synchronize();
            int id = used->ring[used_idx % NUM].id;
            // 只处理不是当前请求的完成
            if(id != idx[0]) {
                free_chain(id);
            }
            used_idx++;
        }
        
        poll_count++;
        if(poll_count % 1000000 == 0) {
            printf("virtio_disk_rw: polling... status=0x%x, poll_count=%d, used_idx=%d, used->idx=%d\n",
                   ops[idx[0]].status, poll_count, used_idx, used->idx);
        }
        if(poll_count > 10000000) {
            printf("virtio_disk_rw: timeout waiting for completion\n");
            printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
                   idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
            printf("virtio_disk_rw: avail->idx=%d, used->idx=%d, used_idx=%d\n",
                   avail->idx, used->idx, used_idx);
            panic("virtio_disk_rw completion timeout");
        }
    }
    
    // 处理当前请求的完成
    while(used->idx != used_idx) {
        __sync_synchronize();
        int id = used->ring[used_idx % NUM].id;
        if(id == idx[0]) {
            used_idx++;
            break;
        }
        free_chain(id);
        used_idx++;
    }

    if(ops[idx[0]].status != 0) {
        printf("virtio_disk_rw: device returned error status=0x%x\n", ops[idx[0]].status);
        printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
               idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
        printf("virtio_disk_rw: sector=%d, write=%d\n", (int)sector, write);
        panic("virtio_disk_rw");
    }

    free_chain(idx[0]);
}

void
virtio_disk_init_wrapper(void)
{
    virtio_disk_init();
}

void
virtio_disk_read(struct buf *b)
{
    if(!virtio_disk_available) {
        panic("virtio_disk_read: VirtIO disk not available");
    }
    virtio_disk_rw(b, 0);
}

void
virtio_disk_write(struct buf *b)
{
    if(!virtio_disk_available) {
        panic("virtio_disk_write: VirtIO disk not available");
    }
    virtio_disk_rw(b, 1);
}
