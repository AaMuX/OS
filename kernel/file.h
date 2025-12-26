#ifndef _FILE_H
#define _FILE_H

#include "types.h"
#include "fs.h"

// 文件系统API
struct file *filealloc(void);
void fileclose(struct file *f);
struct file *filedup(struct file *f);
int fileread(struct file *f, uint64 addr, int n);
int filewrite(struct file *f, uint64 addr, int n);
int filestat(struct file *f, uint64 addr);
int fileseek(struct file *f, int offset, int whence);

// 系统调用接口
int sys_open(char *path, int omode);
int sys_close(int fd);
int sys_read(int fd, char *p, int n);
int sys_write(int fd, char *p, int n);
int sys_unlink(char *path);
int sys_mkdir(char *path);
int sys_chdir(char *path);

#endif // _FILE_H
