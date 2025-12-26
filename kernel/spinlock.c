#include "types.h"
#include "defs.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"

static inline uint64 read_mstatus(void) {
    return r_mstatus();
}

void intr_on(void) {
    uint64 mstatus = read_mstatus();
    mstatus |= MSTATUS_MIE;
    w_mstatus(mstatus);
}

void intr_off(void) {
    uint64 mstatus = read_mstatus();
    mstatus &= ~MSTATUS_MIE;
    w_mstatus(mstatus);
}

int intr_get(void) {
    return (read_mstatus() & MSTATUS_MIE) != 0;
}

void initlock(struct spinlock *lk, const char *name) {
    lk->locked = 0;
    lk->name = name;
    lk->cpu = 0;
}

static inline int xchg(volatile uint *addr, uint newval) {
    uint result;
    asm volatile("amoswap.w %0, %2, %1"
                 : "=r"(result), "+A"(*addr)
                 : "r"(newval)
                 : "memory");
    return result;
}

void push_off(void) {
    int old = intr_get();
    intr_off();
    struct cpu *c = mycpu();
    if (c->noff == 0) {
        c->intena = old;
    }
    c->noff += 1;
}

void pop_off(void) {
    struct cpu *c = mycpu();
    if (intr_get()) {
        panic("pop_off - interruptible");
    }
    if (c->noff < 1) {
        panic("pop_off");
    }
    c->noff -= 1;
    if (c->noff == 0 && c->intena) {
        intr_on();
    }
}

void acquire(struct spinlock *lk) {
    push_off();
    if (holding(lk)) {
        printf("lock already held: %s\n", lk->name ? lk->name : "unknown");
        panic("acquire");
    }
    while (xchg(&lk->locked, 1) != 0)
        ;
    __sync_synchronize();
    lk->cpu = mycpu();
}

void release(struct spinlock *lk) {
    if (!holding(lk)) {
        panic("release");
    }
    __sync_synchronize();
    lk->cpu = 0;
    lk->locked = 0;
    pop_off();
}

int holding(struct spinlock *lk) {
    return lk->locked && lk->cpu == mycpu();
}

