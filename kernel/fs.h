#ifndef _FS_H
#define _FS_H

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"

// 文件系统布局设计
#define BLOCK_SIZE 4096  // 块大小：4KB，平衡小文件和大文件效率
#define SUPERBLOCK_NUM 1 // 超级块位置
#define LOG_START 2      // 日志区起始块号
#define LOG_SIZE 30      // 日志区大小（块数）
#define INODES_PER_BLOCK (BLOCK_SIZE / sizeof(struct dinode))
#define IPB INODES_PER_BLOCK

// 文件类型
#define T_DIR 1  // 目录
#define T_FILE 2 // 文件
#define T_DEV 3  // 设备文件

// 文件模式
#define O_RDONLY 0x000
#define O_WRONLY 0x001
#define O_RDWR 0x002
#define O_CREATE 0x200
#define O_TRUNC 0x400

// 统计信息结构（需要在函数声明之前定义）
struct stat
{
    int dev;     // 设备号
    uint ino;    // inode号
    short type;  // 文件类型
    short nlink; // 链接数
    uint64 size; // 文件大小
};

// inode设计
struct my_inode
{
    uint16 mode;                // 文件模式和类型
    uint16 uid;                 // 所有者ID
    uint32 size;                // 文件大小
    uint32 blocks;              // 分配的块数
    uint32 atime, mtime, ctime; // 时间戳
    uint32 direct[12];          // 直接块指针（12个，支持48KB小文件）
    uint32 indirect;            // 一级间接块（支持4MB文件）
    uint32 double_indirect;     // 二级间接块（可选，支持4GB文件）
};

// 磁盘上的inode结构（dinode）
struct dinode
{
    uint16 mode;
    uint16 uid;
    uint32 size;
    uint32 blocks;
    short type;  // 文件类型
    short nlink; // 链接数
    uint32 atime;
    uint32 mtime;
    uint32 ctime;
    uint32 direct[12];
    uint32 indirect;
    uint32 double_indirect;
};

// 超级块结构
struct superblock
{
    uint32 magic;      // 文件系统魔数
    uint32 size;       // 文件系统大小（块数）
    uint32 nblocks;    // 数据块数
    uint32 ninodes;    // inode数
    uint32 nlog;       // 日志块数
    uint32 logstart;   // 日志起始块号
    uint32 inodestart; // inode区起始块号
    uint32 bmapstart;  // 位图起始块号
};

// 目录项格式
#define DIRSIZ 14
struct dirent
{
    ushort inum;       // inode号，0表示空闲
    char name[DIRSIZ]; // 文件名
};

// 内存中的inode结构
struct inode
{
    uint dev;              // 设备号
    uint inum;             // inode号
    int ref;               // 引用计数
    struct sleeplock lock; // 保护inode的锁（使用sleeplock）
    int valid;             // inode是否从磁盘读取
    short type;            // 文件类型
    short nlink;           // 链接数

    // 从磁盘inode复制
    uint16 mode;
    uint16 uid;
    uint32 size;
    uint32 blocks;
    uint32 atime;
    uint32 mtime;
    uint32 ctime;
    uint32 direct[12];
    uint32 indirect;
    uint32 double_indirect;
};

// 文件结构
struct file
{
    enum
    {
        FD_NONE,
        FD_PIPE,
        FD_INODE,
        FD_DEVICE
    } type;
    int ref; // 引用计数
    char readable;
    char writable;
    struct inode *ip; // FD_INODE和FD_DEVICE
    uint off;         // FD_INODE
    short major;      // FD_DEVICE
};

// 文件系统函数声明
void fsinit(int dev);
void iinit(void);
void fileinit(void);
struct inode *ialloc(uint dev, short type);
void iupdate(struct inode *ip);
struct inode *idup(struct inode *ip);
void ilock(struct inode *ip);
void iunlock(struct inode *ip);
void iput(struct inode *ip);
void iunlockput(struct inode *ip);
void stati(struct inode *ip, struct stat *st);
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n);
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n);
void itrunc(struct inode *ip);
uint bmap(struct inode *ip, uint bn);
uint balloc(uint dev);
void bfree(int dev, uint b);

// 目录操作
struct inode *dirlookup(struct inode *dp, char *name, uint *poff);
int dirlink(struct inode *dp, char *name, uint inum);
int dirunlink(struct inode *dp, char *name);

// 路径解析
struct inode *namei(char *path);
struct inode *nameiparent(char *path, char *name);

// 创建文件
struct inode *create(char *path, short type, short major, short minor);

// 超级块
extern struct superblock sb;

// 根inode号
#define ROOTINO 1
#define ROOTDEV 1

#endif // _FS_H
