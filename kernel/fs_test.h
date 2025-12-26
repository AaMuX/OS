#ifndef _FS_TEST_H
#define _FS_TEST_H

// 文件系统测试函数
void run_filesystem_tests(void);
void test_filesystem_integrity(void);
void test_concurrent_access(void);
void test_crash_recovery(void);
void test_filesystem_performance(void);

// 调试函数
void debug_filesystem_state(void);
void debug_inode_usage(void);
void debug_disk_io(void);

#endif // _FS_TEST_H
