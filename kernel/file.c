#include "types.h"
#include "param.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "file.h"
#include "sleeplock.h"
#include "log.h"

// 内存复制
static void *
memmove(void *dst, const void *src, uint n)
{
    const char *s;
    char *d;

    s = src;
    d = dst;
    if (s < d && s + n > d)
    {
        s += n;
        d += n;
        while (n-- > 0)
            *--d = *--s;
    }
    else
        while (n-- > 0)
            *d++ = *s++;
    return dst;
}

struct
{
    struct file file[NFILE];
    struct spinlock lock;
} ftable;

// 文件描述符表：将小的整数fd映射到file结构
// 简化实现：直接使用file数组索引作为fd

void fileinit(void)
{
    initlock(&ftable.lock, "ftable");
}

// 分配一个文件结构
struct file *
filealloc(void)
{
    struct file *f;

    acquire(&ftable.lock);
    for (f = ftable.file; f < ftable.file + NFILE; f++)
    {
        if (f->ref == 0)
        {
            f->ref = 1;
            release(&ftable.lock);
            return f;
        }
    }
    release(&ftable.lock);
    return 0;
}

// 增加文件引用计数
struct file *
filedup(struct file *f)
{
    acquire(&ftable.lock);
    if (f->ref < 1)
        panic("filedup");
    f->ref++;
    release(&ftable.lock);
    return f;
}

// 关闭文件
void fileclose(struct file *f)
{
    struct file ff;

    acquire(&ftable.lock);
    if (f->ref < 1)
        panic("fileclose");
    if (--f->ref > 0)
    {
        release(&ftable.lock);
        return;
    }
    ff = *f;
    f->ref = 0;
    f->type = FD_NONE;
    release(&ftable.lock);

    if (ff.type == FD_INODE)
    {
        iput(ff.ip);
    }
}

// 从文件读取
int fileread(struct file *f, uint64 addr, int n)
{
    int r = 0;

    if (f->readable == 0)
        return -1;

    if (f->type == FD_INODE)
    {
        ilock(f->ip);
        if ((r = readi(f->ip, 1, addr, f->off, n)) > 0)
            f->off += r;
        iunlock(f->ip);
    }
    else
    {
        panic("fileread");
    }

    return r;
}

// 写入文件
int filewrite(struct file *f, uint64 addr, int n)
{
    int r, ret = 0;

    if (f->writable == 0)
        return -1;

    if (f->type == FD_INODE)
    {
        int max = ((MAXOPBLOCKS - 1 - 1 - 2) / 2) * BSIZE;
        int i = 0;
        while (i < n)
        {
            int n1 = n - i;
            if (n1 > max)
                n1 = max;

            begin_op();
            ilock(f->ip);
            if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
                f->off += r;
            iunlock(f->ip);
            end_op();

            if (r < 0)
                break;
            if (r != n1)
                panic("short filewrite");
            i += r;
        }
        ret = (i == n ? n : -1);
    }
    else
    {
        panic("filewrite");
    }

    return ret;
}

// 获取文件统计信息
int filestat(struct file *f, uint64 addr)
{
    struct stat st;

    if (f->type == FD_INODE)
    {
        ilock(f->ip);
        stati(f->ip, &st);
        iunlock(f->ip);
        // 简化：直接复制到地址
        memmove((void *)addr, (void *)&st, sizeof(st));
        return 0;
    }
    return -1;
}

