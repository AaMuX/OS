// kernel/test.c
#include "riscv.h"
#include "defs.h"
#include "syscall.h"
#include "proc.h"
#include "fs.h"
#include "file.h"
#include "fcntl.h"
#include "stat.h"

#define NULL ((void *)0)

extern struct proc proc[NPROC];
extern uint64 get_time(void);

void assert(int condition)
{
    if (!condition)
    {
        printf("ASSERTION FAILED!\n");
        while (1)
            ;
    }
}

static struct proc *find_current_process_hard()
{
    struct proc *p = myproc();
    if (p && p->state == RUNNING)
        return p;
    for (int i = 0; i < NPROC; i++)
    {
        if (proc[i].state == RUNNING)
            return &proc[i];
    }
    return NULL;
}

static int do_syscall(int num, uint64 a0, uint64 a1, uint64 a2)
{
    struct proc *p = find_current_process_hard();
    if (p == NULL)
    {
        printf("\n[FATAL] No RUNNING process!\n");
        while (1)
            ;
    }

    register long t_a7 asm("a7") = num;
    register long t_a0 asm("a0") = a0;
    register long t_a1 asm("a1") = a1;
    register long t_a2 asm("a2") = a2;

    asm volatile(".4byte 0x00100073"
                 : "+r"(t_a0)
                 : "r"(t_a1), "r"(t_a2), "r"(t_a7)
                 : "memory");

    return t_a0;
}

int stub_getpid(void) { return do_syscall(SYS_getpid, 0, 0, 0); }
int stub_fork(void) { return do_syscall(SYS_fork, 0, 0, 0); }
int stub_wait(int *s) { return do_syscall(SYS_wait, (uint64)s, 0, 0); }
void stub_exit(int s) { do_syscall(SYS_exit, s, 0, 0); }
int stub_write(int fd, char *p, int n) { return do_syscall(SYS_write, fd, (uint64)p, n); }
int stub_read(int fd, void *p, int n) { return do_syscall(SYS_read, fd, (uint64)p, n); }
int stub_open(const char *path, int mode) { return do_syscall(SYS_open, (uint64)path, mode, 0); }
int stub_close(int fd) { return do_syscall(SYS_close, fd, 0, 0); }
int stub_unlink(const char *path) { return do_syscall(SYS_unlink, (uint64)path, 0, 0); }
int stub_mkdir(const char *path) { return do_syscall(SYS_mkdir, (uint64)path, 0, 0); }
int stub_chdir(const char *path) { return do_syscall(SYS_chdir, (uint64)path, 0, 0); }
int stub_dup(int fd) { return do_syscall(SYS_dup, fd, 0, 0); }
int stub_link(const char *old, const char *newp) { return do_syscall(SYS_link, (uint64)old, (uint64)newp, 0); }
int stub_mknod(const char *path, int major, int minor) { return do_syscall(SYS_mknod, (uint64)path, major, minor); }
int stub_fstat(int fd, struct stat *st) { return do_syscall(SYS_fstat, fd, (uint64)st, 0); }


// 1. 基础功能测试
void test_basic_syscalls(void)
{
    printf("\n=== Test: Basic System Calls ===\n");

    int pid = stub_getpid();
    printf("Current PID (via syscall): %d\n", pid);
    assert(pid > 0);

    printf("Testing fork()...\n");
    int child_pid = stub_fork();

    if (child_pid == 0)
    {
        printf("  [Child] Hello from child! PID=%d\n", stub_getpid());
        stub_exit(42);
    }
    else if (child_pid > 0)
    {
        printf("  [Parent] Forked child PID=%d\n", child_pid);
        int status = 0;
        int waited_pid = stub_wait(&status);
        printf("  [Parent] Child %d exited with status %d\n", waited_pid, status);
        assert(waited_pid == child_pid);
        assert(status == 42);
    }
    else
    {
        printf("Fork failed!\n");
    }
    printf("Basic system calls test passed\n");
}

// 2. 参数传递测试
void test_parameter_passing(void)
{
    printf("\n=== Test: Parameter Passing ===\n");
    char *msg = "  [Syscall Write] Hello World via write()!\n";
    int len = 0;
    while (msg[len])
        len++;
    int n = stub_write(1, msg, len);
    printf("  Write returned: %d (expected %d)\n", n, len);
    assert(n == len);
    printf("Parameter passing test passed\n");
}

// 3. 安全性测试
void test_security(void)
{
    printf("\n=== Test: Security Test ===\n");
    char *invalid_ptr = (char *)0x0;
    printf("  Writing to invalid pointer %p...\n", invalid_ptr);

    int result = stub_write(1, invalid_ptr, 10);
    printf("  Result: %d (Expected: -1)\n", result);

    assert(result == -1);
    printf("Security test passed: Invalid pointer correctly rejected\n");
}

// 4. 性能测试
void test_syscall_performance(void)
{
    printf("\n=== Test : Syscall Performance ===\n");

    uint64 start_time = get_time();
    int count = 10000;

    printf("  Running %d getpid() calls...\n", count);
    for (int i = 0; i < count; i++)
    {
        stub_getpid();
    }

    uint64 end_time = get_time();
    uint64 duration = end_time - start_time;

    printf("  %d getpid() calls took %lu cycles\n", count, duration);
    if (count > 0)
        printf("  Average cycles per syscall: %lu\n", duration / count);
    printf("Performance test passed\n");
}

void run_lab6_tests(void)
{
    printf("\n===== Starting Lab6 Tests =====\n");

    // 尝试打开一个文件作为 stdout，如果尚未打开
    int fd = stub_open("console", O_CREATE | O_RDWR);
    if (fd == 0)
    {
        stub_dup(fd); // fd 1
        stub_dup(fd); // fd 2
    }

    test_basic_syscalls();
    test_parameter_passing();
    test_security();
    test_syscall_performance();
    printf("\n===== All Tests Passed! =====\n");
}

// 存根
void test_physical_memory(void) {}
void test_pagetable(void) {}
void test_virtual_memory(void) {}
void test_timer_interrupt(void) {}
void test_exception_handling(void) {}
void test_interrupt_overhead(void) {}
void run_all_tests(void) {}
