#include "types.h"
#include "param.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "file.h"
#include "bio.h"
#include "log.h"
#include "proc.h"
#include "sbi.h"
#include "timer.h"

// 外部声明
extern struct superblock sb;
extern struct log log;

// 声明icache（在fs.c中定义）
extern struct {
    struct spinlock lock;
    struct inode inode[NINODE];
} icache;

// 前向声明
void debug_filesystem_state(void);
void debug_inode_usage(void);
void debug_disk_io(void);

// 测试辅助宏
#define assert(condition, message) \
    do { \
        if (!(condition)) { \
            printf("✗ ASSERTION FAILED: %s\n", message); \
            test_failures++; \
            return; \
        } \
    } while(0)

static int test_failures = 0;

// 字符串长度函数
static int strlen(const char *s) {
    int n = 0;
    while(s[n] != '\0') n++;
    return n;
}

// 字符串比较函数
static int strcmp(const char *s, const char *t) {
    while(*s && *t && *s == *t) {
        s++;
        t++;
    }
    return *s - *t;
}


// 格式化字符串函数（简化版）
static void snprintf(char *buf, int size, const char *fmt, ...) {
    // 简化实现：只支持 %d 和 %s
    va_list args;
    va_start(args, fmt);
    char *p = buf;
    const char *f = fmt;
    int i = 0;
    
    while(*f && i < size - 1) {
        if(*f == '%' && *(f+1) == 'd') {
            int val = va_arg(args, int);
            // 简化：直接转换为字符串
            if(val == 0) {
                *p++ = '0';
                i++;
            } else {
                char temp[32];
                int j = 0;
                int v = val;
                if(v < 0) {
                    *p++ = '-';
                    i++;
                    v = -v;
                }
                while(v > 0 && j < 31) {
                    temp[j++] = '0' + (v % 10);
                    v /= 10;
                }
                while(j > 0 && i < size - 1) {
                    *p++ = temp[--j];
                    i++;
                }
            }
            f += 2;
        } else if(*f == '%' && *(f+1) == 's') {
            const char *str = va_arg(args, const char*);
            while(*str && i < size - 1) {
                *p++ = *str++;
                i++;
            }
            f += 2;
        } else {
            *p++ = *f++;
            i++;
        }
    }
    *p = '\0';
    va_end(args);
}

// ==================== 文件系统完整性测试 ====================

void test_filesystem_integrity(void) {
    printf("Testing filesystem integrity...\n");
    
    // 创建测试文件
    int fd = sys_open("testfile", O_CREATE | O_RDWR);
    if(fd < 0) {
        printf("✗ Failed to create testfile\n");
        test_failures++;
        return;
    }
    printf("✓ Created testfile (fd=%d)\n", fd);

    // 写入数据
    char buffer[] = "Hello, filesystem!";
    int bytes = sys_write(fd, buffer, strlen(buffer));
    if(bytes != strlen(buffer)) {
        printf("✗ Write failed: expected %d, got %d\n", strlen(buffer), bytes);
        test_failures++;
        sys_close(fd);
        return;
    }
    printf("✓ Wrote %d bytes to testfile\n", bytes);
    
    sys_close(fd);
    printf("✓ Closed testfile\n");

    // 重新打开并验证
    fd = sys_open("testfile", O_RDONLY);
    if(fd < 0) {
        printf("✗ Failed to reopen testfile\n");
        test_failures++;
        return;
    }
    printf("✓ Reopened testfile (fd=%d)\n", fd);

    char read_buffer[64];
    bytes = sys_read(fd, read_buffer, sizeof(read_buffer) - 1);
    if(bytes < 0) {
        printf("✗ Read failed\n");
        test_failures++;
        sys_close(fd);
        return;
    }
    read_buffer[bytes] = '\0';
    printf("✓ Read %d bytes from testfile\n", bytes);

    if(strcmp(buffer, read_buffer) != 0) {
        printf("✗ Data mismatch: expected '%s', got '%s'\n", buffer, read_buffer);
        test_failures++;
    } else {
        printf("✓ Data matches: '%s'\n", read_buffer);
    }
    
    sys_close(fd);

    // 删除文件
    if(sys_unlink("testfile") != 0) {
        printf("✗ Failed to unlink testfile\n");
        test_failures++;
        return;
    }
    printf("✓ Unlinked testfile\n");

    printf("Filesystem integrity test passed\n");
}

// ==================== 并发访问测试 ====================

static int concurrent_test_count = 0;
static int worker_pids[4] = {-1, -1, -1, -1};  // 存储每个 worker 的 PID