// 系统调用：打开文件（参考xv6实现）
int sys_open(char *path, int omode)
{
    struct inode *ip;
    struct file *f;

    begin_op();
    if (omode & O_CREATE)
    {
        ip = create(path, T_FILE, 0, 0);
        if (ip == 0)
        {
            end_op();
            return -1;
        }
        // create 返回的 inode 已经锁定
    }
    else
    {
        if ((ip = namei(path)) == 0)
        {
            end_op();
            return -1;
        }
        ilock(ip);
        if (ip->type == T_DIR && omode != O_RDONLY)
        {
            iunlockput(ip);
            end_op();
            return -1;
        }
    }

    if ((f = filealloc()) == 0)
    {
        iunlockput(ip);
        end_op();
        return -1;
    }

    // 简化：直接使用文件指针作为fd
    if (ip->type == T_DEV)
    {
        f->type = FD_DEVICE;
        f->major = 0; // 简化
    }
    else
    {
        f->type = FD_INODE;
        f->off = 0;
    }
    f->ip = ip;
    f->readable = !(omode & O_WRONLY);
    f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

    if ((omode & O_TRUNC) && ip->type == T_FILE)
    {
        itrunc(ip);
    }

    iunlock(ip);
    end_op();

    // 返回文件描述符（file数组中的索引）
    int fd = (int)(f - ftable.file);

    if (fd < 0 || fd >= NFILE)
    {
        panic("sys_open: invalid fd");
    }

    return fd;
}

// 根据文件描述符获取file结构
static struct file *
fd2file(int fd)
{
    if (fd < 0 || fd >= NFILE)
        return 0;

    struct file *f = &ftable.file[fd];
    if (f->ref < 1)
        return 0;

    return f;
}

// 系统调用：关闭文件
int sys_close(int fd)
{
    struct file *f = fd2file(fd);

    if (f == 0)
        return -1;
    fileclose(f);
    return 0;
}

// 系统调用：读取文件
int sys_read(int fd, char *p, int n)
{
    struct file *f = fd2file(fd);

    if (f == 0)
        return -1;
    return fileread(f, (uint64)p, n);
}

// 系统调用：写入文件
int sys_write(int fd, char *p, int n)
{
    struct file *f = fd2file(fd);

    if (f == 0)
        return -1;
    return filewrite(f, (uint64)p, n);
}

// 创建文件或目录（参考xv6实现）
struct inode *
create(char *path, short type, short major, short minor)
{
    struct inode *ip, *dp;
    char name[DIRSIZ];

    if ((dp = nameiparent(path, name)) == 0)
    {
        return 0;
    }

    // 确保 name 被正确设置
    if (name[0] == 0)
    {
        iput(dp);
        return 0;
    }

    // nameiparent 返回的 dp 是未锁定的，需要锁定
    ilock(dp);

    if ((ip = dirlookup(dp, name, 0)) != 0)
    {
        iunlockput(dp);
        ilock(ip);
        if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEV))
            return ip;
        iunlockput(ip);
        return 0;
    }

    if ((ip = ialloc(dp->dev, type)) == 0)
    {
        panic("create: ialloc");
    }

    ilock(ip);
    ip->nlink = 1;
    iupdate(ip);

    if (type == T_DIR)
    {
        dp->nlink++;
        iupdate(dp);
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
            panic("create dots");
    }

    if (dirlink(dp, name, ip->inum) < 0)
    {
        panic("create: dirlink");
    }

    iunlockput(dp);

    return ip;
}

// 系统调用：删除文件
int sys_unlink(char *path)
{
    struct inode *ip, *dp;
    char name[DIRSIZ];
    uint off;

    begin_op();
    if ((dp = nameiparent(path, name)) == 0)
    {
        end_op();
        return -1;
    }

    ilock(dp);

    if ((ip = dirlookup(dp, name, &off)) == 0)
    {
        iunlockput(dp);
        end_op();
        return -1;
    }

    ilock(ip);
    if (ip->nlink < 1)
        panic("unlink: nlink < 1");
    if (ip->type == T_DIR)
    {
        iunlockput(ip);
        iunlockput(dp);
        end_op();
        return -1;
    }

    if (dirunlink(dp, name) == -1)
    {
        iunlockput(ip);
        iunlockput(dp);
        end_op();
        return -1;
    }

    iupdate(dp);
    iunlockput(dp);

    ip->nlink--;
    iupdate(ip);
    iunlockput(ip);

    end_op();
    return 0;
}

// 系统调用：创建目录
int sys_mkdir(char *path)
{
    struct inode *ip;

    begin_op();
    if ((ip = create(path, T_DIR, 0, 0)) == 0)
    {
        end_op();
        return -1;
    }
    iunlockput(ip);
    end_op();
    return 0;
}
