#ifndef _SPINLOCK_H
#define _SPINLOCK_H

#include "types.h"

struct cpu;

struct spinlock {
    uint locked;
    const char *name;
    struct cpu *cpu;
};

void initlock(struct spinlock *lk, const char *name);
void acquire(struct spinlock *lk);
void release(struct spinlock *lk);
int holding(struct spinlock *lk);

void push_off(void);
void pop_off(void);
int intr_get(void);
void intr_on(void);
void intr_off(void);

#endif

