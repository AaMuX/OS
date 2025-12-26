# qemu -kernel loads the kernel at 0x80000000
# and causes the hart (i.e. CPU) to jump there.
# kernel.ld causes the following code to
# be placed at 0x80000000.
.section .text
.global _entry
_entry:
        # set up a stack for C.
        # stack0 is declared in kernel.ld,
        # with a 4096-byte stack.
        la sp, stack0
        li a0, 1024*4
        add sp, sp, a0
        
        # jump to main() in main.c
        call main
        
spin:
        j spin