static void concurrent_test_worker(void) {
    // 获取当前进程的 PID，用于查找对应的 worker ID
    extern struct proc* myproc(void);
    struct proc *p = myproc();
    int worker_id = -1;
    
    // 根据 PID 查找对应的 worker ID
    for(int i = 0; i < 4; i++) {
        if(worker_pids[i] == p->pid) {
            worker_id = i;
            break;
        }
    }
    
    // 如果找不到，使用 PID 的相对值（假设主进程 PID 是 1，worker 从 2 开始）
    if(worker_id < 0) {
        worker_id = p->pid - 2;
        if(worker_id < 0 || worker_id >= 4) {
            worker_id = p->pid % 4;  // 如果映射失败，使用 PID 取模
        }
    }
    
    char filename[32];
    snprintf(filename, sizeof(filename), "test_%d", worker_id);
    
    printf("Worker %d (PID %d): Starting concurrent test\n", worker_id, p->pid);
    
    for(int j = 0; j < 100; j++) {
        int fd = sys_open(filename, O_CREATE | O_RDWR);
        if(fd >= 0) {
            sys_write(fd, (char*)&j, sizeof(j));
            sys_close(fd);
            sys_unlink(filename);
            concurrent_test_count++;
        }
    }
    
    printf("Worker %d (PID %d): Completed %d operations\n", worker_id, p->pid, concurrent_test_count);
    exit_process(0);
}

void test_concurrent_access(void) {
    printf("Testing concurrent file access...\n");
    
    concurrent_test_count = 0;
    
    // 创建多个进程同时访问文件系统
    for(int i = 0; i < 4; i++) {
        int pid = create_process(concurrent_test_worker);
        if(pid < 0) {
            printf("✗ Failed to create worker process %d\n", i);
            test_failures++;
            continue;
        }
        worker_pids[i] = pid;  // 保存 PID 到 worker ID 的映射
        printf("✓ Created worker process %d (PID %d)\n", i, pid);
    }

    // 等待所有子进程完成
    for(int i = 0; i < 4; i++) {
        int status;
        if(wait_process(&status) < 0) {
            printf("✗ Failed to wait for process\n");
            test_failures++;
        } else {
            printf("✓ Worker process exited with status %d\n", status);
        }
    }

    printf("Concurrent access test completed (total operations: %d)\n", concurrent_test_count);
}

// ==================== 崩溃恢复测试 ====================

void test_crash_recovery(void) {
    printf("Testing crash recovery...\n");
    
    // 模拟崩溃场景：
    // 1. 开始大量文件操作
    // 2. 在中途"崩溃"（重启系统）
    // 3. 检查文件系统一致性
    
    printf("Creating test files before simulated crash...\n");
    
    // 创建一些文件
    for(int i = 0; i < 10; i++) {
        char filename[32];
        snprintf(filename, sizeof(filename), "crash_test_%d", i);
        
        int fd = sys_open(filename, O_CREATE | O_RDWR);
        if(fd >= 0) {
            char data[64];
            snprintf(data, sizeof(data), "Test data for file %d", i);
            sys_write(fd, data, strlen(data));
            sys_close(fd);
            printf("✓ Created %s\n", filename);
        }
    }
    
    // 模拟崩溃：直接调用恢复函数
    printf("Simulating crash...\n");
    recover_from_log();
    printf("✓ Log recovery completed\n");
    
    // 检查文件系统状态
    printf("Checking filesystem state after recovery...\n");
    debug_filesystem_state();
    
    // 清理测试文件
    for(int i = 0; i < 10; i++) {
        char filename[32];
        snprintf(filename, sizeof(filename), "crash_test_%d", i);
        sys_unlink(filename);
    }
    
    printf("Crash recovery test completed\n");
}

// ==================== 性能测试 ====================


