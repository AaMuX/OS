#include "types.h"
#include "defs.h"

__attribute__((noreturn)) void panic(const char *s) {
    printf("panic: %s\n", s);
    for(;;)
        ;
}