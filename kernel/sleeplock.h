#ifndef _SLEEPLOCK_H
#define _SLEEPLOCK_H

#include "types.h"
#include "spinlock.h"

struct sleeplock {
    uint locked;
    struct spinlock lk;
    char *name;
    int pid;
};

void initsleeplock(struct sleeplock *lk, char *name);
void acquiresleep(struct sleeplock *lk);
void releasesleep(struct sleeplock *lk);
int holdingsleep(struct sleeplock *lk);

#endif // _SLEEPLOCK_H

