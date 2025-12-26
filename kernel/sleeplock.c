#include "types.h"
#include "defs.h"
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    initlock(&lk->lk, "sleep lock");
    lk->locked = 0;
    lk->name = name;
    lk->pid = 0;
}

void
acquiresleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    while (lk->locked) {
        // 简化：自旋等待（实际应该使用sleep/wakeup）
        release(&lk->lk);
        acquire(&lk->lk);
    }
    lk->locked = 1;
    lk->pid = myproc() ? myproc()->pid : 0;
    release(&lk->lk);
}

void
releasesleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    lk->locked = 0;
    lk->pid = 0;
    release(&lk->lk);
}

int
holdingsleep(struct sleeplock *lk)
{
    int r;
    acquire(&lk->lk);
    r = lk->locked && (lk->pid == (myproc() ? myproc()->pid : 0));
    release(&lk->lk);
    return r;
}