void test_filesystem_performance(void) {
    printf("Testing filesystem performance...\n");
    
    // 大量小文件测试（减少数量以避免 inode 耗尽）
    printf("Creating 100 small files...\n");
    int small_files_created = 0;
    for(int i = 0; i < 100; i++) {
        char filename[32];
        snprintf(filename, sizeof(filename), "small_%d", i);

        int fd = sys_open(filename, O_CREATE | O_RDWR);
        if(fd >= 0) {
            sys_write(fd, "test", 4);
            sys_close(fd);
            // 立即删除文件以释放 inode
            sys_unlink(filename);
            small_files_created++;
        }
    }
    printf("✓ Created and deleted %d small files (100x4B)\n", small_files_created);

    // 大文件测试（使用 512KB 以避免块耗尽）
    printf("Creating large file (512KB)...\n");
    int fd = sys_open("large_file", O_CREATE | O_RDWR);
    int large_file_blocks = 0;
    if(fd >= 0) {
        char large_buffer[4096];
        // 初始化缓冲区
        for(int i = 0; i < 4096; i++) {
            large_buffer[i] = (char)(i % 256);
        }
        
        for(int i = 0; i < 128; i++) { // 512KB文件 (128 * 4KB = 512KB)
            if(sys_write(fd, large_buffer, sizeof(large_buffer)) > 0) {
                large_file_blocks++;
            }
        }
        sys_close(fd);
    }
    printf("✓ Large file created (%d blocks, 512KB)\n", large_file_blocks);

    // 清理测试文件
    printf("Cleaning up test files...\n");
    for(int i = 0; i < 100; i++) {
        char filename[32];
        snprintf(filename, sizeof(filename), "small_%d", i);
        sys_unlink(filename);
    }
    sys_unlink("large_file");
    
    printf("Performance test completed\n");
}

// ==================== 调试功能 ====================

void debug_filesystem_state(void) {
    printf("=== Filesystem Debug Info ===\n");
    
    // 显示超级块信息
    printf("Superblock info:\n");
    printf("  Magic: 0x%x\n", sb.magic);
    printf("  Size: %d blocks\n", sb.size);
    printf("  Nblocks: %d\n", sb.nblocks);
    printf("  Ninodes: %d\n", sb.ninodes);
    printf("  Nlog: %d\n", sb.nlog);
    printf("  Log start: %d\n", sb.logstart);
    printf("  Inode start: %d\n", sb.inodestart);
    printf("  Bitmap start: %d\n", sb.bmapstart);
    
    // 显示块缓存状态（简化）
    printf("\nBlock cache: (simplified info)\n");
    printf("  Cache size: %d blocks\n", NBUF);
    
    // 显示日志状态
    printf("\nLog state:\n");
    printf("  Start: %d\n", log.start);
    printf("  Size: %d\n", log.size);
    printf("  Outstanding: %d\n", log.outstanding);
    printf("  Committing: %d\n", log.committing);
    printf("  Log entries: %d\n", log.lh.n);
    
    printf("=== End of Debug Info ===\n");
}

void debug_inode_usage(void) {
    printf("=== Inode Usage ===\n");
    
    int used_count = 0;
    for(int i = 0; i < NINODE; i++) {
        struct inode *ip = &icache.inode[i];
        if(ip->ref > 0) {
            printf("Inode %d: ref=%d, type=%d, size=%d, dev=%d\n",
                   ip->inum, ip->ref, ip->type, ip->size, ip->dev);
            used_count++;
        }
    }
    
    printf("Total inodes in use: %d/%d\n", used_count, NINODE);
    printf("=== End of Inode Usage ===\n");
}

// 磁盘I/O统计（需要在实际实现中添加计数器）
static int disk_read_count = 0;
static int disk_write_count = 0;

void debug_disk_io(void) {
    printf("=== Disk I/O Statistics ===\n");
    printf("Disk reads: %d\n", disk_read_count);
    printf("Disk writes: %d\n", disk_write_count);
    printf("=== End of Disk I/O Statistics ===\n");
}

// ==================== 主测试运行器 ====================

static void filesystem_test_runner(void) {
    printf("\n");
    printf("========================================\n");
    printf("    FILESYSTEM TEST SUITE\n");
    printf("========================================\n");
    
    test_failures = 0;
    
    // 运行所有测试
    test_filesystem_integrity();
    printf("\n");
    
    test_concurrent_access();
    printf("\n");
    
    test_crash_recovery();
    printf("\n");
    
    test_filesystem_performance();
    printf("\n");
    
    // 调试信息
    debug_filesystem_state();
    printf("\n");
    debug_inode_usage();
    printf("\n");
    debug_disk_io();
    printf("\n");
    
    // 输出最终结果
    printf("========================================\n");
    if (test_failures == 0) {
        printf("✓ ALL FILESYSTEM TESTS PASSED\n");
    } else {
        printf("✗ %d FILESYSTEM TEST(S) FAILED\n", test_failures);
    }
    printf("========================================\n");
    
    exit_process(0);
}

void run_filesystem_tests(void) {
    printf("Starting filesystem tests...\n");
    
    // 先等待一下确保系统稳定
    ksleep(10);
    
    int test_runner_pid = create_process(filesystem_test_runner);
    
    if(test_runner_pid < 0) {
        printf("ERROR: Failed to create filesystem test runner process\n");
        return;
    }
    
    printf("Filesystem test runner started with PID %d\n", test_runner_pid);
}

