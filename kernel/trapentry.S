# save/restore context and jump to kerneltrap
	.section .text
	.align 4
	.globl kernelvec
	.globl _trapframe

# single-core: use a global trapframe symbol
kernelvec:
	# allocate space in trapframe via direct store
	la t0, _trapframe
	# save registers
	sd ra, 0(t0)
	sd sp, 8(t0)
	sd gp, 16(t0)
	sd tp, 24(t0)
	sd t0, 32(t0)
	sd t1, 40(t0)
	sd t2, 48(t0)
	sd s0, 56(t0)
	sd s1, 64(t0)
	sd a0, 72(t0)
	sd a1, 80(t0)
	sd a2, 88(t0)
	sd a3, 96(t0)
	sd a4, 104(t0)
	sd a5, 112(t0)
	sd a6, 120(t0)
	sd a7, 128(t0)
	sd s2, 136(t0)
	sd s3, 144(t0)
	sd s4, 152(t0)
	sd s5, 160(t0)
	sd s6, 168(t0)
	sd s7, 176(t0)
	sd s8, 184(t0)
	sd s9, 192(t0)
	sd s10, 200(t0)
	sd s11, 208(t0)
	sd t3, 216(t0)
	sd t4, 224(t0)
	sd t5, 232(t0)
	sd t6, 240(t0)
	csrr t1, mepc
	sd t1, 248(t0)
	csrr t1, mstatus
	sd t1, 256(t0)

	# call C handler
	call kerneltrap

	# restore
	la t0, _trapframe
	ld ra, 0(t0)
	ld sp, 8(t0)
	ld gp, 16(t0)
	ld tp, 24(t0)
	ld t0, 32(t0)
	ld t1, 40(t0)
	ld t2, 48(t0)
	ld s0, 56(t0)
	ld s1, 64(t0)
	ld a0, 72(t0)
	ld a1, 80(t0)
	ld a2, 88(t0)
	ld a3, 96(t0)
	ld a4, 104(t0)
	ld a5, 112(t0)
	ld a6, 120(t0)
	ld a7, 128(t0)
	ld s2, 136(t0)
	ld s3, 144(t0)
	ld s4, 152(t0)
	ld s5, 160(t0)
	ld s6, 168(t0)
	ld s7, 176(t0)
	ld s8, 184(t0)
	ld s9, 192(t0)
	ld s10, 200(t0)
	ld s11, 208(t0)
	ld t3, 216(t0)
	ld t4, 224(t0)
	ld t5, 232(t0)
	ld t6, 240(t0)
	ld t1, 248(t0)
	csrw mepc, t1
	ld t1, 256(t0)
	csrw mstatus, t1
	mret

