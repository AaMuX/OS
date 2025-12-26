
os.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
        # set up a stack for C.
        # stack0 is declared in kernel.ld,
        # with a 4096-byte stack.
        la sp, stack0
    80000000:	00465117          	auipc	sp,0x465
    80000004:	de010113          	addi	sp,sp,-544 # 80464de0 <stack0>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        add sp, sp, a0
    8000000a:	912a                	add	sp,sp,a0
        
        # jump to main() in main.c
        call main
    8000000c:	006000ef          	jal	ra,80000012 <main>

0000000080000010 <spin>:
        
spin:
    80000010:	a001                	j	80000010 <spin>

0000000080000012 <main>:
#include "vm.h"

extern void run_process_tests(void);

void main()
{
    80000012:	1141                	addi	sp,sp,-16
    80000014:	e406                	sd	ra,8(sp)
    80000016:	e022                	sd	s0,0(sp)
    80000018:	0800                	addi	s0,sp,16
    // 初始化系统组件
    console_init();
    8000001a:	00000097          	auipc	ra,0x0
    8000001e:	7fa080e7          	jalr	2042(ra) # 80000814 <console_init>
    printf("=== RISC-V OS: Priority Scheduling ===\n\n");
    80000022:	0000a517          	auipc	a0,0xa
    80000026:	07e50513          	addi	a0,a0,126 # 8000a0a0 <etext+0xa0>
    8000002a:	00000097          	auipc	ra,0x0
    8000002e:	4da080e7          	jalr	1242(ra) # 80000504 <printf>

    pmm_init();
    80000032:	00001097          	auipc	ra,0x1
    80000036:	f64080e7          	jalr	-156(ra) # 80000f96 <pmm_init>

    // 初始化虚拟内存
    kvminit();
    8000003a:	00002097          	auipc	ra,0x2
    8000003e:	dec080e7          	jalr	-532(ra) # 80001e26 <kvminit>
    kvminithart();
    80000042:	00002097          	auipc	ra,0x2
    80000046:	e5a080e7          	jalr	-422(ra) # 80001e9c <kvminithart>

    proc_init();
    8000004a:	00004097          	auipc	ra,0x4
    8000004e:	b00080e7          	jalr	-1280(ra) # 80003b4a <proc_init>
    trap_init();
    80000052:	00003097          	auipc	ra,0x3
    80000056:	d18080e7          	jalr	-744(ra) # 80002d6a <trap_init>
    timer_init();
    8000005a:	00003097          	auipc	ra,0x3
    8000005e:	5a4080e7          	jalr	1444(ra) # 800035fe <timer_init>

    printf("System initialization completed.\n");
    80000062:	0000a517          	auipc	a0,0xa
    80000066:	06e50513          	addi	a0,a0,110 # 8000a0d0 <etext+0xd0>
    8000006a:	00000097          	auipc	ra,0x0
    8000006e:	49a080e7          	jalr	1178(ra) # 80000504 <printf>
    printf("Starting priority scheduling tests...\n\n");
    80000072:	0000a517          	auipc	a0,0xa
    80000076:	08650513          	addi	a0,a0,134 # 8000a0f8 <etext+0xf8>
    8000007a:	00000097          	auipc	ra,0x0
    8000007e:	48a080e7          	jalr	1162(ra) # 80000504 <printf>

    // 运行优先级调度测试
    run_process_tests();
    80000082:	00006097          	auipc	ra,0x6
    80000086:	ed6080e7          	jalr	-298(ra) # 80005f58 <run_process_tests>

    // 等待测试完成
    ksleep(100);
    8000008a:	06400513          	li	a0,100
    8000008e:	00004097          	auipc	ra,0x4
    80000092:	0fc080e7          	jalr	252(ra) # 8000418a <ksleep>

    // 测试完成后进入调度器
    printf("\nAll tests completed. Entering scheduler...\n");
    80000096:	0000a517          	auipc	a0,0xa
    8000009a:	08a50513          	addi	a0,a0,138 # 8000a120 <etext+0x120>
    8000009e:	00000097          	auipc	ra,0x0
    800000a2:	466080e7          	jalr	1126(ra) # 80000504 <printf>
    scheduler();
    800000a6:	00004097          	auipc	ra,0x4
    800000aa:	eae080e7          	jalr	-338(ra) # 80003f54 <scheduler>

00000000800000ae <uart_interrupt_handler>:
    }
}

// 外部中断处理函数（处理所有外部中断，包括UART）
void uart_interrupt_handler(void)
{
    800000ae:	1141                	addi	sp,sp,-16
    800000b0:	e422                	sd	s0,8(sp)
    800000b2:	0800                	addi	s0,sp,16
    // 从PLIC claim中断（获取中断ID）
    volatile uint32 *plic_claim = (volatile uint32 *)PLIC_CLAIM(0);
    uint32 irq_id = *plic_claim;
    800000b4:	0c2007b7          	lui	a5,0xc200
    800000b8:	43dc                	lw	a5,4(a5)
    800000ba:	2781                	sext.w	a5,a5

    // 处理UART中断
    if (irq_id == UART_IRQ)
    800000bc:	4729                	li	a4,10
    800000be:	00e78963          	beq	a5,a4,800000d0 <uart_interrupt_handler+0x22>
        // 其他外部中断（暂未实现）
        // printf("Unknown external interrupt: %d\n", irq_id);
    }

    // 完成中断处理（向PLIC发送完成信号）
    if (irq_id != 0)
    800000c2:	c781                	beqz	a5,800000ca <uart_interrupt_handler+0x1c>
    {
        *plic_claim = irq_id;
    800000c4:	0c200737          	lui	a4,0xc200
    800000c8:	c35c                	sw	a5,4(a4)
    }
}
    800000ca:	6422                	ld	s0,8(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret
    uint8 iir = ReadReg(IIR);
    800000d0:	10000737          	lui	a4,0x10000
    800000d4:	00274703          	lbu	a4,2(a4) # 10000002 <_entry-0x6ffffffe>
    800000d8:	0ff77693          	andi	a3,a4,255
    if ((iir & IIR_NO_INT) == 0)
    800000dc:	8b05                	andi	a4,a4,1
    800000de:	f37d                	bnez	a4,800000c4 <uart_interrupt_handler+0x16>
        if ((iir & 0x0F) == IIR_RX_INT)
    800000e0:	8abd                	andi	a3,a3,15
    800000e2:	4711                	li	a4,4
    800000e4:	fee690e3          	bne	a3,a4,800000c4 <uart_interrupt_handler+0x16>
            while (ReadReg(LSR) & LSR_RX_READY)
    800000e8:	100005b7          	lui	a1,0x10000
                uint32 next_head = (uart_rx_head + 1) % UART_RX_BUF_SIZE;
    800000ec:	0000f517          	auipc	a0,0xf
    800000f0:	76850513          	addi	a0,a0,1896 # 8000f854 <uart_rx_head>
                if (next_head != uart_rx_tail)
    800000f4:	0000f817          	auipc	a6,0xf
    800000f8:	75c80813          	addi	a6,a6,1884 # 8000f850 <uart_rx_tail>
                    uart_rx_buf[uart_rx_head] = c;
    800000fc:	00010897          	auipc	a7,0x10
    80000100:	80488893          	addi	a7,a7,-2044 # 8000f900 <uart_rx_buf>
            while (ReadReg(LSR) & LSR_RX_READY)
    80000104:	0055c703          	lbu	a4,5(a1) # 10000005 <_entry-0x6ffffffb>
    80000108:	8b05                	andi	a4,a4,1
    8000010a:	df4d                	beqz	a4,800000c4 <uart_interrupt_handler+0x16>
                char c = ReadReg(RHR);
    8000010c:	0005c703          	lbu	a4,0(a1)
    80000110:	0ff77613          	andi	a2,a4,255
                uint32 next_head = (uart_rx_head + 1) % UART_RX_BUF_SIZE;
    80000114:	4118                	lw	a4,0(a0)
    80000116:	2705                	addiw	a4,a4,1
    80000118:	0ff77713          	andi	a4,a4,255
                if (next_head != uart_rx_tail)
    8000011c:	00082683          	lw	a3,0(a6)
    80000120:	2681                	sext.w	a3,a3
    80000122:	fed701e3          	beq	a4,a3,80000104 <uart_interrupt_handler+0x56>
                    uart_rx_buf[uart_rx_head] = c;
    80000126:	4114                	lw	a3,0(a0)
    80000128:	1682                	slli	a3,a3,0x20
    8000012a:	9281                	srli	a3,a3,0x20
    8000012c:	96c6                	add	a3,a3,a7
    8000012e:	00c68023          	sb	a2,0(a3)
                    uart_rx_head = next_head;
    80000132:	c118                	sw	a4,0(a0)
    80000134:	bfc1                	j	80000104 <uart_interrupt_handler+0x56>

0000000080000136 <uartinit>:

void uartinit(void)
{
    80000136:	1141                	addi	sp,sp,-16
    80000138:	e406                	sd	ra,8(sp)
    8000013a:	e022                	sd	s0,0(sp)
    8000013c:	0800                	addi	s0,sp,16
    *plic_priority = 1;
    8000013e:	4705                	li	a4,1
    80000140:	0c0007b7          	lui	a5,0xc000
    80000144:	d798                	sw	a4,40(a5)
    *plic_enable |= (1 << (UART_IRQ % 32));
    80000146:	0c0026b7          	lui	a3,0xc002
    8000014a:	429c                	lw	a5,0(a3)
    8000014c:	2781                	sext.w	a5,a5
    8000014e:	4007e793          	ori	a5,a5,1024
    80000152:	c29c                	sw	a5,0(a3)
    // 初始化PLIC
    plic_init();

    // 禁用UART设备中断（先配置好再启用）
    WriteReg(IER, 0x00);
    80000154:	100007b7          	lui	a5,0x10000
    80000158:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

    // 设置波特率
    WriteReg(LCR, 0x80); // 解锁波特率设置
    8000015c:	f8000693          	li	a3,-128
    80000160:	00d781a3          	sb	a3,3(a5)
    WriteReg(0, 0x03);   // 38.4K baud
    80000164:	468d                	li	a3,3
    80000166:	00d78023          	sb	a3,0(a5)
    WriteReg(1, 0x00);
    8000016a:	000780a3          	sb	zero,1(a5)
    WriteReg(LCR, 0x03); // 8位数据，无校验
    8000016e:	00d781a3          	sb	a3,3(a5)

    // 启用FIFO
    WriteReg(FCR, 0x07);
    80000172:	469d                	li	a3,7
    80000174:	00d78123          	sb	a3,2(a5)

    // 启用UART接收中断（IER bit 0 = 接收中断使能）
    WriteReg(IER, 0x01); // 只启用接收中断
    80000178:	00e780a3          	sb	a4,1(a5)

    // 注册外部中断处理函数
    register_interrupt(IRQ_M_EXT, uart_interrupt_handler);
    8000017c:	00000597          	auipc	a1,0x0
    80000180:	f3258593          	addi	a1,a1,-206 # 800000ae <uart_interrupt_handler>
    80000184:	452d                	li	a0,11
    80000186:	00003097          	auipc	ra,0x3
    8000018a:	b16080e7          	jalr	-1258(ra) # 80002c9c <register_interrupt>

    // 启用机器模式外部中断
    enable_interrupt(IRQ_M_EXT);
    8000018e:	452d                	li	a0,11
    80000190:	00003097          	auipc	ra,0x3
    80000194:	b68080e7          	jalr	-1176(ra) # 80002cf8 <enable_interrupt>
}
    80000198:	60a2                	ld	ra,8(sp)
    8000019a:	6402                	ld	s0,0(sp)
    8000019c:	0141                	addi	sp,sp,16
    8000019e:	8082                	ret

00000000800001a0 <uartputc>:

void uartputc(int c)
{
    800001a0:	1141                	addi	sp,sp,-16
    800001a2:	e422                	sd	s0,8(sp)
    800001a4:	0800                	addi	s0,sp,16
    // 等待发送器空闲
    while ((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800001a6:	10000737          	lui	a4,0x10000
    800001aa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800001ae:	0207f793          	andi	a5,a5,32
    800001b2:	dfe5                	beqz	a5,800001aa <uartputc+0xa>
        ;
    WriteReg(THR, c);
    800001b4:	0ff57513          	andi	a0,a0,255
    800001b8:	100007b7          	lui	a5,0x10000
    800001bc:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800001c0:	6422                	ld	s0,8(sp)
    800001c2:	0141                	addi	sp,sp,16
    800001c4:	8082                	ret

00000000800001c6 <uartgetc>:

// 从缓冲区读取字符（非阻塞）
int uartgetc(void)
{
    800001c6:	1141                	addi	sp,sp,-16
    800001c8:	e422                	sd	s0,8(sp)
    800001ca:	0800                	addi	s0,sp,16
    // 先检查硬件是否有数据（轮询方式，作为备用）
    if (ReadReg(LSR) & LSR_RX_READY)
    800001cc:	100007b7          	lui	a5,0x10000
    800001d0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800001d4:	8b85                	andi	a5,a5,1
    800001d6:	e7b1                	bnez	a5,80000222 <uartgetc+0x5c>
    {
        return ReadReg(RHR);
    }

    // 从缓冲区读取
    if (uart_rx_head != uart_rx_tail)
    800001d8:	0000f717          	auipc	a4,0xf
    800001dc:	67c72703          	lw	a4,1660(a4) # 8000f854 <uart_rx_head>
    800001e0:	0000f797          	auipc	a5,0xf
    800001e4:	6707a783          	lw	a5,1648(a5) # 8000f850 <uart_rx_tail>
    800001e8:	04f70463          	beq	a4,a5,80000230 <uartgetc+0x6a>
    {
        char c = uart_rx_buf[uart_rx_tail];
    800001ec:	0000f717          	auipc	a4,0xf
    800001f0:	66476703          	lwu	a4,1636(a4) # 8000f850 <uart_rx_tail>
    800001f4:	0000f797          	auipc	a5,0xf
    800001f8:	70c78793          	addi	a5,a5,1804 # 8000f900 <uart_rx_buf>
    800001fc:	97ba                	add	a5,a5,a4
    800001fe:	0007c503          	lbu	a0,0(a5)
        uart_rx_tail = (uart_rx_tail + 1) % UART_RX_BUF_SIZE;
    80000202:	0000f797          	auipc	a5,0xf
    80000206:	64e7a783          	lw	a5,1614(a5) # 8000f850 <uart_rx_tail>
    8000020a:	2785                	addiw	a5,a5,1
    8000020c:	0ff7f793          	andi	a5,a5,255
    80000210:	0000f717          	auipc	a4,0xf
    80000214:	64f72023          	sw	a5,1600(a4) # 8000f850 <uart_rx_tail>
        return (unsigned char)c;
    80000218:	0ff57513          	andi	a0,a0,255
    }

    return -1; // 无数据
}
    8000021c:	6422                	ld	s0,8(sp)
    8000021e:	0141                	addi	sp,sp,16
    80000220:	8082                	ret
        return ReadReg(RHR);
    80000222:	100007b7          	lui	a5,0x10000
    80000226:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000022a:	0ff57513          	andi	a0,a0,255
    8000022e:	b7fd                	j	8000021c <uartgetc+0x56>
    return -1; // 无数据
    80000230:	557d                	li	a0,-1
    80000232:	b7ed                	j	8000021c <uartgetc+0x56>

0000000080000234 <uart_has_char>:

// 检查是否有字符可读
int uart_has_char(void)
{
    80000234:	1141                	addi	sp,sp,-16
    80000236:	e422                	sd	s0,8(sp)
    80000238:	0800                	addi	s0,sp,16
    return (uart_rx_head != uart_rx_tail) || (ReadReg(LSR) & LSR_RX_READY);
    8000023a:	0000f717          	auipc	a4,0xf
    8000023e:	61a72703          	lw	a4,1562(a4) # 8000f854 <uart_rx_head>
    80000242:	0000f797          	auipc	a5,0xf
    80000246:	60e7a783          	lw	a5,1550(a5) # 8000f850 <uart_rx_tail>
    8000024a:	4505                	li	a0,1
    8000024c:	00f70563          	beq	a4,a5,80000256 <uart_has_char+0x22>
}
    80000250:	6422                	ld	s0,8(sp)
    80000252:	0141                	addi	sp,sp,16
    80000254:	8082                	ret
    return (uart_rx_head != uart_rx_tail) || (ReadReg(LSR) & LSR_RX_READY);
    80000256:	100007b7          	lui	a5,0x10000
    8000025a:	0057c503          	lbu	a0,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000025e:	8905                	andi	a0,a0,1
    80000260:	bfc5                	j	80000250 <uart_has_char+0x1c>

0000000080000262 <uart_rx_available>:

// 获取缓冲区中待读取的字符数
int uart_rx_available(void)
{
    80000262:	1141                	addi	sp,sp,-16
    80000264:	e422                	sd	s0,8(sp)
    80000266:	0800                	addi	s0,sp,16
    if (uart_rx_head >= uart_rx_tail)
    80000268:	0000f717          	auipc	a4,0xf
    8000026c:	5ec72703          	lw	a4,1516(a4) # 8000f854 <uart_rx_head>
    80000270:	0000f797          	auipc	a5,0xf
    80000274:	5e07a783          	lw	a5,1504(a5) # 8000f850 <uart_rx_tail>
    80000278:	00f76e63          	bltu	a4,a5,80000294 <uart_rx_available+0x32>
    {
        return uart_rx_head - uart_rx_tail;
    8000027c:	0000f517          	auipc	a0,0xf
    80000280:	5d852503          	lw	a0,1496(a0) # 8000f854 <uart_rx_head>
    80000284:	0000f797          	auipc	a5,0xf
    80000288:	5cc7a783          	lw	a5,1484(a5) # 8000f850 <uart_rx_tail>
    8000028c:	9d1d                	subw	a0,a0,a5
    }
    else
    {
        return UART_RX_BUF_SIZE - (uart_rx_tail - uart_rx_head);
    }
}
    8000028e:	6422                	ld	s0,8(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
        return UART_RX_BUF_SIZE - (uart_rx_tail - uart_rx_head);
    80000294:	0000f517          	auipc	a0,0xf
    80000298:	5c052503          	lw	a0,1472(a0) # 8000f854 <uart_rx_head>
    8000029c:	0000f797          	auipc	a5,0xf
    800002a0:	5b47a783          	lw	a5,1460(a5) # 8000f850 <uart_rx_tail>
    800002a4:	1005051b          	addiw	a0,a0,256
    800002a8:	9d1d                	subw	a0,a0,a5
    800002aa:	b7d5                	j	8000028e <uart_rx_available+0x2c>

00000000800002ac <uart_puts>:

// 新增：输出字符串函数
void uart_puts(const char *s)
{
    800002ac:	1101                	addi	sp,sp,-32
    800002ae:	ec06                	sd	ra,24(sp)
    800002b0:	e822                	sd	s0,16(sp)
    800002b2:	e426                	sd	s1,8(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
    while (*s)
    800002b8:	00054503          	lbu	a0,0(a0)
    800002bc:	c909                	beqz	a0,800002ce <uart_puts+0x22>
    {
        uartputc(*s++);
    800002be:	0485                	addi	s1,s1,1
    800002c0:	00000097          	auipc	ra,0x0
    800002c4:	ee0080e7          	jalr	-288(ra) # 800001a0 <uartputc>
    while (*s)
    800002c8:	0004c503          	lbu	a0,0(s1)
    800002cc:	f96d                	bnez	a0,800002be <uart_puts+0x12>
    }
}
    800002ce:	60e2                	ld	ra,24(sp)
    800002d0:	6442                	ld	s0,16(sp)
    800002d2:	64a2                	ld	s1,8(sp)
    800002d4:	6105                	addi	sp,sp,32
    800002d6:	8082                	ret

00000000800002d8 <uart_flush>:

// 新增：强制刷新输出缓冲区
void uart_flush(void)
{
    800002d8:	1141                	addi	sp,sp,-16
    800002da:	e422                	sd	s0,8(sp)
    800002dc:	0800                	addi	s0,sp,16
    // 等待所有数据发送完成
    while ((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800002de:	10000737          	lui	a4,0x10000
    800002e2:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800002e6:	0207f793          	andi	a5,a5,32
    800002ea:	dfe5                	beqz	a5,800002e2 <uart_flush+0xa>
        ;
}
    800002ec:	6422                	ld	s0,8(sp)
    800002ee:	0141                	addi	sp,sp,16
    800002f0:	8082                	ret

00000000800002f2 <uart_readline>:

// 读取一行输入（阻塞直到收到换行符或缓冲区满）
// 注意：这个函数会阻塞等待输入，适合在中断驱动的系统中使用
int uart_readline(char *buf, int maxlen)
{
    800002f2:	7159                	addi	sp,sp,-112
    800002f4:	f486                	sd	ra,104(sp)
    800002f6:	f0a2                	sd	s0,96(sp)
    800002f8:	eca6                	sd	s1,88(sp)
    800002fa:	e8ca                	sd	s2,80(sp)
    800002fc:	e4ce                	sd	s3,72(sp)
    800002fe:	e0d2                	sd	s4,64(sp)
    80000300:	fc56                	sd	s5,56(sp)
    80000302:	f85a                	sd	s6,48(sp)
    80000304:	f45e                	sd	s7,40(sp)
    80000306:	f062                	sd	s8,32(sp)
    80000308:	ec66                	sd	s9,24(sp)
    8000030a:	e86a                	sd	s10,16(sp)
    8000030c:	1880                	addi	s0,sp,112
    8000030e:	8baa                	mv	s7,a0
    int i = 0;
    while (i < maxlen - 1)
    80000310:	fff5899b          	addiw	s3,a1,-1
    80000314:	0b305d63          	blez	s3,800003ce <uart_readline+0xdc>
    int i = 0;
    80000318:	4901                	li	s2,0
        {
            // 回显字符
            uartputc(c);
            uart_flush();

            if (c == '\n' || c == '\r')
    8000031a:	4aa9                	li	s5,10
    8000031c:	4b35                	li	s6,13
            {
                buf[i] = '\0';
                return i;
            }
            else if (c == '\b' || c == 127)
    8000031e:	4a21                	li	s4,8
    80000320:	07f00c13          	li	s8,127
                    uartputc(' ');
                    uartputc('\b');
                    uart_flush();
                }
            }
            else if (c >= 32 && c < 127)
    80000324:	05e00c93          	li	s9,94
            { // 可打印字符
                buf[i++] = c;
            }
        }
        // 简单延时，避免CPU占用过高
        for (volatile int j = 0; j < 1000; j++)
    80000328:	3e700493          	li	s1,999
    8000032c:	a815                	j	80000360 <uart_readline+0x6e>
                buf[i] = '\0';
    8000032e:	9bca                	add	s7,s7,s2
    80000330:	000b8023          	sb	zero,0(s7)
                return i;
    80000334:	a04d                	j	800003d6 <uart_readline+0xe4>
                if (i > 0)
    80000336:	07204663          	bgtz	s2,800003a2 <uart_readline+0xb0>
        for (volatile int j = 0; j < 1000; j++)
    8000033a:	f8042e23          	sw	zero,-100(s0)
    8000033e:	f9c42783          	lw	a5,-100(s0)
    80000342:	2781                	sext.w	a5,a5
    80000344:	00f4cc63          	blt	s1,a5,8000035c <uart_readline+0x6a>
    80000348:	f9c42783          	lw	a5,-100(s0)
    8000034c:	2785                	addiw	a5,a5,1
    8000034e:	f8f42e23          	sw	a5,-100(s0)
    80000352:	f9c42783          	lw	a5,-100(s0)
    80000356:	2781                	sext.w	a5,a5
    80000358:	fef4d8e3          	bge	s1,a5,80000348 <uart_readline+0x56>
    while (i < maxlen - 1)
    8000035c:	07395a63          	bge	s2,s3,800003d0 <uart_readline+0xde>
        int c = uartgetc();
    80000360:	00000097          	auipc	ra,0x0
    80000364:	e66080e7          	jalr	-410(ra) # 800001c6 <uartgetc>
    80000368:	8d2a                	mv	s10,a0
        if (c >= 0 && c != '\0')
    8000036a:	fca058e3          	blez	a0,8000033a <uart_readline+0x48>
            uartputc(c);
    8000036e:	00000097          	auipc	ra,0x0
    80000372:	e32080e7          	jalr	-462(ra) # 800001a0 <uartputc>
            uart_flush();
    80000376:	00000097          	auipc	ra,0x0
    8000037a:	f62080e7          	jalr	-158(ra) # 800002d8 <uart_flush>
            if (c == '\n' || c == '\r')
    8000037e:	fb5d08e3          	beq	s10,s5,8000032e <uart_readline+0x3c>
    80000382:	fb6d06e3          	beq	s10,s6,8000032e <uart_readline+0x3c>
            else if (c == '\b' || c == 127)
    80000386:	fb4d08e3          	beq	s10,s4,80000336 <uart_readline+0x44>
    8000038a:	fb8d06e3          	beq	s10,s8,80000336 <uart_readline+0x44>
            else if (c >= 32 && c < 127)
    8000038e:	fe0d079b          	addiw	a5,s10,-32
    80000392:	fafce4e3          	bltu	s9,a5,8000033a <uart_readline+0x48>
                buf[i++] = c;
    80000396:	012b87b3          	add	a5,s7,s2
    8000039a:	01a78023          	sb	s10,0(a5)
    8000039e:	2905                	addiw	s2,s2,1
    800003a0:	bf69                	j	8000033a <uart_readline+0x48>
                    i--;
    800003a2:	397d                	addiw	s2,s2,-1
                    uartputc('\b');
    800003a4:	8552                	mv	a0,s4
    800003a6:	00000097          	auipc	ra,0x0
    800003aa:	dfa080e7          	jalr	-518(ra) # 800001a0 <uartputc>
                    uartputc(' ');
    800003ae:	02000513          	li	a0,32
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	dee080e7          	jalr	-530(ra) # 800001a0 <uartputc>
                    uartputc('\b');
    800003ba:	8552                	mv	a0,s4
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	de4080e7          	jalr	-540(ra) # 800001a0 <uartputc>
                    uart_flush();
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	f14080e7          	jalr	-236(ra) # 800002d8 <uart_flush>
    800003cc:	b7bd                	j	8000033a <uart_readline+0x48>
    int i = 0;
    800003ce:	4901                	li	s2,0
            ;
    }
    buf[i] = '\0';
    800003d0:	9bca                	add	s7,s7,s2
    800003d2:	000b8023          	sb	zero,0(s7)
    return i;
    800003d6:	854a                	mv	a0,s2
    800003d8:	70a6                	ld	ra,104(sp)
    800003da:	7406                	ld	s0,96(sp)
    800003dc:	64e6                	ld	s1,88(sp)
    800003de:	6946                	ld	s2,80(sp)
    800003e0:	69a6                	ld	s3,72(sp)
    800003e2:	6a06                	ld	s4,64(sp)
    800003e4:	7ae2                	ld	s5,56(sp)
    800003e6:	7b42                	ld	s6,48(sp)
    800003e8:	7ba2                	ld	s7,40(sp)
    800003ea:	7c02                	ld	s8,32(sp)
    800003ec:	6ce2                	ld	s9,24(sp)
    800003ee:	6d42                	ld	s10,16(sp)
    800003f0:	6165                	addi	sp,sp,112
    800003f2:	8082                	ret

00000000800003f4 <print_int>:
    console_puts(s);
}

// 数字转换核心算法
static void print_int(long long num, int base, int sign, int width, int zero_pad)
{
    800003f4:	711d                	addi	sp,sp,-96
    800003f6:	ec86                	sd	ra,88(sp)
    800003f8:	e8a2                	sd	s0,80(sp)
    800003fa:	e4a6                	sd	s1,72(sp)
    800003fc:	e0ca                	sd	s2,64(sp)
    800003fe:	fc4e                	sd	s3,56(sp)
    80000400:	f852                	sd	s4,48(sp)
    80000402:	f456                	sd	s5,40(sp)
    80000404:	1080                	addi	s0,sp,96
    unsigned long long unum;
    int is_negative = 0;
    int num_digits = 0; // 纯数字部分的位数

    // 1. 处理符号和数值转换
    if (sign && num < 0)
    80000406:	c219                	beqz	a2,8000040c <print_int+0x18>
    80000408:	02054763          	bltz	a0,80000436 <print_int+0x42>
    {
        unum = num;
    }

    // 2. 数字转换（反向存储）
    if (unum == 0)
    8000040c:	e90d                	bnez	a0,8000043e <print_int+0x4a>
    {
        buf[i++] = '0';
    8000040e:	03000793          	li	a5,48
    80000412:	faf40023          	sb	a5,-96(s0)
    int is_negative = 0;
    80000416:	4981                	li	s3,0
        num_digits = 1;
    80000418:	4a05                	li	s4,1
        buf[i++] = '0';
    8000041a:	4905                	li	s2,1
    {
        total_width += 1; // 负号占一位
    }

    // 4. 宽度填充逻辑
    if (width > total_width)
    8000041c:	0ada5363          	bge	s4,a3,800004c2 <print_int+0xce>
    {
        int padding = width - total_width;
    80000420:	41468a3b          	subw	s4,a3,s4
        char pad_char = ' ';

        // 零填充的特殊处理
        if (zero_pad)
    80000424:	cf35                	beqz	a4,800004a0 <print_int+0xac>
                is_negative = 0; // 标记符号已输出
            }
        }

        // 输出填充字符
        while (padding-- > 0)
    80000426:	fffa049b          	addiw	s1,s4,-1
    8000042a:	03000a93          	li	s5,48
    8000042e:	4981                	li	s3,0
    80000430:	07404e63          	bgtz	s4,800004ac <print_int+0xb8>
    80000434:	a079                	j	800004c2 <print_int+0xce>
        unum = -num;
    80000436:	40a00533          	neg	a0,a0
        is_negative = 1;
    8000043a:	4985                	li	s3,1
    8000043c:	a011                	j	80000440 <print_int+0x4c>
    int is_negative = 0;
    8000043e:	4981                	li	s3,0
        while (unum > 0)
    80000440:	fa040613          	addi	a2,s0,-96
    int i = 0;
    80000444:	4901                	li	s2,0
            buf[i++] = digits[unum % base];
    80000446:	0000a817          	auipc	a6,0xa
    8000044a:	d6a80813          	addi	a6,a6,-662 # 8000a1b0 <digits>
    8000044e:	8a4a                	mv	s4,s2
    80000450:	2905                	addiw	s2,s2,1
    80000452:	02b577b3          	remu	a5,a0,a1
    80000456:	97c2                	add	a5,a5,a6
    80000458:	0007c783          	lbu	a5,0(a5)
    8000045c:	00f60023          	sb	a5,0(a2)
            unum /= base;
    80000460:	87aa                	mv	a5,a0
    80000462:	02b55533          	divu	a0,a0,a1
        while (unum > 0)
    80000466:	0605                	addi	a2,a2,1
    80000468:	feb7f3e3          	bgeu	a5,a1,8000044e <print_int+0x5a>
    if (is_negative)
    8000046c:	02098563          	beqz	s3,80000496 <print_int+0xa2>
        total_width += 1; // 负号占一位
    80000470:	2a09                	addiw	s4,s4,2
    80000472:	000a079b          	sext.w	a5,s4
    if (width > total_width)
    80000476:	02d7c263          	blt	a5,a3,8000049a <print_int+0xa6>
    console_putc(c);
    8000047a:	02d00513          	li	a0,45
    8000047e:	00000097          	auipc	ra,0x0
    80000482:	3ae080e7          	jalr	942(ra) # 8000082c <console_putc>
}
    80000486:	a835                	j	800004c2 <print_int+0xce>
    console_putc(c);
    80000488:	02d00513          	li	a0,45
    8000048c:	00000097          	auipc	ra,0x0
    80000490:	3a0080e7          	jalr	928(ra) # 8000082c <console_putc>
}
    80000494:	bf49                	j	80000426 <print_int+0x32>
            num_digits++;
    80000496:	8a4a                	mv	s4,s2
    80000498:	b751                	j	8000041c <print_int+0x28>
        int padding = width - total_width;
    8000049a:	41468a3b          	subw	s4,a3,s4
        if (zero_pad)
    8000049e:	f76d                	bnez	a4,80000488 <print_int+0x94>
        while (padding-- > 0)
    800004a0:	fffa049b          	addiw	s1,s4,-1
    800004a4:	01405d63          	blez	s4,800004be <print_int+0xca>
        char pad_char = ' ';
    800004a8:	02000a93          	li	s5,32
    console_putc(c);
    800004ac:	8556                	mv	a0,s5
    800004ae:	00000097          	auipc	ra,0x0
    800004b2:	37e080e7          	jalr	894(ra) # 8000082c <console_putc>
        while (padding-- > 0)
    800004b6:	87a6                	mv	a5,s1
    800004b8:	34fd                	addiw	s1,s1,-1
    800004ba:	fef049e3          	bgtz	a5,800004ac <print_int+0xb8>
            putc(pad_char);
        }
    }

    // 5. 输出符号（如果不是零填充情况）
    if (is_negative)
    800004be:	fa099ee3          	bnez	s3,8000047a <print_int+0x86>
    {
        putc('-');
    }

    // 6. 输出数字（正向）
    while (--i >= 0)
    800004c2:	03205863          	blez	s2,800004f2 <print_int+0xfe>
    800004c6:	fa040793          	addi	a5,s0,-96
    800004ca:	012784b3          	add	s1,a5,s2
    800004ce:	f9f40793          	addi	a5,s0,-97
    800004d2:	97ca                	add	a5,a5,s2
    800004d4:	397d                	addiw	s2,s2,-1
    800004d6:	1902                	slli	s2,s2,0x20
    800004d8:	02095913          	srli	s2,s2,0x20
    800004dc:	41278933          	sub	s2,a5,s2
    console_putc(c);
    800004e0:	fff4c503          	lbu	a0,-1(s1)
    800004e4:	00000097          	auipc	ra,0x0
    800004e8:	348080e7          	jalr	840(ra) # 8000082c <console_putc>
    while (--i >= 0)
    800004ec:	14fd                	addi	s1,s1,-1
    800004ee:	fe9919e3          	bne	s2,s1,800004e0 <print_int+0xec>
    {
        putc(buf[i]);
    }
}
    800004f2:	60e6                	ld	ra,88(sp)
    800004f4:	6446                	ld	s0,80(sp)
    800004f6:	64a6                	ld	s1,72(sp)
    800004f8:	6906                	ld	s2,64(sp)
    800004fa:	79e2                	ld	s3,56(sp)
    800004fc:	7a42                	ld	s4,48(sp)
    800004fe:	7aa2                	ld	s5,40(sp)
    80000500:	6125                	addi	sp,sp,96
    80000502:	8082                	ret

0000000080000504 <printf>:
    }
}

// 格式化字符串解析核心
int printf(const char *fmt, ...)
{
    80000504:	7131                	addi	sp,sp,-192
    80000506:	fc86                	sd	ra,120(sp)
    80000508:	f8a2                	sd	s0,112(sp)
    8000050a:	f4a6                	sd	s1,104(sp)
    8000050c:	f0ca                	sd	s2,96(sp)
    8000050e:	ecce                	sd	s3,88(sp)
    80000510:	e8d2                	sd	s4,80(sp)
    80000512:	e4d6                	sd	s5,72(sp)
    80000514:	e0da                	sd	s6,64(sp)
    80000516:	fc5e                	sd	s7,56(sp)
    80000518:	f862                	sd	s8,48(sp)
    8000051a:	f466                	sd	s9,40(sp)
    8000051c:	f06a                	sd	s10,32(sp)
    8000051e:	ec6e                	sd	s11,24(sp)
    80000520:	0100                	addi	s0,sp,128
    80000522:	84aa                	mv	s1,a0
    80000524:	e40c                	sd	a1,8(s0)
    80000526:	e810                	sd	a2,16(s0)
    80000528:	ec14                	sd	a3,24(s0)
    8000052a:	f018                	sd	a4,32(s0)
    8000052c:	f41c                	sd	a5,40(s0)
    8000052e:	03043823          	sd	a6,48(s0)
    80000532:	03143c23          	sd	a7,56(s0)
    va_list ap;
    va_start(ap, fmt);
    80000536:	00840793          	addi	a5,s0,8
    8000053a:	f8f43423          	sd	a5,-120(s0)

    for (int i = 0; fmt[i] != '\0'; i++)
    8000053e:	00054503          	lbu	a0,0(a0)
    80000542:	24050f63          	beqz	a0,800007a0 <printf+0x29c>
    80000546:	4c01                	li	s8,0
    {
        if (fmt[i] != '%')
    80000548:	02500913          	li	s2,37
        int width = 0;
        int zero_pad = 0;
        int length_l = 0; // 是否存在 'l' 长度修饰符

        // 解析标志和宽度
        if (fmt[i] == '0')
    8000054c:	03000a93          	li	s5,48
    80000550:	0000aa17          	auipc	s4,0xa
    80000554:	c08a0a13          	addi	s4,s4,-1016 # 8000a158 <etext+0x158>

        case 's':
        { // 字符串
            char *s = va_arg(ap, char *);
            if (s == NULL)
                s = "(null)";
    80000558:	0000ab97          	auipc	s7,0xa
    8000055c:	bf8b8b93          	addi	s7,s7,-1032 # 8000a150 <etext+0x150>
            putc(digits[digit]);
    80000560:	0000ab17          	auipc	s6,0xa
    80000564:	c50b0b13          	addi	s6,s6,-944 # 8000a1b0 <digits>
            started = 1;
    80000568:	4985                	li	s3,1
    8000056a:	a2dd                	j	80000750 <printf+0x24c>
        i++;
    8000056c:	001c059b          	addiw	a1,s8,1
        if (fmt[i] == '0')
    80000570:	00b487b3          	add	a5,s1,a1
    80000574:	0007c783          	lbu	a5,0(a5)
        int zero_pad = 0;
    80000578:	4701                	li	a4,0
        if (fmt[i] == '0')
    8000057a:	09578463          	beq	a5,s5,80000602 <printf+0xfe>
        while (fmt[i] >= '0' && fmt[i] <= '9')
    8000057e:	00b487b3          	add	a5,s1,a1
    80000582:	0007c603          	lbu	a2,0(a5)
    80000586:	fd06079b          	addiw	a5,a2,-48
    8000058a:	0ff7f793          	andi	a5,a5,255
    8000058e:	46a5                	li	a3,9
    80000590:	06f6ed63          	bltu	a3,a5,8000060a <printf+0x106>
    80000594:	2585                	addiw	a1,a1,1
    80000596:	4681                	li	a3,0
    80000598:	4825                	li	a6,9
            width = width * 10 + (fmt[i] - '0');
    8000059a:	0026979b          	slliw	a5,a3,0x2
    8000059e:	9ebd                	addw	a3,a3,a5
    800005a0:	0016969b          	slliw	a3,a3,0x1
    800005a4:	fd06061b          	addiw	a2,a2,-48
    800005a8:	9eb1                	addw	a3,a3,a2
            i++;
    800005aa:	00058c1b          	sext.w	s8,a1
        while (fmt[i] >= '0' && fmt[i] <= '9')
    800005ae:	00b487b3          	add	a5,s1,a1
    800005b2:	0007c603          	lbu	a2,0(a5)
    800005b6:	0585                	addi	a1,a1,1
    800005b8:	fd06051b          	addiw	a0,a2,-48
    800005bc:	0ff57513          	andi	a0,a0,255
    800005c0:	fca87de3          	bgeu	a6,a0,8000059a <printf+0x96>
        if (fmt[i] == 'l')
    800005c4:	06c00793          	li	a5,108
        int length_l = 0; // 是否存在 'l' 长度修饰符
    800005c8:	4501                	li	a0,0
        if (fmt[i] == 'l')
    800005ca:	04f60363          	beq	a2,a5,80000610 <printf+0x10c>
        switch (fmt[i])
    800005ce:	01848cb3          	add	s9,s1,s8
    800005d2:	000cc783          	lbu	a5,0(s9)
    800005d6:	1b278363          	beq	a5,s2,8000077c <printf+0x278>
    800005da:	f9d7861b          	addiw	a2,a5,-99
    800005de:	0ff67613          	andi	a2,a2,255
    800005e2:	45d5                	li	a1,21
    800005e4:	1ac5e263          	bltu	a1,a2,80000788 <printf+0x284>
    800005e8:	f9d7879b          	addiw	a5,a5,-99
    800005ec:	0ff7f593          	andi	a1,a5,255
    800005f0:	4655                	li	a2,21
    800005f2:	18b66b63          	bltu	a2,a1,80000788 <printf+0x284>
    800005f6:	00259793          	slli	a5,a1,0x2
    800005fa:	97d2                	add	a5,a5,s4
    800005fc:	439c                	lw	a5,0(a5)
    800005fe:	97d2                	add	a5,a5,s4
    80000600:	8782                	jr	a5
            i++;
    80000602:	002c059b          	addiw	a1,s8,2
            zero_pad = 1;
    80000606:	874e                	mv	a4,s3
    80000608:	bf9d                	j	8000057e <printf+0x7a>
        while (fmt[i] >= '0' && fmt[i] <= '9')
    8000060a:	8c2e                	mv	s8,a1
    8000060c:	4681                	li	a3,0
    8000060e:	bf5d                	j	800005c4 <printf+0xc0>
            i++;
    80000610:	2c05                	addiw	s8,s8,1
            length_l = 1;
    80000612:	854e                	mv	a0,s3
    80000614:	bf6d                	j	800005ce <printf+0xca>
            if (length_l)
    80000616:	cd19                	beqz	a0,80000634 <printf+0x130>
                print_int(va_arg(ap, long), 10, 1, width, zero_pad);
    80000618:	f8843783          	ld	a5,-120(s0)
    8000061c:	00878613          	addi	a2,a5,8
    80000620:	f8c43423          	sd	a2,-120(s0)
    80000624:	864e                	mv	a2,s3
    80000626:	45a9                	li	a1,10
    80000628:	6388                	ld	a0,0(a5)
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	dca080e7          	jalr	-566(ra) # 800003f4 <print_int>
    80000632:	aa09                	j	80000744 <printf+0x240>
                print_int(va_arg(ap, int), 10, 1, width, zero_pad);
    80000634:	f8843783          	ld	a5,-120(s0)
    80000638:	00878613          	addi	a2,a5,8
    8000063c:	f8c43423          	sd	a2,-120(s0)
    80000640:	864e                	mv	a2,s3
    80000642:	45a9                	li	a1,10
    80000644:	4388                	lw	a0,0(a5)
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	dae080e7          	jalr	-594(ra) # 800003f4 <print_int>
    8000064e:	a8dd                	j	80000744 <printf+0x240>
            if (length_l)
    80000650:	cd19                	beqz	a0,8000066e <printf+0x16a>
                unsigned long v = va_arg(ap, unsigned long);
    80000652:	f8843783          	ld	a5,-120(s0)
    80000656:	00878613          	addi	a2,a5,8
    8000065a:	f8c43423          	sd	a2,-120(s0)
                print_int((long long)v, 10, 0, width, zero_pad);
    8000065e:	4601                	li	a2,0
    80000660:	45a9                	li	a1,10
    80000662:	6388                	ld	a0,0(a5)
    80000664:	00000097          	auipc	ra,0x0
    80000668:	d90080e7          	jalr	-624(ra) # 800003f4 <print_int>
    8000066c:	a8e1                	j	80000744 <printf+0x240>
                print_int(va_arg(ap, unsigned int), 10, 0, width, zero_pad);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878613          	addi	a2,a5,8
    80000676:	f8c43423          	sd	a2,-120(s0)
    8000067a:	4601                	li	a2,0
    8000067c:	45a9                	li	a1,10
    8000067e:	0007e503          	lwu	a0,0(a5)
    80000682:	00000097          	auipc	ra,0x0
    80000686:	d72080e7          	jalr	-654(ra) # 800003f4 <print_int>
    8000068a:	a86d                	j	80000744 <printf+0x240>
            if (length_l)
    8000068c:	cd19                	beqz	a0,800006aa <printf+0x1a6>
                unsigned long v = va_arg(ap, unsigned long);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878613          	addi	a2,a5,8
    80000696:	f8c43423          	sd	a2,-120(s0)
                print_int((long long)v, 16, 0, width, zero_pad);
    8000069a:	4601                	li	a2,0
    8000069c:	45c1                	li	a1,16
    8000069e:	6388                	ld	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	d54080e7          	jalr	-684(ra) # 800003f4 <print_int>
    800006a8:	a871                	j	80000744 <printf+0x240>
                print_int(va_arg(ap, unsigned int), 16, 0, width, zero_pad);
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878613          	addi	a2,a5,8
    800006b2:	f8c43423          	sd	a2,-120(s0)
    800006b6:	4601                	li	a2,0
    800006b8:	45c1                	li	a1,16
    800006ba:	0007e503          	lwu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	d36080e7          	jalr	-714(ra) # 800003f4 <print_int>
    800006c6:	a8bd                	j	80000744 <printf+0x240>
            print_ptr(va_arg(ap, uint64));
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	0007bd03          	ld	s10,0(a5)
    console_putc(c);
    800006d8:	8556                	mv	a0,s5
    800006da:	00000097          	auipc	ra,0x0
    800006de:	152080e7          	jalr	338(ra) # 8000082c <console_putc>
    800006e2:	07800513          	li	a0,120
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	146080e7          	jalr	326(ra) # 8000082c <console_putc>
    int started = 0;
    800006ee:	4701                	li	a4,0
    for (int i = 60; i >= 0; i -= 4)
    800006f0:	03c00c93          	li	s9,60
    800006f4:	5df1                	li	s11,-4
    if (ptr == 0)
    800006f6:	020d1363          	bnez	s10,8000071c <printf+0x218>
    console_putc(c);
    800006fa:	8556                	mv	a0,s5
    800006fc:	00000097          	auipc	ra,0x0
    80000700:	130080e7          	jalr	304(ra) # 8000082c <console_putc>
}
    80000704:	a081                	j	80000744 <printf+0x240>
            putc(digits[digit]);
    80000706:	97da                	add	a5,a5,s6
    console_putc(c);
    80000708:	0007c503          	lbu	a0,0(a5)
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	120080e7          	jalr	288(ra) # 8000082c <console_putc>
            started = 1;
    80000714:	874e                	mv	a4,s3
    for (int i = 60; i >= 0; i -= 4)
    80000716:	3cf1                	addiw	s9,s9,-4
    80000718:	03bc8663          	beq	s9,s11,80000744 <printf+0x240>
        int digit = (ptr >> i) & 0xF;
    8000071c:	019d57b3          	srl	a5,s10,s9
    80000720:	8bbd                	andi	a5,a5,15
        if (digit != 0 || started || i == 0)
    80000722:	8f5d                	or	a4,a4,a5
    80000724:	f36d                	bnez	a4,80000706 <printf+0x202>
    80000726:	fe0c98e3          	bnez	s9,80000716 <printf+0x212>
    8000072a:	bff1                	j	80000706 <printf+0x202>
            putc(va_arg(ap, int));
    8000072c:	f8843783          	ld	a5,-120(s0)
    80000730:	00878713          	addi	a4,a5,8
    80000734:	f8e43423          	sd	a4,-120(s0)
    console_putc(c);
    80000738:	0007c503          	lbu	a0,0(a5)
    8000073c:	00000097          	auipc	ra,0x0
    80000740:	0f0080e7          	jalr	240(ra) # 8000082c <console_putc>
    for (int i = 0; fmt[i] != '\0'; i++)
    80000744:	2c05                	addiw	s8,s8,1
    80000746:	018487b3          	add	a5,s1,s8
    8000074a:	0007c503          	lbu	a0,0(a5)
    8000074e:	c929                	beqz	a0,800007a0 <printf+0x29c>
        if (fmt[i] != '%')
    80000750:	e1250ee3          	beq	a0,s2,8000056c <printf+0x68>
    console_putc(c);
    80000754:	00000097          	auipc	ra,0x0
    80000758:	0d8080e7          	jalr	216(ra) # 8000082c <console_putc>
            continue;
    8000075c:	b7e5                	j	80000744 <printf+0x240>
            char *s = va_arg(ap, char *);
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	6388                	ld	a0,0(a5)
            if (s == NULL)
    8000076c:	c511                	beqz	a0,80000778 <printf+0x274>
    console_puts(s);
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	15a080e7          	jalr	346(ra) # 800008c8 <console_puts>
}
    80000776:	b7f9                	j	80000744 <printf+0x240>
                s = "(null)";
    80000778:	855e                	mv	a0,s7
    8000077a:	bfd5                	j	8000076e <printf+0x26a>
    console_putc(c);
    8000077c:	854a                	mv	a0,s2
    8000077e:	00000097          	auipc	ra,0x0
    80000782:	0ae080e7          	jalr	174(ra) # 8000082c <console_putc>
}
    80000786:	bf7d                	j	80000744 <printf+0x240>
    console_putc(c);
    80000788:	854a                	mv	a0,s2
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	0a2080e7          	jalr	162(ra) # 8000082c <console_putc>
    80000792:	000cc503          	lbu	a0,0(s9)
    80000796:	00000097          	auipc	ra,0x0
    8000079a:	096080e7          	jalr	150(ra) # 8000082c <console_putc>
}
    8000079e:	b75d                	j	80000744 <printf+0x240>
        }
    }

    va_end(ap);
    return 0;
}
    800007a0:	4501                	li	a0,0
    800007a2:	70e6                	ld	ra,120(sp)
    800007a4:	7446                	ld	s0,112(sp)
    800007a6:	74a6                	ld	s1,104(sp)
    800007a8:	7906                	ld	s2,96(sp)
    800007aa:	69e6                	ld	s3,88(sp)
    800007ac:	6a46                	ld	s4,80(sp)
    800007ae:	6aa6                	ld	s5,72(sp)
    800007b0:	6b06                	ld	s6,64(sp)
    800007b2:	7be2                	ld	s7,56(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    800007bc:	6129                	addi	sp,sp,192
    800007be:	8082                	ret

00000000800007c0 <sprintf>:

// 简化版sprintf（基础实现）
int sprintf(char *buf, const char *fmt, ...)
{
    800007c0:	711d                	addi	sp,sp,-96
    800007c2:	f406                	sd	ra,40(sp)
    800007c4:	f022                	sd	s0,32(sp)
    800007c6:	ec26                	sd	s1,24(sp)
    800007c8:	1800                	addi	s0,sp,48
    800007ca:	84ae                	mv	s1,a1
    800007cc:	e010                	sd	a2,0(s0)
    800007ce:	e414                	sd	a3,8(s0)
    800007d0:	e818                	sd	a4,16(s0)
    800007d2:	ec1c                	sd	a5,24(s0)
    800007d4:	03043023          	sd	a6,32(s0)
    800007d8:	03143423          	sd	a7,40(s0)
    // 简化实现：暂时直接调用printf
    // 完整实现需要重定向输出到缓冲区
    va_list ap;
    va_start(ap, fmt);
    800007dc:	fc843c23          	sd	s0,-40(s0)
    printf(fmt, ap); // 注意：这需要修改printf支持缓冲区
    800007e0:	85a2                	mv	a1,s0
    800007e2:	8526                	mv	a0,s1
    800007e4:	00000097          	auipc	ra,0x0
    800007e8:	d20080e7          	jalr	-736(ra) # 80000504 <printf>
    va_end(ap);

    // 返回估计的长度
    int len = 0;
    while (fmt[len])
    800007ec:	0004c783          	lbu	a5,0(s1)
    800007f0:	c385                	beqz	a5,80000810 <sprintf+0x50>
    800007f2:	0485                	addi	s1,s1,1
    800007f4:	87a6                	mv	a5,s1
    800007f6:	4685                	li	a3,1
    800007f8:	9e85                	subw	a3,a3,s1
        len++;
    800007fa:	00f6853b          	addw	a0,a3,a5
    while (fmt[len])
    800007fe:	0785                	addi	a5,a5,1
    80000800:	fff7c703          	lbu	a4,-1(a5)
    80000804:	fb7d                	bnez	a4,800007fa <sprintf+0x3a>
    return len;
    80000806:	70a2                	ld	ra,40(sp)
    80000808:	7402                	ld	s0,32(sp)
    8000080a:	64e2                	ld	s1,24(sp)
    8000080c:	6125                	addi	sp,sp,96
    8000080e:	8082                	ret
    int len = 0;
    80000810:	4501                	li	a0,0
    80000812:	bfd5                	j	80000806 <sprintf+0x46>

0000000080000814 <console_init>:

extern void uart_flush(void); // 声明在uart.c中定义的函数

// 控制台初始化
void console_init(void)
{
    80000814:	1141                	addi	sp,sp,-16
    80000816:	e406                	sd	ra,8(sp)
    80000818:	e022                	sd	s0,0(sp)
    8000081a:	0800                	addi	s0,sp,16
    // 初始化UART
    uartinit();
    8000081c:	00000097          	auipc	ra,0x0
    80000820:	91a080e7          	jalr	-1766(ra) # 80000136 <uartinit>
}
    80000824:	60a2                	ld	ra,8(sp)
    80000826:	6402                	ld	s0,0(sp)
    80000828:	0141                	addi	sp,sp,16
    8000082a:	8082                	ret

000000008000082c <console_putc>:

// 输出单个字符（带特殊字符处理）
void console_putc(char c)
{
    8000082c:	1141                	addi	sp,sp,-16
    8000082e:	e406                	sd	ra,8(sp)
    80000830:	e022                	sd	s0,0(sp)
    80000832:	0800                	addi	s0,sp,16
    // 处理特殊控制字符
    switch (c)
    80000834:	47a5                	li	a5,9
    80000836:	02f50c63          	beq	a0,a5,8000086e <console_putc+0x42>
    8000083a:	47a9                	li	a5,10
    8000083c:	00f50a63          	beq	a0,a5,80000850 <console_putc+0x24>
    80000840:	47a1                	li	a5,8
    80000842:	06f50263          	beq	a0,a5,800008a6 <console_putc+0x7a>
        uartputc('\b');
        uartputc(' ');
        uartputc('\b');
        break;
    default: // 普通字符
        uartputc(c);
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	95a080e7          	jalr	-1702(ra) # 800001a0 <uartputc>
        break;
    }
}
    8000084e:	a881                	j	8000089e <console_putc+0x72>
        uartputc('\r');
    80000850:	4535                	li	a0,13
    80000852:	00000097          	auipc	ra,0x0
    80000856:	94e080e7          	jalr	-1714(ra) # 800001a0 <uartputc>
        uartputc('\n');
    8000085a:	4529                	li	a0,10
    8000085c:	00000097          	auipc	ra,0x0
    80000860:	944080e7          	jalr	-1724(ra) # 800001a0 <uartputc>
        uart_flush(); // 刷新输出
    80000864:	00000097          	auipc	ra,0x0
    80000868:	a74080e7          	jalr	-1420(ra) # 800002d8 <uart_flush>
        break;
    8000086c:	a80d                	j	8000089e <console_putc+0x72>
            uartputc(' ');
    8000086e:	02000513          	li	a0,32
    80000872:	00000097          	auipc	ra,0x0
    80000876:	92e080e7          	jalr	-1746(ra) # 800001a0 <uartputc>
    8000087a:	02000513          	li	a0,32
    8000087e:	00000097          	auipc	ra,0x0
    80000882:	922080e7          	jalr	-1758(ra) # 800001a0 <uartputc>
    80000886:	02000513          	li	a0,32
    8000088a:	00000097          	auipc	ra,0x0
    8000088e:	916080e7          	jalr	-1770(ra) # 800001a0 <uartputc>
    80000892:	02000513          	li	a0,32
    80000896:	00000097          	auipc	ra,0x0
    8000089a:	90a080e7          	jalr	-1782(ra) # 800001a0 <uartputc>
}
    8000089e:	60a2                	ld	ra,8(sp)
    800008a0:	6402                	ld	s0,0(sp)
    800008a2:	0141                	addi	sp,sp,16
    800008a4:	8082                	ret
        uartputc('\b');
    800008a6:	4521                	li	a0,8
    800008a8:	00000097          	auipc	ra,0x0
    800008ac:	8f8080e7          	jalr	-1800(ra) # 800001a0 <uartputc>
        uartputc(' ');
    800008b0:	02000513          	li	a0,32
    800008b4:	00000097          	auipc	ra,0x0
    800008b8:	8ec080e7          	jalr	-1812(ra) # 800001a0 <uartputc>
        uartputc('\b');
    800008bc:	4521                	li	a0,8
    800008be:	00000097          	auipc	ra,0x0
    800008c2:	8e2080e7          	jalr	-1822(ra) # 800001a0 <uartputc>
        break;
    800008c6:	bfe1                	j	8000089e <console_putc+0x72>

00000000800008c8 <console_puts>:

// 输出字符串
void console_puts(const char *s)
{
    800008c8:	1101                	addi	sp,sp,-32
    800008ca:	ec06                	sd	ra,24(sp)
    800008cc:	e822                	sd	s0,16(sp)
    800008ce:	e426                	sd	s1,8(sp)
    800008d0:	1000                	addi	s0,sp,32
    800008d2:	84aa                	mv	s1,a0
    while (*s)
    800008d4:	00054503          	lbu	a0,0(a0)
    800008d8:	c909                	beqz	a0,800008ea <console_puts+0x22>
    {
        console_putc(*s++);
    800008da:	0485                	addi	s1,s1,1
    800008dc:	00000097          	auipc	ra,0x0
    800008e0:	f50080e7          	jalr	-176(ra) # 8000082c <console_putc>
    while (*s)
    800008e4:	0004c503          	lbu	a0,0(s1)
    800008e8:	f96d                	bnez	a0,800008da <console_puts+0x12>
    }
    uart_flush(); // 字符串输出完成后刷新
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	9ee080e7          	jalr	-1554(ra) # 800002d8 <uart_flush>
}
    800008f2:	60e2                	ld	ra,24(sp)
    800008f4:	6442                	ld	s0,16(sp)
    800008f6:	64a2                	ld	s1,8(sp)
    800008f8:	6105                	addi	sp,sp,32
    800008fa:	8082                	ret

00000000800008fc <console_clear>:

// 清屏功能（通过发送ANSI转义序列）
void console_clear(void)
{
    800008fc:	1141                	addi	sp,sp,-16
    800008fe:	e406                	sd	ra,8(sp)
    80000900:	e022                	sd	s0,0(sp)
    80000902:	0800                	addi	s0,sp,16
    // ANSI清屏序列：ESC[2J
    console_puts("\x1B[2J");
    80000904:	0000a517          	auipc	a0,0xa
    80000908:	8c450513          	addi	a0,a0,-1852 # 8000a1c8 <digits+0x18>
    8000090c:	00000097          	auipc	ra,0x0
    80000910:	fbc080e7          	jalr	-68(ra) # 800008c8 <console_puts>
    // 光标复位：ESC[H
    console_puts("\x1B[H");
    80000914:	0000a517          	auipc	a0,0xa
    80000918:	8bc50513          	addi	a0,a0,-1860 # 8000a1d0 <digits+0x20>
    8000091c:	00000097          	auipc	ra,0x0
    80000920:	fac080e7          	jalr	-84(ra) # 800008c8 <console_puts>
}
    80000924:	60a2                	ld	ra,8(sp)
    80000926:	6402                	ld	s0,0(sp)
    80000928:	0141                	addi	sp,sp,16
    8000092a:	8082                	ret

000000008000092c <console_clear_line>:

// 以下是新添加的一些拓展功能
//  清除当前行
void console_clear_line(void)
{
    8000092c:	1141                	addi	sp,sp,-16
    8000092e:	e406                	sd	ra,8(sp)
    80000930:	e022                	sd	s0,0(sp)
    80000932:	0800                	addi	s0,sp,16
    console_puts("\x1B[K"); // 清除从光标到行尾
    80000934:	0000a517          	auipc	a0,0xa
    80000938:	8a450513          	addi	a0,a0,-1884 # 8000a1d8 <digits+0x28>
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	f8c080e7          	jalr	-116(ra) # 800008c8 <console_puts>
}
    80000944:	60a2                	ld	ra,8(sp)
    80000946:	6402                	ld	s0,0(sp)
    80000948:	0141                	addi	sp,sp,16
    8000094a:	8082                	ret

000000008000094c <console_clear_to_end>:

// 清除从光标到屏幕末尾
void console_clear_to_end(void)
{
    8000094c:	1141                	addi	sp,sp,-16
    8000094e:	e406                	sd	ra,8(sp)
    80000950:	e022                	sd	s0,0(sp)
    80000952:	0800                	addi	s0,sp,16
    console_puts("\x1B[J"); // 清除从光标到屏幕末尾
    80000954:	0000a517          	auipc	a0,0xa
    80000958:	88c50513          	addi	a0,a0,-1908 # 8000a1e0 <digits+0x30>
    8000095c:	00000097          	auipc	ra,0x0
    80000960:	f6c080e7          	jalr	-148(ra) # 800008c8 <console_puts>
}
    80000964:	60a2                	ld	ra,8(sp)
    80000966:	6402                	ld	s0,0(sp)
    80000968:	0141                	addi	sp,sp,16
    8000096a:	8082                	ret

000000008000096c <console_goto_xy>:

// 光标定位：goto_xy(int x, int y)
void console_goto_xy(int x, int y)
{
    8000096c:	1101                	addi	sp,sp,-32
    8000096e:	ec06                	sd	ra,24(sp)
    80000970:	e822                	sd	s0,16(sp)
    80000972:	1000                	addi	s0,sp,32
    char buf[16];
    char *p = buf;

    // 构建ANSI序列：\x1B[y;xH
    *p++ = '\x1B';
    80000974:	47ed                	li	a5,27
    80000976:	fef40023          	sb	a5,-32(s0)
    *p++ = '[';
    8000097a:	05b00793          	li	a5,91
    8000097e:	fef400a3          	sb	a5,-31(s0)

    // 处理行号
    if (y >= 10)
    80000982:	47a5                	li	a5,9
    80000984:	06b7d763          	bge	a5,a1,800009f2 <console_goto_xy+0x86>
    {
        *p++ = '0' + (y / 10);
    80000988:	4729                	li	a4,10
    8000098a:	02e5c7bb          	divw	a5,a1,a4
    8000098e:	0307879b          	addiw	a5,a5,48
    80000992:	fef40123          	sb	a5,-30(s0)
        *p++ = '0' + (y % 10);
    80000996:	02e5e5bb          	remw	a1,a1,a4
    8000099a:	0305859b          	addiw	a1,a1,48
    8000099e:	feb401a3          	sb	a1,-29(s0)
    800009a2:	fe440793          	addi	a5,s0,-28
    else
    {
        *p++ = '0' + y;
    }

    *p++ = ';';
    800009a6:	03b00713          	li	a4,59
    800009aa:	00e78023          	sb	a4,0(a5)

    // 处理列号
    if (x >= 10)
    800009ae:	4725                	li	a4,9
    800009b0:	04a75863          	bge	a4,a0,80000a00 <console_goto_xy+0x94>
    {
        *p++ = '0' + (x / 10);
    800009b4:	46a9                	li	a3,10
    800009b6:	02d5473b          	divw	a4,a0,a3
    800009ba:	0307071b          	addiw	a4,a4,48
    800009be:	00e780a3          	sb	a4,1(a5)
        *p++ = '0' + (x % 10);
    800009c2:	00378713          	addi	a4,a5,3
    800009c6:	02d5653b          	remw	a0,a0,a3
    800009ca:	0305051b          	addiw	a0,a0,48
    800009ce:	00a78123          	sb	a0,2(a5)
    else
    {
        *p++ = '0' + x;
    }

    *p++ = 'H';
    800009d2:	04800793          	li	a5,72
    800009d6:	00f70023          	sb	a5,0(a4)
    *p = '\0';
    800009da:	000700a3          	sb	zero,1(a4)

    console_puts(buf);
    800009de:	fe040513          	addi	a0,s0,-32
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	ee6080e7          	jalr	-282(ra) # 800008c8 <console_puts>
}
    800009ea:	60e2                	ld	ra,24(sp)
    800009ec:	6442                	ld	s0,16(sp)
    800009ee:	6105                	addi	sp,sp,32
    800009f0:	8082                	ret
        *p++ = '0' + y;
    800009f2:	0305859b          	addiw	a1,a1,48
    800009f6:	feb40123          	sb	a1,-30(s0)
    800009fa:	fe340793          	addi	a5,s0,-29
    800009fe:	b765                	j	800009a6 <console_goto_xy+0x3a>
        *p++ = '0' + x;
    80000a00:	00278713          	addi	a4,a5,2
    80000a04:	0305051b          	addiw	a0,a0,48
    80000a08:	00a780a3          	sb	a0,1(a5)
    80000a0c:	b7d9                	j	800009d2 <console_goto_xy+0x66>

0000000080000a0e <console_cursor_home>:

// 光标回家（左上角）
void console_cursor_home(void)
{
    80000a0e:	1141                	addi	sp,sp,-16
    80000a10:	e406                	sd	ra,8(sp)
    80000a12:	e022                	sd	s0,0(sp)
    80000a14:	0800                	addi	s0,sp,16
    console_puts("\x1B[H");
    80000a16:	00009517          	auipc	a0,0x9
    80000a1a:	7ba50513          	addi	a0,a0,1978 # 8000a1d0 <digits+0x20>
    80000a1e:	00000097          	auipc	ra,0x0
    80000a22:	eaa080e7          	jalr	-342(ra) # 800008c8 <console_puts>
}
    80000a26:	60a2                	ld	ra,8(sp)
    80000a28:	6402                	ld	s0,0(sp)
    80000a2a:	0141                	addi	sp,sp,16
    80000a2c:	8082                	ret

0000000080000a2e <console_cursor_save>:

// 保存光标位置
void console_cursor_save(void)
{
    80000a2e:	1141                	addi	sp,sp,-16
    80000a30:	e406                	sd	ra,8(sp)
    80000a32:	e022                	sd	s0,0(sp)
    80000a34:	0800                	addi	s0,sp,16
    console_puts("\x1B[s");
    80000a36:	00009517          	auipc	a0,0x9
    80000a3a:	7b250513          	addi	a0,a0,1970 # 8000a1e8 <digits+0x38>
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e8a080e7          	jalr	-374(ra) # 800008c8 <console_puts>
}
    80000a46:	60a2                	ld	ra,8(sp)
    80000a48:	6402                	ld	s0,0(sp)
    80000a4a:	0141                	addi	sp,sp,16
    80000a4c:	8082                	ret

0000000080000a4e <console_cursor_restore>:

// 恢复光标位置
void console_cursor_restore(void)
{
    80000a4e:	1141                	addi	sp,sp,-16
    80000a50:	e406                	sd	ra,8(sp)
    80000a52:	e022                	sd	s0,0(sp)
    80000a54:	0800                	addi	s0,sp,16
    console_puts("\x1B[u");
    80000a56:	00009517          	auipc	a0,0x9
    80000a5a:	79a50513          	addi	a0,a0,1946 # 8000a1f0 <digits+0x40>
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	e6a080e7          	jalr	-406(ra) # 800008c8 <console_puts>
}
    80000a66:	60a2                	ld	ra,8(sp)
    80000a68:	6402                	ld	s0,0(sp)
    80000a6a:	0141                	addi	sp,sp,16
    80000a6c:	8082                	ret

0000000080000a6e <console_cursor_show>:

// 显示/隐藏光标
void console_cursor_show(int show)
{
    80000a6e:	1141                	addi	sp,sp,-16
    80000a70:	e406                	sd	ra,8(sp)
    80000a72:	e022                	sd	s0,0(sp)
    80000a74:	0800                	addi	s0,sp,16
    if (show)
    80000a76:	cd09                	beqz	a0,80000a90 <console_cursor_show+0x22>
    {
        console_puts("\x1B[?25h"); // 显示光标
    80000a78:	00009517          	auipc	a0,0x9
    80000a7c:	78050513          	addi	a0,a0,1920 # 8000a1f8 <digits+0x48>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	e48080e7          	jalr	-440(ra) # 800008c8 <console_puts>
    }
    else
    {
        console_puts("\x1B[?25l"); // 隐藏光标
    }
}
    80000a88:	60a2                	ld	ra,8(sp)
    80000a8a:	6402                	ld	s0,0(sp)
    80000a8c:	0141                	addi	sp,sp,16
    80000a8e:	8082                	ret
        console_puts("\x1B[?25l"); // 隐藏光标
    80000a90:	00009517          	auipc	a0,0x9
    80000a94:	77050513          	addi	a0,a0,1904 # 8000a200 <digits+0x50>
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	e30080e7          	jalr	-464(ra) # 800008c8 <console_puts>
}
    80000aa0:	b7e5                	j	80000a88 <console_cursor_show+0x1a>

0000000080000aa2 <console_set_color>:

// ==================== 颜色控制功能 ====================

// 设置颜色属性
void console_set_color(int color)
{
    80000aa2:	1101                	addi	sp,sp,-32
    80000aa4:	ec06                	sd	ra,24(sp)
    80000aa6:	e822                	sd	s0,16(sp)
    80000aa8:	1000                	addi	s0,sp,32
    char buf[16];
    char *p = buf;

    *p++ = '\x1B';
    80000aaa:	47ed                	li	a5,27
    80000aac:	fef40023          	sb	a5,-32(s0)
    *p++ = '[';
    80000ab0:	05b00793          	li	a5,91
    80000ab4:	fef400a3          	sb	a5,-31(s0)

    if (color == 0)
    80000ab8:	e51d                	bnez	a0,80000ae6 <console_set_color+0x44>
    {
        // 重置所有属性
        *p++ = '0';
    80000aba:	03000793          	li	a5,48
    80000abe:	fef40123          	sb	a5,-30(s0)
    80000ac2:	fe340793          	addi	a5,s0,-29
                *p++ = '0' + color;
            }
        }
    }

    *p++ = 'm';
    80000ac6:	06d00713          	li	a4,109
    80000aca:	00e78023          	sb	a4,0(a5)
    *p = '\0';
    80000ace:	000780a3          	sb	zero,1(a5)

    console_puts(buf);
    80000ad2:	fe040513          	addi	a0,s0,-32
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	df2080e7          	jalr	-526(ra) # 800008c8 <console_puts>
}
    80000ade:	60e2                	ld	ra,24(sp)
    80000ae0:	6442                	ld	s0,16(sp)
    80000ae2:	6105                	addi	sp,sp,32
    80000ae4:	8082                	ret
        if (color >= 30 && color <= 37)
    80000ae6:	fe25079b          	addiw	a5,a0,-30
    80000aea:	471d                	li	a4,7
    80000aec:	02f76063          	bltu	a4,a5,80000b0c <console_set_color+0x6a>
                *p++ = '0' + (color / 10);
    80000af0:	03300793          	li	a5,51
    80000af4:	fef40123          	sb	a5,-30(s0)
                *p++ = '0' + (color % 10);
    80000af8:	47a9                	li	a5,10
    80000afa:	02f5653b          	remw	a0,a0,a5
    80000afe:	0305051b          	addiw	a0,a0,48
    80000b02:	fea401a3          	sb	a0,-29(s0)
    80000b06:	fe440793          	addi	a5,s0,-28
    80000b0a:	bf75                	j	80000ac6 <console_set_color+0x24>
            if (color >= 10)
    80000b0c:	47a5                	li	a5,9
    80000b0e:	02a7d263          	bge	a5,a0,80000b32 <console_set_color+0x90>
                *p++ = '0' + (color / 10);
    80000b12:	4729                	li	a4,10
    80000b14:	02e547bb          	divw	a5,a0,a4
    80000b18:	0307879b          	addiw	a5,a5,48
    80000b1c:	fef40123          	sb	a5,-30(s0)
                *p++ = '0' + (color % 10);
    80000b20:	02e5653b          	remw	a0,a0,a4
    80000b24:	0305051b          	addiw	a0,a0,48
    80000b28:	fea401a3          	sb	a0,-29(s0)
    80000b2c:	fe440793          	addi	a5,s0,-28
    80000b30:	bf59                	j	80000ac6 <console_set_color+0x24>
                *p++ = '0' + color;
    80000b32:	0305051b          	addiw	a0,a0,48
    80000b36:	fea40123          	sb	a0,-30(s0)
    80000b3a:	fe340793          	addi	a5,s0,-29
    80000b3e:	b761                	j	80000ac6 <console_set_color+0x24>

0000000080000b40 <console_reset_color>:

// 重置颜色
void console_reset_color(void)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e406                	sd	ra,8(sp)
    80000b44:	e022                	sd	s0,0(sp)
    80000b46:	0800                	addi	s0,sp,16
    console_puts("\x1B[0m");
    80000b48:	00009517          	auipc	a0,0x9
    80000b4c:	6c050513          	addi	a0,a0,1728 # 8000a208 <digits+0x58>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	d78080e7          	jalr	-648(ra) # 800008c8 <console_puts>
}
    80000b58:	60a2                	ld	ra,8(sp)
    80000b5a:	6402                	ld	s0,0(sp)
    80000b5c:	0141                	addi	sp,sp,16
    80000b5e:	8082                	ret

0000000080000b60 <printf_color>:

// 带颜色的printf
int printf_color(int color, const char *fmt, ...)
{
    80000b60:	7175                	addi	sp,sp,-144
    80000b62:	ec86                	sd	ra,88(sp)
    80000b64:	e8a2                	sd	s0,80(sp)
    80000b66:	e4a6                	sd	s1,72(sp)
    80000b68:	e0ca                	sd	s2,64(sp)
    80000b6a:	fc4e                	sd	s3,56(sp)
    80000b6c:	f852                	sd	s4,48(sp)
    80000b6e:	f456                	sd	s5,40(sp)
    80000b70:	f05a                	sd	s6,32(sp)
    80000b72:	ec5e                	sd	s7,24(sp)
    80000b74:	1080                	addi	s0,sp,96
    80000b76:	892e                	mv	s2,a1
    80000b78:	e010                	sd	a2,0(s0)
    80000b7a:	e414                	sd	a3,8(s0)
    80000b7c:	e818                	sd	a4,16(s0)
    80000b7e:	ec1c                	sd	a5,24(s0)
    80000b80:	03043023          	sd	a6,32(s0)
    80000b84:	03143423          	sd	a7,40(s0)
    va_list ap;

    // 设置颜色
    console_set_color(color);
    80000b88:	00000097          	auipc	ra,0x0
    80000b8c:	f1a080e7          	jalr	-230(ra) # 80000aa2 <console_set_color>

    // 直接使用现有的printf功能
    va_start(ap, fmt);
    80000b90:	fa843423          	sd	s0,-88(s0)

    // 简化实现：先设置颜色，然后调用普通输出
    // 这里我们直接处理字符串，不进行复杂格式化
    for (int i = 0; fmt[i] != '\0'; i++)
    80000b94:	00094503          	lbu	a0,0(s2)
    80000b98:	c155                	beqz	a0,80000c3c <printf_color+0xdc>
    80000b9a:	4481                	li	s1,0
    {
        if (fmt[i] != '%')
    80000b9c:	02500993          	li	s3,37
            continue;
        }

        // 简单处理 %s 和 %c
        i++;
        switch (fmt[i])
    80000ba0:	06300b13          	li	s6,99
    80000ba4:	07300a93          	li	s5,115
        {
        case 's':
        {
            char *s = va_arg(ap, char *);
            if (!s)
                s = "(null)";
    80000ba8:	00009b97          	auipc	s7,0x9
    80000bac:	5a8b8b93          	addi	s7,s7,1448 # 8000a150 <etext+0x150>
    80000bb0:	a819                	j	80000bc6 <printf_color+0x66>
            console_putc(fmt[i]);
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	c7a080e7          	jalr	-902(ra) # 8000082c <console_putc>
    for (int i = 0; fmt[i] != '\0'; i++)
    80000bba:	2485                	addiw	s1,s1,1
    80000bbc:	009907b3          	add	a5,s2,s1
    80000bc0:	0007c503          	lbu	a0,0(a5)
    80000bc4:	cd25                	beqz	a0,80000c3c <printf_color+0xdc>
        if (fmt[i] != '%')
    80000bc6:	ff3516e3          	bne	a0,s3,80000bb2 <printf_color+0x52>
        i++;
    80000bca:	2485                	addiw	s1,s1,1
        switch (fmt[i])
    80000bcc:	00990a33          	add	s4,s2,s1
    80000bd0:	000a4783          	lbu	a5,0(s4)
    80000bd4:	05678163          	beq	a5,s6,80000c16 <printf_color+0xb6>
    80000bd8:	03578063          	beq	a5,s5,80000bf8 <printf_color+0x98>
    80000bdc:	05378a63          	beq	a5,s3,80000c30 <printf_color+0xd0>
        case '%':
            console_putc('%');
            break;
        default:
            // 对于复杂格式，回退到普通输出
            console_putc('%');
    80000be0:	854e                	mv	a0,s3
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	c4a080e7          	jalr	-950(ra) # 8000082c <console_putc>
            console_putc(fmt[i]);
    80000bea:	000a4503          	lbu	a0,0(s4)
    80000bee:	00000097          	auipc	ra,0x0
    80000bf2:	c3e080e7          	jalr	-962(ra) # 8000082c <console_putc>
            break;
    80000bf6:	b7d1                	j	80000bba <printf_color+0x5a>
            char *s = va_arg(ap, char *);
    80000bf8:	fa843783          	ld	a5,-88(s0)
    80000bfc:	00878713          	addi	a4,a5,8
    80000c00:	fae43423          	sd	a4,-88(s0)
    80000c04:	6388                	ld	a0,0(a5)
            if (!s)
    80000c06:	c511                	beqz	a0,80000c12 <printf_color+0xb2>
            console_puts(s);
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	cc0080e7          	jalr	-832(ra) # 800008c8 <console_puts>
            break;
    80000c10:	b76d                	j	80000bba <printf_color+0x5a>
                s = "(null)";
    80000c12:	855e                	mv	a0,s7
    80000c14:	bfd5                	j	80000c08 <printf_color+0xa8>
            char c = va_arg(ap, int);
    80000c16:	fa843783          	ld	a5,-88(s0)
    80000c1a:	00878713          	addi	a4,a5,8
    80000c1e:	fae43423          	sd	a4,-88(s0)
            console_putc(c);
    80000c22:	0007c503          	lbu	a0,0(a5)
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	c06080e7          	jalr	-1018(ra) # 8000082c <console_putc>
            break;
    80000c2e:	b771                	j	80000bba <printf_color+0x5a>
            console_putc('%');
    80000c30:	854e                	mv	a0,s3
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	bfa080e7          	jalr	-1030(ra) # 8000082c <console_putc>
            break;
    80000c3a:	b741                	j	80000bba <printf_color+0x5a>
    }

    va_end(ap);

    // 重置颜色
    console_reset_color();
    80000c3c:	00000097          	auipc	ra,0x0
    80000c40:	f04080e7          	jalr	-252(ra) # 80000b40 <console_reset_color>

    return 0; // 简化返回
}
    80000c44:	4501                	li	a0,0
    80000c46:	60e6                	ld	ra,88(sp)
    80000c48:	6446                	ld	s0,80(sp)
    80000c4a:	64a6                	ld	s1,72(sp)
    80000c4c:	6906                	ld	s2,64(sp)
    80000c4e:	79e2                	ld	s3,56(sp)
    80000c50:	7a42                	ld	s4,48(sp)
    80000c52:	7aa2                	ld	s5,40(sp)
    80000c54:	7b02                	ld	s6,32(sp)
    80000c56:	6be2                	ld	s7,24(sp)
    80000c58:	6149                	addi	sp,sp,144
    80000c5a:	8082                	ret

0000000080000c5c <buddy_system_init>:
    }
}

// 伙伴系统初始化
static void buddy_system_init(void)
{
    80000c5c:	1141                	addi	sp,sp,-16
    80000c5e:	e422                	sd	s0,8(sp)
    80000c60:	0800                	addi	s0,sp,16
    if (pmm.initialized)
    80000c62:	0000f797          	auipc	a5,0xf
    80000c66:	e6e7a783          	lw	a5,-402(a5) # 8000fad0 <pmm+0xd0>
    80000c6a:	12079f63          	bnez	a5,80000da8 <buddy_system_init+0x14c>
    80000c6e:	0000f797          	auipc	a5,0xf
    80000c72:	db278793          	addi	a5,a5,-590 # 8000fa20 <pmm+0x20>
    80000c76:	0000f717          	auipc	a4,0xf
    80000c7a:	e5a70713          	addi	a4,a4,-422 # 8000fad0 <pmm+0xd0>
    // printf("PMM: Initializing buddy system...\n");

    // 初始化所有阶的空闲链表
    for (int i = 0; i <= MAX_ORDER; i++)
    {
        pmm.free_area[i].free_list = NULL;
    80000c7e:	0007b023          	sd	zero,0(a5)
        pmm.free_area[i].nr_free = 0;
    80000c82:	0007a423          	sw	zero,8(a5)
    for (int i = 0; i <= MAX_ORDER; i++)
    80000c86:	07c1                	addi	a5,a5,16
    80000c88:	fef71be3          	bne	a4,a5,80000c7e <buddy_system_init+0x22>
    }

    // 设置内存范围
    pmm.base_addr = PGROUNDUP((uint64)end);
    80000c8c:	6685                	lui	a3,0x1
    80000c8e:	00466617          	auipc	a2,0x466
    80000c92:	15160613          	addi	a2,a2,337 # 80466ddf <end+0xfff>
    80000c96:	77fd                	lui	a5,0xfffff
    80000c98:	8e7d                	and	a2,a2,a5
    80000c9a:	0000f717          	auipc	a4,0xf
    80000c9e:	d6670713          	addi	a4,a4,-666 # 8000fa00 <pmm>
    80000ca2:	eb10                	sd	a2,16(a4)
    pmm.end_addr = PGROUNDDOWN(PHYSICAL_TOP);
    80000ca4:	47c5                	li	a5,17
    80000ca6:	07ee                	slli	a5,a5,0x1b
    80000ca8:	ef1c                	sd	a5,24(a4)
    pmm.total_pages = (pmm.end_addr - pmm.base_addr) / PGSIZE;
    80000caa:	8f91                	sub	a5,a5,a2
    80000cac:	00c7d813          	srli	a6,a5,0xc
    80000cb0:	01073023          	sd	a6,0(a4)
        (void)alignment; // silence unused when debug prints are disabled
        // 对齐分析打印移除（保持安静）
    }

    // 主分配循环
    while (remaining_pages > 0)
    80000cb4:	0cd7e363          	bltu	a5,a3,80000d7a <buddy_system_init+0x11e>
    {
        // 找到当前地址能够分配的最大阶
        int best_order = -1;
        for (int order = MAX_ORDER; order >= 0; order--)
    80000cb8:	4f29                	li	t5,10
        {
            uint64 block_pages = (1UL << order);
            uint64 block_size = block_pages * PGSIZE;
    80000cba:	6585                	lui	a1,0x1
            uint64 block_pages = (1UL << order);
    80000cbc:	4885                	li	a7,1
        for (int order = MAX_ORDER; order >= 0; order--)
    80000cbe:	557d                	li	a0,-1
            for (int order = MAX_ORDER; order >= 0; order--)
            {
                uint64 block_size = PGSIZE * (1UL << order);
                uint64 aligned_addr = (current_addr + block_size - 1) & ~(block_size - 1);

                if (aligned_addr < pmm.end_addr &&
    80000cc0:	8e3a                	mv	t3,a4
    80000cc2:	a091                	j	80000d06 <buddy_system_init+0xaa>
        for (int order = MAX_ORDER; order >= 0; order--)
    80000cc4:	37fd                	addiw	a5,a5,-1
    80000cc6:	04a78263          	beq	a5,a0,80000d0a <buddy_system_init+0xae>
            uint64 block_size = block_pages * PGSIZE;
    80000cca:	00f596b3          	sll	a3,a1,a5
            if ((current_addr % block_size) == 0 && remaining_pages >= block_pages)
    80000cce:	fff68713          	addi	a4,a3,-1 # fff <_entry-0x7ffff001>
    80000cd2:	8f71                	and	a4,a4,a2
    80000cd4:	fb65                	bnez	a4,80000cc4 <buddy_system_init+0x68>
            uint64 block_pages = (1UL << order);
    80000cd6:	00f89733          	sll	a4,a7,a5
            if ((current_addr % block_size) == 0 && remaining_pages >= block_pages)
    80000cda:	fee865e3          	bltu	a6,a4,80000cc4 <buddy_system_init+0x68>
        if (best_order >= 0)
    80000cde:	0207c663          	bltz	a5,80000d0a <buddy_system_init+0xae>
            block->next = pmm.free_area[best_order].free_list;
    80000ce2:	0789                	addi	a5,a5,2
    80000ce4:	0792                	slli	a5,a5,0x4
    80000ce6:	97f2                	add	a5,a5,t3
    80000ce8:	0007b303          	ld	t1,0(a5) # fffffffffffff000 <end+0xffffffff7fb99220>
    80000cec:	00663023          	sd	t1,0(a2)
            pmm.free_area[best_order].free_list = block;
    80000cf0:	e390                	sd	a2,0(a5)
            pmm.free_area[best_order].nr_free++;
    80000cf2:	0087a303          	lw	t1,8(a5)
    80000cf6:	2305                	addiw	t1,t1,1
    80000cf8:	0067a423          	sw	t1,8(a5)
            current_addr += block_size;
    80000cfc:	9636                	add	a2,a2,a3
            remaining_pages -= block_pages;
    80000cfe:	40e80833          	sub	a6,a6,a4
    while (remaining_pages > 0)
    80000d02:	06080c63          	beqz	a6,80000d7a <buddy_system_init+0x11e>
        for (int order = MAX_ORDER; order >= 0; order--)
    80000d06:	87fa                	mv	a5,t5
    80000d08:	b7c9                	j	80000cca <buddy_system_init+0x6e>
                if (aligned_addr < pmm.end_addr &&
    80000d0a:	018e3e83          	ld	t4,24(t3)
    80000d0e:	86fa                	mv	a3,t5
                uint64 aligned_addr = (current_addr + block_size - 1) & ~(block_size - 1);
    80000d10:	fff60313          	addi	t1,a2,-1
    80000d14:	a021                	j	80000d1c <buddy_system_init+0xc0>
            for (int order = MAX_ORDER; order >= 0; order--)
    80000d16:	36fd                	addiw	a3,a3,-1
    80000d18:	02a68263          	beq	a3,a0,80000d3c <buddy_system_init+0xe0>
                uint64 block_size = PGSIZE * (1UL << order);
    80000d1c:	00d597b3          	sll	a5,a1,a3
                uint64 aligned_addr = (current_addr + block_size - 1) & ~(block_size - 1);
    80000d20:	00f30733          	add	a4,t1,a5
    80000d24:	40f007b3          	neg	a5,a5
    80000d28:	8ff9                	and	a5,a5,a4
                if (aligned_addr < pmm.end_addr &&
    80000d2a:	ffd7f6e3          	bgeu	a5,t4,80000d16 <buddy_system_init+0xba>
                    (aligned_addr - current_addr) / PGSIZE <= remaining_pages)
    80000d2e:	40c78733          	sub	a4,a5,a2
    80000d32:	8331                	srli	a4,a4,0xc
                if (aligned_addr < pmm.end_addr &&
    80000d34:	fee861e3          	bltu	a6,a4,80000d16 <buddy_system_init+0xba>
                    found = 1;
                    break;
                }
            }

            if (found && next_aligned_addr > current_addr)
    80000d38:	00f66f63          	bltu	a2,a5,80000d56 <buddy_system_init+0xfa>
            }
            else
            {
                // 无法对齐，使用单页
                struct free_page *block = (struct free_page *)current_addr;
                block->next = pmm.free_area[0].free_list;
    80000d3c:	020e3783          	ld	a5,32(t3)
    80000d40:	e21c                	sd	a5,0(a2)
                pmm.free_area[0].free_list = block;
    80000d42:	02ce3023          	sd	a2,32(t3)
                pmm.free_area[0].nr_free++;
    80000d46:	028e2783          	lw	a5,40(t3)
    80000d4a:	2785                	addiw	a5,a5,1
    80000d4c:	02fe2423          	sw	a5,40(t3)

                current_addr += PGSIZE;
    80000d50:	962e                	add	a2,a2,a1
                remaining_pages--;
    80000d52:	187d                	addi	a6,a6,-1
                total_blocks++;
    80000d54:	b77d                	j	80000d02 <buddy_system_init+0xa6>
                while (current_addr < next_aligned_addr && remaining_pages > 0)
    80000d56:	02080263          	beqz	a6,80000d7a <buddy_system_init+0x11e>
                    block->next = pmm.free_area[0].free_list;
    80000d5a:	020e3703          	ld	a4,32(t3)
    80000d5e:	e218                	sd	a4,0(a2)
                    pmm.free_area[0].free_list = block;
    80000d60:	02ce3023          	sd	a2,32(t3)
                    pmm.free_area[0].nr_free++;
    80000d64:	028e2703          	lw	a4,40(t3)
    80000d68:	2705                	addiw	a4,a4,1
    80000d6a:	02ee2423          	sw	a4,40(t3)
                    current_addr += PGSIZE;
    80000d6e:	962e                	add	a2,a2,a1
                    remaining_pages--;
    80000d70:	187d                	addi	a6,a6,-1
                while (current_addr < next_aligned_addr && remaining_pages > 0)
    80000d72:	f8f678e3          	bgeu	a2,a5,80000d02 <buddy_system_init+0xa6>
    80000d76:	fe0812e3          	bnez	a6,80000d5a <buddy_system_init+0xfe>
    // 验证和完成
    uint64 used_pages = (current_addr - pmm.base_addr) / PGSIZE;
    (void)used_pages; // silence unused when debug prints are disabled
    // printf("PMM: Memory usage: %d/%d pages\n", (int)used_pages, (int)pmm.total_pages);

    pmm.initialized = 1;
    80000d7a:	0000f797          	auipc	a5,0xf
    80000d7e:	c8678793          	addi	a5,a5,-890 # 8000fa00 <pmm>
    80000d82:	4705                	li	a4,1
    80000d84:	0ce7a823          	sw	a4,208(a5)
    pmm.free_pages = pmm.total_pages;
    80000d88:	6398                	ld	a4,0(a5)
    80000d8a:	e798                	sd	a4,8(a5)

    // 统计信息
    // printf("PMM: Buddy system initialized with %d free pages\n", pmm.free_pages);
    // printf("PMM: Total blocks allocated: %d\n", total_blocks);

    for (int i = 0; i <= MAX_ORDER; i++)
    80000d8c:	0000f797          	auipc	a5,0xf
    80000d90:	d3c78793          	addi	a5,a5,-708 # 8000fac8 <pmm+0xc8>
    80000d94:	0000f697          	auipc	a3,0xf
    80000d98:	c8468693          	addi	a3,a3,-892 # 8000fa18 <pmm+0x18>

    // 检查最大可用块
    int max_order = -1;
    for (int i = MAX_ORDER; i >= 0; i--)
    {
        if (pmm.free_area[i].nr_free > 0)
    80000d9c:	4398                	lw	a4,0(a5)
    80000d9e:	00e04563          	bgtz	a4,80000da8 <buddy_system_init+0x14c>
    for (int i = MAX_ORDER; i >= 0; i--)
    80000da2:	17c1                	addi	a5,a5,-16
    80000da4:	fed79ce3          	bne	a5,a3,80000d9c <buddy_system_init+0x140>
            break;
        }
    }
    (void)max_order; // silence unused when debug prints are disabled
    // printf("PMM: Maximum available order: %d (%d pages)\n", max_order, (1 << max_order));
}
    80000da8:	6422                	ld	s0,8(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <alloc_pages_buddy>:
}

// 伙伴系统分配
void *alloc_pages_buddy(int order)
{
    if (order < 0 || order > MAX_ORDER)
    80000dae:	47a9                	li	a5,10
    80000db0:	0aa7ee63          	bltu	a5,a0,80000e6c <alloc_pages_buddy+0xbe>
{
    80000db4:	1101                	addi	sp,sp,-32
    80000db6:	ec06                	sd	ra,24(sp)
    80000db8:	e822                	sd	s0,16(sp)
    80000dba:	e426                	sd	s1,8(sp)
    80000dbc:	1000                	addi	s0,sp,32
    80000dbe:	84aa                	mv	s1,a0
        return NULL;

    if (!pmm.initialized)
    80000dc0:	0000f797          	auipc	a5,0xf
    80000dc4:	d107a783          	lw	a5,-752(a5) # 8000fad0 <pmm+0xd0>
    80000dc8:	c79d                	beqz	a5,80000df6 <alloc_pages_buddy+0x48>
        buddy_system_init();

    int current_order = order;

    // 寻找合适大小的空闲块
    while (current_order <= MAX_ORDER)
    80000dca:	00449713          	slli	a4,s1,0x4
    80000dce:	0000f797          	auipc	a5,0xf
    80000dd2:	c5a78793          	addi	a5,a5,-934 # 8000fa28 <pmm+0x28>
    80000dd6:	973e                	add	a4,a4,a5
    int current_order = order;
    80000dd8:	87a6                	mv	a5,s1
    while (current_order <= MAX_ORDER)
    80000dda:	462d                	li	a2,11
    {
        if (pmm.free_area[current_order].nr_free > 0)
    80000ddc:	4314                	lw	a3,0(a4)
    80000dde:	02d04163          	bgtz	a3,80000e00 <alloc_pages_buddy+0x52>

            // printf("PMM: SUCCESS: Allocated %d pages at 0x%p (order %d)\n",
            //        allocated_pages, block, order);
            return block;
        }
        current_order++;
    80000de2:	2785                	addiw	a5,a5,1
    while (current_order <= MAX_ORDER)
    80000de4:	0741                	addi	a4,a4,16
    80000de6:	fec79be3          	bne	a5,a2,80000ddc <alloc_pages_buddy+0x2e>
    }

    // printf("PMM: FAILED: No memory for order %d\n", order);
    return NULL;
    80000dea:	4501                	li	a0,0
}
    80000dec:	60e2                	ld	ra,24(sp)
    80000dee:	6442                	ld	s0,16(sp)
    80000df0:	64a2                	ld	s1,8(sp)
    80000df2:	6105                	addi	sp,sp,32
    80000df4:	8082                	ret
        buddy_system_init();
    80000df6:	00000097          	auipc	ra,0x0
    80000dfa:	e66080e7          	jalr	-410(ra) # 80000c5c <buddy_system_init>
    80000dfe:	b7f1                	j	80000dca <alloc_pages_buddy+0x1c>
            struct free_page *block = pmm.free_area[current_order].free_list;
    80000e00:	00278713          	addi	a4,a5,2
    80000e04:	00471613          	slli	a2,a4,0x4
    80000e08:	0000f717          	auipc	a4,0xf
    80000e0c:	bf870713          	addi	a4,a4,-1032 # 8000fa00 <pmm>
    80000e10:	9732                	add	a4,a4,a2
    80000e12:	6308                	ld	a0,0(a4)
            pmm.free_area[current_order].free_list = block->next;
    80000e14:	6110                	ld	a2,0(a0)
    80000e16:	e310                	sd	a2,0(a4)
            pmm.free_area[current_order].nr_free--;
    80000e18:	36fd                	addiw	a3,a3,-1
    80000e1a:	c714                	sw	a3,8(a4)
            while (current_order > order)
    80000e1c:	02f4d163          	bge	s1,a5,80000e3e <alloc_pages_buddy+0x90>
    80000e20:	00178693          	addi	a3,a5,1
    80000e24:	00469713          	slli	a4,a3,0x4
    80000e28:	0000f697          	auipc	a3,0xf
    80000e2c:	bd868693          	addi	a3,a3,-1064 # 8000fa00 <pmm>
    80000e30:	96ba                	add	a3,a3,a4
    uint64 block_size = PGSIZE * (1UL << order);
    80000e32:	6805                	lui	a6,0x1
    return (addr_val >= pmm.base_addr && addr_val < pmm.end_addr);
    80000e34:	0000f597          	auipc	a1,0xf
    80000e38:	bcc58593          	addi	a1,a1,-1076 # 8000fa00 <pmm>
    80000e3c:	a099                	j	80000e82 <alloc_pages_buddy+0xd4>
            pmm.free_pages -= allocated_pages;
    80000e3e:	0000f697          	auipc	a3,0xf
    80000e42:	bc268693          	addi	a3,a3,-1086 # 8000fa00 <pmm>
    80000e46:	4785                	li	a5,1
    80000e48:	0097973b          	sllw	a4,a5,s1
    80000e4c:	669c                	ld	a5,8(a3)
    80000e4e:	8f99                	sub	a5,a5,a4
    80000e50:	e69c                	sd	a5,8(a3)
    for (int i = 0; i < n; i++)
    80000e52:	87aa                	mv	a5,a0
            simple_memset(block, 0, allocated_pages * PGSIZE);
    80000e54:	6705                	lui	a4,0x1
    80000e56:	0097173b          	sllw	a4,a4,s1
    80000e5a:	1702                	slli	a4,a4,0x20
    80000e5c:	9301                	srli	a4,a4,0x20
    80000e5e:	972a                	add	a4,a4,a0
        cdst[i] = c;
    80000e60:	00078023          	sb	zero,0(a5)
    for (int i = 0; i < n; i++)
    80000e64:	0785                	addi	a5,a5,1
    80000e66:	fef71de3          	bne	a4,a5,80000e60 <alloc_pages_buddy+0xb2>
    80000e6a:	b749                	j	80000dec <alloc_pages_buddy+0x3e>
        return NULL;
    80000e6c:	4501                	li	a0,0
}
    80000e6e:	8082                	ret
                    buddy_page->next = pmm.free_area[current_order].free_list;
    80000e70:	6290                	ld	a2,0(a3)
    80000e72:	e310                	sd	a2,0(a4)
                    pmm.free_area[current_order].free_list = buddy_page;
    80000e74:	e298                	sd	a4,0(a3)
                    pmm.free_area[current_order].nr_free++;
    80000e76:	4698                	lw	a4,8(a3)
    80000e78:	2705                	addiw	a4,a4,1
    80000e7a:	c698                	sw	a4,8(a3)
            while (current_order > order)
    80000e7c:	16c1                	addi	a3,a3,-16
    80000e7e:	fcf480e3          	beq	s1,a5,80000e3e <alloc_pages_buddy+0x90>
                current_order--;
    80000e82:	37fd                	addiw	a5,a5,-1
    uint64 block_size = PGSIZE * (1UL << order);
    80000e84:	00f81733          	sll	a4,a6,a5
    uint64 buddy_addr = block_addr ^ block_size;
    80000e88:	8f29                	xor	a4,a4,a0
    return (addr_val >= pmm.base_addr && addr_val < pmm.end_addr);
    80000e8a:	6990                	ld	a2,16(a1)
    80000e8c:	fec768e3          	bltu	a4,a2,80000e7c <alloc_pages_buddy+0xce>
    80000e90:	6d90                	ld	a2,24(a1)
    80000e92:	fcc76fe3          	bltu	a4,a2,80000e70 <alloc_pages_buddy+0xc2>
    80000e96:	b7dd                	j	80000e7c <alloc_pages_buddy+0xce>

0000000080000e98 <free_pages_buddy>:

// 伙伴系统释放
void free_pages_buddy(void *page, int order)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e422                	sd	s0,8(sp)
    80000e9c:	0800                	addi	s0,sp,16
    if (page == NULL || order < 0 || order > MAX_ORDER)
    80000e9e:	cd3d                	beqz	a0,80000f1c <free_pages_buddy+0x84>
    80000ea0:	0005879b          	sext.w	a5,a1
    80000ea4:	4729                	li	a4,10
    80000ea6:	06f76b63          	bltu	a4,a5,80000f1c <free_pages_buddy+0x84>
        return;
    if (!pmm.initialized)
    80000eaa:	0000f797          	auipc	a5,0xf
    80000eae:	c267a783          	lw	a5,-986(a5) # 8000fad0 <pmm+0xd0>
    80000eb2:	c7ad                	beqz	a5,80000f1c <free_pages_buddy+0x84>

    void *current_block = page;
    int current_order = order;

    // 尝试合并伙伴块
    while (current_order < MAX_ORDER)
    80000eb4:	47a5                	li	a5,9
    80000eb6:	06b7c863          	blt	a5,a1,80000f26 <free_pages_buddy+0x8e>
    80000eba:	00258893          	addi	a7,a1,2
    80000ebe:	00489793          	slli	a5,a7,0x4
    80000ec2:	0000f897          	auipc	a7,0xf
    80000ec6:	b3e88893          	addi	a7,a7,-1218 # 8000fa00 <pmm>
    80000eca:	98be                	add	a7,a7,a5
    int current_order = order;
    80000ecc:	862e                	mv	a2,a1
    uint64 block_size = PGSIZE * (1UL << order);
    80000ece:	6e85                	lui	t4,0x1
    return (addr_val >= pmm.base_addr && addr_val < pmm.end_addr);
    80000ed0:	0000f317          	auipc	t1,0xf
    80000ed4:	b3030313          	addi	t1,t1,-1232 # 8000fa00 <pmm>
    while (current_order < MAX_ORDER)
    80000ed8:	4f29                	li	t5,10
    uint64 block_size = PGSIZE * (1UL << order);
    80000eda:	00ce9833          	sll	a6,t4,a2
    uint64 buddy_addr = block_addr ^ block_size;
    80000ede:	01054833          	xor	a6,a0,a6
    return (void *)buddy_addr;
    80000ee2:	8742                	mv	a4,a6
    return (addr_val >= pmm.base_addr && addr_val < pmm.end_addr);
    80000ee4:	01033783          	ld	a5,16(t1)
    80000ee8:	00f86663          	bltu	a6,a5,80000ef4 <free_pages_buddy+0x5c>
    80000eec:	01833783          	ld	a5,24(t1)
    80000ef0:	02f86d63          	bltu	a6,a5,80000f2a <free_pages_buddy+0x92>
        // printf("PMM: Merged to order %d, block at 0x%p\n", current_order, current_block);
    }

    // 将块加入对应阶的空闲链表
    struct free_page *new_block = (struct free_page *)current_block;
    new_block->next = pmm.free_area[current_order].free_list;
    80000ef4:	0000f717          	auipc	a4,0xf
    80000ef8:	b0c70713          	addi	a4,a4,-1268 # 8000fa00 <pmm>
    80000efc:	00260793          	addi	a5,a2,2
    80000f00:	0792                	slli	a5,a5,0x4
    80000f02:	97ba                	add	a5,a5,a4
    80000f04:	6394                	ld	a3,0(a5)
    80000f06:	e114                	sd	a3,0(a0)
    pmm.free_area[current_order].free_list = new_block;
    80000f08:	e388                	sd	a0,0(a5)
    pmm.free_area[current_order].nr_free++;
    80000f0a:	4794                	lw	a3,8(a5)
    80000f0c:	2685                	addiw	a3,a3,1
    80000f0e:	c794                	sw	a3,8(a5)

    int freed_pages = 1 << order;
    pmm.free_pages += freed_pages;
    80000f10:	4785                	li	a5,1
    80000f12:	00b797bb          	sllw	a5,a5,a1
    80000f16:	670c                	ld	a1,8(a4)
    80000f18:	95be                	add	a1,a1,a5
    80000f1a:	e70c                	sd	a1,8(a4)

    // printf("PMM: Freed %d pages, added to order %d\n", freed_pages, current_order);
}
    80000f1c:	6422                	ld	s0,8(sp)
    80000f1e:	0141                	addi	sp,sp,16
    80000f20:	8082                	ret
        struct free_page **prev = &pmm.free_area[current_order].free_list;
    80000f22:	86f2                	mv	a3,t3
    80000f24:	a831                	j	80000f40 <free_pages_buddy+0xa8>
    int current_order = order;
    80000f26:	862e                	mv	a2,a1
    80000f28:	b7f1                	j	80000ef4 <free_pages_buddy+0x5c>
        struct free_page *curr = pmm.free_area[current_order].free_list;
    80000f2a:	8e46                	mv	t3,a7
    80000f2c:	0008b783          	ld	a5,0(a7)
        while (curr != NULL)
    80000f30:	d3f1                	beqz	a5,80000ef4 <free_pages_buddy+0x5c>
            if (curr == buddy)
    80000f32:	fee788e3          	beq	a5,a4,80000f22 <free_pages_buddy+0x8a>
            curr = curr->next;
    80000f36:	86be                	mv	a3,a5
    80000f38:	639c                	ld	a5,0(a5)
        while (curr != NULL)
    80000f3a:	dfcd                	beqz	a5,80000ef4 <free_pages_buddy+0x5c>
            if (curr == buddy)
    80000f3c:	fee79de3          	bne	a5,a4,80000f36 <free_pages_buddy+0x9e>
                *prev = curr->next;
    80000f40:	00083783          	ld	a5,0(a6) # 1000 <_entry-0x7ffff000>
    80000f44:	e29c                	sd	a5,0(a3)
                pmm.free_area[current_order].nr_free--;
    80000f46:	008e2783          	lw	a5,8(t3)
    80000f4a:	37fd                	addiw	a5,a5,-1
    80000f4c:	00fe2423          	sw	a5,8(t3)
        if (current_block > buddy)
    80000f50:	00a77363          	bgeu	a4,a0,80000f56 <free_pages_buddy+0xbe>
    80000f54:	8542                	mv	a0,a6
        current_order++;
    80000f56:	2605                	addiw	a2,a2,1
    while (current_order < MAX_ORDER)
    80000f58:	08c1                	addi	a7,a7,16
    80000f5a:	f9e610e3          	bne	a2,t5,80000eda <free_pages_buddy+0x42>
    80000f5e:	bf59                	j	80000ef4 <free_pages_buddy+0x5c>

0000000080000f60 <get_order>:

// 获取合适的阶
int get_order(int n)
{
    80000f60:	1141                	addi	sp,sp,-16
    80000f62:	e422                	sd	s0,8(sp)
    80000f64:	0800                	addi	s0,sp,16
    if (n <= 0)
    80000f66:	02a05663          	blez	a0,80000f92 <get_order+0x32>
    80000f6a:	86aa                	mv	a3,a0
        return -1;
    if (n == 1)
    80000f6c:	4785                	li	a5,1
        return 0;
    80000f6e:	4501                	li	a0,0
    if (n == 1)
    80000f70:	00f68e63          	beq	a3,a5,80000f8c <get_order+0x2c>

    int order = 0;
    80000f74:	4701                	li	a4,0
    int size = 1;
    while (size < n)
    {
        size <<= 1;
    80000f76:	0017979b          	slliw	a5,a5,0x1
        order++;
    80000f7a:	2705                	addiw	a4,a4,1
    while (size < n)
    80000f7c:	fed7cde3          	blt	a5,a3,80000f76 <get_order+0x16>
    }

    if (order > MAX_ORDER)
    80000f80:	853a                	mv	a0,a4
    80000f82:	47a9                	li	a5,10
    80000f84:	00e7d363          	bge	a5,a4,80000f8a <get_order+0x2a>
    80000f88:	4529                	li	a0,10
    80000f8a:	2501                	sext.w	a0,a0
        order = MAX_ORDER;
    return order;
}
    80000f8c:	6422                	ld	s0,8(sp)
    80000f8e:	0141                	addi	sp,sp,16
    80000f90:	8082                	ret
        return -1;
    80000f92:	557d                	li	a0,-1
    80000f94:	bfe5                	j	80000f8c <get_order+0x2c>

0000000080000f96 <pmm_init>:

// 初始化物理内存管理器
void pmm_init(void)
{
    80000f96:	1141                	addi	sp,sp,-16
    80000f98:	e406                	sd	ra,8(sp)
    80000f9a:	e022                	sd	s0,0(sp)
    80000f9c:	0800                	addi	s0,sp,16
    pmm.base_addr = PGROUNDUP((uint64)end);
    80000f9e:	00466797          	auipc	a5,0x466
    80000fa2:	e4178793          	addi	a5,a5,-447 # 80466ddf <end+0xfff>
    80000fa6:	76fd                	lui	a3,0xfffff
    80000fa8:	8efd                	and	a3,a3,a5
    80000faa:	0000f717          	auipc	a4,0xf
    80000fae:	a5670713          	addi	a4,a4,-1450 # 8000fa00 <pmm>
    80000fb2:	eb14                	sd	a3,16(a4)
    pmm.end_addr = PGROUNDDOWN(PHYSICAL_TOP);
    80000fb4:	47c5                	li	a5,17
    80000fb6:	07ee                	slli	a5,a5,0x1b
    80000fb8:	ef1c                	sd	a5,24(a4)
    pmm.total_pages = (pmm.end_addr - pmm.base_addr) / PGSIZE;
    80000fba:	8f95                	sub	a5,a5,a3
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	e31c                	sd	a5,0(a4)
    pmm.free_pages = 0;
    80000fc0:	00073423          	sd	zero,8(a4)
    pmm.initialized = 0;
    80000fc4:	0c072823          	sw	zero,208(a4)

    // printf("PMM: Initializing memory manager\n");
    // printf("PMM: Memory range: 0x%p to 0x%p (%d pages)\n",
    //        (void*)pmm.base_addr, (void*)pmm.end_addr, pmm.total_pages);

    buddy_system_init();
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	c94080e7          	jalr	-876(ra) # 80000c5c <buddy_system_init>
}
    80000fd0:	60a2                	ld	ra,8(sp)
    80000fd2:	6402                	ld	s0,0(sp)
    80000fd4:	0141                	addi	sp,sp,16
    80000fd6:	8082                	ret

0000000080000fd8 <alloc_page>:

// 分配单个物理页
void *alloc_page(void)
{
    80000fd8:	1141                	addi	sp,sp,-16
    80000fda:	e406                	sd	ra,8(sp)
    80000fdc:	e022                	sd	s0,0(sp)
    80000fde:	0800                	addi	s0,sp,16
    return alloc_pages_buddy(0);
    80000fe0:	4501                	li	a0,0
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	dcc080e7          	jalr	-564(ra) # 80000dae <alloc_pages_buddy>
}
    80000fea:	60a2                	ld	ra,8(sp)
    80000fec:	6402                	ld	s0,0(sp)
    80000fee:	0141                	addi	sp,sp,16
    80000ff0:	8082                	ret

0000000080000ff2 <free_page>:

// 释放单个物理页
void free_page(void *page)
{
    80000ff2:	1141                	addi	sp,sp,-16
    80000ff4:	e406                	sd	ra,8(sp)
    80000ff6:	e022                	sd	s0,0(sp)
    80000ff8:	0800                	addi	s0,sp,16
    free_pages_buddy(page, 0);
    80000ffa:	4581                	li	a1,0
    80000ffc:	00000097          	auipc	ra,0x0
    80001000:	e9c080e7          	jalr	-356(ra) # 80000e98 <free_pages_buddy>
}
    80001004:	60a2                	ld	ra,8(sp)
    80001006:	6402                	ld	s0,0(sp)
    80001008:	0141                	addi	sp,sp,16
    8000100a:	8082                	ret

000000008000100c <alloc_pages>:

// 分配连续的n个页面
void *alloc_pages(int n)
{
    if (n <= 0)
    8000100c:	02a05263          	blez	a0,80001030 <alloc_pages+0x24>
{
    80001010:	1141                	addi	sp,sp,-16
    80001012:	e406                	sd	ra,8(sp)
    80001014:	e022                	sd	s0,0(sp)
    80001016:	0800                	addi	s0,sp,16
        return NULL;
    int order = get_order(n);
    80001018:	00000097          	auipc	ra,0x0
    8000101c:	f48080e7          	jalr	-184(ra) # 80000f60 <get_order>
    return alloc_pages_buddy(order);
    80001020:	00000097          	auipc	ra,0x0
    80001024:	d8e080e7          	jalr	-626(ra) # 80000dae <alloc_pages_buddy>
}
    80001028:	60a2                	ld	ra,8(sp)
    8000102a:	6402                	ld	s0,0(sp)
    8000102c:	0141                	addi	sp,sp,16
    8000102e:	8082                	ret
        return NULL;
    80001030:	4501                	li	a0,0
}
    80001032:	8082                	ret

0000000080001034 <pmm_stats>:

// 获取内存统计信息
void pmm_stats(void)
{
    80001034:	7139                	addi	sp,sp,-64
    80001036:	fc06                	sd	ra,56(sp)
    80001038:	f822                	sd	s0,48(sp)
    8000103a:	f426                	sd	s1,40(sp)
    8000103c:	f04a                	sd	s2,32(sp)
    8000103e:	ec4e                	sd	s3,24(sp)
    80001040:	e852                	sd	s4,16(sp)
    80001042:	e456                	sd	s5,8(sp)
    80001044:	0080                	addi	s0,sp,64
    printf("=== Physical Memory Manager Statistics ===\n");
    80001046:	00009517          	auipc	a0,0x9
    8000104a:	1ca50513          	addi	a0,a0,458 # 8000a210 <digits+0x60>
    8000104e:	fffff097          	auipc	ra,0xfffff
    80001052:	4b6080e7          	jalr	1206(ra) # 80000504 <printf>
    printf("Total pages:    %d\n", pmm.total_pages);
    80001056:	0000f497          	auipc	s1,0xf
    8000105a:	9aa48493          	addi	s1,s1,-1622 # 8000fa00 <pmm>
    8000105e:	608c                	ld	a1,0(s1)
    80001060:	00009517          	auipc	a0,0x9
    80001064:	1e050513          	addi	a0,a0,480 # 8000a240 <digits+0x90>
    80001068:	fffff097          	auipc	ra,0xfffff
    8000106c:	49c080e7          	jalr	1180(ra) # 80000504 <printf>
    printf("Free pages:     %d\n", pmm.free_pages);
    80001070:	648c                	ld	a1,8(s1)
    80001072:	00009517          	auipc	a0,0x9
    80001076:	1e650513          	addi	a0,a0,486 # 8000a258 <digits+0xa8>
    8000107a:	fffff097          	auipc	ra,0xfffff
    8000107e:	48a080e7          	jalr	1162(ra) # 80000504 <printf>
    printf("Used pages:     %d\n", pmm.total_pages - pmm.free_pages);
    80001082:	608c                	ld	a1,0(s1)
    80001084:	649c                	ld	a5,8(s1)
    80001086:	8d9d                	sub	a1,a1,a5
    80001088:	00009517          	auipc	a0,0x9
    8000108c:	1e850513          	addi	a0,a0,488 # 8000a270 <digits+0xc0>
    80001090:	fffff097          	auipc	ra,0xfffff
    80001094:	474080e7          	jalr	1140(ra) # 80000504 <printf>
    printf("Memory usage:   %d/%d KB\n",
           (pmm.total_pages - pmm.free_pages) * 4,
    80001098:	6090                	ld	a2,0(s1)
    8000109a:	648c                	ld	a1,8(s1)
    8000109c:	40b605b3          	sub	a1,a2,a1
    printf("Memory usage:   %d/%d KB\n",
    800010a0:	060a                	slli	a2,a2,0x2
    800010a2:	058a                	slli	a1,a1,0x2
    800010a4:	00009517          	auipc	a0,0x9
    800010a8:	1e450513          	addi	a0,a0,484 # 8000a288 <digits+0xd8>
    800010ac:	fffff097          	auipc	ra,0xfffff
    800010b0:	458080e7          	jalr	1112(ra) # 80000504 <printf>
           pmm.total_pages * 4);
    printf("Base address:   0x%p\n", (void *)pmm.base_addr);
    800010b4:	688c                	ld	a1,16(s1)
    800010b6:	00009517          	auipc	a0,0x9
    800010ba:	1f250513          	addi	a0,a0,498 # 8000a2a8 <digits+0xf8>
    800010be:	fffff097          	auipc	ra,0xfffff
    800010c2:	446080e7          	jalr	1094(ra) # 80000504 <printf>
    printf("End address:    0x%p\n", (void *)pmm.end_addr);
    800010c6:	6c8c                	ld	a1,24(s1)
    800010c8:	00009517          	auipc	a0,0x9
    800010cc:	1f850513          	addi	a0,a0,504 # 8000a2c0 <digits+0x110>
    800010d0:	fffff097          	auipc	ra,0xfffff
    800010d4:	434080e7          	jalr	1076(ra) # 80000504 <printf>

    printf("\nBuddy System Status:\n");
    800010d8:	00009517          	auipc	a0,0x9
    800010dc:	20050513          	addi	a0,a0,512 # 8000a2d8 <digits+0x128>
    800010e0:	fffff097          	auipc	ra,0xfffff
    800010e4:	424080e7          	jalr	1060(ra) # 80000504 <printf>
    for (int i = 0; i <= MAX_ORDER; i++)
    800010e8:	0000f917          	auipc	s2,0xf
    800010ec:	94090913          	addi	s2,s2,-1728 # 8000fa28 <pmm+0x28>
    800010f0:	4481                	li	s1,0
    {
        if (pmm.free_area[i].nr_free > 0)
        {
            printf("  Order %d (%d pages): %d free blocks\n",
    800010f2:	4a85                	li	s5,1
    800010f4:	00009a17          	auipc	s4,0x9
    800010f8:	1fca0a13          	addi	s4,s4,508 # 8000a2f0 <digits+0x140>
    for (int i = 0; i <= MAX_ORDER; i++)
    800010fc:	49ad                	li	s3,11
    800010fe:	a829                	j	80001118 <pmm_stats+0xe4>
            printf("  Order %d (%d pages): %d free blocks\n",
    80001100:	009a963b          	sllw	a2,s5,s1
    80001104:	85a6                	mv	a1,s1
    80001106:	8552                	mv	a0,s4
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	3fc080e7          	jalr	1020(ra) # 80000504 <printf>
    for (int i = 0; i <= MAX_ORDER; i++)
    80001110:	2485                	addiw	s1,s1,1
    80001112:	0941                	addi	s2,s2,16
    80001114:	01348763          	beq	s1,s3,80001122 <pmm_stats+0xee>
        if (pmm.free_area[i].nr_free > 0)
    80001118:	00092683          	lw	a3,0(s2)
    8000111c:	fed05ae3          	blez	a3,80001110 <pmm_stats+0xdc>
    80001120:	b7c5                	j	80001100 <pmm_stats+0xcc>
                   i, (1 << i), pmm.free_area[i].nr_free);
        }
    }
}
    80001122:	70e2                	ld	ra,56(sp)
    80001124:	7442                	ld	s0,48(sp)
    80001126:	74a2                	ld	s1,40(sp)
    80001128:	7902                	ld	s2,32(sp)
    8000112a:	69e2                	ld	s3,24(sp)
    8000112c:	6a42                	ld	s4,16(sp)
    8000112e:	6aa2                	ld	s5,8(sp)
    80001130:	6121                	addi	sp,sp,64
    80001132:	8082                	ret

0000000080001134 <get_free_memory>:

// 获取空闲内存大小
uint64 get_free_memory(void)
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e422                	sd	s0,8(sp)
    80001138:	0800                	addi	s0,sp,16
    return pmm.free_pages * PGSIZE;
}
    8000113a:	0000f517          	auipc	a0,0xf
    8000113e:	8ce53503          	ld	a0,-1842(a0) # 8000fa08 <pmm+0x8>
    80001142:	0532                	slli	a0,a0,0xc
    80001144:	6422                	ld	s0,8(sp)
    80001146:	0141                	addi	sp,sp,16
    80001148:	8082                	ret

000000008000114a <get_total_memory>:

// 获取总内存大小
uint64 get_total_memory(void)
{
    8000114a:	1141                	addi	sp,sp,-16
    8000114c:	e422                	sd	s0,8(sp)
    8000114e:	0800                	addi	s0,sp,16
    return pmm.total_pages * PGSIZE;
}
    80001150:	0000f517          	auipc	a0,0xf
    80001154:	8b053503          	ld	a0,-1872(a0) # 8000fa00 <pmm>
    80001158:	0532                	slli	a0,a0,0xc
    8000115a:	6422                	ld	s0,8(sp)
    8000115c:	0141                	addi	sp,sp,16
    8000115e:	8082                	ret

0000000080001160 <test_4page_allocation>:

// 测试4页分配功能
void test_4page_allocation(void)
{
    80001160:	1101                	addi	sp,sp,-32
    80001162:	ec06                	sd	ra,24(sp)
    80001164:	e822                	sd	s0,16(sp)
    80001166:	e426                	sd	s1,8(sp)
    80001168:	1000                	addi	s0,sp,32
    printf("\n=== Testing 4-Page Allocation ===\n\n");
    8000116a:	00009517          	auipc	a0,0x9
    8000116e:	1ae50513          	addi	a0,a0,430 # 8000a318 <digits+0x168>
    80001172:	fffff097          	auipc	ra,0xfffff
    80001176:	392080e7          	jalr	914(ra) # 80000504 <printf>

    pmm_stats();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	eba080e7          	jalr	-326(ra) # 80001034 <pmm_stats>

    printf("1. Allocating 4 pages...\n");
    80001182:	00009517          	auipc	a0,0x9
    80001186:	1be50513          	addi	a0,a0,446 # 8000a340 <digits+0x190>
    8000118a:	fffff097          	auipc	ra,0xfffff
    8000118e:	37a080e7          	jalr	890(ra) # 80000504 <printf>
    void *pages4 = alloc_pages(4);
    80001192:	4511                	li	a0,4
    80001194:	00000097          	auipc	ra,0x0
    80001198:	e78080e7          	jalr	-392(ra) # 8000100c <alloc_pages>

    if (pages4)
    8000119c:	cd61                	beqz	a0,80001274 <test_4page_allocation+0x114>
    8000119e:	84aa                	mv	s1,a0
    {
        printf("   SUCCESS: Allocated 4 pages at 0x%p\n", pages4);
    800011a0:	85aa                	mv	a1,a0
    800011a2:	00009517          	auipc	a0,0x9
    800011a6:	1be50513          	addi	a0,a0,446 # 8000a360 <digits+0x1b0>
    800011aa:	fffff097          	auipc	ra,0xfffff
    800011ae:	35a080e7          	jalr	858(ra) # 80000504 <printf>

        printf("2. Testing data access in 4 pages...\n");
    800011b2:	00009517          	auipc	a0,0x9
    800011b6:	1d650513          	addi	a0,a0,470 # 8000a388 <digits+0x1d8>
    800011ba:	fffff097          	auipc	ra,0xfffff
    800011be:	34a080e7          	jalr	842(ra) # 80000504 <printf>
        {
            uint64 *page_data = (uint64 *)((uint64)pages4 + page * PGSIZE);
            uint64 test_value = 0x1234567890ABCD00 + page;

            // 写入测试数据
            page_data[0] = test_value;
    800011c2:	00009797          	auipc	a5,0x9
    800011c6:	e3e7b783          	ld	a5,-450(a5) # 8000a000 <etext>
    800011ca:	e09c                	sd	a5,0(s1)
            page_data[PGSIZE / sizeof(uint64) - 1] = test_value + 1;
    800011cc:	6685                	lui	a3,0x1
    800011ce:	00d48733          	add	a4,s1,a3
    800011d2:	00009797          	auipc	a5,0x9
    800011d6:	e367b783          	ld	a5,-458(a5) # 8000a008 <etext+0x8>
    800011da:	fef73c23          	sd	a5,-8(a4)
            page_data[0] = test_value;
    800011de:	e31c                	sd	a5,0(a4)
            page_data[PGSIZE / sizeof(uint64) - 1] = test_value + 1;
    800011e0:	9736                	add	a4,a4,a3
    800011e2:	00009797          	auipc	a5,0x9
    800011e6:	e2e7b783          	ld	a5,-466(a5) # 8000a010 <etext+0x10>
    800011ea:	fef73c23          	sd	a5,-8(a4)
            uint64 *page_data = (uint64 *)((uint64)pages4 + page * PGSIZE);
    800011ee:	6709                	lui	a4,0x2
    800011f0:	9726                	add	a4,a4,s1
            page_data[0] = test_value;
    800011f2:	e31c                	sd	a5,0(a4)
            page_data[PGSIZE / sizeof(uint64) - 1] = test_value + 1;
    800011f4:	9736                	add	a4,a4,a3
    800011f6:	00009617          	auipc	a2,0x9
    800011fa:	e2263603          	ld	a2,-478(a2) # 8000a018 <etext+0x18>
    800011fe:	fec73c23          	sd	a2,-8(a4) # 1ff8 <_entry-0x7fffe008>
            uint64 *page_data = (uint64 *)((uint64)pages4 + page * PGSIZE);
    80001202:	678d                	lui	a5,0x3
    80001204:	97a6                	add	a5,a5,s1
            page_data[0] = test_value;
    80001206:	e390                	sd	a2,0(a5)
            page_data[PGSIZE / sizeof(uint64) - 1] = test_value + 1;
    80001208:	97b6                	add	a5,a5,a3
    8000120a:	00009717          	auipc	a4,0x9
    8000120e:	e1673703          	ld	a4,-490(a4) # 8000a020 <etext+0x20>
    80001212:	fee7bc23          	sd	a4,-8(a5) # 2ff8 <_entry-0x7fffd008>
            }
        }

        if (success)
        {
            printf("   SUCCESS: All 4 pages data access works\n");
    80001216:	00009517          	auipc	a0,0x9
    8000121a:	19a50513          	addi	a0,a0,410 # 8000a3b0 <digits+0x200>
    8000121e:	fffff097          	auipc	ra,0xfffff
    80001222:	2e6080e7          	jalr	742(ra) # 80000504 <printf>
        }

        printf("3. Freeing 4 pages...\n");
    80001226:	00009517          	auipc	a0,0x9
    8000122a:	1ba50513          	addi	a0,a0,442 # 8000a3e0 <digits+0x230>
    8000122e:	fffff097          	auipc	ra,0xfffff
    80001232:	2d6080e7          	jalr	726(ra) # 80000504 <printf>
        free_pages_buddy(pages4, 2); // order 2 = 4 pages
    80001236:	4589                	li	a1,2
    80001238:	8526                	mv	a0,s1
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	c5e080e7          	jalr	-930(ra) # 80000e98 <free_pages_buddy>
        printf("   SUCCESS: Freed 4 pages\n");
    80001242:	00009517          	auipc	a0,0x9
    80001246:	1b650513          	addi	a0,a0,438 # 8000a3f8 <digits+0x248>
    8000124a:	fffff097          	auipc	ra,0xfffff
    8000124e:	2ba080e7          	jalr	698(ra) # 80000504 <printf>

        pmm_stats();
    80001252:	00000097          	auipc	ra,0x0
    80001256:	de2080e7          	jalr	-542(ra) # 80001034 <pmm_stats>
        printf("\n=== 4-Page Allocation Test PASSED ===\n");
    8000125a:	00009517          	auipc	a0,0x9
    8000125e:	1be50513          	addi	a0,a0,446 # 8000a418 <digits+0x268>
    80001262:	fffff097          	auipc	ra,0xfffff
    80001266:	2a2080e7          	jalr	674(ra) # 80000504 <printf>
    else
    {
        printf("   FAILED: Could not allocate 4 pages\n");
        printf("\n=== 4-Page Allocation Test FAILED ===\n");
    }
}
    8000126a:	60e2                	ld	ra,24(sp)
    8000126c:	6442                	ld	s0,16(sp)
    8000126e:	64a2                	ld	s1,8(sp)
    80001270:	6105                	addi	sp,sp,32
    80001272:	8082                	ret
        printf("   FAILED: Could not allocate 4 pages\n");
    80001274:	00009517          	auipc	a0,0x9
    80001278:	1cc50513          	addi	a0,a0,460 # 8000a440 <digits+0x290>
    8000127c:	fffff097          	auipc	ra,0xfffff
    80001280:	288080e7          	jalr	648(ra) # 80000504 <printf>
        printf("\n=== 4-Page Allocation Test FAILED ===\n");
    80001284:	00009517          	auipc	a0,0x9
    80001288:	1e450513          	addi	a0,a0,484 # 8000a468 <digits+0x2b8>
    8000128c:	fffff097          	auipc	ra,0xfffff
    80001290:	278080e7          	jalr	632(ra) # 80000504 <printf>
}
    80001294:	bfd9                	j	8000126a <test_4page_allocation+0x10a>

0000000080001296 <test_buddy_system_comprehensive>:

// 伙伴系统完整测试
void test_buddy_system_comprehensive(void)
{
    80001296:	7179                	addi	sp,sp,-48
    80001298:	f406                	sd	ra,40(sp)
    8000129a:	f022                	sd	s0,32(sp)
    8000129c:	ec26                	sd	s1,24(sp)
    8000129e:	e84a                	sd	s2,16(sp)
    800012a0:	e44e                	sd	s3,8(sp)
    800012a2:	1800                	addi	s0,sp,48
    printf("\n=== Comprehensive Buddy System Test ===\n\n");
    800012a4:	00009517          	auipc	a0,0x9
    800012a8:	1ec50513          	addi	a0,a0,492 # 8000a490 <digits+0x2e0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	258080e7          	jalr	600(ra) # 80000504 <printf>

    // 初始状态
    printf("1. Initial System State:\n");
    800012b4:	00009517          	auipc	a0,0x9
    800012b8:	20c50513          	addi	a0,a0,524 # 8000a4c0 <digits+0x310>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	248080e7          	jalr	584(ra) # 80000504 <printf>
    pmm_stats();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	d70080e7          	jalr	-656(ra) # 80001034 <pmm_stats>

    // 测试1: 基本单页分配
    printf("\n2. Testing Single Page Allocation:\n");
    800012cc:	00009517          	auipc	a0,0x9
    800012d0:	21450513          	addi	a0,a0,532 # 8000a4e0 <digits+0x330>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	230080e7          	jalr	560(ra) # 80000504 <printf>
    void *page1 = alloc_page();
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	cfc080e7          	jalr	-772(ra) # 80000fd8 <alloc_page>
    800012e4:	892a                	mv	s2,a0
    void *page2 = alloc_page();
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	cf2080e7          	jalr	-782(ra) # 80000fd8 <alloc_page>
    800012ee:	84aa                	mv	s1,a0
    void *page3 = alloc_page();
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	ce8080e7          	jalr	-792(ra) # 80000fd8 <alloc_page>

    if (page1 && page2 && page3)
    800012f8:	06090163          	beqz	s2,8000135a <test_buddy_system_comprehensive+0xc4>
    800012fc:	ccb9                	beqz	s1,8000135a <test_buddy_system_comprehensive+0xc4>
    800012fe:	cd31                	beqz	a0,8000135a <test_buddy_system_comprehensive+0xc4>
    {
        printf("   SUCCESS: Allocated single pages: 0x%p, 0x%p, 0x%p\n", page1, page2, page3);
    80001300:	86aa                	mv	a3,a0
    80001302:	8626                	mv	a2,s1
    80001304:	85ca                	mv	a1,s2
    80001306:	00009517          	auipc	a0,0x9
    8000130a:	20250513          	addi	a0,a0,514 # 8000a508 <digits+0x358>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	1f6080e7          	jalr	502(ra) # 80000504 <printf>

        // 测试数据访问
        *(uint64 *)page1 = 0x12345678;
    80001316:	12345737          	lui	a4,0x12345
    8000131a:	67870713          	addi	a4,a4,1656 # 12345678 <_entry-0x6dcba988>
    8000131e:	00e93023          	sd	a4,0(s2)
        *(uint64 *)page2 = 0x87654321;
    80001322:	21d957b7          	lui	a5,0x21d95
    80001326:	078a                	slli	a5,a5,0x2
    80001328:	32178793          	addi	a5,a5,801 # 21d95321 <_entry-0x5e26acdf>
    8000132c:	e09c                	sd	a5,0(s1)
        if (*(uint64 *)page1 == 0x12345678 && *(uint64 *)page2 == 0x87654321)
    8000132e:	00093783          	ld	a5,0(s2)
    80001332:	00e78b63          	beq	a5,a4,80001348 <test_buddy_system_comprehensive+0xb2>
        {
            printf("   SUCCESS: Single page data access works\n");
        }
        else
        {
            printf("   FAIL: Single page data access failed\n");
    80001336:	00009517          	auipc	a0,0x9
    8000133a:	23a50513          	addi	a0,a0,570 # 8000a570 <digits+0x3c0>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	1c6080e7          	jalr	454(ra) # 80000504 <printf>
    80001346:	a015                	j	8000136a <test_buddy_system_comprehensive+0xd4>
            printf("   SUCCESS: Single page data access works\n");
    80001348:	00009517          	auipc	a0,0x9
    8000134c:	1f850513          	addi	a0,a0,504 # 8000a540 <digits+0x390>
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	1b4080e7          	jalr	436(ra) # 80000504 <printf>
    80001358:	a809                	j	8000136a <test_buddy_system_comprehensive+0xd4>
        }
    }
    else
    {
        printf("   FAIL: Single page allocation failed\n");
    8000135a:	00009517          	auipc	a0,0x9
    8000135e:	24650513          	addi	a0,a0,582 # 8000a5a0 <digits+0x3f0>
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	1a2080e7          	jalr	418(ra) # 80000504 <printf>
    }

    // 测试2: 不同大小的连续页面分配
    printf("\n3. Testing Different Size Allocations:\n");
    8000136a:	00009517          	auipc	a0,0x9
    8000136e:	25e50513          	addi	a0,a0,606 # 8000a5c8 <digits+0x418>
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	192080e7          	jalr	402(ra) # 80000504 <printf>

    // 分配4页
    void *pages4 = alloc_pages(4);
    8000137a:	4511                	li	a0,4
    8000137c:	00000097          	auipc	ra,0x0
    80001380:	c90080e7          	jalr	-880(ra) # 8000100c <alloc_pages>
    80001384:	84aa                	mv	s1,a0
    if (pages4)
    80001386:	24050363          	beqz	a0,800015cc <test_buddy_system_comprehensive+0x336>
    {
        printf("   SUCCESS: Allocated 4 pages at 0x%p\n", pages4);
    8000138a:	85aa                	mv	a1,a0
    8000138c:	00009517          	auipc	a0,0x9
    80001390:	fd450513          	addi	a0,a0,-44 # 8000a360 <digits+0x1b0>
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	170080e7          	jalr	368(ra) # 80000504 <printf>
        // 测试4页数据访问
        int success = 1;
        for (int i = 0; i < 4; i++)
        {
            uint64 *addr = (uint64 *)((uint64)pages4 + i * PGSIZE);
            *addr = 0xABCDEF0123456789 + i;
    8000139c:	00009797          	auipc	a5,0x9
    800013a0:	c8c7b783          	ld	a5,-884(a5) # 8000a028 <etext+0x28>
    800013a4:	e09c                	sd	a5,0(s1)
    800013a6:	6785                	lui	a5,0x1
    800013a8:	97a6                	add	a5,a5,s1
    800013aa:	00009717          	auipc	a4,0x9
    800013ae:	c8673703          	ld	a4,-890(a4) # 8000a030 <etext+0x30>
    800013b2:	e398                	sd	a4,0(a5)
    800013b4:	6789                	lui	a5,0x2
    800013b6:	97a6                	add	a5,a5,s1
    800013b8:	00009717          	auipc	a4,0x9
    800013bc:	c8073703          	ld	a4,-896(a4) # 8000a038 <etext+0x38>
    800013c0:	e398                	sd	a4,0(a5)
    800013c2:	678d                	lui	a5,0x3
    800013c4:	97a6                	add	a5,a5,s1
    800013c6:	00009717          	auipc	a4,0x9
    800013ca:	c7a73703          	ld	a4,-902(a4) # 8000a040 <etext+0x40>
    800013ce:	e398                	sd	a4,0(a5)
            {
                success = 0;
                break;
            }
        }
        printf("   %s: 4-page data access test\n", success ? "SUCCESS" : "FAIL");
    800013d0:	00009597          	auipc	a1,0x9
    800013d4:	22858593          	addi	a1,a1,552 # 8000a5f8 <digits+0x448>
    800013d8:	00009517          	auipc	a0,0x9
    800013dc:	22850513          	addi	a0,a0,552 # 8000a600 <digits+0x450>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	124080e7          	jalr	292(ra) # 80000504 <printf>
    {
        printf("   FAIL: 4-page allocation failed\n");
    }

    // 分配8页
    void *pages8 = alloc_pages(8);
    800013e8:	4521                	li	a0,8
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	c22080e7          	jalr	-990(ra) # 8000100c <alloc_pages>
    800013f2:	85aa                	mv	a1,a0
    if (pages8)
    800013f4:	1e050563          	beqz	a0,800015de <test_buddy_system_comprehensive+0x348>
    {
        printf("   SUCCESS: Allocated 8 pages at 0x%p\n", pages8);
    800013f8:	00009517          	auipc	a0,0x9
    800013fc:	25050513          	addi	a0,a0,592 # 8000a648 <digits+0x498>
    80001400:	fffff097          	auipc	ra,0xfffff
    80001404:	104080e7          	jalr	260(ra) # 80000504 <printf>
    {
        printf("   FAIL: 8-page allocation failed\n");
    }

    // 分配16页
    void *pages16 = alloc_pages(16);
    80001408:	4541                	li	a0,16
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	c02080e7          	jalr	-1022(ra) # 8000100c <alloc_pages>
    80001412:	85aa                	mv	a1,a0
    if (pages16)
    80001414:	1c050e63          	beqz	a0,800015f0 <test_buddy_system_comprehensive+0x35a>
    {
        printf("   SUCCESS: Allocated 16 pages at 0x%p\n", pages16);
    80001418:	00009517          	auipc	a0,0x9
    8000141c:	28050513          	addi	a0,a0,640 # 8000a698 <digits+0x4e8>
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	0e4080e7          	jalr	228(ra) # 80000504 <printf>
    {
        printf("   FAIL: 16-page allocation failed\n");
    }

    // 测试3: 中间状态检查
    printf("\n4. Intermediate State Check:\n");
    80001428:	00009517          	auipc	a0,0x9
    8000142c:	2c050513          	addi	a0,a0,704 # 8000a6e8 <digits+0x538>
    80001430:	fffff097          	auipc	ra,0xfffff
    80001434:	0d4080e7          	jalr	212(ra) # 80000504 <printf>
    pmm_stats();
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	bfc080e7          	jalr	-1028(ra) # 80001034 <pmm_stats>

    // 测试4: 释放和重新分配测试
    printf("\n5. Free and Reallocation Test:\n");
    80001440:	00009517          	auipc	a0,0x9
    80001444:	2c850513          	addi	a0,a0,712 # 8000a708 <digits+0x558>
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	0bc080e7          	jalr	188(ra) # 80000504 <printf>

    // 释放一些页面
    if (pages4)
    80001450:	c085                	beqz	s1,80001470 <test_buddy_system_comprehensive+0x1da>
    {
        free_pages_buddy(pages4, 2); // order 2 = 4 pages
    80001452:	4589                	li	a1,2
    80001454:	8526                	mv	a0,s1
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	a42080e7          	jalr	-1470(ra) # 80000e98 <free_pages_buddy>
        printf("   Freed 4 pages at 0x%p\n", pages4);
    8000145e:	85a6                	mv	a1,s1
    80001460:	00009517          	auipc	a0,0x9
    80001464:	2d050513          	addi	a0,a0,720 # 8000a730 <digits+0x580>
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	09c080e7          	jalr	156(ra) # 80000504 <printf>
    }

    if (page1)
    80001470:	02090063          	beqz	s2,80001490 <test_buddy_system_comprehensive+0x1fa>
    {
        free_page(page1);
    80001474:	854a                	mv	a0,s2
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	b7c080e7          	jalr	-1156(ra) # 80000ff2 <free_page>
        printf("   Freed single page at 0x%p\n", page1);
    8000147e:	85ca                	mv	a1,s2
    80001480:	00009517          	auipc	a0,0x9
    80001484:	2d050513          	addi	a0,a0,720 # 8000a750 <digits+0x5a0>
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	07c080e7          	jalr	124(ra) # 80000504 <printf>
    }

    // 检查释放后的状态
    printf("\n6. State After Free:\n");
    80001490:	00009517          	auipc	a0,0x9
    80001494:	2e050513          	addi	a0,a0,736 # 8000a770 <digits+0x5c0>
    80001498:	fffff097          	auipc	ra,0xfffff
    8000149c:	06c080e7          	jalr	108(ra) # 80000504 <printf>
    pmm_stats();
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	b94080e7          	jalr	-1132(ra) # 80001034 <pmm_stats>

    // 重新分配相同大小的页面
    void *pages4_again = alloc_pages(4);
    800014a8:	4511                	li	a0,4
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	b62080e7          	jalr	-1182(ra) # 8000100c <alloc_pages>
    800014b2:	84aa                	mv	s1,a0
    if (pages4_again)
    800014b4:	14050763          	beqz	a0,80001602 <test_buddy_system_comprehensive+0x36c>
    {
        printf("   SUCCESS: Reallocated 4 pages at 0x%p\n", pages4_again);
    800014b8:	85aa                	mv	a1,a0
    800014ba:	00009517          	auipc	a0,0x9
    800014be:	2ce50513          	addi	a0,a0,718 # 8000a788 <digits+0x5d8>
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	042080e7          	jalr	66(ra) # 80000504 <printf>
        // 验证重新分配的页面可用
        int realloc_success = 1;
        for (int i = 0; i < 4; i++)
        {
            uint64 *addr = (uint64 *)((uint64)pages4_again + i * PGSIZE);
            *addr = 0x1122334455667788 + i;
    800014ca:	00009797          	auipc	a5,0x9
    800014ce:	b7e7b783          	ld	a5,-1154(a5) # 8000a048 <etext+0x48>
    800014d2:	e09c                	sd	a5,0(s1)
    800014d4:	6785                	lui	a5,0x1
    800014d6:	97a6                	add	a5,a5,s1
    800014d8:	00009717          	auipc	a4,0x9
    800014dc:	b7873703          	ld	a4,-1160(a4) # 8000a050 <etext+0x50>
    800014e0:	e398                	sd	a4,0(a5)
    800014e2:	6789                	lui	a5,0x2
    800014e4:	97a6                	add	a5,a5,s1
    800014e6:	00009717          	auipc	a4,0x9
    800014ea:	b7273703          	ld	a4,-1166(a4) # 8000a058 <etext+0x58>
    800014ee:	e398                	sd	a4,0(a5)
    800014f0:	650d                	lui	a0,0x3
    800014f2:	94aa                	add	s1,s1,a0
    800014f4:	00009797          	auipc	a5,0x9
    800014f8:	b6c7b783          	ld	a5,-1172(a5) # 8000a060 <etext+0x60>
    800014fc:	e09c                	sd	a5,0(s1)
            {
                realloc_success = 0;
                break;
            }
        }
        printf("   %s: Reallocated page data access\n", realloc_success ? "SUCCESS" : "FAIL");
    800014fe:	00009597          	auipc	a1,0x9
    80001502:	0fa58593          	addi	a1,a1,250 # 8000a5f8 <digits+0x448>
    80001506:	00009517          	auipc	a0,0x9
    8000150a:	2b250513          	addi	a0,a0,690 # 8000a7b8 <digits+0x608>
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	ff6080e7          	jalr	-10(ra) # 80000504 <printf>
    {
        printf("   FAIL: 4-page reallocation failed\n");
    }

    // 测试5: 伙伴合并测试
    printf("\n7. Buddy Merge Test:\n");
    80001516:	00009517          	auipc	a0,0x9
    8000151a:	2f250513          	addi	a0,a0,754 # 8000a808 <digits+0x658>
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	fe6080e7          	jalr	-26(ra) # 80000504 <printf>

    // 分配两个相邻的小块，然后释放看是否能合并
    void *merge_test1 = alloc_pages(32); // order 1
    80001526:	02000513          	li	a0,32
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	ae2080e7          	jalr	-1310(ra) # 8000100c <alloc_pages>
    80001532:	84aa                	mv	s1,a0
    void *merge_test2 = alloc_pages(32); // order 1
    80001534:	02000513          	li	a0,32
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	ad4080e7          	jalr	-1324(ra) # 8000100c <alloc_pages>
    80001540:	892a                	mv	s2,a0

    if (merge_test1 && merge_test2)
    80001542:	c8e9                	beqz	s1,80001614 <test_buddy_system_comprehensive+0x37e>
    80001544:	c961                	beqz	a0,80001614 <test_buddy_system_comprehensive+0x37e>
    {
        printf("   Allocated two order 5 blocks: 0x%p, 0x%p\n", merge_test1, merge_test2);
    80001546:	862a                	mv	a2,a0
    80001548:	85a6                	mv	a1,s1
    8000154a:	00009517          	auipc	a0,0x9
    8000154e:	2d650513          	addi	a0,a0,726 # 8000a820 <digits+0x670>
    80001552:	fffff097          	auipc	ra,0xfffff
    80001556:	fb2080e7          	jalr	-78(ra) # 80000504 <printf>
    uint64 buddy_addr = block_addr ^ block_size;
    8000155a:	000209b7          	lui	s3,0x20

        // 检查它们是否是伙伴
        void *buddy1 = find_buddy(merge_test1, 5);
        void *buddy2 = find_buddy(merge_test2, 5);
        printf("   Buddy of 0x%p is 0x%p\n", merge_test1, buddy1);
    8000155e:	0134c633          	xor	a2,s1,s3
    80001562:	85a6                	mv	a1,s1
    80001564:	00009517          	auipc	a0,0x9
    80001568:	2ec50513          	addi	a0,a0,748 # 8000a850 <digits+0x6a0>
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	f98080e7          	jalr	-104(ra) # 80000504 <printf>
        printf("   Buddy of 0x%p is 0x%p\n", merge_test2, buddy2);
    80001574:	01394633          	xor	a2,s2,s3
    80001578:	85ca                	mv	a1,s2
    8000157a:	00009517          	auipc	a0,0x9
    8000157e:	2d650513          	addi	a0,a0,726 # 8000a850 <digits+0x6a0>
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	f82080e7          	jalr	-126(ra) # 80000504 <printf>

        // 释放并检查合并
        free_pages_buddy(merge_test1, 5);
    8000158a:	4595                	li	a1,5
    8000158c:	8526                	mv	a0,s1
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	90a080e7          	jalr	-1782(ra) # 80000e98 <free_pages_buddy>
        free_pages_buddy(merge_test2, 5);
    80001596:	4595                	li	a1,5
    80001598:	854a                	mv	a0,s2
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	8fe080e7          	jalr	-1794(ra) # 80000e98 <free_pages_buddy>
        printf("   Freed both order 5 blocks\n");
    800015a2:	00009517          	auipc	a0,0x9
    800015a6:	2ce50513          	addi	a0,a0,718 # 8000a870 <digits+0x6c0>
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	f5a080e7          	jalr	-166(ra) # 80000504 <printf>

        // 检查是否合并成了order 6块
        printf("   Checking if blocks merged...\n");
    800015b2:	00009517          	auipc	a0,0x9
    800015b6:	2de50513          	addi	a0,a0,734 # 8000a890 <digits+0x6e0>
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	f4a080e7          	jalr	-182(ra) # 80000504 <printf>
        pmm_stats();
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	a72080e7          	jalr	-1422(ra) # 80001034 <pmm_stats>
    {
    800015ca:	a8a9                	j	80001624 <test_buddy_system_comprehensive+0x38e>
        printf("   FAIL: 4-page allocation failed\n");
    800015cc:	00009517          	auipc	a0,0x9
    800015d0:	05450513          	addi	a0,a0,84 # 8000a620 <digits+0x470>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f30080e7          	jalr	-208(ra) # 80000504 <printf>
    800015dc:	b531                	j	800013e8 <test_buddy_system_comprehensive+0x152>
        printf("   FAIL: 8-page allocation failed\n");
    800015de:	00009517          	auipc	a0,0x9
    800015e2:	09250513          	addi	a0,a0,146 # 8000a670 <digits+0x4c0>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f1e080e7          	jalr	-226(ra) # 80000504 <printf>
    800015ee:	bd29                	j	80001408 <test_buddy_system_comprehensive+0x172>
        printf("   FAIL: 16-page allocation failed\n");
    800015f0:	00009517          	auipc	a0,0x9
    800015f4:	0d050513          	addi	a0,a0,208 # 8000a6c0 <digits+0x510>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f0c080e7          	jalr	-244(ra) # 80000504 <printf>
    80001600:	b525                	j	80001428 <test_buddy_system_comprehensive+0x192>
        printf("   FAIL: 4-page reallocation failed\n");
    80001602:	00009517          	auipc	a0,0x9
    80001606:	1de50513          	addi	a0,a0,478 # 8000a7e0 <digits+0x630>
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	efa080e7          	jalr	-262(ra) # 80000504 <printf>
    80001612:	b711                	j	80001516 <test_buddy_system_comprehensive+0x280>
    }
    else
    {
        printf("   FAIL: Could not allocate blocks for merge test\n");
    80001614:	00009517          	auipc	a0,0x9
    80001618:	2a450513          	addi	a0,a0,676 # 8000a8b8 <digits+0x708>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	ee8080e7          	jalr	-280(ra) # 80000504 <printf>
    }

    // 测试6: 边界情况测试
    printf("\n8. Edge Case Tests:\n");
    80001624:	00009517          	auipc	a0,0x9
    80001628:	2cc50513          	addi	a0,a0,716 # 8000a8f0 <digits+0x740>
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	ed8080e7          	jalr	-296(ra) # 80000504 <printf>

    // 测试无效分配
    void *invalid1 = alloc_pages(0);
    80001634:	4501                	li	a0,0
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	9d6080e7          	jalr	-1578(ra) # 8000100c <alloc_pages>
    8000163e:	84aa                	mv	s1,a0
    void *invalid2 = alloc_pages(-1);
    80001640:	557d                	li	a0,-1
    80001642:	00000097          	auipc	ra,0x0
    80001646:	9ca080e7          	jalr	-1590(ra) # 8000100c <alloc_pages>
    if (invalid1 == NULL && invalid2 == NULL)
    8000164a:	c885                	beqz	s1,8000167a <test_buddy_system_comprehensive+0x3e4>
    {
        printf("   SUCCESS: Invalid allocation requests correctly rejected\n");
    }
    else
    {
        printf("   FAIL: Invalid allocations not properly handled\n");
    8000164c:	00009517          	auipc	a0,0x9
    80001650:	2fc50513          	addi	a0,a0,764 # 8000a948 <digits+0x798>
    80001654:	fffff097          	auipc	ra,0xfffff
    80001658:	eb0080e7          	jalr	-336(ra) # 80000504 <printf>
    }

    printf("\n=== Buddy System Comprehensive Test Completed ===\n");
    8000165c:	00009517          	auipc	a0,0x9
    80001660:	32450513          	addi	a0,a0,804 # 8000a980 <digits+0x7d0>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	ea0080e7          	jalr	-352(ra) # 80000504 <printf>
    8000166c:	70a2                	ld	ra,40(sp)
    8000166e:	7402                	ld	s0,32(sp)
    80001670:	64e2                	ld	s1,24(sp)
    80001672:	6942                	ld	s2,16(sp)
    80001674:	69a2                	ld	s3,8(sp)
    80001676:	6145                	addi	sp,sp,48
    80001678:	8082                	ret
    if (invalid1 == NULL && invalid2 == NULL)
    8000167a:	f969                	bnez	a0,8000164c <test_buddy_system_comprehensive+0x3b6>
        printf("   SUCCESS: Invalid allocation requests correctly rejected\n");
    8000167c:	00009517          	auipc	a0,0x9
    80001680:	28c50513          	addi	a0,a0,652 # 8000a908 <digits+0x758>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	e80080e7          	jalr	-384(ra) # 80000504 <printf>
    8000168c:	bfc1                	j	8000165c <test_buddy_system_comprehensive+0x3c6>

000000008000168e <free_pagetable_recursive>:
    
    return pt;
}

// 递归释放页表
static void free_pagetable_recursive(pagetable_t pt, int level) {
    8000168e:	7179                	addi	sp,sp,-48
    80001690:	f406                	sd	ra,40(sp)
    80001692:	f022                	sd	s0,32(sp)
    80001694:	ec26                	sd	s1,24(sp)
    80001696:	e84a                	sd	s2,16(sp)
    80001698:	e44e                	sd	s3,8(sp)
    8000169a:	e052                	sd	s4,0(sp)
    8000169c:	1800                	addi	s0,sp,48
    8000169e:	8a2a                	mv	s4,a0
    for (int i = 0; i < 512; i++) {
    800016a0:	84aa                	mv	s1,a0
    800016a2:	6905                	lui	s2,0x1
    800016a4:	992a                	add	s2,s2,a0
        pte_t pte = pt[i];
        if (pte & PTE_V) {
            if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
                // 中间页表页，递归释放
                pagetable_t child = (pagetable_t)PTE2PA(pte);
                free_pagetable_recursive(child, level + 1);
    800016a6:	0015899b          	addiw	s3,a1,1
    800016aa:	a021                	j	800016b2 <free_pagetable_recursive+0x24>
    for (int i = 0; i < 512; i++) {
    800016ac:	04a1                	addi	s1,s1,8
    800016ae:	03248163          	beq	s1,s2,800016d0 <free_pagetable_recursive+0x42>
        pte_t pte = pt[i];
    800016b2:	6088                	ld	a0,0(s1)
        if (pte & PTE_V) {
    800016b4:	00157793          	andi	a5,a0,1
    800016b8:	dbf5                	beqz	a5,800016ac <free_pagetable_recursive+0x1e>
            if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
    800016ba:	00e57793          	andi	a5,a0,14
    800016be:	f7fd                	bnez	a5,800016ac <free_pagetable_recursive+0x1e>
                pagetable_t child = (pagetable_t)PTE2PA(pte);
    800016c0:	8129                	srli	a0,a0,0xa
                free_pagetable_recursive(child, level + 1);
    800016c2:	85ce                	mv	a1,s3
    800016c4:	0532                	slli	a0,a0,0xc
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	fc8080e7          	jalr	-56(ra) # 8000168e <free_pagetable_recursive>
    800016ce:	bff9                	j	800016ac <free_pagetable_recursive+0x1e>
            }
            // 叶子页表项指向的物理页由调用者负责释放
        }
    }
    free_page((void*)pt);
    800016d0:	8552                	mv	a0,s4
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	920080e7          	jalr	-1760(ra) # 80000ff2 <free_page>
}
    800016da:	70a2                	ld	ra,40(sp)
    800016dc:	7402                	ld	s0,32(sp)
    800016de:	64e2                	ld	s1,24(sp)
    800016e0:	6942                	ld	s2,16(sp)
    800016e2:	69a2                	ld	s3,8(sp)
    800016e4:	6a02                	ld	s4,0(sp)
    800016e6:	6145                	addi	sp,sp,48
    800016e8:	8082                	ret

00000000800016ea <dump_pagetable_recursive>:
    
    return PTE2PA(*pte) | (va & 0xFFF);
}

// 递归打印页表
static void dump_pagetable_recursive(pagetable_t pt, int level, uint64 base_va) {
    800016ea:	7175                	addi	sp,sp,-144
    800016ec:	e506                	sd	ra,136(sp)
    800016ee:	e122                	sd	s0,128(sp)
    800016f0:	fca6                	sd	s1,120(sp)
    800016f2:	f8ca                	sd	s2,112(sp)
    800016f4:	f4ce                	sd	s3,104(sp)
    800016f6:	f0d2                	sd	s4,96(sp)
    800016f8:	ecd6                	sd	s5,88(sp)
    800016fa:	e8da                	sd	s6,80(sp)
    800016fc:	e4de                	sd	s7,72(sp)
    800016fe:	e0e2                	sd	s8,64(sp)
    80001700:	fc66                	sd	s9,56(sp)
    80001702:	f86a                	sd	s10,48(sp)
    80001704:	0900                	addi	s0,sp,144
    80001706:	8ab2                	mv	s5,a2
    char *level_names[] = {"L2", "L1", "L0"};
    80001708:	00009797          	auipc	a5,0x9
    8000170c:	2b078793          	addi	a5,a5,688 # 8000a9b8 <digits+0x808>
    80001710:	f8f43423          	sd	a5,-120(s0)
    80001714:	00009797          	auipc	a5,0x9
    80001718:	2ac78793          	addi	a5,a5,684 # 8000a9c0 <digits+0x810>
    8000171c:	f8f43823          	sd	a5,-112(s0)
    80001720:	00009797          	auipc	a5,0x9
    80001724:	2a878793          	addi	a5,a5,680 # 8000a9c8 <digits+0x818>
    80001728:	f8f43c23          	sd	a5,-104(s0)
    
    for (int i = 0; i < 512; i++) {
        pte_t pte = pt[i];
        if (pte & PTE_V) {
            uint64 child_va = base_va | ((uint64)i << VPN_SHIFT(level));
    8000172c:	00359a1b          	slliw	s4,a1,0x3
    80001730:	00ba0a3b          	addw	s4,s4,a1
    80001734:	2a31                	addiw	s4,s4,12
    80001736:	892a                	mv	s2,a0
    80001738:	4481                	li	s1,0
                dump_pagetable_recursive(child_pt, level - 1, child_va);
            } else {
                // 叶子映射
                uint64 pa = PTE2PA(pte);
                char perms[10];
                int idx = 0;
    8000173a:	4b81                	li	s7,0
                if (pte & PTE_U) perms[idx++] = 'U';
                if (pte & PTE_A) perms[idx++] = 'A';
                if (pte & PTE_D) perms[idx++] = 'D';
                perms[idx] = '\0';
                
                printf("  %s[%03d] 0x%p -> 0x%p [%s]\n",
    8000173c:	00359b13          	slli	s6,a1,0x3
    80001740:	fa040793          	addi	a5,s0,-96
    80001744:	9b3e                	add	s6,s6,a5
                       level_names[level], i, level_names[level-1], (void*)PTE2PA(pte));
    80001746:	fff58c1b          	addiw	s8,a1,-1
                printf("  %s[%03d] -> %s page table at 0x%p\n", 
    8000174a:	003c1c93          	slli	s9,s8,0x3
    8000174e:	9cbe                	add	s9,s9,a5
    80001750:	a08d                	j	800017b2 <dump_pagetable_recursive+0xc8>
                       level_names[level], i, level_names[level-1], (void*)PTE2PA(pte));
    80001752:	83a9                	srli	a5,a5,0xa
    80001754:	00c79d13          	slli	s10,a5,0xc
                printf("  %s[%03d] -> %s page table at 0x%p\n", 
    80001758:	876a                	mv	a4,s10
    8000175a:	fe8cb683          	ld	a3,-24(s9)
    8000175e:	fe8b3583          	ld	a1,-24(s6)
    80001762:	00009517          	auipc	a0,0x9
    80001766:	26e50513          	addi	a0,a0,622 # 8000a9d0 <digits+0x820>
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	d9a080e7          	jalr	-614(ra) # 80000504 <printf>
                dump_pagetable_recursive(child_pt, level - 1, child_va);
    80001772:	864e                	mv	a2,s3
    80001774:	85e2                	mv	a1,s8
    80001776:	856a                	mv	a0,s10
    80001778:	00000097          	auipc	ra,0x0
    8000177c:	f72080e7          	jalr	-142(ra) # 800016ea <dump_pagetable_recursive>
    80001780:	a01d                	j	800017a6 <dump_pagetable_recursive+0xbc>
                perms[idx] = '\0';
    80001782:	fa040793          	addi	a5,s0,-96
    80001786:	96be                	add	a3,a3,a5
    80001788:	fc068c23          	sb	zero,-40(a3) # fd8 <_entry-0x7ffff028>
                printf("  %s[%03d] 0x%p -> 0x%p [%s]\n",
    8000178c:	f7840793          	addi	a5,s0,-136
    80001790:	86ce                	mv	a3,s3
    80001792:	fe8b3583          	ld	a1,-24(s6)
    80001796:	00009517          	auipc	a0,0x9
    8000179a:	26250513          	addi	a0,a0,610 # 8000a9f8 <digits+0x848>
    8000179e:	fffff097          	auipc	ra,0xfffff
    800017a2:	d66080e7          	jalr	-666(ra) # 80000504 <printf>
    for (int i = 0; i < 512; i++) {
    800017a6:	0485                	addi	s1,s1,1
    800017a8:	0921                	addi	s2,s2,8
    800017aa:	20000793          	li	a5,512
    800017ae:	0af48463          	beq	s1,a5,80001856 <dump_pagetable_recursive+0x16c>
    800017b2:	0004861b          	sext.w	a2,s1
        pte_t pte = pt[i];
    800017b6:	00093783          	ld	a5,0(s2) # 1000 <_entry-0x7ffff000>
        if (pte & PTE_V) {
    800017ba:	0017f713          	andi	a4,a5,1
    800017be:	d765                	beqz	a4,800017a6 <dump_pagetable_recursive+0xbc>
            uint64 child_va = base_va | ((uint64)i << VPN_SHIFT(level));
    800017c0:	014499b3          	sll	s3,s1,s4
    800017c4:	0159e9b3          	or	s3,s3,s5
            if ((pte & (PTE_R | PTE_W | PTE_X)) == 0) {
    800017c8:	00e7f713          	andi	a4,a5,14
    800017cc:	d359                	beqz	a4,80001752 <dump_pagetable_recursive+0x68>
                uint64 pa = PTE2PA(pte);
    800017ce:	00a7d713          	srli	a4,a5,0xa
    800017d2:	0732                	slli	a4,a4,0xc
                if (pte & PTE_R) perms[idx++] = 'R';
    800017d4:	0027f593          	andi	a1,a5,2
                int idx = 0;
    800017d8:	86de                	mv	a3,s7
                if (pte & PTE_R) perms[idx++] = 'R';
    800017da:	c591                	beqz	a1,800017e6 <dump_pagetable_recursive+0xfc>
    800017dc:	05200693          	li	a3,82
    800017e0:	f6d40c23          	sb	a3,-136(s0)
    800017e4:	4685                	li	a3,1
                if (pte & PTE_W) perms[idx++] = 'W'; 
    800017e6:	0047f593          	andi	a1,a5,4
    800017ea:	c989                	beqz	a1,800017fc <dump_pagetable_recursive+0x112>
    800017ec:	fa040593          	addi	a1,s0,-96
    800017f0:	95b6                	add	a1,a1,a3
    800017f2:	05700513          	li	a0,87
    800017f6:	fca58c23          	sb	a0,-40(a1)
    800017fa:	2685                	addiw	a3,a3,1
                if (pte & PTE_X) perms[idx++] = 'X';
    800017fc:	0087f593          	andi	a1,a5,8
    80001800:	c989                	beqz	a1,80001812 <dump_pagetable_recursive+0x128>
    80001802:	fa040593          	addi	a1,s0,-96
    80001806:	95b6                	add	a1,a1,a3
    80001808:	05800513          	li	a0,88
    8000180c:	fca58c23          	sb	a0,-40(a1)
    80001810:	2685                	addiw	a3,a3,1
                if (pte & PTE_U) perms[idx++] = 'U';
    80001812:	0107f593          	andi	a1,a5,16
    80001816:	c989                	beqz	a1,80001828 <dump_pagetable_recursive+0x13e>
    80001818:	fa040593          	addi	a1,s0,-96
    8000181c:	95b6                	add	a1,a1,a3
    8000181e:	05500513          	li	a0,85
    80001822:	fca58c23          	sb	a0,-40(a1)
    80001826:	2685                	addiw	a3,a3,1
                if (pte & PTE_A) perms[idx++] = 'A';
    80001828:	0407f593          	andi	a1,a5,64
    8000182c:	c989                	beqz	a1,8000183e <dump_pagetable_recursive+0x154>
    8000182e:	fa040593          	addi	a1,s0,-96
    80001832:	95b6                	add	a1,a1,a3
    80001834:	04100513          	li	a0,65
    80001838:	fca58c23          	sb	a0,-40(a1)
    8000183c:	2685                	addiw	a3,a3,1
                if (pte & PTE_D) perms[idx++] = 'D';
    8000183e:	0807f793          	andi	a5,a5,128
    80001842:	d3a1                	beqz	a5,80001782 <dump_pagetable_recursive+0x98>
    80001844:	fa040793          	addi	a5,s0,-96
    80001848:	97b6                	add	a5,a5,a3
    8000184a:	04400593          	li	a1,68
    8000184e:	fcb78c23          	sb	a1,-40(a5)
    80001852:	2685                	addiw	a3,a3,1
    80001854:	b73d                	j	80001782 <dump_pagetable_recursive+0x98>
                       level_names[level], i, (void*)child_va, (void*)pa, perms);
            }
        }
    }
}
    80001856:	60aa                	ld	ra,136(sp)
    80001858:	640a                	ld	s0,128(sp)
    8000185a:	74e6                	ld	s1,120(sp)
    8000185c:	7946                	ld	s2,112(sp)
    8000185e:	79a6                	ld	s3,104(sp)
    80001860:	7a06                	ld	s4,96(sp)
    80001862:	6ae6                	ld	s5,88(sp)
    80001864:	6b46                	ld	s6,80(sp)
    80001866:	6ba6                	ld	s7,72(sp)
    80001868:	6c06                	ld	s8,64(sp)
    8000186a:	7ce2                	ld	s9,56(sp)
    8000186c:	7d42                	ld	s10,48(sp)
    8000186e:	6149                	addi	sp,sp,144
    80001870:	8082                	ret

0000000080001872 <create_pagetable>:
pagetable_t create_pagetable(void) {
    80001872:	1141                	addi	sp,sp,-16
    80001874:	e406                	sd	ra,8(sp)
    80001876:	e022                	sd	s0,0(sp)
    80001878:	0800                	addi	s0,sp,16
    pagetable_t pt = (pagetable_t)alloc_page();
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	75e080e7          	jalr	1886(ra) # 80000fd8 <alloc_page>
    if (pt == NULL) {
    80001882:	c909                	beqz	a0,80001894 <create_pagetable+0x22>
    80001884:	87aa                	mv	a5,a0
    80001886:	6705                	lui	a4,0x1
    80001888:	972a                	add	a4,a4,a0
        pt[i] = 0;
    8000188a:	0007b023          	sd	zero,0(a5)
    for (int i = 0; i < 512; i++) {
    8000188e:	07a1                	addi	a5,a5,8
    80001890:	fee79de3          	bne	a5,a4,8000188a <create_pagetable+0x18>
}
    80001894:	60a2                	ld	ra,8(sp)
    80001896:	6402                	ld	s0,0(sp)
    80001898:	0141                	addi	sp,sp,16
    8000189a:	8082                	ret

000000008000189c <destroy_pagetable>:
    if (pt == NULL) return;
    8000189c:	cd11                	beqz	a0,800018b8 <destroy_pagetable+0x1c>
void destroy_pagetable(pagetable_t pt) {
    8000189e:	1141                	addi	sp,sp,-16
    800018a0:	e406                	sd	ra,8(sp)
    800018a2:	e022                	sd	s0,0(sp)
    800018a4:	0800                	addi	s0,sp,16
    free_pagetable_recursive(pt, 0);
    800018a6:	4581                	li	a1,0
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	de6080e7          	jalr	-538(ra) # 8000168e <free_pagetable_recursive>
}
    800018b0:	60a2                	ld	ra,8(sp)
    800018b2:	6402                	ld	s0,0(sp)
    800018b4:	0141                	addi	sp,sp,16
    800018b6:	8082                	ret
    800018b8:	8082                	ret

00000000800018ba <walk_lookup>:
pte_t* walk_lookup(pagetable_t pt, uint64 va) {
    800018ba:	1141                	addi	sp,sp,-16
    800018bc:	e422                	sd	s0,8(sp)
    800018be:	0800                	addi	s0,sp,16
    if (va >= MAXVA) {
    800018c0:	57fd                	li	a5,-1
    800018c2:	83e9                	srli	a5,a5,0x1a
    800018c4:	04b7e863          	bltu	a5,a1,80001914 <walk_lookup+0x5a>
        pte_t *pte = &current[VPN_MASK(va, level)];
    800018c8:	01e5d793          	srli	a5,a1,0x1e
        if (!(*pte & PTE_V)) {
    800018cc:	078e                	slli	a5,a5,0x3
    800018ce:	953e                	add	a0,a0,a5
    800018d0:	611c                	ld	a5,0(a0)
    800018d2:	0017f713          	andi	a4,a5,1
    800018d6:	c329                	beqz	a4,80001918 <walk_lookup+0x5e>
        current = (pagetable_t)PTE2PA(*pte);
    800018d8:	83a9                	srli	a5,a5,0xa
    800018da:	00c79713          	slli	a4,a5,0xc
        pte_t *pte = &current[VPN_MASK(va, level)];
    800018de:	0155d793          	srli	a5,a1,0x15
    800018e2:	1ff7f793          	andi	a5,a5,511
        if (!(*pte & PTE_V)) {
    800018e6:	078e                	slli	a5,a5,0x3
    800018e8:	97ba                	add	a5,a5,a4
    800018ea:	6388                	ld	a0,0(a5)
    800018ec:	00157793          	andi	a5,a0,1
    800018f0:	c795                	beqz	a5,8000191c <walk_lookup+0x62>
        current = (pagetable_t)PTE2PA(*pte);
    800018f2:	8129                	srli	a0,a0,0xa
    800018f4:	00c51793          	slli	a5,a0,0xc
    pte_t *pte = &current[VPN_MASK(va, 0)];
    800018f8:	00c5d513          	srli	a0,a1,0xc
    800018fc:	1ff57513          	andi	a0,a0,511
    80001900:	050e                	slli	a0,a0,0x3
    80001902:	953e                	add	a0,a0,a5
    if (!(*pte & PTE_V)) {
    80001904:	611c                	ld	a5,0(a0)
        return NULL;
    80001906:	8b85                	andi	a5,a5,1
    80001908:	40f007b3          	neg	a5,a5
    8000190c:	8d7d                	and	a0,a0,a5
}
    8000190e:	6422                	ld	s0,8(sp)
    80001910:	0141                	addi	sp,sp,16
    80001912:	8082                	ret
        return NULL;
    80001914:	4501                	li	a0,0
    80001916:	bfe5                	j	8000190e <walk_lookup+0x54>
            return NULL;
    80001918:	4501                	li	a0,0
    8000191a:	bfd5                	j	8000190e <walk_lookup+0x54>
    8000191c:	4501                	li	a0,0
    8000191e:	bfc5                	j	8000190e <walk_lookup+0x54>

0000000080001920 <walk_create>:
    if (va >= MAXVA) {
    80001920:	57fd                	li	a5,-1
    80001922:	83e9                	srli	a5,a5,0x1a
    80001924:	08b7e263          	bltu	a5,a1,800019a8 <walk_create+0x88>
pte_t* walk_create(pagetable_t pt, uint64 va) {
    80001928:	7139                	addi	sp,sp,-64
    8000192a:	fc06                	sd	ra,56(sp)
    8000192c:	f822                	sd	s0,48(sp)
    8000192e:	f426                	sd	s1,40(sp)
    80001930:	f04a                	sd	s2,32(sp)
    80001932:	ec4e                	sd	s3,24(sp)
    80001934:	e852                	sd	s4,16(sp)
    80001936:	e456                	sd	s5,8(sp)
    80001938:	0080                	addi	s0,sp,64
    8000193a:	892e                	mv	s2,a1
    8000193c:	49f9                	li	s3,30
    8000193e:	6a85                	lui	s5,0x1
    for (int level = 2; level > 0; level--) {
    80001940:	4a31                	li	s4,12
        pte_t *pte = &current[VPN_MASK(va, level)];
    80001942:	013954b3          	srl	s1,s2,s3
    80001946:	1ff4f493          	andi	s1,s1,511
    8000194a:	048e                	slli	s1,s1,0x3
    8000194c:	94aa                	add	s1,s1,a0
        if (*pte & PTE_V) {
    8000194e:	6088                	ld	a0,0(s1)
    80001950:	00157793          	andi	a5,a0,1
    80001954:	c78d                	beqz	a5,8000197e <walk_create+0x5e>
            current = (pagetable_t)PTE2PA(*pte);
    80001956:	8129                	srli	a0,a0,0xa
    80001958:	0532                	slli	a0,a0,0xc
    for (int level = 2; level > 0; level--) {
    8000195a:	39dd                	addiw	s3,s3,-9
    8000195c:	ff4993e3          	bne	s3,s4,80001942 <walk_create+0x22>
    return &current[VPN_MASK(va, 0)];
    80001960:	00c95793          	srli	a5,s2,0xc
    80001964:	1ff7f793          	andi	a5,a5,511
    80001968:	078e                	slli	a5,a5,0x3
    8000196a:	953e                	add	a0,a0,a5
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6121                	addi	sp,sp,64
    8000197c:	8082                	ret
            pagetable_t new_pt = (pagetable_t)alloc_page();
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	65a080e7          	jalr	1626(ra) # 80000fd8 <alloc_page>
            if (new_pt == NULL) {
    80001986:	d17d                	beqz	a0,8000196c <walk_create+0x4c>
    80001988:	86aa                	mv	a3,a0
    8000198a:	01550733          	add	a4,a0,s5
    8000198e:	87aa                	mv	a5,a0
                new_pt[i] = 0;
    80001990:	0007b023          	sd	zero,0(a5)
            for (int i = 0; i < 512; i++) {
    80001994:	07a1                	addi	a5,a5,8
    80001996:	fee79de3          	bne	a5,a4,80001990 <walk_create+0x70>
            *pte = PA2PTE(new_pt) | PTE_V;
    8000199a:	00c6d793          	srli	a5,a3,0xc
    8000199e:	07aa                	slli	a5,a5,0xa
    800019a0:	0017e793          	ori	a5,a5,1
    800019a4:	e09c                	sd	a5,0(s1)
            current = new_pt;
    800019a6:	bf55                	j	8000195a <walk_create+0x3a>
        return NULL;
    800019a8:	4501                	li	a0,0
}
    800019aa:	8082                	ret

00000000800019ac <map_page>:
int map_page(pagetable_t pt, uint64 va, uint64 pa, int perm) {
    800019ac:	7179                	addi	sp,sp,-48
    800019ae:	f406                	sd	ra,40(sp)
    800019b0:	f022                	sd	s0,32(sp)
    800019b2:	ec26                	sd	s1,24(sp)
    800019b4:	e84a                	sd	s2,16(sp)
    800019b6:	e44e                	sd	s3,8(sp)
    800019b8:	1800                	addi	s0,sp,48
    800019ba:	892e                	mv	s2,a1
    800019bc:	84b2                	mv	s1,a2
    if ((va % PGSIZE) != 0 || (pa % PGSIZE) != 0) {
    800019be:	00c5e7b3          	or	a5,a1,a2
    800019c2:	17d2                	slli	a5,a5,0x34
    800019c4:	eb8d                	bnez	a5,800019f6 <map_page+0x4a>
    800019c6:	89b6                	mv	s3,a3
    pte_t *pte = walk_create(pt, va);
    800019c8:	00000097          	auipc	ra,0x0
    800019cc:	f58080e7          	jalr	-168(ra) # 80001920 <walk_create>
    if (pte == NULL) {
    800019d0:	cd0d                	beqz	a0,80001a0a <map_page+0x5e>
    if (*pte & PTE_V) {
    800019d2:	611c                	ld	a5,0(a0)
    800019d4:	8b85                	andi	a5,a5,1
    800019d6:	e7a1                	bnez	a5,80001a1e <map_page+0x72>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800019d8:	80b1                	srli	s1,s1,0xc
    800019da:	04aa                	slli	s1,s1,0xa
    800019dc:	0134e6b3          	or	a3,s1,s3
    800019e0:	0016e693          	ori	a3,a3,1
    800019e4:	e114                	sd	a3,0(a0)
    return 0;
    800019e6:	4501                	li	a0,0
}
    800019e8:	70a2                	ld	ra,40(sp)
    800019ea:	7402                	ld	s0,32(sp)
    800019ec:	64e2                	ld	s1,24(sp)
    800019ee:	6942                	ld	s2,16(sp)
    800019f0:	69a2                	ld	s3,8(sp)
    800019f2:	6145                	addi	sp,sp,48
    800019f4:	8082                	ret
        printf("VM: unaligned address va=0x%p pa=0x%p\n", (void*)va, (void*)pa);
    800019f6:	00009517          	auipc	a0,0x9
    800019fa:	02250513          	addi	a0,a0,34 # 8000aa18 <digits+0x868>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	b06080e7          	jalr	-1274(ra) # 80000504 <printf>
        return -1;
    80001a06:	557d                	li	a0,-1
    80001a08:	b7c5                	j	800019e8 <map_page+0x3c>
        printf("VM: failed to walk page table\n");
    80001a0a:	00009517          	auipc	a0,0x9
    80001a0e:	03650513          	addi	a0,a0,54 # 8000aa40 <digits+0x890>
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	af2080e7          	jalr	-1294(ra) # 80000504 <printf>
        return -1;
    80001a1a:	557d                	li	a0,-1
    80001a1c:	b7f1                	j	800019e8 <map_page+0x3c>
        printf("VM: already mapped va=0x%p\n", (void*)va);
    80001a1e:	85ca                	mv	a1,s2
    80001a20:	00009517          	auipc	a0,0x9
    80001a24:	04050513          	addi	a0,a0,64 # 8000aa60 <digits+0x8b0>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	adc080e7          	jalr	-1316(ra) # 80000504 <printf>
        return -1;
    80001a30:	557d                	li	a0,-1
    80001a32:	bf5d                	j	800019e8 <map_page+0x3c>

0000000080001a34 <map_region>:
    if (size == 0) {
    80001a34:	10068563          	beqz	a3,80001b3e <map_region+0x10a>
int map_region(pagetable_t pt, uint64 va, uint64 pa, uint64 size, int perm) {
    80001a38:	7159                	addi	sp,sp,-112
    80001a3a:	f486                	sd	ra,104(sp)
    80001a3c:	f0a2                	sd	s0,96(sp)
    80001a3e:	eca6                	sd	s1,88(sp)
    80001a40:	e8ca                	sd	s2,80(sp)
    80001a42:	e4ce                	sd	s3,72(sp)
    80001a44:	e0d2                	sd	s4,64(sp)
    80001a46:	fc56                	sd	s5,56(sp)
    80001a48:	f85a                	sd	s6,48(sp)
    80001a4a:	f45e                	sd	s7,40(sp)
    80001a4c:	f062                	sd	s8,32(sp)
    80001a4e:	ec66                	sd	s9,24(sp)
    80001a50:	e86a                	sd	s10,16(sp)
    80001a52:	e46e                	sd	s11,8(sp)
    80001a54:	1880                	addi	s0,sp,112
    80001a56:	89aa                	mv	s3,a0
    80001a58:	8c3a                	mv	s8,a4
    if ((va % PGSIZE) != 0 || (pa % PGSIZE) != 0) {
    80001a5a:	00c5e7b3          	or	a5,a1,a2
    80001a5e:	17d2                	slli	a5,a5,0x34
    80001a60:	0347da93          	srli	s5,a5,0x34
    80001a64:	eff9                	bnez	a5,80001b42 <map_region+0x10e>
    uint64 total_pages = size / PGSIZE;
    80001a66:	00c6db93          	srli	s7,a3,0xc
    for (uint64 i = 0; i < total_pages; i++) {
    80001a6a:	6785                	lui	a5,0x1
    80001a6c:	0af6eb63          	bltu	a3,a5,80001b22 <map_region+0xee>
    80001a70:	84ae                	mv	s1,a1
    80001a72:	8956                	mv	s2,s5
    uint64 skipped_pages = 0;
    80001a74:	8a56                	mv	s4,s5
        if (map_page(pt, current_va, current_pa, perm) != 0) {
    80001a76:	40b60b33          	sub	s6,a2,a1
            printf("VM: Failed to map page %d/%d at VA 0x%p\n", 
    80001a7a:	000b8d9b          	sext.w	s11,s7
    80001a7e:	00009d17          	auipc	s10,0x9
    80001a82:	002d0d13          	addi	s10,s10,2 # 8000aa80 <digits+0x8d0>
    for (uint64 i = 0; i < total_pages; i++) {
    80001a86:	6c85                	lui	s9,0x1
    80001a88:	a005                	j	80001aa8 <map_region+0x74>
        if (map_page(pt, current_va, current_pa, perm) != 0) {
    80001a8a:	86e2                	mv	a3,s8
    80001a8c:	009b0633          	add	a2,s6,s1
    80001a90:	85a6                	mv	a1,s1
    80001a92:	854e                	mv	a0,s3
    80001a94:	00000097          	auipc	ra,0x0
    80001a98:	f18080e7          	jalr	-232(ra) # 800019ac <map_page>
    80001a9c:	e115                	bnez	a0,80001ac0 <map_region+0x8c>
        mapped_pages++;
    80001a9e:	0a85                	addi	s5,s5,1
    for (uint64 i = 0; i < total_pages; i++) {
    80001aa0:	0905                	addi	s2,s2,1
    80001aa2:	94e6                	add	s1,s1,s9
    80001aa4:	03797863          	bgeu	s2,s7,80001ad4 <map_region+0xa0>
        pte_t *pte = walk_lookup(pt, current_va);
    80001aa8:	85a6                	mv	a1,s1
    80001aaa:	854e                	mv	a0,s3
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	e0e080e7          	jalr	-498(ra) # 800018ba <walk_lookup>
        if (pte && (*pte & PTE_V)) {
    80001ab4:	d979                	beqz	a0,80001a8a <map_region+0x56>
    80001ab6:	611c                	ld	a5,0(a0)
    80001ab8:	8b85                	andi	a5,a5,1
    80001aba:	dbe1                	beqz	a5,80001a8a <map_region+0x56>
            skipped_pages++;
    80001abc:	0a05                	addi	s4,s4,1
            continue;
    80001abe:	b7cd                	j	80001aa0 <map_region+0x6c>
            printf("VM: Failed to map page %d/%d at VA 0x%p\n", 
    80001ac0:	86a6                	mv	a3,s1
    80001ac2:	866e                	mv	a2,s11
    80001ac4:	0009059b          	sext.w	a1,s2
    80001ac8:	856a                	mv	a0,s10
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	a3a080e7          	jalr	-1478(ra) # 80000504 <printf>
            continue;
    80001ad2:	b7f9                	j	80001aa0 <map_region+0x6c>
    if (skipped_pages > 0) {
    80001ad4:	040a0863          	beqz	s4,80001b24 <map_region+0xf0>
        printf("VM: Successfully mapped %d/%d pages (%d already mapped)\n", 
    80001ad8:	000a069b          	sext.w	a3,s4
    80001adc:	000b861b          	sext.w	a2,s7
    80001ae0:	000a859b          	sext.w	a1,s5
    80001ae4:	00009517          	auipc	a0,0x9
    80001ae8:	fcc50513          	addi	a0,a0,-52 # 8000aab0 <digits+0x900>
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	a18080e7          	jalr	-1512(ra) # 80000504 <printf>
    return (mapped_pages + skipped_pages == total_pages) ? 0 : -1;
    80001af4:	015a0533          	add	a0,s4,s5
    80001af8:	41750533          	sub	a0,a0,s7
    80001afc:	00a03533          	snez	a0,a0
    80001b00:	40a00533          	neg	a0,a0
}
    80001b04:	70a6                	ld	ra,104(sp)
    80001b06:	7406                	ld	s0,96(sp)
    80001b08:	64e6                	ld	s1,88(sp)
    80001b0a:	6946                	ld	s2,80(sp)
    80001b0c:	69a6                	ld	s3,72(sp)
    80001b0e:	6a06                	ld	s4,64(sp)
    80001b10:	7ae2                	ld	s5,56(sp)
    80001b12:	7b42                	ld	s6,48(sp)
    80001b14:	7ba2                	ld	s7,40(sp)
    80001b16:	7c02                	ld	s8,32(sp)
    80001b18:	6ce2                	ld	s9,24(sp)
    80001b1a:	6d42                	ld	s10,16(sp)
    80001b1c:	6da2                	ld	s11,8(sp)
    80001b1e:	6165                	addi	sp,sp,112
    80001b20:	8082                	ret
    uint64 skipped_pages = 0;
    80001b22:	8a56                	mv	s4,s5
        printf("VM: Successfully mapped %d/%d pages\n", (int)mapped_pages, (int)total_pages);
    80001b24:	000b861b          	sext.w	a2,s7
    80001b28:	000a859b          	sext.w	a1,s5
    80001b2c:	00009517          	auipc	a0,0x9
    80001b30:	fc450513          	addi	a0,a0,-60 # 8000aaf0 <digits+0x940>
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	9d0080e7          	jalr	-1584(ra) # 80000504 <printf>
    80001b3c:	bf65                	j	80001af4 <map_region+0xc0>
        return 0;
    80001b3e:	4501                	li	a0,0
}
    80001b40:	8082                	ret
        return -1;
    80001b42:	557d                	li	a0,-1
    80001b44:	b7c1                	j	80001b04 <map_region+0xd0>

0000000080001b46 <unmap_page>:
void unmap_page(pagetable_t pt, uint64 va) {
    80001b46:	1141                	addi	sp,sp,-16
    80001b48:	e406                	sd	ra,8(sp)
    80001b4a:	e022                	sd	s0,0(sp)
    80001b4c:	0800                	addi	s0,sp,16
    pte_t *pte = walk_lookup(pt, va);
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	d6c080e7          	jalr	-660(ra) # 800018ba <walk_lookup>
    if (pte && (*pte & PTE_V)) {
    80001b56:	c511                	beqz	a0,80001b62 <unmap_page+0x1c>
    80001b58:	611c                	ld	a5,0(a0)
    80001b5a:	8b85                	andi	a5,a5,1
    80001b5c:	c399                	beqz	a5,80001b62 <unmap_page+0x1c>
        *pte = 0;
    80001b5e:	00053023          	sd	zero,0(a0)
}
    80001b62:	60a2                	ld	ra,8(sp)
    80001b64:	6402                	ld	s0,0(sp)
    80001b66:	0141                	addi	sp,sp,16
    80001b68:	8082                	ret

0000000080001b6a <walkaddr>:
uint64 walkaddr(pagetable_t pt, uint64 va) {
    80001b6a:	1101                	addi	sp,sp,-32
    80001b6c:	ec06                	sd	ra,24(sp)
    80001b6e:	e822                	sd	s0,16(sp)
    80001b70:	e426                	sd	s1,8(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84ae                	mv	s1,a1
    pte_t *pte = walk_lookup(pt, va);
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	d44080e7          	jalr	-700(ra) # 800018ba <walk_lookup>
    if (pte == NULL || !(*pte & PTE_V)) {
    80001b7e:	c10d                	beqz	a0,80001ba0 <walkaddr+0x36>
    80001b80:	611c                	ld	a5,0(a0)
    80001b82:	0017f513          	andi	a0,a5,1
    80001b86:	c901                	beqz	a0,80001b96 <walkaddr+0x2c>
    return PTE2PA(*pte) | (va & 0xFFF);
    80001b88:	00a7d513          	srli	a0,a5,0xa
    80001b8c:	0532                	slli	a0,a0,0xc
    80001b8e:	03449593          	slli	a1,s1,0x34
    80001b92:	91d1                	srli	a1,a1,0x34
    80001b94:	8d4d                	or	a0,a0,a1
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret
        return 0;
    80001ba0:	4501                	li	a0,0
    80001ba2:	bfd5                	j	80001b96 <walkaddr+0x2c>

0000000080001ba4 <dump_pagetable>:

// 打印页表内容
void dump_pagetable(pagetable_t pt, int level) {
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	e04a                	sd	s2,0(sp)
    80001bae:	1000                	addi	s0,sp,32
    if (pt == NULL) {
    80001bb0:	c121                	beqz	a0,80001bf0 <dump_pagetable+0x4c>
    80001bb2:	84aa                	mv	s1,a0
    80001bb4:	892e                	mv	s2,a1
        printf("VM: null page table\n");
        return;
    }
    
    printf("=== Page Table Dump (level %d) ===\n", level);
    80001bb6:	00009517          	auipc	a0,0x9
    80001bba:	f7a50513          	addi	a0,a0,-134 # 8000ab30 <digits+0x980>
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	946080e7          	jalr	-1722(ra) # 80000504 <printf>
    dump_pagetable_recursive(pt, level, 0);
    80001bc6:	4601                	li	a2,0
    80001bc8:	85ca                	mv	a1,s2
    80001bca:	8526                	mv	a0,s1
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	b1e080e7          	jalr	-1250(ra) # 800016ea <dump_pagetable_recursive>
    printf("=== End of Page Table ===\n");
    80001bd4:	00009517          	auipc	a0,0x9
    80001bd8:	f8450513          	addi	a0,a0,-124 # 8000ab58 <digits+0x9a8>
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	928080e7          	jalr	-1752(ra) # 80000504 <printf>
}
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6902                	ld	s2,0(sp)
    80001bec:	6105                	addi	sp,sp,32
    80001bee:	8082                	ret
        printf("VM: null page table\n");
    80001bf0:	00009517          	auipc	a0,0x9
    80001bf4:	f2850513          	addi	a0,a0,-216 # 8000ab18 <digits+0x968>
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	90c080e7          	jalr	-1780(ra) # 80000504 <printf>
        return;
    80001c00:	b7d5                	j	80001be4 <dump_pagetable+0x40>

0000000080001c02 <kvm_map_devices>:
    
    printf("KVM: Kernel page table initialized successfully\n");
}

// 映射设备区域
void kvm_map_devices(void) {
    80001c02:	1101                	addi	sp,sp,-32
    80001c04:	ec06                	sd	ra,24(sp)
    80001c06:	e822                	sd	s0,16(sp)
    80001c08:	e426                	sd	s1,8(sp)
    80001c0a:	1000                	addi	s0,sp,32
    printf("KVM: Mapping devices...\n");
    80001c0c:	00009517          	auipc	a0,0x9
    80001c10:	f6c50513          	addi	a0,a0,-148 # 8000ab78 <digits+0x9c8>
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	8f0080e7          	jalr	-1808(ra) # 80000504 <printf>
    
    // 映射 CLINT (Core Local Interruptor) - 定时器相关
    // CLINT 区域从 0x02000000 开始，需要映射至少 64KB
    uint64 clint_start = 0x02000000;
    uint64 clint_size = 0x10000;  // 64KB，足够覆盖 CLINT 区域
    printf("  CLINT: 0x%p - 0x%p [RW]\n", (void*)clint_start, (void*)(clint_start + clint_size));
    80001c1c:	02010637          	lui	a2,0x2010
    80001c20:	020005b7          	lui	a1,0x2000
    80001c24:	00009517          	auipc	a0,0x9
    80001c28:	f7450513          	addi	a0,a0,-140 # 8000ab98 <digits+0x9e8>
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	8d8080e7          	jalr	-1832(ra) # 80000504 <printf>
    if (map_region(kernel_pagetable, clint_start, clint_start, clint_size, PTE_R | PTE_W) != 0) {
    80001c34:	4719                	li	a4,6
    80001c36:	66c1                	lui	a3,0x10
    80001c38:	02000637          	lui	a2,0x2000
    80001c3c:	020005b7          	lui	a1,0x2000
    80001c40:	0000e517          	auipc	a0,0xe
    80001c44:	c1853503          	ld	a0,-1000(a0) # 8000f858 <kernel_pagetable>
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	dec080e7          	jalr	-532(ra) # 80001a34 <map_region>
    80001c50:	e551                	bnez	a0,80001cdc <kvm_map_devices+0xda>
        printf("KVM: Warning: CLINT mapping failed, continuing...\n");
    }
    
    // 映射 UART - 如果已经映射则跳过
    printf("  UART: 0x%p [RW]\n", (void*)UART0);
    80001c52:	100005b7          	lui	a1,0x10000
    80001c56:	00009517          	auipc	a0,0x9
    80001c5a:	f9a50513          	addi	a0,a0,-102 # 8000abf0 <digits+0xa40>
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	8a6080e7          	jalr	-1882(ra) # 80000504 <printf>
    pte_t *uart_pte = walk_lookup(kernel_pagetable, UART0);
    80001c66:	0000e497          	auipc	s1,0xe
    80001c6a:	bf24b483          	ld	s1,-1038(s1) # 8000f858 <kernel_pagetable>
    80001c6e:	100005b7          	lui	a1,0x10000
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	c46080e7          	jalr	-954(ra) # 800018ba <walk_lookup>
    if (uart_pte && (*uart_pte & PTE_V)) {
    80001c7c:	c501                	beqz	a0,80001c84 <kvm_map_devices+0x82>
    80001c7e:	611c                	ld	a5,0(a0)
    80001c80:	8b85                	andi	a5,a5,1
    80001c82:	e7b5                	bnez	a5,80001cee <kvm_map_devices+0xec>
        printf("  UART already mapped, skipping...\n");
    } else {
        if (map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W) != 0) {
    80001c84:	4719                	li	a4,6
    80001c86:	6685                	lui	a3,0x1
    80001c88:	10000637          	lui	a2,0x10000
    80001c8c:	100005b7          	lui	a1,0x10000
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	da2080e7          	jalr	-606(ra) # 80001a34 <map_region>
    80001c9a:	e13d                	bnez	a0,80001d00 <kvm_map_devices+0xfe>
    // 映射 VIRTIO MMIO 区域（0x10001000 - 0x10020000，覆盖所有可能的VirtIO设备）
    // QEMU virt机器上，VirtIO MMIO设备通常在0x10001000-0x10008000范围内
    // 注意：0x10000000 已经被 UART 占用，所以从 0x10001000 开始
    uint64 virtio_start = 0x10001000;
    uint64 virtio_size = 0x1F000;  // 约124KB，足够覆盖所有VirtIO设备
    printf("  VIRTIO MMIO: 0x%p - 0x%p [RW]\n", (void*)virtio_start, (void*)(virtio_start + virtio_size));
    80001c9c:	10020637          	lui	a2,0x10020
    80001ca0:	100015b7          	lui	a1,0x10001
    80001ca4:	00009517          	auipc	a0,0x9
    80001ca8:	fc450513          	addi	a0,a0,-60 # 8000ac68 <digits+0xab8>
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	858080e7          	jalr	-1960(ra) # 80000504 <printf>
    if (map_region(kernel_pagetable, virtio_start, virtio_start, virtio_size, PTE_R | PTE_W) != 0) {
    80001cb4:	4719                	li	a4,6
    80001cb6:	66fd                	lui	a3,0x1f
    80001cb8:	10001637          	lui	a2,0x10001
    80001cbc:	100015b7          	lui	a1,0x10001
    80001cc0:	0000e517          	auipc	a0,0xe
    80001cc4:	b9853503          	ld	a0,-1128(a0) # 8000f858 <kernel_pagetable>
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	d6c080e7          	jalr	-660(ra) # 80001a34 <map_region>
    80001cd0:	e129                	bnez	a0,80001d12 <kvm_map_devices+0x110>
        printf("KVM: Warning: VIRTIO MMIO mapping failed, continuing...\n");
    }
}
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6105                	addi	sp,sp,32
    80001cda:	8082                	ret
        printf("KVM: Warning: CLINT mapping failed, continuing...\n");
    80001cdc:	00009517          	auipc	a0,0x9
    80001ce0:	edc50513          	addi	a0,a0,-292 # 8000abb8 <digits+0xa08>
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	820080e7          	jalr	-2016(ra) # 80000504 <printf>
    80001cec:	b79d                	j	80001c52 <kvm_map_devices+0x50>
        printf("  UART already mapped, skipping...\n");
    80001cee:	00009517          	auipc	a0,0x9
    80001cf2:	f1a50513          	addi	a0,a0,-230 # 8000ac08 <digits+0xa58>
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	80e080e7          	jalr	-2034(ra) # 80000504 <printf>
    80001cfe:	bf79                	j	80001c9c <kvm_map_devices+0x9a>
            printf("KVM: Warning: UART mapping failed, continuing...\n");
    80001d00:	00009517          	auipc	a0,0x9
    80001d04:	f3050513          	addi	a0,a0,-208 # 8000ac30 <digits+0xa80>
    80001d08:	ffffe097          	auipc	ra,0xffffe
    80001d0c:	7fc080e7          	jalr	2044(ra) # 80000504 <printf>
    80001d10:	b771                	j	80001c9c <kvm_map_devices+0x9a>
        printf("KVM: Warning: VIRTIO MMIO mapping failed, continuing...\n");
    80001d12:	00009517          	auipc	a0,0x9
    80001d16:	f7e50513          	addi	a0,a0,-130 # 8000ac90 <digits+0xae0>
    80001d1a:	ffffe097          	auipc	ra,0xffffe
    80001d1e:	7ea080e7          	jalr	2026(ra) # 80000504 <printf>
}
    80001d22:	bf45                	j	80001cd2 <kvm_map_devices+0xd0>

0000000080001d24 <kvm_map_kernel>:
void kvm_map_kernel(void) {
    80001d24:	1101                	addi	sp,sp,-32
    80001d26:	ec06                	sd	ra,24(sp)
    80001d28:	e822                	sd	s0,16(sp)
    80001d2a:	e426                	sd	s1,8(sp)
    80001d2c:	e04a                	sd	s2,0(sp)
    80001d2e:	1000                	addi	s0,sp,32
    printf("KVM: Mapping kernel regions...\n");
    80001d30:	00009517          	auipc	a0,0x9
    80001d34:	fa050513          	addi	a0,a0,-96 # 8000acd0 <digits+0xb20>
    80001d38:	ffffe097          	auipc	ra,0xffffe
    80001d3c:	7cc080e7          	jalr	1996(ra) # 80000504 <printf>
    uint64 text_size = (uint64)etext - KERNBASE;
    80001d40:	00008497          	auipc	s1,0x8
    80001d44:	2c048493          	addi	s1,s1,704 # 8000a000 <etext>
    printf("  Text: 0x%p - 0x%p [RX]\n", 
    80001d48:	8626                	mv	a2,s1
    80001d4a:	4905                	li	s2,1
    80001d4c:	01f91593          	slli	a1,s2,0x1f
    80001d50:	00009517          	auipc	a0,0x9
    80001d54:	fa050513          	addi	a0,a0,-96 # 8000acf0 <digits+0xb40>
    80001d58:	ffffe097          	auipc	ra,0xffffe
    80001d5c:	7ac080e7          	jalr	1964(ra) # 80000504 <printf>
    if (map_region(kernel_pagetable, KERNBASE, KERNBASE, 
    80001d60:	4729                	li	a4,10
    80001d62:	80008697          	auipc	a3,0x80008
    80001d66:	29e68693          	addi	a3,a3,670 # a000 <_entry-0x7fff6000>
    80001d6a:	01f91613          	slli	a2,s2,0x1f
    80001d6e:	85b2                	mv	a1,a2
    80001d70:	0000e517          	auipc	a0,0xe
    80001d74:	ae853503          	ld	a0,-1304(a0) # 8000f858 <kernel_pagetable>
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	cbc080e7          	jalr	-836(ra) # 80001a34 <map_region>
    80001d80:	e149                	bnez	a0,80001e02 <kvm_map_kernel+0xde>
    printf("  Text mapping: SUCCESS\n");
    80001d82:	00009517          	auipc	a0,0x9
    80001d86:	fb650513          	addi	a0,a0,-74 # 8000ad38 <digits+0xb88>
    80001d8a:	ffffe097          	auipc	ra,0xffffe
    80001d8e:	77a080e7          	jalr	1914(ra) # 80000504 <printf>
    printf("  Data+Physical: 0x%p - 0x%p [RW]\n", 
    80001d92:	4945                	li	s2,17
    80001d94:	01b91613          	slli	a2,s2,0x1b
    80001d98:	00008597          	auipc	a1,0x8
    80001d9c:	26858593          	addi	a1,a1,616 # 8000a000 <etext>
    80001da0:	00009517          	auipc	a0,0x9
    80001da4:	fb850513          	addi	a0,a0,-72 # 8000ad58 <digits+0xba8>
    80001da8:	ffffe097          	auipc	ra,0xffffe
    80001dac:	75c080e7          	jalr	1884(ra) # 80000504 <printf>
    uint64 data_physical_size = PHYSTOP - (uint64)etext;
    80001db0:	01b91693          	slli	a3,s2,0x1b
    if (map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
    80001db4:	4719                	li	a4,6
    80001db6:	8e85                	sub	a3,a3,s1
    80001db8:	8626                	mv	a2,s1
    80001dba:	85a6                	mv	a1,s1
    80001dbc:	0000e517          	auipc	a0,0xe
    80001dc0:	a9c53503          	ld	a0,-1380(a0) # 8000f858 <kernel_pagetable>
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	c70080e7          	jalr	-912(ra) # 80001a34 <map_region>
    80001dcc:	e521                	bnez	a0,80001e14 <kvm_map_kernel+0xf0>
    printf("  Data+Physical mapping: SUCCESS\n");
    80001dce:	00009517          	auipc	a0,0x9
    80001dd2:	fea50513          	addi	a0,a0,-22 # 8000adb8 <digits+0xc08>
    80001dd6:	ffffe097          	auipc	ra,0xffffe
    80001dda:	72e080e7          	jalr	1838(ra) # 80000504 <printf>
    kvm_map_devices();
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	e24080e7          	jalr	-476(ra) # 80001c02 <kvm_map_devices>
    printf("KVM: Kernel page table initialized successfully\n");
    80001de6:	00009517          	auipc	a0,0x9
    80001dea:	ffa50513          	addi	a0,a0,-6 # 8000ade0 <digits+0xc30>
    80001dee:	ffffe097          	auipc	ra,0xffffe
    80001df2:	716080e7          	jalr	1814(ra) # 80000504 <printf>
}
    80001df6:	60e2                	ld	ra,24(sp)
    80001df8:	6442                	ld	s0,16(sp)
    80001dfa:	64a2                	ld	s1,8(sp)
    80001dfc:	6902                	ld	s2,0(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret
        printf("KVM: Error: kernel text mapping failed\n");
    80001e02:	00009517          	auipc	a0,0x9
    80001e06:	f0e50513          	addi	a0,a0,-242 # 8000ad10 <digits+0xb60>
    80001e0a:	ffffe097          	auipc	ra,0xffffe
    80001e0e:	6fa080e7          	jalr	1786(ra) # 80000504 <printf>
        return;
    80001e12:	b7d5                	j	80001df6 <kvm_map_kernel+0xd2>
        printf("KVM: Error: data+physical memory mapping failed\n");
    80001e14:	00009517          	auipc	a0,0x9
    80001e18:	f6c50513          	addi	a0,a0,-148 # 8000ad80 <digits+0xbd0>
    80001e1c:	ffffe097          	auipc	ra,0xffffe
    80001e20:	6e8080e7          	jalr	1768(ra) # 80000504 <printf>
        return;
    80001e24:	bfc9                	j	80001df6 <kvm_map_kernel+0xd2>

0000000080001e26 <kvminit>:
void kvminit(void) {
    80001e26:	1141                	addi	sp,sp,-16
    80001e28:	e406                	sd	ra,8(sp)
    80001e2a:	e022                	sd	s0,0(sp)
    80001e2c:	0800                	addi	s0,sp,16
    if (kernel_pagetable != NULL) {
    80001e2e:	0000e797          	auipc	a5,0xe
    80001e32:	a2a7b783          	ld	a5,-1494(a5) # 8000f858 <kernel_pagetable>
    80001e36:	cf89                	beqz	a5,80001e50 <kvminit+0x2a>
        printf("KVM: Kernel page table already initialized\n");
    80001e38:	00009517          	auipc	a0,0x9
    80001e3c:	fe050513          	addi	a0,a0,-32 # 8000ae18 <digits+0xc68>
    80001e40:	ffffe097          	auipc	ra,0xffffe
    80001e44:	6c4080e7          	jalr	1732(ra) # 80000504 <printf>
}
    80001e48:	60a2                	ld	ra,8(sp)
    80001e4a:	6402                	ld	s0,0(sp)
    80001e4c:	0141                	addi	sp,sp,16
    80001e4e:	8082                	ret
    printf("KVM: Initializing kernel page table...\n");
    80001e50:	00009517          	auipc	a0,0x9
    80001e54:	ff850513          	addi	a0,a0,-8 # 8000ae48 <digits+0xc98>
    80001e58:	ffffe097          	auipc	ra,0xffffe
    80001e5c:	6ac080e7          	jalr	1708(ra) # 80000504 <printf>
    kernel_pagetable = create_pagetable();
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	a12080e7          	jalr	-1518(ra) # 80001872 <create_pagetable>
    80001e68:	0000e797          	auipc	a5,0xe
    80001e6c:	9ea7b823          	sd	a0,-1552(a5) # 8000f858 <kernel_pagetable>
    if (kernel_pagetable == NULL) {
    80001e70:	cd11                	beqz	a0,80001e8c <kvminit+0x66>
    kvm_map_kernel();  
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	eb2080e7          	jalr	-334(ra) # 80001d24 <kvm_map_kernel>
    printf("KVM: Kernel page table initialized successfully\n");
    80001e7a:	00009517          	auipc	a0,0x9
    80001e7e:	f6650513          	addi	a0,a0,-154 # 8000ade0 <digits+0xc30>
    80001e82:	ffffe097          	auipc	ra,0xffffe
    80001e86:	682080e7          	jalr	1666(ra) # 80000504 <printf>
    80001e8a:	bf7d                	j	80001e48 <kvminit+0x22>
        panic("kvminit: failed to create kernel page table");
    80001e8c:	00009517          	auipc	a0,0x9
    80001e90:	fe450513          	addi	a0,a0,-28 # 8000ae70 <digits+0xcc0>
    80001e94:	00001097          	auipc	ra,0x1
    80001e98:	bf8080e7          	jalr	-1032(ra) # 80002a8c <panic>

0000000080001e9c <kvminithart>:

// 激活内核页表
void kvminithart(void) {
    80001e9c:	1101                	addi	sp,sp,-32
    80001e9e:	ec06                	sd	ra,24(sp)
    80001ea0:	e822                	sd	s0,16(sp)
    80001ea2:	e426                	sd	s1,8(sp)
    80001ea4:	1000                	addi	s0,sp,32
    printf("KVM: Activating kernel page table...\n");
    80001ea6:	00009517          	auipc	a0,0x9
    80001eaa:	ffa50513          	addi	a0,a0,-6 # 8000aea0 <digits+0xcf0>
    80001eae:	ffffe097          	auipc	ra,0xffffe
    80001eb2:	656080e7          	jalr	1622(ra) # 80000504 <printf>
    
    if (kernel_pagetable == NULL) {
    80001eb6:	0000e797          	auipc	a5,0xe
    80001eba:	9a27b783          	ld	a5,-1630(a5) # 8000f858 <kernel_pagetable>
    80001ebe:	cba9                	beqz	a5,80001f10 <kvminithart+0x74>
        panic("kvminithart: kernel page table not initialized");
    }
    
    // 等待之前的写操作完成
    asm volatile("sfence.vma");
    80001ec0:	12000073          	sfence.vma

// RISC-V CSR 操作函数
static inline uint64 r_satp()
{
    uint64 x;
    asm volatile("csrr %0, satp" : "=r"(x));
    80001ec4:	180024f3          	csrr	s1,satp
    
    // 保存旧的SATP值（用于调试）
    uint64 old_satp = r_satp();
    
    // 设置SATP寄存器
    uint64 new_satp = MAKE_SATP(kernel_pagetable);
    80001ec8:	0000e797          	auipc	a5,0xe
    80001ecc:	9907b783          	ld	a5,-1648(a5) # 8000f858 <kernel_pagetable>
    80001ed0:	83b1                	srli	a5,a5,0xc
    80001ed2:	577d                	li	a4,-1
    80001ed4:	177e                	slli	a4,a4,0x3f
    80001ed6:	8fd9                	or	a5,a5,a4
    return x;
}

static inline void w_satp(uint64 x)
{
    asm volatile("csrw satp, %0" : : "r"(x));
    80001ed8:	18079073          	csrw	satp,a5
    w_satp(new_satp);
    
    // 刷新TLB
    asm volatile("sfence.vma");
    80001edc:	12000073          	sfence.vma
    
    printf("KVM: Virtual memory enabled\n");
    80001ee0:	00009517          	auipc	a0,0x9
    80001ee4:	01850513          	addi	a0,a0,24 # 8000aef8 <digits+0xd48>
    80001ee8:	ffffe097          	auipc	ra,0xffffe
    80001eec:	61c080e7          	jalr	1564(ra) # 80000504 <printf>
    asm volatile("csrr %0, satp" : "=r"(x));
    80001ef0:	18002673          	csrr	a2,satp
    printf("KVM: SATP changed: 0x%p -> 0x%p\n", 
    80001ef4:	85a6                	mv	a1,s1
    80001ef6:	00009517          	auipc	a0,0x9
    80001efa:	02250513          	addi	a0,a0,34 # 8000af18 <digits+0xd68>
    80001efe:	ffffe097          	auipc	ra,0xffffe
    80001f02:	606080e7          	jalr	1542(ra) # 80000504 <printf>
           (void*)old_satp, (void*)r_satp());
}
    80001f06:	60e2                	ld	ra,24(sp)
    80001f08:	6442                	ld	s0,16(sp)
    80001f0a:	64a2                	ld	s1,8(sp)
    80001f0c:	6105                	addi	sp,sp,32
    80001f0e:	8082                	ret
        panic("kvminithart: kernel page table not initialized");
    80001f10:	00009517          	auipc	a0,0x9
    80001f14:	fb850513          	addi	a0,a0,-72 # 8000aec8 <digits+0xd18>
    80001f18:	00001097          	auipc	ra,0x1
    80001f1c:	b74080e7          	jalr	-1164(ra) # 80002a8c <panic>

0000000080001f20 <get_kernel_pagetable>:

// 获取内核页表
void* get_kernel_pagetable(void) {
    80001f20:	1141                	addi	sp,sp,-16
    80001f22:	e422                	sd	s0,8(sp)
    80001f24:	0800                	addi	s0,sp,16
    return (void*)kernel_pagetable;
}
    80001f26:	0000e517          	auipc	a0,0xe
    80001f2a:	93253503          	ld	a0,-1742(a0) # 8000f858 <kernel_pagetable>
    80001f2e:	6422                	ld	s0,8(sp)
    80001f30:	0141                	addi	sp,sp,16
    80001f32:	8082                	ret

0000000080001f34 <vm_test_basic>:

// ==================== 测试函数 ====================

// 基本测试函数
void vm_test_basic(void) {
    80001f34:	715d                	addi	sp,sp,-80
    80001f36:	e486                	sd	ra,72(sp)
    80001f38:	e0a2                	sd	s0,64(sp)
    80001f3a:	fc26                	sd	s1,56(sp)
    80001f3c:	f84a                	sd	s2,48(sp)
    80001f3e:	f44e                	sd	s3,40(sp)
    80001f40:	f052                	sd	s4,32(sp)
    80001f42:	ec56                	sd	s5,24(sp)
    80001f44:	e85a                	sd	s6,16(sp)
    80001f46:	e45e                	sd	s7,8(sp)
    80001f48:	0880                	addi	s0,sp,80
    printf("\n=== Virtual Memory System Test ===\n\n");
    80001f4a:	00009517          	auipc	a0,0x9
    80001f4e:	ff650513          	addi	a0,a0,-10 # 8000af40 <digits+0xd90>
    80001f52:	ffffe097          	auipc	ra,0xffffe
    80001f56:	5b2080e7          	jalr	1458(ra) # 80000504 <printf>
    
    // 1. 创建页表
    printf("1. Creating page table...\n");
    80001f5a:	00009517          	auipc	a0,0x9
    80001f5e:	00e50513          	addi	a0,a0,14 # 8000af68 <digits+0xdb8>
    80001f62:	ffffe097          	auipc	ra,0xffffe
    80001f66:	5a2080e7          	jalr	1442(ra) # 80000504 <printf>
    pagetable_t pt = create_pagetable();
    80001f6a:	00000097          	auipc	ra,0x0
    80001f6e:	908080e7          	jalr	-1784(ra) # 80001872 <create_pagetable>
    if (pt == NULL) {
    80001f72:	20050163          	beqz	a0,80002174 <vm_test_basic+0x240>
    80001f76:	84aa                	mv	s1,a0
        printf("FAIL: Failed to create page table\n");
        return;
    }
    printf("SUCCESS: Page table created at 0x%p\n", pt);
    80001f78:	85aa                	mv	a1,a0
    80001f7a:	00009517          	auipc	a0,0x9
    80001f7e:	03650513          	addi	a0,a0,54 # 8000afb0 <digits+0xe00>
    80001f82:	ffffe097          	auipc	ra,0xffffe
    80001f86:	582080e7          	jalr	1410(ra) # 80000504 <printf>
    
    // 2. 分配一些物理页
    printf("\n2. Allocating physical pages...\n");
    80001f8a:	00009517          	auipc	a0,0x9
    80001f8e:	04e50513          	addi	a0,a0,78 # 8000afd8 <digits+0xe28>
    80001f92:	ffffe097          	auipc	ra,0xffffe
    80001f96:	572080e7          	jalr	1394(ra) # 80000504 <printf>
    void *page1 = alloc_page();
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	03e080e7          	jalr	62(ra) # 80000fd8 <alloc_page>
    80001fa2:	892a                	mv	s2,a0
    void *page2 = alloc_page();
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	034080e7          	jalr	52(ra) # 80000fd8 <alloc_page>
    80001fac:	89aa                	mv	s3,a0
    void *page3 = alloc_page();
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	02a080e7          	jalr	42(ra) # 80000fd8 <alloc_page>
    80001fb6:	8a2a                	mv	s4,a0
    
    if (!page1 || !page2 || !page3) {
    80001fb8:	1c090763          	beqz	s2,80002186 <vm_test_basic+0x252>
    80001fbc:	1c098563          	beqz	s3,80002186 <vm_test_basic+0x252>
    80001fc0:	1c050363          	beqz	a0,80002186 <vm_test_basic+0x252>
        printf("FAIL: Failed to allocate physical pages\n");
        destroy_pagetable(pt);
        return;
    }
    printf("SUCCESS: Allocated pages: 0x%p, 0x%p, 0x%p\n", page1, page2, page3);
    80001fc4:	86aa                	mv	a3,a0
    80001fc6:	864e                	mv	a2,s3
    80001fc8:	85ca                	mv	a1,s2
    80001fca:	00009517          	auipc	a0,0x9
    80001fce:	06650513          	addi	a0,a0,102 # 8000b030 <digits+0xe80>
    80001fd2:	ffffe097          	auipc	ra,0xffffe
    80001fd6:	532080e7          	jalr	1330(ra) # 80000504 <printf>
    
    // 3. 建立映射
    printf("\n3. Creating mappings...\n");
    80001fda:	00009517          	auipc	a0,0x9
    80001fde:	08650513          	addi	a0,a0,134 # 8000b060 <digits+0xeb0>
    80001fe2:	ffffe097          	auipc	ra,0xffffe
    80001fe6:	522080e7          	jalr	1314(ra) # 80000504 <printf>
    
    // 映射1: 代码页 (RX)
    if (map_page(pt, 0x1000, (uint64)page1, PTE_R | PTE_X) != 0) {
    80001fea:	46a9                	li	a3,10
    80001fec:	864a                	mv	a2,s2
    80001fee:	6585                	lui	a1,0x1
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	00000097          	auipc	ra,0x0
    80001ff6:	9ba080e7          	jalr	-1606(ra) # 800019ac <map_page>
    80001ffa:	1a050463          	beqz	a0,800021a2 <vm_test_basic+0x26e>
        printf("FAIL: Failed to map code page\n");
    80001ffe:	00009517          	auipc	a0,0x9
    80002002:	08250513          	addi	a0,a0,130 # 8000b080 <digits+0xed0>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	4fe080e7          	jalr	1278(ra) # 80000504 <printf>
    } else {
        printf("SUCCESS: Mapped 0x1000 -> 0x%p [RX]\n", page1);
    }
    
    // 映射2: 数据页 (RW)
    if (map_page(pt, 0x2000, (uint64)page2, PTE_R | PTE_W) != 0) {
    8000200e:	4699                	li	a3,6
    80002010:	864e                	mv	a2,s3
    80002012:	6589                	lui	a1,0x2
    80002014:	8526                	mv	a0,s1
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	996080e7          	jalr	-1642(ra) # 800019ac <map_page>
    8000201e:	18050c63          	beqz	a0,800021b6 <vm_test_basic+0x282>
        printf("FAIL: Failed to map data page\n");
    80002022:	00009517          	auipc	a0,0x9
    80002026:	0a650513          	addi	a0,a0,166 # 8000b0c8 <digits+0xf18>
    8000202a:	ffffe097          	auipc	ra,0xffffe
    8000202e:	4da080e7          	jalr	1242(ra) # 80000504 <printf>
    } else {
        printf("SUCCESS: Mapped 0x2000 -> 0x%p [RW]\n", page2);
    }
    
    // 映射3: 用户数据页 (RWU)
    if (map_page(pt, 0x3000, (uint64)page3, PTE_R | PTE_W | PTE_U) != 0) {
    80002032:	46d9                	li	a3,22
    80002034:	8652                	mv	a2,s4
    80002036:	658d                	lui	a1,0x3
    80002038:	8526                	mv	a0,s1
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	972080e7          	jalr	-1678(ra) # 800019ac <map_page>
    80002042:	18050463          	beqz	a0,800021ca <vm_test_basic+0x296>
        printf("FAIL: Failed to map user page\n");
    80002046:	00009517          	auipc	a0,0x9
    8000204a:	0ca50513          	addi	a0,a0,202 # 8000b110 <digits+0xf60>
    8000204e:	ffffe097          	auipc	ra,0xffffe
    80002052:	4b6080e7          	jalr	1206(ra) # 80000504 <printf>
    } else {
        printf("SUCCESS: Mapped 0x3000 -> 0x%p [RWU]\n", page3);
    }
    
    // 4. 测试地址转换
    printf("\n4. Testing address translation...\n");
    80002056:	00009517          	auipc	a0,0x9
    8000205a:	10250513          	addi	a0,a0,258 # 8000b158 <digits+0xfa8>
    8000205e:	ffffe097          	auipc	ra,0xffffe
    80002062:	4a6080e7          	jalr	1190(ra) # 80000504 <printf>
    uint64 pa1 = walkaddr(pt, 0x1000);
    80002066:	6585                	lui	a1,0x1
    80002068:	8526                	mv	a0,s1
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	b00080e7          	jalr	-1280(ra) # 80001b6a <walkaddr>
    80002072:	8baa                	mv	s7,a0
    uint64 pa2 = walkaddr(pt, 0x2000);
    80002074:	6589                	lui	a1,0x2
    80002076:	8526                	mv	a0,s1
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	af2080e7          	jalr	-1294(ra) # 80001b6a <walkaddr>
    80002080:	8b2a                	mv	s6,a0
    uint64 pa3 = walkaddr(pt, 0x3000);
    80002082:	658d                	lui	a1,0x3
    80002084:	8526                	mv	a0,s1
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	ae4080e7          	jalr	-1308(ra) # 80001b6a <walkaddr>
    8000208e:	8aaa                	mv	s5,a0
    
    printf("walkaddr(0x1000) = 0x%p (expected: 0x%p)\n", (void*)pa1, page1);
    80002090:	864a                	mv	a2,s2
    80002092:	85de                	mv	a1,s7
    80002094:	00009517          	auipc	a0,0x9
    80002098:	0ec50513          	addi	a0,a0,236 # 8000b180 <digits+0xfd0>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	468080e7          	jalr	1128(ra) # 80000504 <printf>
    printf("walkaddr(0x2000) = 0x%p (expected: 0x%p)\n", (void*)pa2, page2);
    800020a4:	864e                	mv	a2,s3
    800020a6:	85da                	mv	a1,s6
    800020a8:	00009517          	auipc	a0,0x9
    800020ac:	10850513          	addi	a0,a0,264 # 8000b1b0 <digits+0x1000>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	454080e7          	jalr	1108(ra) # 80000504 <printf>
    printf("walkaddr(0x3000) = 0x%p (expected: 0x%p)\n", (void*)pa3, page3);
    800020b8:	8652                	mv	a2,s4
    800020ba:	85d6                	mv	a1,s5
    800020bc:	00009517          	auipc	a0,0x9
    800020c0:	12450513          	addi	a0,a0,292 # 8000b1e0 <digits+0x1030>
    800020c4:	ffffe097          	auipc	ra,0xffffe
    800020c8:	440080e7          	jalr	1088(ra) # 80000504 <printf>
    
    // 5. 测试无效地址
    uint64 pa_invalid = walkaddr(pt, 0x4000);
    800020cc:	6591                	lui	a1,0x4
    800020ce:	8526                	mv	a0,s1
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	a9a080e7          	jalr	-1382(ra) # 80001b6a <walkaddr>
    800020d8:	85aa                	mv	a1,a0
    printf("walkaddr(0x4000) = 0x%p (expected: 0x0)\n", (void*)pa_invalid);
    800020da:	00009517          	auipc	a0,0x9
    800020de:	13650513          	addi	a0,a0,310 # 8000b210 <digits+0x1060>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	422080e7          	jalr	1058(ra) # 80000504 <printf>
    
    // 6. 打印页表结构
    printf("\n5. Page table structure:\n");
    800020ea:	00009517          	auipc	a0,0x9
    800020ee:	15650513          	addi	a0,a0,342 # 8000b240 <digits+0x1090>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	412080e7          	jalr	1042(ra) # 80000504 <printf>
    dump_pagetable(pt, 2);
    800020fa:	4589                	li	a1,2
    800020fc:	8526                	mv	a0,s1
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	aa6080e7          	jalr	-1370(ra) # 80001ba4 <dump_pagetable>
    
    // 7. 清理
    printf("\n6. Cleaning up...\n");
    80002106:	00009517          	auipc	a0,0x9
    8000210a:	15a50513          	addi	a0,a0,346 # 8000b260 <digits+0x10b0>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	3f6080e7          	jalr	1014(ra) # 80000504 <printf>
    destroy_pagetable(pt);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	784080e7          	jalr	1924(ra) # 8000189c <destroy_pagetable>
    free_page(page1);
    80002120:	854a                	mv	a0,s2
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	ed0080e7          	jalr	-304(ra) # 80000ff2 <free_page>
    free_page(page2);
    8000212a:	854e                	mv	a0,s3
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	ec6080e7          	jalr	-314(ra) # 80000ff2 <free_page>
    free_page(page3);
    80002134:	8552                	mv	a0,s4
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	ebc080e7          	jalr	-324(ra) # 80000ff2 <free_page>
    printf("SUCCESS: All resources freed\n");
    8000213e:	00009517          	auipc	a0,0x9
    80002142:	13a50513          	addi	a0,a0,314 # 8000b278 <digits+0x10c8>
    80002146:	ffffe097          	auipc	ra,0xffffe
    8000214a:	3be080e7          	jalr	958(ra) # 80000504 <printf>
    
    printf("\n=== Virtual Memory Test Completed ===\n\n");
    8000214e:	00009517          	auipc	a0,0x9
    80002152:	14a50513          	addi	a0,a0,330 # 8000b298 <digits+0x10e8>
    80002156:	ffffe097          	auipc	ra,0xffffe
    8000215a:	3ae080e7          	jalr	942(ra) # 80000504 <printf>
}
    8000215e:	60a6                	ld	ra,72(sp)
    80002160:	6406                	ld	s0,64(sp)
    80002162:	74e2                	ld	s1,56(sp)
    80002164:	7942                	ld	s2,48(sp)
    80002166:	79a2                	ld	s3,40(sp)
    80002168:	7a02                	ld	s4,32(sp)
    8000216a:	6ae2                	ld	s5,24(sp)
    8000216c:	6b42                	ld	s6,16(sp)
    8000216e:	6ba2                	ld	s7,8(sp)
    80002170:	6161                	addi	sp,sp,80
    80002172:	8082                	ret
        printf("FAIL: Failed to create page table\n");
    80002174:	00009517          	auipc	a0,0x9
    80002178:	e1450513          	addi	a0,a0,-492 # 8000af88 <digits+0xdd8>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	388080e7          	jalr	904(ra) # 80000504 <printf>
        return;
    80002184:	bfe9                	j	8000215e <vm_test_basic+0x22a>
        printf("FAIL: Failed to allocate physical pages\n");
    80002186:	00009517          	auipc	a0,0x9
    8000218a:	e7a50513          	addi	a0,a0,-390 # 8000b000 <digits+0xe50>
    8000218e:	ffffe097          	auipc	ra,0xffffe
    80002192:	376080e7          	jalr	886(ra) # 80000504 <printf>
        destroy_pagetable(pt);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	704080e7          	jalr	1796(ra) # 8000189c <destroy_pagetable>
        return;
    800021a0:	bf7d                	j	8000215e <vm_test_basic+0x22a>
        printf("SUCCESS: Mapped 0x1000 -> 0x%p [RX]\n", page1);
    800021a2:	85ca                	mv	a1,s2
    800021a4:	00009517          	auipc	a0,0x9
    800021a8:	efc50513          	addi	a0,a0,-260 # 8000b0a0 <digits+0xef0>
    800021ac:	ffffe097          	auipc	ra,0xffffe
    800021b0:	358080e7          	jalr	856(ra) # 80000504 <printf>
    800021b4:	bda9                	j	8000200e <vm_test_basic+0xda>
        printf("SUCCESS: Mapped 0x2000 -> 0x%p [RW]\n", page2);
    800021b6:	85ce                	mv	a1,s3
    800021b8:	00009517          	auipc	a0,0x9
    800021bc:	f3050513          	addi	a0,a0,-208 # 8000b0e8 <digits+0xf38>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	344080e7          	jalr	836(ra) # 80000504 <printf>
    800021c8:	b5ad                	j	80002032 <vm_test_basic+0xfe>
        printf("SUCCESS: Mapped 0x3000 -> 0x%p [RWU]\n", page3);
    800021ca:	85d2                	mv	a1,s4
    800021cc:	00009517          	auipc	a0,0x9
    800021d0:	f6450513          	addi	a0,a0,-156 # 8000b130 <digits+0xf80>
    800021d4:	ffffe097          	auipc	ra,0xffffe
    800021d8:	330080e7          	jalr	816(ra) # 80000504 <printf>
    800021dc:	bdad                	j	80002056 <vm_test_basic+0x122>

00000000800021de <test_physical_memory>:

// 物理内存分配器测试
void test_physical_memory(void) {
    800021de:	1101                	addi	sp,sp,-32
    800021e0:	ec06                	sd	ra,24(sp)
    800021e2:	e822                	sd	s0,16(sp)
    800021e4:	e426                	sd	s1,8(sp)
    800021e6:	e04a                	sd	s2,0(sp)
    800021e8:	1000                	addi	s0,sp,32
    printf("\n=== Physical Memory Allocator Test ===\n\n");
    800021ea:	00009517          	auipc	a0,0x9
    800021ee:	0de50513          	addi	a0,a0,222 # 8000b2c8 <digits+0x1118>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	312080e7          	jalr	786(ra) # 80000504 <printf>
    
    // 测试基本分配和释放
    printf("1. Testing basic allocation...\n");
    800021fa:	00009517          	auipc	a0,0x9
    800021fe:	0fe50513          	addi	a0,a0,254 # 8000b2f8 <digits+0x1148>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	302080e7          	jalr	770(ra) # 80000504 <printf>
    void *page1 = alloc_page();
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	dce080e7          	jalr	-562(ra) # 80000fd8 <alloc_page>
    80002212:	84aa                	mv	s1,a0
    void *page2 = alloc_page();
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	dc4080e7          	jalr	-572(ra) # 80000fd8 <alloc_page>
    
    if (page1 == NULL || page2 == NULL) {
    8000221c:	c8a9                	beqz	s1,8000226e <test_physical_memory+0x90>
    8000221e:	892a                	mv	s2,a0
    80002220:	c539                	beqz	a0,8000226e <test_physical_memory+0x90>
        printf("FAIL: Failed to allocate pages\n");
        return;
    }
    
    printf("  Allocated: page1=0x%p, page2=0x%p\n", page1, page2);
    80002222:	862a                	mv	a2,a0
    80002224:	85a6                	mv	a1,s1
    80002226:	00009517          	auipc	a0,0x9
    8000222a:	11250513          	addi	a0,a0,274 # 8000b338 <digits+0x1188>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	2d6080e7          	jalr	726(ra) # 80000504 <printf>
    
    // 页对齐检查
    if (((uint64)page1 & 0xFFF) != 0 || ((uint64)page2 & 0xFFF) != 0) {
    80002236:	0124e7b3          	or	a5,s1,s2
    8000223a:	17d2                	slli	a5,a5,0x34
    8000223c:	c3b1                	beqz	a5,80002280 <test_physical_memory+0xa2>
        printf("FAIL: Pages not aligned\n");
    8000223e:	00009517          	auipc	a0,0x9
    80002242:	12250513          	addi	a0,a0,290 # 8000b360 <digits+0x11b0>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	2be080e7          	jalr	702(ra) # 80000504 <printf>
        free_page(page1);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	da2080e7          	jalr	-606(ra) # 80000ff2 <free_page>
        free_page(page2);
    80002258:	854a                	mv	a0,s2
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	d98080e7          	jalr	-616(ra) # 80000ff2 <free_page>
    // 清理
    free_page(page2);
    free_page(page3);
    
    printf("SUCCESS: Physical memory test passed\n");
}
    80002262:	60e2                	ld	ra,24(sp)
    80002264:	6442                	ld	s0,16(sp)
    80002266:	64a2                	ld	s1,8(sp)
    80002268:	6902                	ld	s2,0(sp)
    8000226a:	6105                	addi	sp,sp,32
    8000226c:	8082                	ret
        printf("FAIL: Failed to allocate pages\n");
    8000226e:	00009517          	auipc	a0,0x9
    80002272:	0aa50513          	addi	a0,a0,170 # 8000b318 <digits+0x1168>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	28e080e7          	jalr	654(ra) # 80000504 <printf>
        return;
    8000227e:	b7d5                	j	80002262 <test_physical_memory+0x84>
    printf("  Page alignment check: PASS\n");
    80002280:	00009517          	auipc	a0,0x9
    80002284:	10050513          	addi	a0,a0,256 # 8000b380 <digits+0x11d0>
    80002288:	ffffe097          	auipc	ra,0xffffe
    8000228c:	27c080e7          	jalr	636(ra) # 80000504 <printf>
    printf("2. Testing data access...\n");
    80002290:	00009517          	auipc	a0,0x9
    80002294:	11050513          	addi	a0,a0,272 # 8000b3a0 <digits+0x11f0>
    80002298:	ffffe097          	auipc	ra,0xffffe
    8000229c:	26c080e7          	jalr	620(ra) # 80000504 <printf>
    *(uint64*)page1 = 0x123456789ABCDEF0;
    800022a0:	00008797          	auipc	a5,0x8
    800022a4:	dc87b783          	ld	a5,-568(a5) # 8000a068 <etext+0x68>
    800022a8:	e09c                	sd	a5,0(s1)
    printf("  Data access test: PASS\n");
    800022aa:	00009517          	auipc	a0,0x9
    800022ae:	11650513          	addi	a0,a0,278 # 8000b3c0 <digits+0x1210>
    800022b2:	ffffe097          	auipc	ra,0xffffe
    800022b6:	252080e7          	jalr	594(ra) # 80000504 <printf>
    printf("3. Testing free and realloc...\n");
    800022ba:	00009517          	auipc	a0,0x9
    800022be:	12650513          	addi	a0,a0,294 # 8000b3e0 <digits+0x1230>
    800022c2:	ffffe097          	auipc	ra,0xffffe
    800022c6:	242080e7          	jalr	578(ra) # 80000504 <printf>
    free_page(page1);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	d26080e7          	jalr	-730(ra) # 80000ff2 <free_page>
    void *page3 = alloc_page();
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	d04080e7          	jalr	-764(ra) # 80000fd8 <alloc_page>
    800022dc:	84aa                	mv	s1,a0
    if (page3 == NULL) {
    800022de:	cd0d                	beqz	a0,80002318 <test_physical_memory+0x13a>
    printf("  Reallocated: page3=0x%p\n", page3);
    800022e0:	85aa                	mv	a1,a0
    800022e2:	00009517          	auipc	a0,0x9
    800022e6:	14650513          	addi	a0,a0,326 # 8000b428 <digits+0x1278>
    800022ea:	ffffe097          	auipc	ra,0xffffe
    800022ee:	21a080e7          	jalr	538(ra) # 80000504 <printf>
    free_page(page2);
    800022f2:	854a                	mv	a0,s2
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	cfe080e7          	jalr	-770(ra) # 80000ff2 <free_page>
    free_page(page3);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	cf4080e7          	jalr	-780(ra) # 80000ff2 <free_page>
    printf("SUCCESS: Physical memory test passed\n");
    80002306:	00009517          	auipc	a0,0x9
    8000230a:	14250513          	addi	a0,a0,322 # 8000b448 <digits+0x1298>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	1f6080e7          	jalr	502(ra) # 80000504 <printf>
    80002316:	b7b1                	j	80002262 <test_physical_memory+0x84>
        printf("FAIL: Failed to reallocate page\n");
    80002318:	00009517          	auipc	a0,0x9
    8000231c:	0e850513          	addi	a0,a0,232 # 8000b400 <digits+0x1250>
    80002320:	ffffe097          	auipc	ra,0xffffe
    80002324:	1e4080e7          	jalr	484(ra) # 80000504 <printf>
        free_page(page2);
    80002328:	854a                	mv	a0,s2
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	cc8080e7          	jalr	-824(ra) # 80000ff2 <free_page>
        return;
    80002332:	bf05                	j	80002262 <test_physical_memory+0x84>

0000000080002334 <test_pagetable>:

// 页表功能测试
void test_pagetable(void) {
    80002334:	7139                	addi	sp,sp,-64
    80002336:	fc06                	sd	ra,56(sp)
    80002338:	f822                	sd	s0,48(sp)
    8000233a:	f426                	sd	s1,40(sp)
    8000233c:	f04a                	sd	s2,32(sp)
    8000233e:	ec4e                	sd	s3,24(sp)
    80002340:	e852                	sd	s4,16(sp)
    80002342:	e456                	sd	s5,8(sp)
    80002344:	0080                	addi	s0,sp,64
    printf("\n=== Page Table Function Test ===\n\n");
    80002346:	00009517          	auipc	a0,0x9
    8000234a:	12a50513          	addi	a0,a0,298 # 8000b470 <digits+0x12c0>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1b6080e7          	jalr	438(ra) # 80000504 <printf>
    
    pagetable_t pt = create_pagetable();
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	51c080e7          	jalr	1308(ra) # 80001872 <create_pagetable>
    if (pt == NULL) {
    8000235e:	cd4d                	beqz	a0,80002418 <test_pagetable+0xe4>
    80002360:	84aa                	mv	s1,a0
        printf("FAIL: Failed to create page table\n");
        return;
    }
    
    printf("1. Created page table at 0x%p\n", pt);
    80002362:	85aa                	mv	a1,a0
    80002364:	00009517          	auipc	a0,0x9
    80002368:	13450513          	addi	a0,a0,308 # 8000b498 <digits+0x12e8>
    8000236c:	ffffe097          	auipc	ra,0xffffe
    80002370:	198080e7          	jalr	408(ra) # 80000504 <printf>
    
    // 测试基本映射
    printf("2. Testing basic mapping...\n");
    80002374:	00009517          	auipc	a0,0x9
    80002378:	14450513          	addi	a0,a0,324 # 8000b4b8 <digits+0x1308>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	188080e7          	jalr	392(ra) # 80000504 <printf>
    uint64 va = 0x1000000;
    void *physical_page = alloc_page();
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	c54080e7          	jalr	-940(ra) # 80000fd8 <alloc_page>
    8000238c:	892a                	mv	s2,a0
    if (physical_page == NULL) {
    8000238e:	cd51                	beqz	a0,8000242a <test_pagetable+0xf6>
        printf("FAIL: Failed to allocate physical page\n");
        destroy_pagetable(pt);
        return;
    }
    
    if (map_page(pt, va, (uint64)physical_page, PTE_R | PTE_W) != 0) {
    80002390:	4699                	li	a3,6
    80002392:	862a                	mv	a2,a0
    80002394:	010005b7          	lui	a1,0x1000
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	612080e7          	jalr	1554(ra) # 800019ac <map_page>
    800023a2:	e155                	bnez	a0,80002446 <test_pagetable+0x112>
        printf("FAIL: Failed to map page\n");
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    printf("  Mapped VA 0x%p -> PA 0x%p [RW]\n", (void*)va, physical_page);
    800023a4:	864a                	mv	a2,s2
    800023a6:	010005b7          	lui	a1,0x1000
    800023aa:	00009517          	auipc	a0,0x9
    800023ae:	17650513          	addi	a0,a0,374 # 8000b520 <digits+0x1370>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	152080e7          	jalr	338(ra) # 80000504 <printf>
    
    // 测试地址转换
    printf("3. Testing address translation...\n");
    800023ba:	00009517          	auipc	a0,0x9
    800023be:	18e50513          	addi	a0,a0,398 # 8000b548 <digits+0x1398>
    800023c2:	ffffe097          	auipc	ra,0xffffe
    800023c6:	142080e7          	jalr	322(ra) # 80000504 <printf>
    pte_t *pte = walk_lookup(pt, va);
    800023ca:	010005b7          	lui	a1,0x1000
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	4ea080e7          	jalr	1258(ra) # 800018ba <walk_lookup>
    800023d8:	8a2a                	mv	s4,a0
    if (pte == NULL || !(*pte & PTE_V)) {
    800023da:	c14d                	beqz	a0,8000247c <test_pagetable+0x148>
    800023dc:	6110                	ld	a2,0(a0)
    800023de:	00167793          	andi	a5,a2,1
    800023e2:	cfc9                	beqz	a5,8000247c <test_pagetable+0x148>
        free_page(physical_page);
        destroy_pagetable(pt);
        return;
    }
    
    uint64 translated_pa = PTE2PA(*pte);
    800023e4:	8229                	srli	a2,a2,0xa
    800023e6:	00c61993          	slli	s3,a2,0xc
    if (translated_pa != (uint64)physical_page) {
    800023ea:	0b390c63          	beq	s2,s3,800024a2 <test_pagetable+0x16e>
        printf("FAIL: Address translation error: expected 0x%p, got 0x%p\n",
    800023ee:	864e                	mv	a2,s3
    800023f0:	85ca                	mv	a1,s2
    800023f2:	00009517          	auipc	a0,0x9
    800023f6:	19e50513          	addi	a0,a0,414 # 8000b590 <digits+0x13e0>
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	10a080e7          	jalr	266(ra) # 80000504 <printf>
               physical_page, (void*)translated_pa);
        free_page(physical_page);
    80002402:	854a                	mv	a0,s2
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	bee080e7          	jalr	-1042(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	48e080e7          	jalr	1166(ra) # 8000189c <destroy_pagetable>
        return;
    80002416:	a891                	j	8000246a <test_pagetable+0x136>
        printf("FAIL: Failed to create page table\n");
    80002418:	00009517          	auipc	a0,0x9
    8000241c:	b7050513          	addi	a0,a0,-1168 # 8000af88 <digits+0xdd8>
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	0e4080e7          	jalr	228(ra) # 80000504 <printf>
        return;
    80002428:	a089                	j	8000246a <test_pagetable+0x136>
        printf("FAIL: Failed to allocate physical page\n");
    8000242a:	00009517          	auipc	a0,0x9
    8000242e:	0ae50513          	addi	a0,a0,174 # 8000b4d8 <digits+0x1328>
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	0d2080e7          	jalr	210(ra) # 80000504 <printf>
        destroy_pagetable(pt);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	460080e7          	jalr	1120(ra) # 8000189c <destroy_pagetable>
        return;
    80002444:	a01d                	j	8000246a <test_pagetable+0x136>
        printf("FAIL: Failed to map page\n");
    80002446:	00009517          	auipc	a0,0x9
    8000244a:	0ba50513          	addi	a0,a0,186 # 8000b500 <digits+0x1350>
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	0b6080e7          	jalr	182(ra) # 80000504 <printf>
        free_page(physical_page);
    80002456:	854a                	mv	a0,s2
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	b9a080e7          	jalr	-1126(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	43a080e7          	jalr	1082(ra) # 8000189c <destroy_pagetable>
    // 清理
    free_page(physical_page);
    destroy_pagetable(pt);
    
    printf("SUCCESS: Page table test passed\n");
}
    8000246a:	70e2                	ld	ra,56(sp)
    8000246c:	7442                	ld	s0,48(sp)
    8000246e:	74a2                	ld	s1,40(sp)
    80002470:	7902                	ld	s2,32(sp)
    80002472:	69e2                	ld	s3,24(sp)
    80002474:	6a42                	ld	s4,16(sp)
    80002476:	6aa2                	ld	s5,8(sp)
    80002478:	6121                	addi	sp,sp,64
    8000247a:	8082                	ret
        printf("FAIL: PTE not found or invalid\n");
    8000247c:	00009517          	auipc	a0,0x9
    80002480:	0f450513          	addi	a0,a0,244 # 8000b570 <digits+0x13c0>
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	080080e7          	jalr	128(ra) # 80000504 <printf>
        free_page(physical_page);
    8000248c:	854a                	mv	a0,s2
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	b64080e7          	jalr	-1180(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	404080e7          	jalr	1028(ra) # 8000189c <destroy_pagetable>
        return;
    800024a0:	b7e9                	j	8000246a <test_pagetable+0x136>
    printf("  Address translation: PASS\n");
    800024a2:	00009517          	auipc	a0,0x9
    800024a6:	12e50513          	addi	a0,a0,302 # 8000b5d0 <digits+0x1420>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	05a080e7          	jalr	90(ra) # 80000504 <printf>
    printf("4. Testing permission bits...\n");
    800024b2:	00009517          	auipc	a0,0x9
    800024b6:	13e50513          	addi	a0,a0,318 # 8000b5f0 <digits+0x1440>
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	04a080e7          	jalr	74(ra) # 80000504 <printf>
    if (!(*pte & PTE_R)) {
    800024c2:	000a3783          	ld	a5,0(s4)
    800024c6:	0027f713          	andi	a4,a5,2
    800024ca:	c725                	beqz	a4,80002532 <test_pagetable+0x1fe>
    if (!(*pte & PTE_W)) {
    800024cc:	0047f713          	andi	a4,a5,4
    800024d0:	c741                	beqz	a4,80002558 <test_pagetable+0x224>
    if (*pte & PTE_X) {
    800024d2:	8ba1                	andi	a5,a5,8
    800024d4:	e7cd                	bnez	a5,8000257e <test_pagetable+0x24a>
    printf("  Permission bits: PASS\n");
    800024d6:	00009517          	auipc	a0,0x9
    800024da:	1aa50513          	addi	a0,a0,426 # 8000b680 <digits+0x14d0>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	026080e7          	jalr	38(ra) # 80000504 <printf>
    printf("5. Testing walkaddr function...\n");
    800024e6:	00009517          	auipc	a0,0x9
    800024ea:	1ba50513          	addi	a0,a0,442 # 8000b6a0 <digits+0x14f0>
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	016080e7          	jalr	22(ra) # 80000504 <printf>
    uint64 walkaddr_result = walkaddr(pt, va);
    800024f6:	010005b7          	lui	a1,0x1000
    800024fa:	8526                	mv	a0,s1
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	66e080e7          	jalr	1646(ra) # 80001b6a <walkaddr>
    if (walkaddr_result != ((uint64)physical_page | (va & 0xFFF))) {
    80002504:	0aa98063          	beq	s3,a0,800025a4 <test_pagetable+0x270>
        printf("FAIL: walkaddr returned 0x%p, expected 0x%p\n",
    80002508:	864a                	mv	a2,s2
    8000250a:	85aa                	mv	a1,a0
    8000250c:	00009517          	auipc	a0,0x9
    80002510:	1bc50513          	addi	a0,a0,444 # 8000b6c8 <digits+0x1518>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	ff0080e7          	jalr	-16(ra) # 80000504 <printf>
        free_page(physical_page);
    8000251c:	854a                	mv	a0,s2
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	ad4080e7          	jalr	-1324(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    80002526:	8526                	mv	a0,s1
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	374080e7          	jalr	884(ra) # 8000189c <destroy_pagetable>
        return;
    80002530:	bf2d                	j	8000246a <test_pagetable+0x136>
        printf("FAIL: Read permission not set\n");
    80002532:	00009517          	auipc	a0,0x9
    80002536:	0de50513          	addi	a0,a0,222 # 8000b610 <digits+0x1460>
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	fca080e7          	jalr	-54(ra) # 80000504 <printf>
        free_page(physical_page);
    80002542:	854a                	mv	a0,s2
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	aae080e7          	jalr	-1362(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    8000254c:	8526                	mv	a0,s1
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	34e080e7          	jalr	846(ra) # 8000189c <destroy_pagetable>
        return;
    80002556:	bf11                	j	8000246a <test_pagetable+0x136>
        printf("FAIL: Write permission not set\n");
    80002558:	00009517          	auipc	a0,0x9
    8000255c:	0d850513          	addi	a0,a0,216 # 8000b630 <digits+0x1480>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	fa4080e7          	jalr	-92(ra) # 80000504 <printf>
        free_page(physical_page);
    80002568:	854a                	mv	a0,s2
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	a88080e7          	jalr	-1400(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    80002572:	8526                	mv	a0,s1
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	328080e7          	jalr	808(ra) # 8000189c <destroy_pagetable>
        return;
    8000257c:	b5fd                	j	8000246a <test_pagetable+0x136>
        printf("FAIL: Execute permission incorrectly set\n");
    8000257e:	00009517          	auipc	a0,0x9
    80002582:	0d250513          	addi	a0,a0,210 # 8000b650 <digits+0x14a0>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	f7e080e7          	jalr	-130(ra) # 80000504 <printf>
        free_page(physical_page);
    8000258e:	854a                	mv	a0,s2
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	a62080e7          	jalr	-1438(ra) # 80000ff2 <free_page>
        destroy_pagetable(pt);
    80002598:	8526                	mv	a0,s1
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	302080e7          	jalr	770(ra) # 8000189c <destroy_pagetable>
        return;
    800025a2:	b5e1                	j	8000246a <test_pagetable+0x136>
    printf("  walkaddr function: PASS\n");
    800025a4:	00009517          	auipc	a0,0x9
    800025a8:	15450513          	addi	a0,a0,340 # 8000b6f8 <digits+0x1548>
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	f58080e7          	jalr	-168(ra) # 80000504 <printf>
    free_page(physical_page);
    800025b4:	854a                	mv	a0,s2
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	a3c080e7          	jalr	-1476(ra) # 80000ff2 <free_page>
    destroy_pagetable(pt);
    800025be:	8526                	mv	a0,s1
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	2dc080e7          	jalr	732(ra) # 8000189c <destroy_pagetable>
    printf("SUCCESS: Page table test passed\n");
    800025c8:	00009517          	auipc	a0,0x9
    800025cc:	15050513          	addi	a0,a0,336 # 8000b718 <digits+0x1568>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	f34080e7          	jalr	-204(ra) # 80000504 <printf>
    800025d8:	bd49                	j	8000246a <test_pagetable+0x136>

00000000800025da <kvmtest>:

// 内核虚拟内存测试
void kvmtest(void) {
    800025da:	715d                	addi	sp,sp,-80
    800025dc:	e486                	sd	ra,72(sp)
    800025de:	e0a2                	sd	s0,64(sp)
    800025e0:	fc26                	sd	s1,56(sp)
    800025e2:	f84a                	sd	s2,48(sp)
    800025e4:	f44e                	sd	s3,40(sp)
    800025e6:	0880                	addi	s0,sp,80
    printf("\n=== Virtual Memory Activation Test ===\n\n");
    800025e8:	00009517          	auipc	a0,0x9
    800025ec:	1a850513          	addi	a0,a0,424 # 8000b790 <digits+0x15e0>
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	f14080e7          	jalr	-236(ra) # 80000504 <printf>
    
    printf("Before enabling paging...\n");
    800025f8:	00009517          	auipc	a0,0x9
    800025fc:	1c850513          	addi	a0,a0,456 # 8000b7c0 <digits+0x1610>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f04080e7          	jalr	-252(ra) # 80000504 <printf>
    
    // 测试1: 检查初始状态
    printf("1. Checking initial state:\n");
    80002608:	00009517          	auipc	a0,0x9
    8000260c:	1d850513          	addi	a0,a0,472 # 8000b7e0 <digits+0x1630>
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	ef4080e7          	jalr	-268(ra) # 80000504 <printf>
    printf("   Kernel page table: 0x%p\n", get_kernel_pagetable());
    80002618:	0000d597          	auipc	a1,0xd
    8000261c:	2405b583          	ld	a1,576(a1) # 8000f858 <kernel_pagetable>
    80002620:	00009517          	auipc	a0,0x9
    80002624:	1e050513          	addi	a0,a0,480 # 8000b800 <digits+0x1650>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	edc080e7          	jalr	-292(ra) # 80000504 <printf>
    80002630:	180025f3          	csrr	a1,satp
    printf("   SATP register: 0x%p\n", (void*)r_satp());
    80002634:	00009517          	auipc	a0,0x9
    80002638:	1ec50513          	addi	a0,a0,492 # 8000b820 <digits+0x1670>
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	ec8080e7          	jalr	-312(ra) # 80000504 <printf>
    80002644:	180027f3          	csrr	a5,satp
    printf("   Paging mode: %s\n", (r_satp() & SATP_SV39) ? "ENABLED" : "DISABLED");
    80002648:	00009597          	auipc	a1,0x9
    8000264c:	0f858593          	addi	a1,a1,248 # 8000b740 <digits+0x1590>
    80002650:	0007c663          	bltz	a5,8000265c <kvmtest+0x82>
    80002654:	00009597          	auipc	a1,0x9
    80002658:	0f458593          	addi	a1,a1,244 # 8000b748 <digits+0x1598>
    8000265c:	00009517          	auipc	a0,0x9
    80002660:	1dc50513          	addi	a0,a0,476 # 8000b838 <digits+0x1688>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	ea0080e7          	jalr	-352(ra) # 80000504 <printf>
    
    // 测试2: 物理内存访问测试
    printf("\n2. Physical memory access test:\n");
    8000266c:	00009517          	auipc	a0,0x9
    80002670:	1e450513          	addi	a0,a0,484 # 8000b850 <digits+0x16a0>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	e90080e7          	jalr	-368(ra) # 80000504 <printf>
    uint64 test_pattern = 0x1234567890ABCDEF;
    extern char end[];
    uint64 *test_addr = (uint64*)((uint64)end - 0x1000);  // end 之前的地址
    8000267c:	00462497          	auipc	s1,0x462
    80002680:	76448493          	addi	s1,s1,1892 # 80464de0 <stack0>
    
    *test_addr = test_pattern;
    80002684:	00008917          	auipc	s2,0x8
    80002688:	9ec93903          	ld	s2,-1556(s2) # 8000a070 <etext+0x70>
    8000268c:	0124b023          	sd	s2,0(s1)
    uint64 read_value = *test_addr;
    printf("   Write 0x%p to 0x%p\n", (void*)test_pattern, test_addr);
    80002690:	8626                	mv	a2,s1
    80002692:	85ca                	mv	a1,s2
    80002694:	00009517          	auipc	a0,0x9
    80002698:	1e450513          	addi	a0,a0,484 # 8000b878 <digits+0x16c8>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	e68080e7          	jalr	-408(ra) # 80000504 <printf>
    printf("   Read  0x%p from 0x%p\n", (void*)read_value, test_addr);
    800026a4:	8626                	mv	a2,s1
    800026a6:	85ca                	mv	a1,s2
    800026a8:	00009517          	auipc	a0,0x9
    800026ac:	1e850513          	addi	a0,a0,488 # 8000b890 <digits+0x16e0>
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	e54080e7          	jalr	-428(ra) # 80000504 <printf>
    printf("   Physical access: %s\n", read_value == test_pattern ? "PASS" : "FAIL");
    800026b8:	00009597          	auipc	a1,0x9
    800026bc:	0a058593          	addi	a1,a1,160 # 8000b758 <digits+0x15a8>
    800026c0:	00009517          	auipc	a0,0x9
    800026c4:	1f050513          	addi	a0,a0,496 # 8000b8b0 <digits+0x1700>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	e3c080e7          	jalr	-452(ra) # 80000504 <printf>
    
    // 启用分页
    printf("\n3. Enabling virtual memory...\n");
    800026d0:	00009517          	auipc	a0,0x9
    800026d4:	1f850513          	addi	a0,a0,504 # 8000b8c8 <digits+0x1718>
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	e2c080e7          	jalr	-468(ra) # 80000504 <printf>
    kvminit();
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	746080e7          	jalr	1862(ra) # 80001e26 <kvminit>
    kvminithart();
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	7b4080e7          	jalr	1972(ra) # 80001e9c <kvminithart>
    
    printf("After enabling paging...\n");
    800026f0:	00009517          	auipc	a0,0x9
    800026f4:	1f850513          	addi	a0,a0,504 # 8000b8e8 <digits+0x1738>
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	e0c080e7          	jalr	-500(ra) # 80000504 <printf>
    
    // 测试4: 检查分页状态
    printf("\n4. Paging status check:\n");
    80002700:	00009517          	auipc	a0,0x9
    80002704:	20850513          	addi	a0,a0,520 # 8000b908 <digits+0x1758>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	dfc080e7          	jalr	-516(ra) # 80000504 <printf>
    printf("   Kernel page table: 0x%p\n", get_kernel_pagetable());
    80002710:	0000d597          	auipc	a1,0xd
    80002714:	1485b583          	ld	a1,328(a1) # 8000f858 <kernel_pagetable>
    80002718:	00009517          	auipc	a0,0x9
    8000271c:	0e850513          	addi	a0,a0,232 # 8000b800 <digits+0x1650>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	de4080e7          	jalr	-540(ra) # 80000504 <printf>
    80002728:	180025f3          	csrr	a1,satp
    printf("   SATP register: 0x%p\n", (void*)r_satp());
    8000272c:	00009517          	auipc	a0,0x9
    80002730:	0f450513          	addi	a0,a0,244 # 8000b820 <digits+0x1670>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	dd0080e7          	jalr	-560(ra) # 80000504 <printf>
    8000273c:	180027f3          	csrr	a5,satp
    printf("   Paging mode: %s\n", (r_satp() & SATP_SV39) ? "ENABLED" : "DISABLED");
    80002740:	00009597          	auipc	a1,0x9
    80002744:	00058593          	mv	a1,a1
    80002748:	0007c663          	bltz	a5,80002754 <kvmtest+0x17a>
    8000274c:	00009597          	auipc	a1,0x9
    80002750:	ffc58593          	addi	a1,a1,-4 # 8000b748 <digits+0x1598>
    80002754:	00009517          	auipc	a0,0x9
    80002758:	0e450513          	addi	a0,a0,228 # 8000b838 <digits+0x1688>
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	da8080e7          	jalr	-600(ra) # 80000504 <printf>
    
    // 测试5: 测试内核代码仍然可执行（通过函数调用测试）
    printf("\n5. Kernel code execution test:\n");
    80002764:	00009517          	auipc	a0,0x9
    80002768:	1c450513          	addi	a0,a0,452 # 8000b928 <digits+0x1778>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	d98080e7          	jalr	-616(ra) # 80000504 <printf>
    printf("   Testing function calls...\n");
    80002774:	00009517          	auipc	a0,0x9
    80002778:	1dc50513          	addi	a0,a0,476 # 8000b950 <digits+0x17a0>
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	d88080e7          	jalr	-632(ra) # 80000504 <printf>
    // 调用一些内核函数来测试代码执行
    uint64 free_mem = get_free_memory();
    80002784:	fffff097          	auipc	ra,0xfffff
    80002788:	9b0080e7          	jalr	-1616(ra) # 80001134 <get_free_memory>
    8000278c:	89aa                	mv	s3,a0
    uint64 total_mem = get_total_memory();
    8000278e:	fffff097          	auipc	ra,0xfffff
    80002792:	9bc080e7          	jalr	-1604(ra) # 8000114a <get_total_memory>
    80002796:	892a                	mv	s2,a0
    printf("   Free memory: %d KB\n", (int)(free_mem / 1024));
    80002798:	00a9d593          	srli	a1,s3,0xa
    8000279c:	2581                	sext.w	a1,a1
    8000279e:	00009517          	auipc	a0,0x9
    800027a2:	1d250513          	addi	a0,a0,466 # 8000b970 <digits+0x17c0>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	d5e080e7          	jalr	-674(ra) # 80000504 <printf>
    printf("   Total memory: %d KB\n", (int)(total_mem / 1024));
    800027ae:	00a95593          	srli	a1,s2,0xa
    800027b2:	2581                	sext.w	a1,a1
    800027b4:	00009517          	auipc	a0,0x9
    800027b8:	1d450513          	addi	a0,a0,468 # 8000b988 <digits+0x17d8>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	d48080e7          	jalr	-696(ra) # 80000504 <printf>
    printf("   Code execution: PASS\n");
    800027c4:	00009517          	auipc	a0,0x9
    800027c8:	1dc50513          	addi	a0,a0,476 # 8000b9a0 <digits+0x17f0>
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	d38080e7          	jalr	-712(ra) # 80000504 <printf>
    
    // 测试6: 测试内核数据仍然可访问
    printf("\n6. Kernel data access test:\n");
    800027d4:	00009517          	auipc	a0,0x9
    800027d8:	1ec50513          	addi	a0,a0,492 # 8000b9c0 <digits+0x1810>
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	d28080e7          	jalr	-728(ra) # 80000504 <printf>
    read_value = *test_addr;
    800027e4:	0004b903          	ld	s2,0(s1)
    printf("   Read 0x%p from 0x%p through page table\n", (void*)read_value, test_addr);
    800027e8:	8626                	mv	a2,s1
    800027ea:	85ca                	mv	a1,s2
    800027ec:	00009517          	auipc	a0,0x9
    800027f0:	1f450513          	addi	a0,a0,500 # 8000b9e0 <digits+0x1830>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	d10080e7          	jalr	-752(ra) # 80000504 <printf>
    printf("   Data access: %s\n", read_value == test_pattern ? "PASS" : "FAIL");
    800027fc:	00008797          	auipc	a5,0x8
    80002800:	8747b783          	ld	a5,-1932(a5) # 8000a070 <etext+0x70>
    80002804:	00009597          	auipc	a1,0x9
    80002808:	f5458593          	addi	a1,a1,-172 # 8000b758 <digits+0x15a8>
    8000280c:	00f90663          	beq	s2,a5,80002818 <kvmtest+0x23e>
    80002810:	00009597          	auipc	a1,0x9
    80002814:	f5058593          	addi	a1,a1,-176 # 8000b760 <digits+0x15b0>
    80002818:	00009517          	auipc	a0,0x9
    8000281c:	1f850513          	addi	a0,a0,504 # 8000ba10 <digits+0x1860>
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	ce4080e7          	jalr	-796(ra) # 80000504 <printf>
    
    // 测试7: 测试新数据写入和读取
    printf("\n7. New data write/read test:\n");
    80002828:	00009517          	auipc	a0,0x9
    8000282c:	20050513          	addi	a0,a0,512 # 8000ba28 <digits+0x1878>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	cd4080e7          	jalr	-812(ra) # 80000504 <printf>
    uint64 new_pattern = 0xFEDCBA9876543210;
    *test_addr = new_pattern;
    80002838:	00008917          	auipc	s2,0x8
    8000283c:	84093903          	ld	s2,-1984(s2) # 8000a078 <etext+0x78>
    80002840:	0124b023          	sd	s2,0(s1)
    read_value = *test_addr;
    printf("   Write 0x%p to 0x%p\n", (void*)new_pattern, test_addr);
    80002844:	8626                	mv	a2,s1
    80002846:	85ca                	mv	a1,s2
    80002848:	00009517          	auipc	a0,0x9
    8000284c:	03050513          	addi	a0,a0,48 # 8000b878 <digits+0x16c8>
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	cb4080e7          	jalr	-844(ra) # 80000504 <printf>
    printf("   Read  0x%p from 0x%p\n", (void*)read_value, test_addr);
    80002858:	8626                	mv	a2,s1
    8000285a:	85ca                	mv	a1,s2
    8000285c:	00009517          	auipc	a0,0x9
    80002860:	03450513          	addi	a0,a0,52 # 8000b890 <digits+0x16e0>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	ca0080e7          	jalr	-864(ra) # 80000504 <printf>
    printf("   New data access: %s\n", read_value == new_pattern ? "PASS" : "FAIL");
    8000286c:	00009597          	auipc	a1,0x9
    80002870:	eec58593          	addi	a1,a1,-276 # 8000b758 <digits+0x15a8>
    80002874:	00009517          	auipc	a0,0x9
    80002878:	1d450513          	addi	a0,a0,468 # 8000ba48 <digits+0x1898>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	c88080e7          	jalr	-888(ra) # 80000504 <printf>
    
    // 测试8: 测试地址转换功能
    printf("\n8. Address translation test:\n");
    80002884:	00009517          	auipc	a0,0x9
    80002888:	1dc50513          	addi	a0,a0,476 # 8000ba60 <digits+0x18b0>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	c78080e7          	jalr	-904(ra) # 80000504 <printf>
    uint64 translated = walkaddr(get_kernel_pagetable(), (uint64)test_addr);
    80002894:	85a6                	mv	a1,s1
    80002896:	0000d517          	auipc	a0,0xd
    8000289a:	fc253503          	ld	a0,-62(a0) # 8000f858 <kernel_pagetable>
    8000289e:	fffff097          	auipc	ra,0xfffff
    800028a2:	2cc080e7          	jalr	716(ra) # 80001b6a <walkaddr>
    800028a6:	892a                	mv	s2,a0
    printf("   Virtual address: 0x%p\n", test_addr);
    800028a8:	85a6                	mv	a1,s1
    800028aa:	00009517          	auipc	a0,0x9
    800028ae:	1d650513          	addi	a0,a0,470 # 8000ba80 <digits+0x18d0>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	c52080e7          	jalr	-942(ra) # 80000504 <printf>
    printf("   Physical address: 0x%p\n", (void*)translated);
    800028ba:	85ca                	mv	a1,s2
    800028bc:	00009517          	auipc	a0,0x9
    800028c0:	1e450513          	addi	a0,a0,484 # 8000baa0 <digits+0x18f0>
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	c40080e7          	jalr	-960(ra) # 80000504 <printf>
    printf("   Address translation: %s\n", 
    800028cc:	00009597          	auipc	a1,0x9
    800028d0:	e8c58593          	addi	a1,a1,-372 # 8000b758 <digits+0x15a8>
    800028d4:	01248663          	beq	s1,s2,800028e0 <kvmtest+0x306>
    800028d8:	00009597          	auipc	a1,0x9
    800028dc:	e8858593          	addi	a1,a1,-376 # 8000b760 <digits+0x15b0>
    800028e0:	00009517          	auipc	a0,0x9
    800028e4:	1e050513          	addi	a0,a0,480 # 8000bac0 <digits+0x1910>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	c1c080e7          	jalr	-996(ra) # 80000504 <printf>
           translated == (uint64)test_addr ? "PASS" : "FAIL");
    
    // 测试9: 测试多个内存区域访问
    printf("\n9. Multiple memory regions test:\n");
    800028f0:	00009517          	auipc	a0,0x9
    800028f4:	1f050513          	addi	a0,a0,496 # 8000bae0 <digits+0x1930>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c0c080e7          	jalr	-1012(ra) # 80000504 <printf>
    uint64 regions[3] = {0x80000000, 0x80100000, 0x80200000};
    80002900:	008017b7          	lui	a5,0x801
    80002904:	07a2                	slli	a5,a5,0x8
    80002906:	fcf43023          	sd	a5,-64(s0)
    8000290a:	40100793          	li	a5,1025
    8000290e:	07d6                	slli	a5,a5,0x15
    80002910:	fcf43423          	sd	a5,-56(s0)
    int region_test_pass = 1;
    
    for (int i = 0; i < 3; i++) {
        uint64 *region_addr = (uint64*)regions[i];
        uint64 test_val = 0xAABBCCDD11223344 + i;
        *region_addr = test_val;
    80002914:	4585                	li	a1,1
    80002916:	05fe                	slli	a1,a1,0x1f
    80002918:	00007797          	auipc	a5,0x7
    8000291c:	7687b783          	ld	a5,1896(a5) # 8000a080 <etext+0x80>
    80002920:	e19c                	sd	a5,0(a1)
        if (*region_addr != test_val) {
            region_test_pass = 0;
            printf("   Region 0x%p: FAIL\n", (void*)regions[i]);
        } else {
            printf("   Region 0x%p: PASS\n", (void*)regions[i]);
    80002922:	00009517          	auipc	a0,0x9
    80002926:	1e650513          	addi	a0,a0,486 # 8000bb08 <digits+0x1958>
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	bda080e7          	jalr	-1062(ra) # 80000504 <printf>
        uint64 *region_addr = (uint64*)regions[i];
    80002932:	fc043583          	ld	a1,-64(s0)
        *region_addr = test_val;
    80002936:	00007797          	auipc	a5,0x7
    8000293a:	7527b783          	ld	a5,1874(a5) # 8000a088 <etext+0x88>
    8000293e:	e19c                	sd	a5,0(a1)
            printf("   Region 0x%p: PASS\n", (void*)regions[i]);
    80002940:	00009517          	auipc	a0,0x9
    80002944:	1c850513          	addi	a0,a0,456 # 8000bb08 <digits+0x1958>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	bbc080e7          	jalr	-1092(ra) # 80000504 <printf>
        uint64 *region_addr = (uint64*)regions[i];
    80002950:	fc843583          	ld	a1,-56(s0)
        *region_addr = test_val;
    80002954:	00007797          	auipc	a5,0x7
    80002958:	73c7b783          	ld	a5,1852(a5) # 8000a090 <etext+0x90>
    8000295c:	e19c                	sd	a5,0(a1)
            printf("   Region 0x%p: PASS\n", (void*)regions[i]);
    8000295e:	00009517          	auipc	a0,0x9
    80002962:	1aa50513          	addi	a0,a0,426 # 8000bb08 <digits+0x1958>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	b9e080e7          	jalr	-1122(ra) # 80000504 <printf>
        }
    }
    printf("   Multiple regions: %s\n", region_test_pass ? "PASS" : "FAIL");
    8000296e:	00009597          	auipc	a1,0x9
    80002972:	dea58593          	addi	a1,a1,-534 # 8000b758 <digits+0x15a8>
    80002976:	00009517          	auipc	a0,0x9
    8000297a:	1aa50513          	addi	a0,a0,426 # 8000bb20 <digits+0x1970>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	b86080e7          	jalr	-1146(ra) # 80000504 <printf>
    
    // 测试10: 页表结构验证
    printf("\n10. Page table structure verification:\n");
    80002986:	00009517          	auipc	a0,0x9
    8000298a:	1ba50513          	addi	a0,a0,442 # 8000bb40 <digits+0x1990>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	b76080e7          	jalr	-1162(ra) # 80000504 <printf>
    pagetable_t kpt = get_kernel_pagetable();
    if (kpt) {
    80002996:	0000d797          	auipc	a5,0xd
    8000299a:	ec27b783          	ld	a5,-318(a5) # 8000f858 <kernel_pagetable>
    8000299e:	c7e9                	beqz	a5,80002a68 <kvmtest+0x48e>
        printf("   Kernel page table exists: PASS\n");
    800029a0:	00009517          	auipc	a0,0x9
    800029a4:	1d050513          	addi	a0,a0,464 # 8000bb70 <digits+0x19c0>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	b5c080e7          	jalr	-1188(ra) # 80000504 <printf>
        // 可以添加更详细的页表检查
        printf("   Basic page table check: PASS\n");
    800029b0:	00009517          	auipc	a0,0x9
    800029b4:	1e850513          	addi	a0,a0,488 # 8000bb98 <digits+0x19e8>
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	b4c080e7          	jalr	-1204(ra) # 80000504 <printf>
    } else {
        printf("   Kernel page table exists: FAIL\n");
    }
    
    // 测试11: 内存分配测试（验证物理内存管理器仍然工作）
    printf("\n11. Memory allocation test:\n");
    800029c0:	00009517          	auipc	a0,0x9
    800029c4:	22850513          	addi	a0,a0,552 # 8000bbe8 <digits+0x1a38>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	b3c080e7          	jalr	-1220(ra) # 80000504 <printf>
    void *allocated_page = alloc_page();
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	608080e7          	jalr	1544(ra) # 80000fd8 <alloc_page>
    800029d8:	84aa                	mv	s1,a0
    if (allocated_page) {
    800029da:	c145                	beqz	a0,80002a7a <kvmtest+0x4a0>
        printf("   Page allocated at: 0x%p\n", allocated_page);
    800029dc:	85aa                	mv	a1,a0
    800029de:	00009517          	auipc	a0,0x9
    800029e2:	22a50513          	addi	a0,a0,554 # 8000bc08 <digits+0x1a58>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b1e080e7          	jalr	-1250(ra) # 80000504 <printf>
        *(uint64*)allocated_page = 0x5555555555555555;
    800029ee:	00007797          	auipc	a5,0x7
    800029f2:	6aa7b783          	ld	a5,1706(a5) # 8000a098 <etext+0x98>
    800029f6:	e09c                	sd	a5,0(s1)
        if (*(uint64*)allocated_page == 0x5555555555555555) {
            printf("   Allocated memory access: PASS\n");
    800029f8:	00009517          	auipc	a0,0x9
    800029fc:	23050513          	addi	a0,a0,560 # 8000bc28 <digits+0x1a78>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b04080e7          	jalr	-1276(ra) # 80000504 <printf>
        } else {
            printf("   Allocated memory access: FAIL\n");
        }
        free_page(allocated_page);
    80002a08:	8526                	mv	a0,s1
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	5e8080e7          	jalr	1512(ra) # 80000ff2 <free_page>
        printf("   Page freed successfully\n");
    80002a12:	00009517          	auipc	a0,0x9
    80002a16:	23e50513          	addi	a0,a0,574 # 8000bc50 <digits+0x1aa0>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	aea080e7          	jalr	-1302(ra) # 80000504 <printf>
    } else {
        printf("   Page allocation: FAIL\n");
    }
    
    printf("\n=== Virtual Memory Activation Test Completed ===\n");
    80002a22:	00009517          	auipc	a0,0x9
    80002a26:	26e50513          	addi	a0,a0,622 # 8000bc90 <digits+0x1ae0>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	ada080e7          	jalr	-1318(ra) # 80000504 <printf>
    80002a32:	180027f3          	csrr	a5,satp
    printf("Summary: Virtual memory system is %s\n", 
    80002a36:	00009597          	auipc	a1,0x9
    80002a3a:	d3258593          	addi	a1,a1,-718 # 8000b768 <digits+0x15b8>
    80002a3e:	0007c663          	bltz	a5,80002a4a <kvmtest+0x470>
    80002a42:	00009597          	auipc	a1,0x9
    80002a46:	d3e58593          	addi	a1,a1,-706 # 8000b780 <digits+0x15d0>
    80002a4a:	00009517          	auipc	a0,0x9
    80002a4e:	27e50513          	addi	a0,a0,638 # 8000bcc8 <digits+0x1b18>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	ab2080e7          	jalr	-1358(ra) # 80000504 <printf>
           (r_satp() & SATP_SV39) ? "ACTIVE AND WORKING" : "NOT WORKING");
    80002a5a:	60a6                	ld	ra,72(sp)
    80002a5c:	6406                	ld	s0,64(sp)
    80002a5e:	74e2                	ld	s1,56(sp)
    80002a60:	7942                	ld	s2,48(sp)
    80002a62:	79a2                	ld	s3,40(sp)
    80002a64:	6161                	addi	sp,sp,80
    80002a66:	8082                	ret
        printf("   Kernel page table exists: FAIL\n");
    80002a68:	00009517          	auipc	a0,0x9
    80002a6c:	15850513          	addi	a0,a0,344 # 8000bbc0 <digits+0x1a10>
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	a94080e7          	jalr	-1388(ra) # 80000504 <printf>
    80002a78:	b7a1                	j	800029c0 <kvmtest+0x3e6>
        printf("   Page allocation: FAIL\n");
    80002a7a:	00009517          	auipc	a0,0x9
    80002a7e:	1f650513          	addi	a0,a0,502 # 8000bc70 <digits+0x1ac0>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	a82080e7          	jalr	-1406(ra) # 80000504 <printf>
    80002a8a:	bf61                	j	80002a22 <kvmtest+0x448>

0000000080002a8c <panic>:
#include "types.h"
#include "defs.h"

__attribute__((noreturn)) void panic(const char *s) {
    80002a8c:	1141                	addi	sp,sp,-16
    80002a8e:	e406                	sd	ra,8(sp)
    80002a90:	e022                	sd	s0,0(sp)
    80002a92:	0800                	addi	s0,sp,16
    80002a94:	85aa                	mv	a1,a0
    printf("panic: %s\n", s);
    80002a96:	00009517          	auipc	a0,0x9
    80002a9a:	25a50513          	addi	a0,a0,602 # 8000bcf0 <digits+0x1b40>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	a66080e7          	jalr	-1434(ra) # 80000504 <printf>
    for(;;)
    80002aa6:	a001                	j	80002aa6 <panic+0x1a>
	...

0000000080002ab0 <kernelvec>:
	.globl _trapframe

# single-core: use a global trapframe symbol
kernelvec:
	# allocate space in trapframe via direct store
	la t0, _trapframe
    80002ab0:	0000d297          	auipc	t0,0xd
    80002ab4:	22828293          	addi	t0,t0,552 # 8000fcd8 <_trapframe>
	# save registers
	sd ra, 0(t0)
    80002ab8:	0012b023          	sd	ra,0(t0)
	sd sp, 8(t0)
    80002abc:	0022b423          	sd	sp,8(t0)
	sd gp, 16(t0)
    80002ac0:	0032b823          	sd	gp,16(t0)
	sd tp, 24(t0)
    80002ac4:	0042bc23          	sd	tp,24(t0)
	sd t0, 32(t0)
    80002ac8:	0252b023          	sd	t0,32(t0)
	sd t1, 40(t0)
    80002acc:	0262b423          	sd	t1,40(t0)
	sd t2, 48(t0)
    80002ad0:	0272b823          	sd	t2,48(t0)
	sd s0, 56(t0)
    80002ad4:	0282bc23          	sd	s0,56(t0)
	sd s1, 64(t0)
    80002ad8:	0492b023          	sd	s1,64(t0)
	sd a0, 72(t0)
    80002adc:	04a2b423          	sd	a0,72(t0)
	sd a1, 80(t0)
    80002ae0:	04b2b823          	sd	a1,80(t0)
	sd a2, 88(t0)
    80002ae4:	04c2bc23          	sd	a2,88(t0)
	sd a3, 96(t0)
    80002ae8:	06d2b023          	sd	a3,96(t0)
	sd a4, 104(t0)
    80002aec:	06e2b423          	sd	a4,104(t0)
	sd a5, 112(t0)
    80002af0:	06f2b823          	sd	a5,112(t0)
	sd a6, 120(t0)
    80002af4:	0702bc23          	sd	a6,120(t0)
	sd a7, 128(t0)
    80002af8:	0912b023          	sd	a7,128(t0)
	sd s2, 136(t0)
    80002afc:	0922b423          	sd	s2,136(t0)
	sd s3, 144(t0)
    80002b00:	0932b823          	sd	s3,144(t0)
	sd s4, 152(t0)
    80002b04:	0942bc23          	sd	s4,152(t0)
	sd s5, 160(t0)
    80002b08:	0b52b023          	sd	s5,160(t0)
	sd s6, 168(t0)
    80002b0c:	0b62b423          	sd	s6,168(t0)
	sd s7, 176(t0)
    80002b10:	0b72b823          	sd	s7,176(t0)
	sd s8, 184(t0)
    80002b14:	0b82bc23          	sd	s8,184(t0)
	sd s9, 192(t0)
    80002b18:	0d92b023          	sd	s9,192(t0)
	sd s10, 200(t0)
    80002b1c:	0da2b423          	sd	s10,200(t0)
	sd s11, 208(t0)
    80002b20:	0db2b823          	sd	s11,208(t0)
	sd t3, 216(t0)
    80002b24:	0dc2bc23          	sd	t3,216(t0)
	sd t4, 224(t0)
    80002b28:	0fd2b023          	sd	t4,224(t0)
	sd t5, 232(t0)
    80002b2c:	0fe2b423          	sd	t5,232(t0)
	sd t6, 240(t0)
    80002b30:	0ff2b823          	sd	t6,240(t0)
	csrr t1, mepc
    80002b34:	34102373          	csrr	t1,mepc
	sd t1, 248(t0)
    80002b38:	0e62bc23          	sd	t1,248(t0)
	csrr t1, mstatus
    80002b3c:	30002373          	csrr	t1,mstatus
	sd t1, 256(t0)
    80002b40:	1062b023          	sd	t1,256(t0)

	# call C handler
	call kerneltrap
    80002b44:	774000ef          	jal	ra,800032b8 <kerneltrap>

	# restore
	la t0, _trapframe
    80002b48:	0000d297          	auipc	t0,0xd
    80002b4c:	19028293          	addi	t0,t0,400 # 8000fcd8 <_trapframe>
	ld ra, 0(t0)
    80002b50:	0002b083          	ld	ra,0(t0)
	ld sp, 8(t0)
    80002b54:	0082b103          	ld	sp,8(t0)
	ld gp, 16(t0)
    80002b58:	0102b183          	ld	gp,16(t0)
	ld tp, 24(t0)
    80002b5c:	0182b203          	ld	tp,24(t0)
	ld t0, 32(t0)
    80002b60:	0202b283          	ld	t0,32(t0)
	ld t1, 40(t0)
    80002b64:	0282b303          	ld	t1,40(t0)
	ld t2, 48(t0)
    80002b68:	0302b383          	ld	t2,48(t0)
	ld s0, 56(t0)
    80002b6c:	0382b403          	ld	s0,56(t0)
	ld s1, 64(t0)
    80002b70:	0402b483          	ld	s1,64(t0)
	ld a0, 72(t0)
    80002b74:	0482b503          	ld	a0,72(t0)
	ld a1, 80(t0)
    80002b78:	0502b583          	ld	a1,80(t0)
	ld a2, 88(t0)
    80002b7c:	0582b603          	ld	a2,88(t0)
	ld a3, 96(t0)
    80002b80:	0602b683          	ld	a3,96(t0)
	ld a4, 104(t0)
    80002b84:	0682b703          	ld	a4,104(t0)
	ld a5, 112(t0)
    80002b88:	0702b783          	ld	a5,112(t0)
	ld a6, 120(t0)
    80002b8c:	0782b803          	ld	a6,120(t0)
	ld a7, 128(t0)
    80002b90:	0802b883          	ld	a7,128(t0)
	ld s2, 136(t0)
    80002b94:	0882b903          	ld	s2,136(t0)
	ld s3, 144(t0)
    80002b98:	0902b983          	ld	s3,144(t0)
	ld s4, 152(t0)
    80002b9c:	0982ba03          	ld	s4,152(t0)
	ld s5, 160(t0)
    80002ba0:	0a02ba83          	ld	s5,160(t0)
	ld s6, 168(t0)
    80002ba4:	0a82bb03          	ld	s6,168(t0)
	ld s7, 176(t0)
    80002ba8:	0b02bb83          	ld	s7,176(t0)
	ld s8, 184(t0)
    80002bac:	0b82bc03          	ld	s8,184(t0)
	ld s9, 192(t0)
    80002bb0:	0c02bc83          	ld	s9,192(t0)
	ld s10, 200(t0)
    80002bb4:	0c82bd03          	ld	s10,200(t0)
	ld s11, 208(t0)
    80002bb8:	0d02bd83          	ld	s11,208(t0)
	ld t3, 216(t0)
    80002bbc:	0d82be03          	ld	t3,216(t0)
	ld t4, 224(t0)
    80002bc0:	0e02be83          	ld	t4,224(t0)
	ld t5, 232(t0)
    80002bc4:	0e82bf03          	ld	t5,232(t0)
	ld t6, 240(t0)
    80002bc8:	0f02bf83          	ld	t6,240(t0)
	ld t1, 248(t0)
    80002bcc:	0f82b303          	ld	t1,248(t0)
	csrw mepc, t1
    80002bd0:	34131073          	csrw	mepc,t1
	ld t1, 256(t0)
    80002bd4:	1002b303          	ld	t1,256(t0)
	csrw mstatus, t1
    80002bd8:	30031073          	csrw	mstatus,t1
	mret
    80002bdc:	30200073          	mret
	...

0000000080002bee <default_handler>:
    return 4;
}

// 默认中断处理函数
static void default_handler(void)
{
    80002bee:	1141                	addi	sp,sp,-16
    80002bf0:	e406                	sd	ra,8(sp)
    80002bf2:	e022                	sd	s0,0(sp)
    80002bf4:	0800                	addi	s0,sp,16
    printf("Unhandled interrupt\n");
    80002bf6:	00009517          	auipc	a0,0x9
    80002bfa:	10a50513          	addi	a0,a0,266 # 8000bd00 <digits+0x1b50>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	906080e7          	jalr	-1786(ra) # 80000504 <printf>
}
    80002c06:	60a2                	ld	ra,8(sp)
    80002c08:	6402                	ld	s0,0(sp)
    80002c0a:	0141                	addi	sp,sp,16
    80002c0c:	8082                	ret

0000000080002c0e <trap_get_context_switch_count>:
uint64 trap_get_context_switch_count(void) { return context_switch_count; }
    80002c0e:	1141                	addi	sp,sp,-16
    80002c10:	e422                	sd	s0,8(sp)
    80002c12:	0800                	addi	s0,sp,16
    80002c14:	0000d517          	auipc	a0,0xd
    80002c18:	c5c53503          	ld	a0,-932(a0) # 8000f870 <context_switch_count>
    80002c1c:	6422                	ld	s0,8(sp)
    80002c1e:	0141                	addi	sp,sp,16
    80002c20:	8082                	ret

0000000080002c22 <trap_get_total_context_switch_time>:
uint64 trap_get_total_context_switch_time(void) { return total_context_switch_time; }
    80002c22:	1141                	addi	sp,sp,-16
    80002c24:	e422                	sd	s0,8(sp)
    80002c26:	0800                	addi	s0,sp,16
    80002c28:	0000d517          	auipc	a0,0xd
    80002c2c:	c5053503          	ld	a0,-944(a0) # 8000f878 <total_context_switch_time>
    80002c30:	6422                	ld	s0,8(sp)
    80002c32:	0141                	addi	sp,sp,16
    80002c34:	8082                	ret

0000000080002c36 <trap_get_max_context_switch_time>:
uint64 trap_get_max_context_switch_time(void) { return max_context_switch_time; }
    80002c36:	1141                	addi	sp,sp,-16
    80002c38:	e422                	sd	s0,8(sp)
    80002c3a:	0800                	addi	s0,sp,16
    80002c3c:	0000d517          	auipc	a0,0xd
    80002c40:	c2c53503          	ld	a0,-980(a0) # 8000f868 <max_context_switch_time>
    80002c44:	6422                	ld	s0,8(sp)
    80002c46:	0141                	addi	sp,sp,16
    80002c48:	8082                	ret

0000000080002c4a <trap_get_min_context_switch_time>:
uint64 trap_get_min_context_switch_time(void) { return min_context_switch_time == ~0UL ? 0 : min_context_switch_time; }
    80002c4a:	1141                	addi	sp,sp,-16
    80002c4c:	e422                	sd	s0,8(sp)
    80002c4e:	0800                	addi	s0,sp,16
    80002c50:	0000d717          	auipc	a4,0xd
    80002c54:	bc073703          	ld	a4,-1088(a4) # 8000f810 <min_context_switch_time>
    80002c58:	57fd                	li	a5,-1
    80002c5a:	4501                	li	a0,0
    80002c5c:	00f70663          	beq	a4,a5,80002c68 <trap_get_min_context_switch_time+0x1e>
    80002c60:	0000d517          	auipc	a0,0xd
    80002c64:	bb053503          	ld	a0,-1104(a0) # 8000f810 <min_context_switch_time>
    80002c68:	6422                	ld	s0,8(sp)
    80002c6a:	0141                	addi	sp,sp,16
    80002c6c:	8082                	ret

0000000080002c6e <trap_reset_stats>:
{
    80002c6e:	1141                	addi	sp,sp,-16
    80002c70:	e422                	sd	s0,8(sp)
    80002c72:	0800                	addi	s0,sp,16
    total_context_switch_time = 0;
    80002c74:	0000d797          	auipc	a5,0xd
    80002c78:	c007b223          	sd	zero,-1020(a5) # 8000f878 <total_context_switch_time>
    context_switch_count = 0;
    80002c7c:	0000d797          	auipc	a5,0xd
    80002c80:	be07ba23          	sd	zero,-1036(a5) # 8000f870 <context_switch_count>
    max_context_switch_time = 0;
    80002c84:	0000d797          	auipc	a5,0xd
    80002c88:	be07b223          	sd	zero,-1052(a5) # 8000f868 <max_context_switch_time>
    min_context_switch_time = ~0UL;
    80002c8c:	57fd                	li	a5,-1
    80002c8e:	0000d717          	auipc	a4,0xd
    80002c92:	b8f73123          	sd	a5,-1150(a4) # 8000f810 <min_context_switch_time>
}
    80002c96:	6422                	ld	s0,8(sp)
    80002c98:	0141                	addi	sp,sp,16
    80002c9a:	8082                	ret

0000000080002c9c <register_interrupt>:
// 注册中断处理函数，用于注册中断处理函数
void register_interrupt(int irq, interrupt_handler_t h)
{
    80002c9c:	1141                	addi	sp,sp,-16
    80002c9e:	e422                	sd	s0,8(sp)
    80002ca0:	0800                	addi	s0,sp,16
    if (irq < 0 || irq >= 64)
    80002ca2:	03f00713          	li	a4,63
    80002ca6:	00a76b63          	bltu	a4,a0,80002cbc <register_interrupt+0x20>
    80002caa:	87aa                	mv	a5,a0
        return;
    interrupt_vector[irq] = h ? h : default_handler;
    80002cac:	c999                	beqz	a1,80002cc2 <register_interrupt+0x26>
    80002cae:	078e                	slli	a5,a5,0x3
    80002cb0:	0000d717          	auipc	a4,0xd
    80002cb4:	e2870713          	addi	a4,a4,-472 # 8000fad8 <interrupt_vector>
    80002cb8:	97ba                	add	a5,a5,a4
    80002cba:	e38c                	sd	a1,0(a5)
}
    80002cbc:	6422                	ld	s0,8(sp)
    80002cbe:	0141                	addi	sp,sp,16
    80002cc0:	8082                	ret
    interrupt_vector[irq] = h ? h : default_handler;
    80002cc2:	00000597          	auipc	a1,0x0
    80002cc6:	f2c58593          	addi	a1,a1,-212 # 80002bee <default_handler>
    80002cca:	b7d5                	j	80002cae <register_interrupt+0x12>

0000000080002ccc <unregister_interrupt>:

// 注销中断处理函数，将中断处理函数重置为默认处理函数
void unregister_interrupt(int irq)
{
    80002ccc:	1141                	addi	sp,sp,-16
    80002cce:	e422                	sd	s0,8(sp)
    80002cd0:	0800                	addi	s0,sp,16
    if (irq < 0 || irq >= 64)
    80002cd2:	03f00713          	li	a4,63
    80002cd6:	00a76e63          	bltu	a4,a0,80002cf2 <unregister_interrupt+0x26>
        return;
    interrupt_vector[irq] = default_handler;
    80002cda:	00351793          	slli	a5,a0,0x3
    80002cde:	0000d717          	auipc	a4,0xd
    80002ce2:	dfa70713          	addi	a4,a4,-518 # 8000fad8 <interrupt_vector>
    80002ce6:	97ba                	add	a5,a5,a4
    80002ce8:	00000717          	auipc	a4,0x0
    80002cec:	f0670713          	addi	a4,a4,-250 # 80002bee <default_handler>
    80002cf0:	e398                	sd	a4,0(a5)
    // 注意：不会自动禁用硬件中断，需要手动调用 disable_interrupt
}
    80002cf2:	6422                	ld	s0,8(sp)
    80002cf4:	0141                	addi	sp,sp,16
    80002cf6:	8082                	ret

0000000080002cf8 <enable_interrupt>:
// 启用中断，用于启用中断
// MIE_MTIE：机器模式定时器中断使能
// MIE_MSIE：机器模式软件中断使能
// MIE_MEIE：机器模式外部中断使能
void enable_interrupt(int irq)
{
    80002cf8:	1141                	addi	sp,sp,-16
    80002cfa:	e422                	sd	s0,8(sp)
    80002cfc:	0800                	addi	s0,sp,16
}

static inline uint64 r_mie()
{
    uint64 x;
    asm volatile("csrr %0, mie" : "=r"(x));
    80002cfe:	304027f3          	csrr	a5,mie
    uint64 mie = r_mie();
    if (irq == IRQ_M_TIMER)
    80002d02:	471d                	li	a4,7
    80002d04:	00e50d63          	beq	a0,a4,80002d1e <enable_interrupt+0x26>
        mie |= MIE_MTIE;
    else if (irq == IRQ_M_SOFT)
    80002d08:	470d                	li	a4,3
    80002d0a:	02e50163          	beq	a0,a4,80002d2c <enable_interrupt+0x34>
        mie |= MIE_MSIE;
    else if (irq == IRQ_M_EXT)
    80002d0e:	472d                	li	a4,11
    80002d10:	00e51963          	bne	a0,a4,80002d22 <enable_interrupt+0x2a>
        mie |= MIE_MEIE;
    80002d14:	6705                	lui	a4,0x1
    80002d16:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80002d1a:	8fd9                	or	a5,a5,a4
    80002d1c:	a019                	j	80002d22 <enable_interrupt+0x2a>
        mie |= MIE_MTIE;
    80002d1e:	0807e793          	ori	a5,a5,128
    return x;
}
static inline void w_mie(uint64 x)
{
    asm volatile("csrw mie, %0" : : "r"(x));
    80002d22:	30479073          	csrw	mie,a5
    w_mie(mie);
}
    80002d26:	6422                	ld	s0,8(sp)
    80002d28:	0141                	addi	sp,sp,16
    80002d2a:	8082                	ret
        mie |= MIE_MSIE;
    80002d2c:	0087e793          	ori	a5,a5,8
    80002d30:	bfcd                	j	80002d22 <enable_interrupt+0x2a>

0000000080002d32 <disable_interrupt>:

void disable_interrupt(int irq)
{
    80002d32:	1141                	addi	sp,sp,-16
    80002d34:	e422                	sd	s0,8(sp)
    80002d36:	0800                	addi	s0,sp,16
    asm volatile("csrr %0, mie" : "=r"(x));
    80002d38:	304027f3          	csrr	a5,mie
    uint64 mie = r_mie();
    if (irq == IRQ_M_TIMER)
    80002d3c:	471d                	li	a4,7
    80002d3e:	00e50d63          	beq	a0,a4,80002d58 <disable_interrupt+0x26>
        mie &= ~MIE_MTIE;
    else if (irq == IRQ_M_SOFT)
    80002d42:	470d                	li	a4,3
    80002d44:	02e50163          	beq	a0,a4,80002d66 <disable_interrupt+0x34>
        mie &= ~MIE_MSIE;
    else if (irq == IRQ_M_EXT)
    80002d48:	472d                	li	a4,11
    80002d4a:	00e51963          	bne	a0,a4,80002d5c <disable_interrupt+0x2a>
        mie &= ~MIE_MEIE;
    80002d4e:	777d                	lui	a4,0xfffff
    80002d50:	7ff70713          	addi	a4,a4,2047 # fffffffffffff7ff <end+0xffffffff7fb99a1f>
    80002d54:	8ff9                	and	a5,a5,a4
    80002d56:	a019                	j	80002d5c <disable_interrupt+0x2a>
        mie &= ~MIE_MTIE;
    80002d58:	f7f7f793          	andi	a5,a5,-129
    asm volatile("csrw mie, %0" : : "r"(x));
    80002d5c:	30479073          	csrw	mie,a5
    w_mie(mie);
}
    80002d60:	6422                	ld	s0,8(sp)
    80002d62:	0141                	addi	sp,sp,16
    80002d64:	8082                	ret
        mie &= ~MIE_MSIE;
    80002d66:	9bdd                	andi	a5,a5,-9
    80002d68:	bfd5                	j	80002d5c <disable_interrupt+0x2a>

0000000080002d6a <trap_init>:

extern void kernelvec(void);

void trap_init(void)
{
    80002d6a:	1141                	addi	sp,sp,-16
    80002d6c:	e422                	sd	s0,8(sp)
    80002d6e:	0800                	addi	s0,sp,16
    asm volatile("csrw mtvec, %0" : : "r"(x));
    80002d70:	00000797          	auipc	a5,0x0
    80002d74:	d4078793          	addi	a5,a5,-704 # 80002ab0 <kernelvec>
    80002d78:	30579073          	csrw	mtvec,a5
    // set mtvec to point to kernelvec in direct mode
    w_mtvec((uint64)kernelvec);
    // init vector table
    for (int i = 0; i < 64; i++)
    80002d7c:	0000d797          	auipc	a5,0xd
    80002d80:	d5c78793          	addi	a5,a5,-676 # 8000fad8 <interrupt_vector>
    80002d84:	0000d697          	auipc	a3,0xd
    80002d88:	f5468693          	addi	a3,a3,-172 # 8000fcd8 <_trapframe>
        interrupt_vector[i] = default_handler;
    80002d8c:	00000717          	auipc	a4,0x0
    80002d90:	e6270713          	addi	a4,a4,-414 # 80002bee <default_handler>
    80002d94:	e398                	sd	a4,0(a5)
    for (int i = 0; i < 64; i++)
    80002d96:	07a1                	addi	a5,a5,8
    80002d98:	fed79ee3          	bne	a5,a3,80002d94 <trap_init+0x2a>
    asm volatile("csrr %0, mstatus" : "=r"(x));
    80002d9c:	300027f3          	csrr	a5,mstatus
    // enable global interrupt in mstatus (mie bits are enabled per interrupt)
    uint64 m = r_mstatus(); // 读取当前机器状态
    m |= MSTATUS_MIE;       // 设置机器模式中断使能位
    80002da0:	0087e793          	ori	a5,a5,8
    asm volatile("csrw mstatus, %0" : : "r"(x));
    80002da4:	30079073          	csrw	mstatus,a5
    w_mstatus(m);           // 写入机器状态
}
    80002da8:	6422                	ld	s0,8(sp)
    80002daa:	0141                	addi	sp,sp,16
    80002dac:	8082                	ret

0000000080002dae <handle_syscall>:
    return mpp == 3; // M-mode
}

// 系统调用处理（参考xv6）
void handle_syscall(struct trapframe *tf)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84aa                	mv	s1,a0
    asm volatile("csrr %0, mstatus" : "=r"(x));
    80002dba:	300027f3          	csrr	a5,mstatus
    uint64 mpp = (mstatus >> 11) & 3;
    80002dbe:	83ad                	srli	a5,a5,0xb
    80002dc0:	8b8d                	andi	a5,a5,3
    uint64 syscall_num = tf->a7;
    // uint64 args[6] = {tf->a0, tf->a1, tf->a2, tf->a3, tf->a4, tf->a5};

    // 检查是否在内核模式（当前只有内核模式）
    if (!is_kernel_mode())
    80002dc2:	470d                	li	a4,3
    80002dc4:	02e79563          	bne	a5,a4,80002dee <handle_syscall+0x40>
    uint64 syscall_num = tf->a7;
    80002dc8:	614c                	ld	a1,128(a0)
        tf->mepc += instruction_length(tf->mepc);
        return;
    }

    // 系统调用分发
    switch (syscall_num)
    80002dca:	4785                	li	a5,1
    80002dcc:	08f58163          	beq	a1,a5,80002e4e <handle_syscall+0xa0>
    80002dd0:	4789                	li	a5,2
    80002dd2:	08f58663          	beq	a1,a5,80002e5e <handle_syscall+0xb0>
    80002dd6:	c1b1                	beqz	a1,80002e1a <handle_syscall+0x6c>
        break;
    case SYS_GETPRIORITY: // 获取进程优先级
        tf->a0 = sys_getpriority((int)tf->a0);
        break;
    default:
        printf("Unknown syscall: num=%lu\n", syscall_num);
    80002dd8:	00009517          	auipc	a0,0x9
    80002ddc:	f9850513          	addi	a0,a0,-104 # 8000bd70 <digits+0x1bc0>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	724080e7          	jalr	1828(ra) # 80000504 <printf>
        tf->a0 = -1; // 返回错误
    80002de8:	57fd                	li	a5,-1
    80002dea:	e4bc                	sd	a5,72(s1)
        break;
    80002dec:	a089                	j	80002e2e <handle_syscall+0x80>
        printf("Syscall from non-kernel mode not supported yet\n");
    80002dee:	00009517          	auipc	a0,0x9
    80002df2:	f2a50513          	addi	a0,a0,-214 # 8000bd18 <digits+0x1b68>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	70e080e7          	jalr	1806(ra) # 80000504 <printf>
        tf->a0 = -1; // 返回错误
    80002dfe:	57fd                	li	a5,-1
    80002e00:	e4bc                	sd	a5,72(s1)
        tf->mepc += instruction_length(tf->mepc);
    80002e02:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    80002e04:	0007d703          	lhu	a4,0(a5)
    if ((first_half & 0x3) != 0x3)
    80002e08:	8b0d                	andi	a4,a4,3
    80002e0a:	460d                	li	a2,3
    return 4;
    80002e0c:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    80002e0e:	00c70363          	beq	a4,a2,80002e14 <handle_syscall+0x66>
        return 2;
    80002e12:	4689                	li	a3,2
        tf->mepc += instruction_length(tf->mepc);
    80002e14:	97b6                	add	a5,a5,a3
    80002e16:	fcfc                	sd	a5,248(s1)
        return;
    80002e18:	a035                	j	80002e44 <handle_syscall+0x96>
        printf("Syscall 0: syscall framework ready\n");
    80002e1a:	00009517          	auipc	a0,0x9
    80002e1e:	f2e50513          	addi	a0,a0,-210 # 8000bd48 <digits+0x1b98>
    80002e22:	ffffd097          	auipc	ra,0xffffd
    80002e26:	6e2080e7          	jalr	1762(ra) # 80000504 <printf>
        tf->a0 = 0; // 成功
    80002e2a:	0404b423          	sd	zero,72(s1)
    }

    tf->mepc += instruction_length(tf->mepc);
    80002e2e:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    80002e30:	0007d703          	lhu	a4,0(a5)
    if ((first_half & 0x3) != 0x3)
    80002e34:	8b0d                	andi	a4,a4,3
    80002e36:	460d                	li	a2,3
    return 4;
    80002e38:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    80002e3a:	00c70363          	beq	a4,a2,80002e40 <handle_syscall+0x92>
        return 2;
    80002e3e:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    80002e40:	97b6                	add	a5,a5,a3
    80002e42:	fcfc                	sd	a5,248(s1)
}
    80002e44:	60e2                	ld	ra,24(sp)
    80002e46:	6442                	ld	s0,16(sp)
    80002e48:	64a2                	ld	s1,8(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret
        tf->a0 = sys_setpriority((int)tf->a0, (int)tf->a1);
    80002e4e:	492c                	lw	a1,80(a0)
    80002e50:	4528                	lw	a0,72(a0)
    80002e52:	00001097          	auipc	ra,0x1
    80002e56:	668080e7          	jalr	1640(ra) # 800044ba <sys_setpriority>
    80002e5a:	e4a8                	sd	a0,72(s1)
        break;
    80002e5c:	bfc9                	j	80002e2e <handle_syscall+0x80>
        tf->a0 = sys_getpriority((int)tf->a0);
    80002e5e:	4528                	lw	a0,72(a0)
    80002e60:	00001097          	auipc	ra,0x1
    80002e64:	6b0080e7          	jalr	1712(ra) # 80004510 <sys_getpriority>
    80002e68:	e4a8                	sd	a0,72(s1)
        break;
    80002e6a:	b7d1                	j	80002e2e <handle_syscall+0x80>

0000000080002e6c <handle_instruction_page_fault>:

// 页故障处理（如果有分页支持）
void handle_instruction_page_fault(struct trapframe *tf)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	e426                	sd	s1,8(sp)
    80002e74:	e04a                	sd	s2,0(sp)
    80002e76:	1000                	addi	s0,sp,32
    80002e78:	84aa                	mv	s1,a0
    return x;
}
static inline uint64 r_mtval()
{
    uint64 x;
    asm volatile("csrr %0, mtval" : "=r"(x));
    80002e7a:	34302973          	csrr	s2,mtval
    uint64 va = r_mtval();
    uint64 mepc = tf->mepc;

    printf("Instruction page fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)mepc);
    80002e7e:	7d70                	ld	a2,248(a0)
    80002e80:	85ca                	mv	a1,s2
    80002e82:	00009517          	auipc	a0,0x9
    80002e86:	f0e50513          	addi	a0,a0,-242 # 8000bd90 <digits+0x1be0>
    80002e8a:	ffffd097          	auipc	ra,0xffffd
    80002e8e:	67a080e7          	jalr	1658(ra) # 80000504 <printf>

    // 如果是内核地址且启用了分页，这是严重错误
    if (is_kernel_address(va))
    80002e92:	800007b7          	lui	a5,0x80000
    80002e96:	fff7c793          	not	a5,a5
    80002e9a:	0327eb63          	bltu	a5,s2,80002ed0 <handle_instruction_page_fault+0x64>
        printf("Kernel instruction page fault - this should not happen!\n");
        panic("Kernel instruction page fault");
    }

    // 用户态页故障处理（当前未实现用户态）
    printf("User instruction page fault not supported yet\n");
    80002e9e:	00009517          	auipc	a0,0x9
    80002ea2:	f8250513          	addi	a0,a0,-126 # 8000be20 <digits+0x1c70>
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	65e080e7          	jalr	1630(ra) # 80000504 <printf>
    tf->mepc += instruction_length(tf->mepc);
    80002eae:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    80002eb0:	0007d703          	lhu	a4,0(a5) # ffffffff80000000 <end+0xfffffffeffb9a220>
    if ((first_half & 0x3) != 0x3)
    80002eb4:	8b0d                	andi	a4,a4,3
    80002eb6:	460d                	li	a2,3
    return 4;
    80002eb8:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    80002eba:	00c70363          	beq	a4,a2,80002ec0 <handle_instruction_page_fault+0x54>
        return 2;
    80002ebe:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    80002ec0:	97b6                	add	a5,a5,a3
    80002ec2:	fcfc                	sd	a5,248(s1)
}
    80002ec4:	60e2                	ld	ra,24(sp)
    80002ec6:	6442                	ld	s0,16(sp)
    80002ec8:	64a2                	ld	s1,8(sp)
    80002eca:	6902                	ld	s2,0(sp)
    80002ecc:	6105                	addi	sp,sp,32
    80002ece:	8082                	ret
        printf("Kernel instruction page fault - this should not happen!\n");
    80002ed0:	00009517          	auipc	a0,0x9
    80002ed4:	ef050513          	addi	a0,a0,-272 # 8000bdc0 <digits+0x1c10>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	62c080e7          	jalr	1580(ra) # 80000504 <printf>
        panic("Kernel instruction page fault");
    80002ee0:	00009517          	auipc	a0,0x9
    80002ee4:	f2050513          	addi	a0,a0,-224 # 8000be00 <digits+0x1c50>
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	ba4080e7          	jalr	-1116(ra) # 80002a8c <panic>

0000000080002ef0 <handle_load_page_fault>:

void handle_load_page_fault(struct trapframe *tf)
{
    80002ef0:	1101                	addi	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	e426                	sd	s1,8(sp)
    80002ef8:	e04a                	sd	s2,0(sp)
    80002efa:	1000                	addi	s0,sp,32
    80002efc:	84aa                	mv	s1,a0
    80002efe:	34302973          	csrr	s2,mtval
    uint64 va = r_mtval();

    printf("Load page fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)tf->mepc);
    80002f02:	7d70                	ld	a2,248(a0)
    80002f04:	85ca                	mv	a1,s2
    80002f06:	00009517          	auipc	a0,0x9
    80002f0a:	f4a50513          	addi	a0,a0,-182 # 8000be50 <digits+0x1ca0>
    80002f0e:	ffffd097          	auipc	ra,0xffffd
    80002f12:	5f6080e7          	jalr	1526(ra) # 80000504 <printf>

    // 内核地址的页故障应该panic
    if (is_kernel_address(va))
    80002f16:	800007b7          	lui	a5,0x80000
    80002f1a:	fff7c793          	not	a5,a5
    80002f1e:	0327eb63          	bltu	a5,s2,80002f54 <handle_load_page_fault+0x64>
        printf("Kernel load page fault - this should not happen!\n");
        panic("Kernel load page fault");
    }

    // 用户态页故障处理（当前未实现）
    printf("User load page fault not supported yet\n");
    80002f22:	00009517          	auipc	a0,0x9
    80002f26:	fa650513          	addi	a0,a0,-90 # 8000bec8 <digits+0x1d18>
    80002f2a:	ffffd097          	auipc	ra,0xffffd
    80002f2e:	5da080e7          	jalr	1498(ra) # 80000504 <printf>
    tf->mepc += instruction_length(tf->mepc);
    80002f32:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    80002f34:	0007d703          	lhu	a4,0(a5) # ffffffff80000000 <end+0xfffffffeffb9a220>
    if ((first_half & 0x3) != 0x3)
    80002f38:	8b0d                	andi	a4,a4,3
    80002f3a:	460d                	li	a2,3
    return 4;
    80002f3c:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    80002f3e:	00c70363          	beq	a4,a2,80002f44 <handle_load_page_fault+0x54>
        return 2;
    80002f42:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    80002f44:	97b6                	add	a5,a5,a3
    80002f46:	fcfc                	sd	a5,248(s1)
}
    80002f48:	60e2                	ld	ra,24(sp)
    80002f4a:	6442                	ld	s0,16(sp)
    80002f4c:	64a2                	ld	s1,8(sp)
    80002f4e:	6902                	ld	s2,0(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret
        printf("Kernel load page fault - this should not happen!\n");
    80002f54:	00009517          	auipc	a0,0x9
    80002f58:	f2450513          	addi	a0,a0,-220 # 8000be78 <digits+0x1cc8>
    80002f5c:	ffffd097          	auipc	ra,0xffffd
    80002f60:	5a8080e7          	jalr	1448(ra) # 80000504 <printf>
        panic("Kernel load page fault");
    80002f64:	00009517          	auipc	a0,0x9
    80002f68:	f4c50513          	addi	a0,a0,-180 # 8000beb0 <digits+0x1d00>
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	b20080e7          	jalr	-1248(ra) # 80002a8c <panic>

0000000080002f74 <handle_store_page_fault>:

void handle_store_page_fault(struct trapframe *tf)
{
    80002f74:	1101                	addi	sp,sp,-32
    80002f76:	ec06                	sd	ra,24(sp)
    80002f78:	e822                	sd	s0,16(sp)
    80002f7a:	e426                	sd	s1,8(sp)
    80002f7c:	e04a                	sd	s2,0(sp)
    80002f7e:	1000                	addi	s0,sp,32
    80002f80:	84aa                	mv	s1,a0
    80002f82:	34302973          	csrr	s2,mtval
    uint64 va = r_mtval();

    printf("Store page fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)tf->mepc);
    80002f86:	7d70                	ld	a2,248(a0)
    80002f88:	85ca                	mv	a1,s2
    80002f8a:	00009517          	auipc	a0,0x9
    80002f8e:	f6650513          	addi	a0,a0,-154 # 8000bef0 <digits+0x1d40>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	572080e7          	jalr	1394(ra) # 80000504 <printf>

    // 内核地址的页故障应该panic
    if (is_kernel_address(va))
    80002f9a:	800007b7          	lui	a5,0x80000
    80002f9e:	fff7c793          	not	a5,a5
    80002fa2:	0327eb63          	bltu	a5,s2,80002fd8 <handle_store_page_fault+0x64>
        printf("Kernel store page fault - this should not happen!\n");
        panic("Kernel store page fault");
    }

    // 用户态页故障处理（当前未实现）
    printf("User store page fault not supported yet\n");
    80002fa6:	00009517          	auipc	a0,0x9
    80002faa:	fc250513          	addi	a0,a0,-62 # 8000bf68 <digits+0x1db8>
    80002fae:	ffffd097          	auipc	ra,0xffffd
    80002fb2:	556080e7          	jalr	1366(ra) # 80000504 <printf>
    tf->mepc += instruction_length(tf->mepc);
    80002fb6:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    80002fb8:	0007d703          	lhu	a4,0(a5) # ffffffff80000000 <end+0xfffffffeffb9a220>
    if ((first_half & 0x3) != 0x3)
    80002fbc:	8b0d                	andi	a4,a4,3
    80002fbe:	460d                	li	a2,3
    return 4;
    80002fc0:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    80002fc2:	00c70363          	beq	a4,a2,80002fc8 <handle_store_page_fault+0x54>
        return 2;
    80002fc6:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    80002fc8:	97b6                	add	a5,a5,a3
    80002fca:	fcfc                	sd	a5,248(s1)
}
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6902                	ld	s2,0(sp)
    80002fd4:	6105                	addi	sp,sp,32
    80002fd6:	8082                	ret
        printf("Kernel store page fault - this should not happen!\n");
    80002fd8:	00009517          	auipc	a0,0x9
    80002fdc:	f4050513          	addi	a0,a0,-192 # 8000bf18 <digits+0x1d68>
    80002fe0:	ffffd097          	auipc	ra,0xffffd
    80002fe4:	524080e7          	jalr	1316(ra) # 80000504 <printf>
        panic("Kernel store page fault");
    80002fe8:	00009517          	auipc	a0,0x9
    80002fec:	f6850513          	addi	a0,a0,-152 # 8000bf50 <digits+0x1da0>
    80002ff0:	00000097          	auipc	ra,0x0
    80002ff4:	a9c080e7          	jalr	-1380(ra) # 80002a8c <panic>

0000000080002ff8 <set_test_mode>:
// 非法指令处理：内核中的非法指令应该panic
// 但在测试场景中，我们允许跳过（测试故意触发的异常）
static int in_test_mode = 0; // 测试模式标志

void set_test_mode(int mode)
{
    80002ff8:	1141                	addi	sp,sp,-16
    80002ffa:	e422                	sd	s0,8(sp)
    80002ffc:	0800                	addi	s0,sp,16
    in_test_mode = mode;
    80002ffe:	0000d797          	auipc	a5,0xd
    80003002:	86a7a123          	sw	a0,-1950(a5) # 8000f860 <in_test_mode>
}
    80003006:	6422                	ld	s0,8(sp)
    80003008:	0141                	addi	sp,sp,16
    8000300a:	8082                	ret

000000008000300c <handle_illegal_instruction>:

void handle_illegal_instruction(struct trapframe *tf)
{
    8000300c:	7179                	addi	sp,sp,-48
    8000300e:	f406                	sd	ra,40(sp)
    80003010:	f022                	sd	s0,32(sp)
    80003012:	ec26                	sd	s1,24(sp)
    80003014:	e84a                	sd	s2,16(sp)
    80003016:	e44e                	sd	s3,8(sp)
    80003018:	1800                	addi	s0,sp,48
    8000301a:	84aa                	mv	s1,a0
    uint64 mepc = tf->mepc;
    8000301c:	0f853903          	ld	s2,248(a0)
    80003020:	343025f3          	csrr	a1,mtval
    uint64 mtval = r_mtval();

    printf("Illegal instruction: mtval=0x%p mepc=0x%p\n", (void *)mtval, (void *)mepc);
    80003024:	864a                	mv	a2,s2
    80003026:	00009517          	auipc	a0,0x9
    8000302a:	f7250513          	addi	a0,a0,-142 # 8000bf98 <digits+0x1de8>
    8000302e:	ffffd097          	auipc	ra,0xffffd
    80003032:	4d6080e7          	jalr	1238(ra) # 80000504 <printf>

    // 内核代码中的非法指令是严重错误
    if (is_kernel_address(mepc))
    80003036:	800007b7          	lui	a5,0x80000
    8000303a:	fff7c793          	not	a5,a5
    8000303e:	0727f263          	bgeu	a5,s2,800030a2 <handle_illegal_instruction+0x96>
    {
        if (in_test_mode)
    80003042:	0000d797          	auipc	a5,0xd
    80003046:	81e7a783          	lw	a5,-2018(a5) # 8000f860 <in_test_mode>
    8000304a:	cb9d                	beqz	a5,80003080 <handle_illegal_instruction+0x74>
        {
            // 测试模式：只打印警告，不panic
            printf("  [TEST MODE] Kernel illegal instruction detected, skipping...\n");
    8000304c:	00009517          	auipc	a0,0x9
    80003050:	f7c50513          	addi	a0,a0,-132 # 8000bfc8 <digits+0x1e18>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	4b0080e7          	jalr	1200(ra) # 80000504 <printf>
    {
        // 用户态非法指令（当前未实现用户态，暂时跳过）
        printf("User illegal instruction handling not implemented yet\n");
    }

    tf->mepc += instruction_length(tf->mepc);
    8000305c:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    8000305e:	0007d703          	lhu	a4,0(a5)
    if ((first_half & 0x3) != 0x3)
    80003062:	8b0d                	andi	a4,a4,3
    80003064:	460d                	li	a2,3
    return 4;
    80003066:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    80003068:	00c70363          	beq	a4,a2,8000306e <handle_illegal_instruction+0x62>
        return 2;
    8000306c:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    8000306e:	97b6                	add	a5,a5,a3
    80003070:	fcfc                	sd	a5,248(s1)
}
    80003072:	70a2                	ld	ra,40(sp)
    80003074:	7402                	ld	s0,32(sp)
    80003076:	64e2                	ld	s1,24(sp)
    80003078:	6942                	ld	s2,16(sp)
    8000307a:	69a2                	ld	s3,8(sp)
    8000307c:	6145                	addi	sp,sp,48
    8000307e:	8082                	ret
            printf("Kernel illegal instruction at 0x%p - system error!\n", (void *)mepc);
    80003080:	85ca                	mv	a1,s2
    80003082:	00009517          	auipc	a0,0x9
    80003086:	f8650513          	addi	a0,a0,-122 # 8000c008 <digits+0x1e58>
    8000308a:	ffffd097          	auipc	ra,0xffffd
    8000308e:	47a080e7          	jalr	1146(ra) # 80000504 <printf>
            panic("Kernel illegal instruction");
    80003092:	00009517          	auipc	a0,0x9
    80003096:	fae50513          	addi	a0,a0,-82 # 8000c040 <digits+0x1e90>
    8000309a:	00000097          	auipc	ra,0x0
    8000309e:	9f2080e7          	jalr	-1550(ra) # 80002a8c <panic>
        printf("User illegal instruction handling not implemented yet\n");
    800030a2:	00009517          	auipc	a0,0x9
    800030a6:	fbe50513          	addi	a0,a0,-66 # 8000c060 <digits+0x1eb0>
    800030aa:	ffffd097          	auipc	ra,0xffffd
    800030ae:	45a080e7          	jalr	1114(ra) # 80000504 <printf>
    800030b2:	b76d                	j	8000305c <handle_illegal_instruction+0x50>

00000000800030b4 <handle_load_access_fault>:

// 访问故障处理：内核地址出错应该panic
void handle_load_access_fault(struct trapframe *tf)
{
    800030b4:	7179                	addi	sp,sp,-48
    800030b6:	f406                	sd	ra,40(sp)
    800030b8:	f022                	sd	s0,32(sp)
    800030ba:	ec26                	sd	s1,24(sp)
    800030bc:	e84a                	sd	s2,16(sp)
    800030be:	e44e                	sd	s3,8(sp)
    800030c0:	1800                	addi	s0,sp,48
    800030c2:	84aa                	mv	s1,a0
    800030c4:	34302973          	csrr	s2,mtval
    uint64 va = r_mtval();
    uint64 mepc = tf->mepc;
    800030c8:	0f853983          	ld	s3,248(a0)

    printf("Load access fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)mepc);
    800030cc:	864e                	mv	a2,s3
    800030ce:	85ca                	mv	a1,s2
    800030d0:	00009517          	auipc	a0,0x9
    800030d4:	fc850513          	addi	a0,a0,-56 # 8000c098 <digits+0x1ee8>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	42c080e7          	jalr	1068(ra) # 80000504 <printf>

    // 内核地址的访问故障通常是严重错误
    if (is_kernel_address(va) || is_kernel_address(mepc))
    800030e0:	800007b7          	lui	a5,0x80000
    800030e4:	fff7c793          	not	a5,a5
    800030e8:	0127e863          	bltu	a5,s2,800030f8 <handle_load_access_fault+0x44>
    800030ec:	800007b7          	lui	a5,0x80000
    800030f0:	fff7c793          	not	a5,a5
    800030f4:	0737f163          	bgeu	a5,s3,80003156 <handle_load_access_fault+0xa2>
    {
        if (in_test_mode)
    800030f8:	0000c797          	auipc	a5,0xc
    800030fc:	7687a783          	lw	a5,1896(a5) # 8000f860 <in_test_mode>
    80003100:	cb9d                	beqz	a5,80003136 <handle_load_access_fault+0x82>
        {
            // 测试模式：只打印警告，不panic
            printf("  [TEST MODE] Kernel load access fault detected, skipping...\n");
    80003102:	00009517          	auipc	a0,0x9
    80003106:	fbe50513          	addi	a0,a0,-66 # 8000c0c0 <digits+0x1f10>
    8000310a:	ffffd097          	auipc	ra,0xffffd
    8000310e:	3fa080e7          	jalr	1018(ra) # 80000504 <printf>
    {
        // 用户态访问故障（当前未实现）
        printf("User load access fault not supported yet\n");
    }

    tf->mepc += instruction_length(tf->mepc);
    80003112:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    80003114:	0007d703          	lhu	a4,0(a5)
    if ((first_half & 0x3) != 0x3)
    80003118:	8b0d                	andi	a4,a4,3
    8000311a:	460d                	li	a2,3
    return 4;
    8000311c:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    8000311e:	00c70363          	beq	a4,a2,80003124 <handle_load_access_fault+0x70>
        return 2;
    80003122:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    80003124:	97b6                	add	a5,a5,a3
    80003126:	fcfc                	sd	a5,248(s1)
}
    80003128:	70a2                	ld	ra,40(sp)
    8000312a:	7402                	ld	s0,32(sp)
    8000312c:	64e2                	ld	s1,24(sp)
    8000312e:	6942                	ld	s2,16(sp)
    80003130:	69a2                	ld	s3,8(sp)
    80003132:	6145                	addi	sp,sp,48
    80003134:	8082                	ret
            printf("Kernel load access fault - memory protection violation!\n");
    80003136:	00009517          	auipc	a0,0x9
    8000313a:	fca50513          	addi	a0,a0,-54 # 8000c100 <digits+0x1f50>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	3c6080e7          	jalr	966(ra) # 80000504 <printf>
            panic("Kernel load access fault");
    80003146:	00009517          	auipc	a0,0x9
    8000314a:	ffa50513          	addi	a0,a0,-6 # 8000c140 <digits+0x1f90>
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	93e080e7          	jalr	-1730(ra) # 80002a8c <panic>
        printf("User load access fault not supported yet\n");
    80003156:	00009517          	auipc	a0,0x9
    8000315a:	00a50513          	addi	a0,a0,10 # 8000c160 <digits+0x1fb0>
    8000315e:	ffffd097          	auipc	ra,0xffffd
    80003162:	3a6080e7          	jalr	934(ra) # 80000504 <printf>
    80003166:	b775                	j	80003112 <handle_load_access_fault+0x5e>

0000000080003168 <handle_store_access_fault>:

void handle_store_access_fault(struct trapframe *tf)
{
    80003168:	7179                	addi	sp,sp,-48
    8000316a:	f406                	sd	ra,40(sp)
    8000316c:	f022                	sd	s0,32(sp)
    8000316e:	ec26                	sd	s1,24(sp)
    80003170:	e84a                	sd	s2,16(sp)
    80003172:	e44e                	sd	s3,8(sp)
    80003174:	1800                	addi	s0,sp,48
    80003176:	84aa                	mv	s1,a0
    80003178:	34302973          	csrr	s2,mtval
    uint64 va = r_mtval();
    uint64 mepc = tf->mepc;
    8000317c:	0f853983          	ld	s3,248(a0)

    printf("Store access fault: va=0x%p mepc=0x%p\n", (void *)va, (void *)mepc);
    80003180:	864e                	mv	a2,s3
    80003182:	85ca                	mv	a1,s2
    80003184:	00009517          	auipc	a0,0x9
    80003188:	00c50513          	addi	a0,a0,12 # 8000c190 <digits+0x1fe0>
    8000318c:	ffffd097          	auipc	ra,0xffffd
    80003190:	378080e7          	jalr	888(ra) # 80000504 <printf>

    // 内核地址的访问故障通常是严重错误
    if (is_kernel_address(va) || is_kernel_address(mepc))
    80003194:	800007b7          	lui	a5,0x80000
    80003198:	fff7c793          	not	a5,a5
    8000319c:	0127e863          	bltu	a5,s2,800031ac <handle_store_access_fault+0x44>
    800031a0:	800007b7          	lui	a5,0x80000
    800031a4:	fff7c793          	not	a5,a5
    800031a8:	0737f163          	bgeu	a5,s3,8000320a <handle_store_access_fault+0xa2>
    {
        if (in_test_mode)
    800031ac:	0000c797          	auipc	a5,0xc
    800031b0:	6b47a783          	lw	a5,1716(a5) # 8000f860 <in_test_mode>
    800031b4:	cb9d                	beqz	a5,800031ea <handle_store_access_fault+0x82>
        {
            // 测试模式：只打印警告，不panic
            printf("  [TEST MODE] Kernel store access fault detected, skipping...\n");
    800031b6:	00009517          	auipc	a0,0x9
    800031ba:	00250513          	addi	a0,a0,2 # 8000c1b8 <digits+0x2008>
    800031be:	ffffd097          	auipc	ra,0xffffd
    800031c2:	346080e7          	jalr	838(ra) # 80000504 <printf>
    {
        // 用户态访问故障（当前未实现）
        printf("User store access fault not supported yet\n");
    }

    tf->mepc += instruction_length(tf->mepc);
    800031c6:	7cfc                	ld	a5,248(s1)
    uint16 first_half = *(volatile uint16 *)mepc;
    800031c8:	0007d703          	lhu	a4,0(a5)
    if ((first_half & 0x3) != 0x3)
    800031cc:	8b0d                	andi	a4,a4,3
    800031ce:	460d                	li	a2,3
    return 4;
    800031d0:	4691                	li	a3,4
    if ((first_half & 0x3) != 0x3)
    800031d2:	00c70363          	beq	a4,a2,800031d8 <handle_store_access_fault+0x70>
        return 2;
    800031d6:	4689                	li	a3,2
    tf->mepc += instruction_length(tf->mepc);
    800031d8:	97b6                	add	a5,a5,a3
    800031da:	fcfc                	sd	a5,248(s1)
}
    800031dc:	70a2                	ld	ra,40(sp)
    800031de:	7402                	ld	s0,32(sp)
    800031e0:	64e2                	ld	s1,24(sp)
    800031e2:	6942                	ld	s2,16(sp)
    800031e4:	69a2                	ld	s3,8(sp)
    800031e6:	6145                	addi	sp,sp,48
    800031e8:	8082                	ret
            printf("Kernel store access fault - memory protection violation!\n");
    800031ea:	00009517          	auipc	a0,0x9
    800031ee:	00e50513          	addi	a0,a0,14 # 8000c1f8 <digits+0x2048>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	312080e7          	jalr	786(ra) # 80000504 <printf>
            panic("Kernel store access fault");
    800031fa:	00009517          	auipc	a0,0x9
    800031fe:	03e50513          	addi	a0,a0,62 # 8000c238 <digits+0x2088>
    80003202:	00000097          	auipc	ra,0x0
    80003206:	88a080e7          	jalr	-1910(ra) # 80002a8c <panic>
        printf("User store access fault not supported yet\n");
    8000320a:	00009517          	auipc	a0,0x9
    8000320e:	04e50513          	addi	a0,a0,78 # 8000c258 <digits+0x20a8>
    80003212:	ffffd097          	auipc	ra,0xffffd
    80003216:	2f2080e7          	jalr	754(ra) # 80000504 <printf>
    8000321a:	b775                	j	800031c6 <handle_store_access_fault+0x5e>

000000008000321c <handle_exception>:

void handle_exception(struct trapframe *tf)
{
    8000321c:	1141                	addi	sp,sp,-16
    8000321e:	e406                	sd	ra,8(sp)
    80003220:	e022                	sd	s0,0(sp)
    80003222:	0800                	addi	s0,sp,16
    asm volatile("csrr %0, mcause" : "=r"(x));
    80003224:	342025f3          	csrr	a1,mcause
    uint64 raw = r_mcause();
    uint64 cause = raw & 0xfff;
    80003228:	03459793          	slli	a5,a1,0x34
    8000322c:	93d1                	srli	a5,a5,0x34
    8000322e:	473d                	li	a4,15
    80003230:	06f76163          	bltu	a4,a5,80003292 <handle_exception+0x76>
    80003234:	078a                	slli	a5,a5,0x2
    80003236:	00009717          	auipc	a4,0x9
    8000323a:	09e70713          	addi	a4,a4,158 # 8000c2d4 <digits+0x2124>
    8000323e:	97ba                	add	a5,a5,a4
    80003240:	439c                	lw	a5,0(a5)
    80003242:	97ba                	add	a5,a5,a4
    80003244:	8782                	jr	a5
    switch (cause)
    {
    case 2: // illegal instruction
        handle_illegal_instruction(tf);
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	dc6080e7          	jalr	-570(ra) # 8000300c <handle_illegal_instruction>
        break;
    default:
        printf("Unknown exception: mcause=%lu mtval=0x%p mepc=0x%p\n", raw, (void *)r_mtval(), (void *)tf->mepc);
        panic("Unknown exception");
    }
}
    8000324e:	60a2                	ld	ra,8(sp)
    80003250:	6402                	ld	s0,0(sp)
    80003252:	0141                	addi	sp,sp,16
    80003254:	8082                	ret
        handle_load_access_fault(tf);
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	e5e080e7          	jalr	-418(ra) # 800030b4 <handle_load_access_fault>
        break;
    8000325e:	bfc5                	j	8000324e <handle_exception+0x32>
        handle_store_access_fault(tf);
    80003260:	00000097          	auipc	ra,0x0
    80003264:	f08080e7          	jalr	-248(ra) # 80003168 <handle_store_access_fault>
        break;
    80003268:	b7dd                	j	8000324e <handle_exception+0x32>
        handle_syscall(tf);
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	b44080e7          	jalr	-1212(ra) # 80002dae <handle_syscall>
        break;
    80003272:	bff1                	j	8000324e <handle_exception+0x32>
        handle_instruction_page_fault(tf);
    80003274:	00000097          	auipc	ra,0x0
    80003278:	bf8080e7          	jalr	-1032(ra) # 80002e6c <handle_instruction_page_fault>
        break;
    8000327c:	bfc9                	j	8000324e <handle_exception+0x32>
        handle_load_page_fault(tf);
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	c72080e7          	jalr	-910(ra) # 80002ef0 <handle_load_page_fault>
        break;
    80003286:	b7e1                	j	8000324e <handle_exception+0x32>
        handle_store_page_fault(tf);
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	cec080e7          	jalr	-788(ra) # 80002f74 <handle_store_page_fault>
        break;
    80003290:	bf7d                	j	8000324e <handle_exception+0x32>
    asm volatile("csrr %0, mtval" : "=r"(x));
    80003292:	34302673          	csrr	a2,mtval
        printf("Unknown exception: mcause=%lu mtval=0x%p mepc=0x%p\n", raw, (void *)r_mtval(), (void *)tf->mepc);
    80003296:	7d74                	ld	a3,248(a0)
    80003298:	00009517          	auipc	a0,0x9
    8000329c:	ff050513          	addi	a0,a0,-16 # 8000c288 <digits+0x20d8>
    800032a0:	ffffd097          	auipc	ra,0xffffd
    800032a4:	264080e7          	jalr	612(ra) # 80000504 <printf>
        panic("Unknown exception");
    800032a8:	00009517          	auipc	a0,0x9
    800032ac:	01850513          	addi	a0,a0,24 # 8000c2c0 <digits+0x2110>
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	7dc080e7          	jalr	2012(ra) # 80002a8c <panic>

00000000800032b8 <kerneltrap>:

void kerneltrap(void)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	1000                	addi	s0,sp,32
    uint64 trap_start = get_time();
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	0f8080e7          	jalr	248(ra) # 800033ba <get_time>
    800032ca:	84aa                	mv	s1,a0
    asm volatile("csrr %0, mcause" : "=r"(x));
    800032cc:	342027f3          	csrr	a5,mcause

    uint64 mcause = r_mcause();
    if (is_interrupt(mcause))
    800032d0:	0207d863          	bgez	a5,80003300 <kerneltrap+0x48>
    {
        int irq = (int)(mcause & 0xfff);
    800032d4:	17d2                	slli	a5,a5,0x34
    800032d6:	0347d713          	srli	a4,a5,0x34
        if (irq >= 0 && irq < 64 && interrupt_vector[irq])
    800032da:	03f00693          	li	a3,63
    800032de:	00e6ec63          	bltu	a3,a4,800032f6 <kerneltrap+0x3e>
    800032e2:	070e                	slli	a4,a4,0x3
    800032e4:	0000c797          	auipc	a5,0xc
    800032e8:	7f478793          	addi	a5,a5,2036 # 8000fad8 <interrupt_vector>
    800032ec:	973e                	add	a4,a4,a5
    800032ee:	631c                	ld	a5,0(a4)
    800032f0:	c399                	beqz	a5,800032f6 <kerneltrap+0x3e>
        {
            interrupt_vector[irq]();
    800032f2:	9782                	jalr	a5
    800032f4:	a831                	j	80003310 <kerneltrap+0x58>
        }
        else
        {
            default_handler();
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	8f8080e7          	jalr	-1800(ra) # 80002bee <default_handler>
    800032fe:	a809                	j	80003310 <kerneltrap+0x58>
        }
    }
    else
    {
        handle_exception(&_trapframe);
    80003300:	0000d517          	auipc	a0,0xd
    80003304:	9d850513          	addi	a0,a0,-1576 # 8000fcd8 <_trapframe>
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	f14080e7          	jalr	-236(ra) # 8000321c <handle_exception>
    }

    // 统计上下文切换开销（保存+恢复+处理）
    uint64 trap_end = get_time();
    80003310:	00000097          	auipc	ra,0x0
    80003314:	0aa080e7          	jalr	170(ra) # 800033ba <get_time>
    uint64 context_time = trap_end - trap_start;
    80003318:	8d05                	sub	a0,a0,s1

    total_context_switch_time += context_time;
    8000331a:	0000c717          	auipc	a4,0xc
    8000331e:	55e70713          	addi	a4,a4,1374 # 8000f878 <total_context_switch_time>
    80003322:	631c                	ld	a5,0(a4)
    80003324:	97aa                	add	a5,a5,a0
    80003326:	e31c                	sd	a5,0(a4)
    context_switch_count++;
    80003328:	0000c717          	auipc	a4,0xc
    8000332c:	54870713          	addi	a4,a4,1352 # 8000f870 <context_switch_count>
    80003330:	631c                	ld	a5,0(a4)
    80003332:	0785                	addi	a5,a5,1
    80003334:	e31c                	sd	a5,0(a4)
    if (context_time > max_context_switch_time)
    80003336:	0000c797          	auipc	a5,0xc
    8000333a:	5327b783          	ld	a5,1330(a5) # 8000f868 <max_context_switch_time>
    8000333e:	00a7f663          	bgeu	a5,a0,8000334a <kerneltrap+0x92>
        max_context_switch_time = context_time;
    80003342:	0000c797          	auipc	a5,0xc
    80003346:	52a7b323          	sd	a0,1318(a5) # 8000f868 <max_context_switch_time>
    if (context_time < min_context_switch_time)
    8000334a:	0000c797          	auipc	a5,0xc
    8000334e:	4c67b783          	ld	a5,1222(a5) # 8000f810 <min_context_switch_time>
    80003352:	00f57663          	bgeu	a0,a5,8000335e <kerneltrap+0xa6>
        min_context_switch_time = context_time;
    80003356:	0000c797          	auipc	a5,0xc
    8000335a:	4aa7bd23          	sd	a0,1210(a5) # 8000f810 <min_context_switch_time>

    // 检查当前进程是否需要让出 CPU（时间片用完）
    // 在 trap 返回前检查，这样可以安全地触发调度
    struct proc *p = myproc();
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	79c080e7          	jalr	1948(ra) # 80003afa <myproc>
    80003366:	84aa                	mv	s1,a0
    if (p)
    80003368:	c10d                	beqz	a0,8000338a <kerneltrap+0xd2>
    {
        acquire(&p->lock);
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	3ec080e7          	jalr	1004(ra) # 80003756 <acquire>
        // 如果进程状态是 RUNNABLE 且时间片用完，需要让出 CPU
        if (p->state == RUNNABLE && p->time_slice == 0)
    80003372:	4c98                	lw	a4,24(s1)
    80003374:	478d                	li	a5,3
    80003376:	00f71563          	bne	a4,a5,80003380 <kerneltrap+0xc8>
    8000337a:	0c44a783          	lw	a5,196(s1)
    8000337e:	cb99                	beqz	a5,80003394 <kerneltrap+0xdc>
            release(&p->lock);
            yield(); // 这会触发调度，不会返回
        }
        else
        {
            release(&p->lock);
    80003380:	8526                	mv	a0,s1
    80003382:	00000097          	auipc	ra,0x0
    80003386:	444080e7          	jalr	1092(ra) # 800037c6 <release>
        }
    }
}
    8000338a:	60e2                	ld	ra,24(sp)
    8000338c:	6442                	ld	s0,16(sp)
    8000338e:	64a2                	ld	s1,8(sp)
    80003390:	6105                	addi	sp,sp,32
    80003392:	8082                	ret
            release(&p->lock);
    80003394:	8526                	mv	a0,s1
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	430080e7          	jalr	1072(ra) # 800037c6 <release>
            yield(); // 这会触发调度，不会返回
    8000339e:	00001097          	auipc	ra,0x1
    800033a2:	b6c080e7          	jalr	-1172(ra) # 80003f0a <yield>
    800033a6:	b7d5                	j	8000338a <kerneltrap+0xd2>

00000000800033a8 <sbi_set_timer>:

static inline uint64 read64(volatile uint64 *addr) {
    return *(addr);//读取64位值从指定地址
}

void sbi_set_timer(uint64 time) {
    800033a8:	1141                	addi	sp,sp,-16
    800033aa:	e422                	sd	s0,8(sp)
    800033ac:	0800                	addi	s0,sp,16
    *(addr) = val;//写入64位值到指定地址
    800033ae:	020047b7          	lui	a5,0x2004
    800033b2:	e388                	sd	a0,0(a5)
    volatile uint64 *mtimecmp = (volatile uint64*)CLINT_MTIMECMP(0);
    write64(mtimecmp, time);//写入时间戳到MTIMECMP寄存器
}//当MTIME >= MTIMECMP时，会触发定时器中断
    800033b4:	6422                	ld	s0,8(sp)
    800033b6:	0141                	addi	sp,sp,16
    800033b8:	8082                	ret

00000000800033ba <get_time>:
//获取当前时间戳的函数
uint64 get_time(void) {
    800033ba:	1141                	addi	sp,sp,-16
    800033bc:	e422                	sd	s0,8(sp)
    800033be:	0800                	addi	s0,sp,16
    return *(addr);//读取64位值从指定地址
    800033c0:	0200c7b7          	lui	a5,0x200c
    800033c4:	ff87b503          	ld	a0,-8(a5) # 200bff8 <_entry-0x7dff4008>
    volatile uint64 *mtime = (volatile uint64*)CLINT_MTIME;
    return read64(mtime);
}
    800033c8:	6422                	ld	s0,8(sp)
    800033ca:	0141                	addi	sp,sp,16
    800033cc:	8082                	ret

00000000800033ce <program_next_timer>:
    min_interrupt_time = ~0UL;
}


//核心功能函数
static void program_next_timer(void) {
    800033ce:	1141                	addi	sp,sp,-16
    800033d0:	e406                	sd	ra,8(sp)
    800033d2:	e022                	sd	s0,0(sp)
    800033d4:	0800                	addi	s0,sp,16
    uint64 now = get_time();
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	fe4080e7          	jalr	-28(ra) # 800033ba <get_time>
    sbi_set_timer(now + timer_interval);//通过SBI调用设置机器模式定时器
    800033de:	0000c797          	auipc	a5,0xc
    800033e2:	4427b783          	ld	a5,1090(a5) # 8000f820 <timer_interval>
    800033e6:	953e                	add	a0,a0,a5
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	fc0080e7          	jalr	-64(ra) # 800033a8 <sbi_set_timer>
}
    800033f0:	60a2                	ld	ra,8(sp)
    800033f2:	6402                	ld	s0,0(sp)
    800033f4:	0141                	addi	sp,sp,16
    800033f6:	8082                	ret

00000000800033f8 <timer_interrupt>:

void timer_interrupt(void) {
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	e426                	sd	s1,8(sp)
    80003400:	e04a                	sd	s2,0(sp)
    80003402:	1000                	addi	s0,sp,32
    // 记录中断进入时间（在trap entry中已记录，这里只统计处理时间）
    uint64 start = get_time();
    80003404:	00000097          	auipc	ra,0x0
    80003408:	fb6080e7          	jalr	-74(ra) # 800033ba <get_time>
    8000340c:	892a                	mv	s2,a0
    
    // 1. 更新系统时间（这里简单计数）
    timer_ticks++;
    8000340e:	0000c797          	auipc	a5,0xc
    80003412:	48a7a783          	lw	a5,1162(a5) # 8000f898 <timer_ticks>
    80003416:	2785                	addiw	a5,a5,1
    80003418:	0000c717          	auipc	a4,0xc
    8000341c:	48f72023          	sw	a5,1152(a4) # 8000f898 <timer_ticks>
    // 2. 处理定时器事件（占位）
    // 3. 触发任务调度（占位）
    // 4. 设置下次中断时间
    program_next_timer();
    80003420:	00000097          	auipc	ra,0x0
    80003424:	fae080e7          	jalr	-82(ra) # 800033ce <program_next_timer>

    // MLFQ: 处理当前运行进程的时间片
    struct proc *p = myproc();
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	6d2080e7          	jalr	1746(ra) # 80003afa <myproc>
    if (p && p->state == RUNNING) {
    80003430:	c511                	beqz	a0,8000343c <timer_interrupt+0x44>
    80003432:	84aa                	mv	s1,a0
    80003434:	4d18                	lw	a4,24(a0)
    80003436:	4791                	li	a5,4
    80003438:	06f70063          	beq	a4,a5,80003498 <timer_interrupt+0xa0>
        
        release(&p->lock);
    }
    
    // 统计处理时间（不包括上下文保存/恢复）---性能度量的一些处理
    uint64 end = get_time();
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	f7e080e7          	jalr	-130(ra) # 800033ba <get_time>
    uint64 duration = end - start;
    80003444:	41250533          	sub	a0,a0,s2
    total_interrupt_time += duration;
    80003448:	0000c717          	auipc	a4,0xc
    8000344c:	44870713          	addi	a4,a4,1096 # 8000f890 <total_interrupt_time>
    80003450:	631c                	ld	a5,0(a4)
    80003452:	97aa                	add	a5,a5,a0
    80003454:	e31c                	sd	a5,0(a4)
    interrupt_count++;
    80003456:	0000c717          	auipc	a4,0xc
    8000345a:	43270713          	addi	a4,a4,1074 # 8000f888 <interrupt_count>
    8000345e:	631c                	ld	a5,0(a4)
    80003460:	0785                	addi	a5,a5,1
    80003462:	e31c                	sd	a5,0(a4)
    if (duration > max_interrupt_time) max_interrupt_time = duration;
    80003464:	0000c797          	auipc	a5,0xc
    80003468:	41c7b783          	ld	a5,1052(a5) # 8000f880 <max_interrupt_time>
    8000346c:	00a7f663          	bgeu	a5,a0,80003478 <timer_interrupt+0x80>
    80003470:	0000c797          	auipc	a5,0xc
    80003474:	40a7b823          	sd	a0,1040(a5) # 8000f880 <max_interrupt_time>
    if (duration < min_interrupt_time) min_interrupt_time = duration;
    80003478:	0000c797          	auipc	a5,0xc
    8000347c:	3a07b783          	ld	a5,928(a5) # 8000f818 <min_interrupt_time>
    80003480:	00f57663          	bgeu	a0,a5,8000348c <timer_interrupt+0x94>
    80003484:	0000c797          	auipc	a5,0xc
    80003488:	38a7ba23          	sd	a0,916(a5) # 8000f818 <min_interrupt_time>
}
    8000348c:	60e2                	ld	ra,24(sp)
    8000348e:	6442                	ld	s0,16(sp)
    80003490:	64a2                	ld	s1,8(sp)
    80003492:	6902                	ld	s2,0(sp)
    80003494:	6105                	addi	sp,sp,32
    80003496:	8082                	ret
        acquire(&p->lock);
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	2be080e7          	jalr	702(ra) # 80003756 <acquire>
        if (p->time_slice > 0) {
    800034a0:	0c44a783          	lw	a5,196(s1)
    800034a4:	00f05d63          	blez	a5,800034be <timer_interrupt+0xc6>
            p->time_slice--;
    800034a8:	37fd                	addiw	a5,a5,-1
    800034aa:	0007871b          	sext.w	a4,a5
    800034ae:	0cf4a223          	sw	a5,196(s1)
            p->ticks++;
    800034b2:	0bc4a783          	lw	a5,188(s1)
    800034b6:	2785                	addiw	a5,a5,1
    800034b8:	0af4ae23          	sw	a5,188(s1)
            if (p->time_slice == 0) {
    800034bc:	c719                	beqz	a4,800034ca <timer_interrupt+0xd2>
        release(&p->lock);
    800034be:	8526                	mv	a0,s1
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	306080e7          	jalr	774(ra) # 800037c6 <release>
    800034c8:	bf95                	j	8000343c <timer_interrupt+0x44>
                p->time_slice_used++;
    800034ca:	0c84a783          	lw	a5,200(s1)
    800034ce:	2785                	addiw	a5,a5,1
    800034d0:	0cf4a423          	sw	a5,200(s1)
                p->consecutive_slices++;
    800034d4:	0cc4a603          	lw	a2,204(s1)
    800034d8:	2605                	addiw	a2,a2,1
    800034da:	0cc4a623          	sw	a2,204(s1)
                printf("[MLFQ] PID %d time slice exhausted (consecutive_slices: %d/%d)\n", 
    800034de:	468d                	li	a3,3
    800034e0:	2601                	sext.w	a2,a2
    800034e2:	4ccc                	lw	a1,28(s1)
    800034e4:	00009517          	auipc	a0,0x9
    800034e8:	e3450513          	addi	a0,a0,-460 # 8000c318 <digits+0x2168>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	018080e7          	jalr	24(ra) # 80000504 <printf>
                if (p->consecutive_slices >= CPU_INTENSIVE_THRESHOLD) {
    800034f4:	0cc4a703          	lw	a4,204(s1)
    800034f8:	4789                	li	a5,2
    800034fa:	00e7d763          	bge	a5,a4,80003508 <timer_interrupt+0x110>
                    if (p->priority > PRIORITY_MIN) {
    800034fe:	0b84a783          	lw	a5,184(s1)
    80003502:	4705                	li	a4,1
    80003504:	00f74563          	blt	a4,a5,8000350e <timer_interrupt+0x116>
                p->state = RUNNABLE;
    80003508:	478d                	li	a5,3
    8000350a:	cc9c                	sw	a5,24(s1)
    8000350c:	bf4d                	j	800034be <timer_interrupt+0xc6>
                        p->priority--;
    8000350e:	37fd                	addiw	a5,a5,-1
    80003510:	0af4ac23          	sw	a5,184(s1)
                        p->consecutive_slices = 0;
    80003514:	0c04a623          	sw	zero,204(s1)
                        p->wait_time = 0;
    80003518:	0c04a023          	sw	zero,192(s1)
                        printf("[MLFQ] PID %d demoted to priority %d (CPU-intensive, wait_time reset)\n", 
    8000351c:	0007861b          	sext.w	a2,a5
    80003520:	4ccc                	lw	a1,28(s1)
    80003522:	00009517          	auipc	a0,0x9
    80003526:	e3650513          	addi	a0,a0,-458 # 8000c358 <digits+0x21a8>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	fda080e7          	jalr	-38(ra) # 80000504 <printf>
    80003532:	bfd9                	j	80003508 <timer_interrupt+0x110>

0000000080003534 <timer_get_ticks>:
int timer_get_ticks(void) { return timer_ticks; }
    80003534:	1141                	addi	sp,sp,-16
    80003536:	e422                	sd	s0,8(sp)
    80003538:	0800                	addi	s0,sp,16
    8000353a:	0000c517          	auipc	a0,0xc
    8000353e:	35e52503          	lw	a0,862(a0) # 8000f898 <timer_ticks>
    80003542:	6422                	ld	s0,8(sp)
    80003544:	0141                	addi	sp,sp,16
    80003546:	8082                	ret

0000000080003548 <timer_get_interrupt_count>:
uint64 timer_get_interrupt_count(void) { return interrupt_count; }
    80003548:	1141                	addi	sp,sp,-16
    8000354a:	e422                	sd	s0,8(sp)
    8000354c:	0800                	addi	s0,sp,16
    8000354e:	0000c517          	auipc	a0,0xc
    80003552:	33a53503          	ld	a0,826(a0) # 8000f888 <interrupt_count>
    80003556:	6422                	ld	s0,8(sp)
    80003558:	0141                	addi	sp,sp,16
    8000355a:	8082                	ret

000000008000355c <timer_get_total_interrupt_time>:
uint64 timer_get_total_interrupt_time(void) { return total_interrupt_time; }
    8000355c:	1141                	addi	sp,sp,-16
    8000355e:	e422                	sd	s0,8(sp)
    80003560:	0800                	addi	s0,sp,16
    80003562:	0000c517          	auipc	a0,0xc
    80003566:	32e53503          	ld	a0,814(a0) # 8000f890 <total_interrupt_time>
    8000356a:	6422                	ld	s0,8(sp)
    8000356c:	0141                	addi	sp,sp,16
    8000356e:	8082                	ret

0000000080003570 <timer_get_max_interrupt_time>:
uint64 timer_get_max_interrupt_time(void) { return max_interrupt_time; }
    80003570:	1141                	addi	sp,sp,-16
    80003572:	e422                	sd	s0,8(sp)
    80003574:	0800                	addi	s0,sp,16
    80003576:	0000c517          	auipc	a0,0xc
    8000357a:	30a53503          	ld	a0,778(a0) # 8000f880 <max_interrupt_time>
    8000357e:	6422                	ld	s0,8(sp)
    80003580:	0141                	addi	sp,sp,16
    80003582:	8082                	ret

0000000080003584 <timer_get_min_interrupt_time>:
uint64 timer_get_min_interrupt_time(void) { return min_interrupt_time == ~0UL ? 0 : min_interrupt_time; }
    80003584:	1141                	addi	sp,sp,-16
    80003586:	e422                	sd	s0,8(sp)
    80003588:	0800                	addi	s0,sp,16
    8000358a:	0000c717          	auipc	a4,0xc
    8000358e:	28e73703          	ld	a4,654(a4) # 8000f818 <min_interrupt_time>
    80003592:	57fd                	li	a5,-1
    80003594:	4501                	li	a0,0
    80003596:	00f70663          	beq	a4,a5,800035a2 <timer_get_min_interrupt_time+0x1e>
    8000359a:	0000c517          	auipc	a0,0xc
    8000359e:	27e53503          	ld	a0,638(a0) # 8000f818 <min_interrupt_time>
    800035a2:	6422                	ld	s0,8(sp)
    800035a4:	0141                	addi	sp,sp,16
    800035a6:	8082                	ret

00000000800035a8 <timer_reset_stats>:
void timer_reset_stats(void) {
    800035a8:	1141                	addi	sp,sp,-16
    800035aa:	e422                	sd	s0,8(sp)
    800035ac:	0800                	addi	s0,sp,16
    total_interrupt_time = 0;
    800035ae:	0000c797          	auipc	a5,0xc
    800035b2:	2e07b123          	sd	zero,738(a5) # 8000f890 <total_interrupt_time>
    interrupt_count = 0;
    800035b6:	0000c797          	auipc	a5,0xc
    800035ba:	2c07b923          	sd	zero,722(a5) # 8000f888 <interrupt_count>
    max_interrupt_time = 0;
    800035be:	0000c797          	auipc	a5,0xc
    800035c2:	2c07b123          	sd	zero,706(a5) # 8000f880 <max_interrupt_time>
    min_interrupt_time = ~0UL;
    800035c6:	57fd                	li	a5,-1
    800035c8:	0000c717          	auipc	a4,0xc
    800035cc:	24f73823          	sd	a5,592(a4) # 8000f818 <min_interrupt_time>
}
    800035d0:	6422                	ld	s0,8(sp)
    800035d2:	0141                	addi	sp,sp,16
    800035d4:	8082                	ret

00000000800035d6 <timer_set_interval>:

void timer_set_interval(uint64 interval) {
    800035d6:	1141                	addi	sp,sp,-16
    800035d8:	e422                	sd	s0,8(sp)
    800035da:	0800                	addi	s0,sp,16
    timer_interval = interval;
    800035dc:	0000c797          	auipc	a5,0xc
    800035e0:	24a7b223          	sd	a0,580(a5) # 8000f820 <timer_interval>
}
    800035e4:	6422                	ld	s0,8(sp)
    800035e6:	0141                	addi	sp,sp,16
    800035e8:	8082                	ret

00000000800035ea <timer_get_interval>:

uint64 timer_get_interval(void) {
    800035ea:	1141                	addi	sp,sp,-16
    800035ec:	e422                	sd	s0,8(sp)
    800035ee:	0800                	addi	s0,sp,16
    return timer_interval;
}
    800035f0:	0000c517          	auipc	a0,0xc
    800035f4:	23053503          	ld	a0,560(a0) # 8000f820 <timer_interval>
    800035f8:	6422                	ld	s0,8(sp)
    800035fa:	0141                	addi	sp,sp,16
    800035fc:	8082                	ret

00000000800035fe <timer_init>:

void timer_init(void) {
    800035fe:	1141                	addi	sp,sp,-16
    80003600:	e406                	sd	ra,8(sp)
    80003602:	e022                	sd	s0,0(sp)
    80003604:	0800                	addi	s0,sp,16
    register_interrupt(IRQ_M_TIMER, timer_interrupt);
    80003606:	00000597          	auipc	a1,0x0
    8000360a:	df258593          	addi	a1,a1,-526 # 800033f8 <timer_interrupt>
    8000360e:	451d                	li	a0,7
    80003610:	fffff097          	auipc	ra,0xfffff
    80003614:	68c080e7          	jalr	1676(ra) # 80002c9c <register_interrupt>
    enable_interrupt(IRQ_M_TIMER);
    80003618:	451d                	li	a0,7
    8000361a:	fffff097          	auipc	ra,0xfffff
    8000361e:	6de080e7          	jalr	1758(ra) # 80002cf8 <enable_interrupt>
    program_next_timer();
    80003622:	00000097          	auipc	ra,0x0
    80003626:	dac080e7          	jalr	-596(ra) # 800033ce <program_next_timer>
}
    8000362a:	60a2                	ld	ra,8(sp)
    8000362c:	6402                	ld	s0,0(sp)
    8000362e:	0141                	addi	sp,sp,16
    80003630:	8082                	ret

0000000080003632 <intr_on>:

static inline uint64 read_mstatus(void) {
    return r_mstatus();
}

void intr_on(void) {
    80003632:	1141                	addi	sp,sp,-16
    80003634:	e422                	sd	s0,8(sp)
    80003636:	0800                	addi	s0,sp,16
    asm volatile("csrr %0, mstatus" : "=r"(x));
    80003638:	300027f3          	csrr	a5,mstatus
    uint64 mstatus = read_mstatus();
    mstatus |= MSTATUS_MIE;
    8000363c:	0087e793          	ori	a5,a5,8
    asm volatile("csrw mstatus, %0" : : "r"(x));
    80003640:	30079073          	csrw	mstatus,a5
    w_mstatus(mstatus);
}
    80003644:	6422                	ld	s0,8(sp)
    80003646:	0141                	addi	sp,sp,16
    80003648:	8082                	ret

000000008000364a <intr_off>:

void intr_off(void) {
    8000364a:	1141                	addi	sp,sp,-16
    8000364c:	e422                	sd	s0,8(sp)
    8000364e:	0800                	addi	s0,sp,16
    asm volatile("csrr %0, mstatus" : "=r"(x));
    80003650:	300027f3          	csrr	a5,mstatus
    uint64 mstatus = read_mstatus();
    mstatus &= ~MSTATUS_MIE;
    80003654:	9bdd                	andi	a5,a5,-9
    asm volatile("csrw mstatus, %0" : : "r"(x));
    80003656:	30079073          	csrw	mstatus,a5
    w_mstatus(mstatus);
}
    8000365a:	6422                	ld	s0,8(sp)
    8000365c:	0141                	addi	sp,sp,16
    8000365e:	8082                	ret

0000000080003660 <intr_get>:

int intr_get(void) {
    80003660:	1141                	addi	sp,sp,-16
    80003662:	e422                	sd	s0,8(sp)
    80003664:	0800                	addi	s0,sp,16
    asm volatile("csrr %0, mstatus" : "=r"(x));
    80003666:	30002573          	csrr	a0,mstatus
    return (read_mstatus() & MSTATUS_MIE) != 0;
    8000366a:	810d                	srli	a0,a0,0x3
}
    8000366c:	8905                	andi	a0,a0,1
    8000366e:	6422                	ld	s0,8(sp)
    80003670:	0141                	addi	sp,sp,16
    80003672:	8082                	ret

0000000080003674 <initlock>:

void initlock(struct spinlock *lk, const char *name) {
    80003674:	1141                	addi	sp,sp,-16
    80003676:	e422                	sd	s0,8(sp)
    80003678:	0800                	addi	s0,sp,16
    lk->locked = 0;
    8000367a:	00052023          	sw	zero,0(a0)
    lk->name = name;
    8000367e:	e50c                	sd	a1,8(a0)
    lk->cpu = 0;
    80003680:	00053823          	sd	zero,16(a0)
}
    80003684:	6422                	ld	s0,8(sp)
    80003686:	0141                	addi	sp,sp,16
    80003688:	8082                	ret

000000008000368a <push_off>:
                 : "r"(newval)
                 : "memory");
    return result;
}

void push_off(void) {
    8000368a:	1101                	addi	sp,sp,-32
    8000368c:	ec06                	sd	ra,24(sp)
    8000368e:	e822                	sd	s0,16(sp)
    80003690:	e426                	sd	s1,8(sp)
    80003692:	1000                	addi	s0,sp,32
    int old = intr_get();
    80003694:	00000097          	auipc	ra,0x0
    80003698:	fcc080e7          	jalr	-52(ra) # 80003660 <intr_get>
    8000369c:	84aa                	mv	s1,a0
    intr_off();
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	fac080e7          	jalr	-84(ra) # 8000364a <intr_off>
    struct cpu *c = mycpu();
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	440080e7          	jalr	1088(ra) # 80003ae6 <mycpu>
    if (c->noff == 0) {
    800036ae:	5d3c                	lw	a5,120(a0)
    800036b0:	e391                	bnez	a5,800036b4 <push_off+0x2a>
        c->intena = old;
    800036b2:	dd64                	sw	s1,124(a0)
    }
    c->noff += 1;
    800036b4:	2785                	addiw	a5,a5,1
    800036b6:	dd3c                	sw	a5,120(a0)
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6105                	addi	sp,sp,32
    800036c0:	8082                	ret

00000000800036c2 <pop_off>:

void pop_off(void) {
    800036c2:	1101                	addi	sp,sp,-32
    800036c4:	ec06                	sd	ra,24(sp)
    800036c6:	e822                	sd	s0,16(sp)
    800036c8:	e426                	sd	s1,8(sp)
    800036ca:	1000                	addi	s0,sp,32
    struct cpu *c = mycpu();
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	41a080e7          	jalr	1050(ra) # 80003ae6 <mycpu>
    800036d4:	84aa                	mv	s1,a0
    if (intr_get()) {
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	f8a080e7          	jalr	-118(ra) # 80003660 <intr_get>
    800036de:	e105                	bnez	a0,800036fe <pop_off+0x3c>
        panic("pop_off - interruptible");
    }
    if (c->noff < 1) {
    800036e0:	5cbc                	lw	a5,120(s1)
    800036e2:	02f05663          	blez	a5,8000370e <pop_off+0x4c>
        panic("pop_off");
    }
    c->noff -= 1;
    800036e6:	37fd                	addiw	a5,a5,-1
    800036e8:	0007871b          	sext.w	a4,a5
    800036ec:	dcbc                	sw	a5,120(s1)
    if (c->noff == 0 && c->intena) {
    800036ee:	e319                	bnez	a4,800036f4 <pop_off+0x32>
    800036f0:	5cfc                	lw	a5,124(s1)
    800036f2:	e795                	bnez	a5,8000371e <pop_off+0x5c>
        intr_on();
    }
}
    800036f4:	60e2                	ld	ra,24(sp)
    800036f6:	6442                	ld	s0,16(sp)
    800036f8:	64a2                	ld	s1,8(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret
        panic("pop_off - interruptible");
    800036fe:	00009517          	auipc	a0,0x9
    80003702:	ca250513          	addi	a0,a0,-862 # 8000c3a0 <digits+0x21f0>
    80003706:	fffff097          	auipc	ra,0xfffff
    8000370a:	386080e7          	jalr	902(ra) # 80002a8c <panic>
        panic("pop_off");
    8000370e:	00009517          	auipc	a0,0x9
    80003712:	caa50513          	addi	a0,a0,-854 # 8000c3b8 <digits+0x2208>
    80003716:	fffff097          	auipc	ra,0xfffff
    8000371a:	376080e7          	jalr	886(ra) # 80002a8c <panic>
        intr_on();
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	f14080e7          	jalr	-236(ra) # 80003632 <intr_on>
}
    80003726:	b7f9                	j	800036f4 <pop_off+0x32>

0000000080003728 <holding>:
    lk->locked = 0;
    pop_off();
}

int holding(struct spinlock *lk) {
    return lk->locked && lk->cpu == mycpu();
    80003728:	411c                	lw	a5,0(a0)
    8000372a:	e399                	bnez	a5,80003730 <holding+0x8>
    8000372c:	4501                	li	a0,0
}
    8000372e:	8082                	ret
int holding(struct spinlock *lk) {
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	e426                	sd	s1,8(sp)
    80003738:	1000                	addi	s0,sp,32
    return lk->locked && lk->cpu == mycpu();
    8000373a:	6904                	ld	s1,16(a0)
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	3aa080e7          	jalr	938(ra) # 80003ae6 <mycpu>
    80003744:	40a48533          	sub	a0,s1,a0
    80003748:	00153513          	seqz	a0,a0
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret

0000000080003756 <acquire>:
void acquire(struct spinlock *lk) {
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	1000                	addi	s0,sp,32
    80003760:	84aa                	mv	s1,a0
    push_off();
    80003762:	00000097          	auipc	ra,0x0
    80003766:	f28080e7          	jalr	-216(ra) # 8000368a <push_off>
    if (holding(lk)) {
    8000376a:	8526                	mv	a0,s1
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	fbc080e7          	jalr	-68(ra) # 80003728 <holding>
    asm volatile("amoswap.w %0, %2, %1"
    80003774:	4705                	li	a4,1
    if (holding(lk)) {
    80003776:	e10d                	bnez	a0,80003798 <acquire+0x42>
    asm volatile("amoswap.w %0, %2, %1"
    80003778:	08e4a7af          	amoswap.w	a5,a4,(s1)
    8000377c:	2781                	sext.w	a5,a5
    while (xchg(&lk->locked, 1) != 0)
    8000377e:	ffed                	bnez	a5,80003778 <acquire+0x22>
    __sync_synchronize();
    80003780:	0ff0000f          	fence
    lk->cpu = mycpu();
    80003784:	00000097          	auipc	ra,0x0
    80003788:	362080e7          	jalr	866(ra) # 80003ae6 <mycpu>
    8000378c:	e888                	sd	a0,16(s1)
}
    8000378e:	60e2                	ld	ra,24(sp)
    80003790:	6442                	ld	s0,16(sp)
    80003792:	64a2                	ld	s1,8(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret
        printf("lock already held: %s\n", lk->name ? lk->name : "unknown");
    80003798:	648c                	ld	a1,8(s1)
    8000379a:	c18d                	beqz	a1,800037bc <acquire+0x66>
    8000379c:	00009517          	auipc	a0,0x9
    800037a0:	c2c50513          	addi	a0,a0,-980 # 8000c3c8 <digits+0x2218>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	d60080e7          	jalr	-672(ra) # 80000504 <printf>
        panic("acquire");
    800037ac:	00009517          	auipc	a0,0x9
    800037b0:	c3450513          	addi	a0,a0,-972 # 8000c3e0 <digits+0x2230>
    800037b4:	fffff097          	auipc	ra,0xfffff
    800037b8:	2d8080e7          	jalr	728(ra) # 80002a8c <panic>
        printf("lock already held: %s\n", lk->name ? lk->name : "unknown");
    800037bc:	00009597          	auipc	a1,0x9
    800037c0:	c0458593          	addi	a1,a1,-1020 # 8000c3c0 <digits+0x2210>
    800037c4:	bfe1                	j	8000379c <acquire+0x46>

00000000800037c6 <release>:
void release(struct spinlock *lk) {
    800037c6:	1101                	addi	sp,sp,-32
    800037c8:	ec06                	sd	ra,24(sp)
    800037ca:	e822                	sd	s0,16(sp)
    800037cc:	e426                	sd	s1,8(sp)
    800037ce:	1000                	addi	s0,sp,32
    800037d0:	84aa                	mv	s1,a0
    if (!holding(lk)) {
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	f56080e7          	jalr	-170(ra) # 80003728 <holding>
    800037da:	c105                	beqz	a0,800037fa <release+0x34>
    __sync_synchronize();
    800037dc:	0ff0000f          	fence
    lk->cpu = 0;
    800037e0:	0004b823          	sd	zero,16(s1)
    lk->locked = 0;
    800037e4:	0004a023          	sw	zero,0(s1)
    pop_off();
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	eda080e7          	jalr	-294(ra) # 800036c2 <pop_off>
}
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret
        panic("release");
    800037fa:	00009517          	auipc	a0,0x9
    800037fe:	bee50513          	addi	a0,a0,-1042 # 8000c3e8 <digits+0x2238>
    80003802:	fffff097          	auipc	ra,0xfffff
    80003806:	28a080e7          	jalr	650(ra) # 80002a8c <panic>

000000008000380a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000380a:	1101                	addi	sp,sp,-32
    8000380c:	ec06                	sd	ra,24(sp)
    8000380e:	e822                	sd	s0,16(sp)
    80003810:	e426                	sd	s1,8(sp)
    80003812:	e04a                	sd	s2,0(sp)
    80003814:	1000                	addi	s0,sp,32
    80003816:	84aa                	mv	s1,a0
    80003818:	892e                	mv	s2,a1
    initlock(&lk->lk, "sleep lock");
    8000381a:	00009597          	auipc	a1,0x9
    8000381e:	bd658593          	addi	a1,a1,-1066 # 8000c3f0 <digits+0x2240>
    80003822:	0521                	addi	a0,a0,8
    80003824:	00000097          	auipc	ra,0x0
    80003828:	e50080e7          	jalr	-432(ra) # 80003674 <initlock>
    lk->locked = 0;
    8000382c:	0004a023          	sw	zero,0(s1)
    lk->name = name;
    80003830:	0324b023          	sd	s2,32(s1)
    lk->pid = 0;
    80003834:	0204a423          	sw	zero,40(s1)
}
    80003838:	60e2                	ld	ra,24(sp)
    8000383a:	6442                	ld	s0,16(sp)
    8000383c:	64a2                	ld	s1,8(sp)
    8000383e:	6902                	ld	s2,0(sp)
    80003840:	6105                	addi	sp,sp,32
    80003842:	8082                	ret

0000000080003844 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003844:	1101                	addi	sp,sp,-32
    80003846:	ec06                	sd	ra,24(sp)
    80003848:	e822                	sd	s0,16(sp)
    8000384a:	e426                	sd	s1,8(sp)
    8000384c:	e04a                	sd	s2,0(sp)
    8000384e:	1000                	addi	s0,sp,32
    80003850:	892a                	mv	s2,a0
    acquire(&lk->lk);
    80003852:	00850493          	addi	s1,a0,8
    80003856:	8526                	mv	a0,s1
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	efe080e7          	jalr	-258(ra) # 80003756 <acquire>
    while (lk->locked) {
    80003860:	00092783          	lw	a5,0(s2)
    80003864:	cf91                	beqz	a5,80003880 <acquiresleep+0x3c>
        // 简化：自旋等待（实际应该使用sleep/wakeup）
        release(&lk->lk);
    80003866:	8526                	mv	a0,s1
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	f5e080e7          	jalr	-162(ra) # 800037c6 <release>
        acquire(&lk->lk);
    80003870:	8526                	mv	a0,s1
    80003872:	00000097          	auipc	ra,0x0
    80003876:	ee4080e7          	jalr	-284(ra) # 80003756 <acquire>
    while (lk->locked) {
    8000387a:	00092783          	lw	a5,0(s2)
    8000387e:	f7e5                	bnez	a5,80003866 <acquiresleep+0x22>
    }
    lk->locked = 1;
    80003880:	4785                	li	a5,1
    80003882:	00f92023          	sw	a5,0(s2)
    lk->pid = myproc() ? myproc()->pid : 0;
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	274080e7          	jalr	628(ra) # 80003afa <myproc>
    8000388e:	4781                	li	a5,0
    80003890:	c511                	beqz	a0,8000389c <acquiresleep+0x58>
    80003892:	00000097          	auipc	ra,0x0
    80003896:	268080e7          	jalr	616(ra) # 80003afa <myproc>
    8000389a:	4d5c                	lw	a5,28(a0)
    8000389c:	02f92423          	sw	a5,40(s2)
    release(&lk->lk);
    800038a0:	8526                	mv	a0,s1
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	f24080e7          	jalr	-220(ra) # 800037c6 <release>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6902                	ld	s2,0(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret

00000000800038b6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
    800038c2:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    800038c4:	00850913          	addi	s2,a0,8
    800038c8:	854a                	mv	a0,s2
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	e8c080e7          	jalr	-372(ra) # 80003756 <acquire>
    lk->locked = 0;
    800038d2:	0004a023          	sw	zero,0(s1)
    lk->pid = 0;
    800038d6:	0204a423          	sw	zero,40(s1)
    release(&lk->lk);
    800038da:	854a                	mv	a0,s2
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	eea080e7          	jalr	-278(ra) # 800037c6 <release>
}
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6902                	ld	s2,0(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret

00000000800038f0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800038f0:	1101                	addi	sp,sp,-32
    800038f2:	ec06                	sd	ra,24(sp)
    800038f4:	e822                	sd	s0,16(sp)
    800038f6:	e426                	sd	s1,8(sp)
    800038f8:	e04a                	sd	s2,0(sp)
    800038fa:	1000                	addi	s0,sp,32
    800038fc:	84aa                	mv	s1,a0
    int r;
    acquire(&lk->lk);
    800038fe:	00850913          	addi	s2,a0,8
    80003902:	854a                	mv	a0,s2
    80003904:	00000097          	auipc	ra,0x0
    80003908:	e52080e7          	jalr	-430(ra) # 80003756 <acquire>
    r = lk->locked && (lk->pid == (myproc() ? myproc()->pid : 0));
    8000390c:	409c                	lw	a5,0(s1)
    8000390e:	ef91                	bnez	a5,8000392a <holdingsleep+0x3a>
    80003910:	4481                	li	s1,0
    release(&lk->lk);
    80003912:	854a                	mv	a0,s2
    80003914:	00000097          	auipc	ra,0x0
    80003918:	eb2080e7          	jalr	-334(ra) # 800037c6 <release>
    return r;
}
    8000391c:	8526                	mv	a0,s1
    8000391e:	60e2                	ld	ra,24(sp)
    80003920:	6442                	ld	s0,16(sp)
    80003922:	64a2                	ld	s1,8(sp)
    80003924:	6902                	ld	s2,0(sp)
    80003926:	6105                	addi	sp,sp,32
    80003928:	8082                	ret
    r = lk->locked && (lk->pid == (myproc() ? myproc()->pid : 0));
    8000392a:	5484                	lw	s1,40(s1)
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	1ce080e7          	jalr	462(ra) # 80003afa <myproc>
    80003934:	4781                	li	a5,0
    80003936:	c511                	beqz	a0,80003942 <holdingsleep+0x52>
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	1c2080e7          	jalr	450(ra) # 80003afa <myproc>
    80003940:	4d5c                	lw	a5,28(a0)
    80003942:	8c9d                	sub	s1,s1,a5
    80003944:	0014b493          	seqz	s1,s1
    80003948:	b7e9                	j	80003912 <holdingsleep+0x22>
	...

000000008000394c <swtch>:
    .section .text
    .globl swtch
    .align 2
swtch:
    sd ra, 0(a0)
    8000394c:	00153023          	sd	ra,0(a0)
    sd sp, 8(a0)
    80003950:	00253423          	sd	sp,8(a0)
    sd s0, 16(a0)
    80003954:	e900                	sd	s0,16(a0)
    sd s1, 24(a0)
    80003956:	ed04                	sd	s1,24(a0)
    sd s2, 32(a0)
    80003958:	03253023          	sd	s2,32(a0)
    sd s3, 40(a0)
    8000395c:	03353423          	sd	s3,40(a0)
    sd s4, 48(a0)
    80003960:	03453823          	sd	s4,48(a0)
    sd s5, 56(a0)
    80003964:	03553c23          	sd	s5,56(a0)
    sd s6, 64(a0)
    80003968:	05653023          	sd	s6,64(a0)
    sd s7, 72(a0)
    8000396c:	05753423          	sd	s7,72(a0)
    sd s8, 80(a0)
    80003970:	05853823          	sd	s8,80(a0)
    sd s9, 88(a0)
    80003974:	05953c23          	sd	s9,88(a0)
    sd s10, 96(a0)
    80003978:	07a53023          	sd	s10,96(a0)
    sd s11, 104(a0)
    8000397c:	07b53423          	sd	s11,104(a0)

    ld ra, 0(a1)
    80003980:	0005b083          	ld	ra,0(a1)
    ld sp, 8(a1)
    80003984:	0085b103          	ld	sp,8(a1)
    ld s0, 16(a1)
    80003988:	6980                	ld	s0,16(a1)
    ld s1, 24(a1)
    8000398a:	6d84                	ld	s1,24(a1)
    ld s2, 32(a1)
    8000398c:	0205b903          	ld	s2,32(a1)
    ld s3, 40(a1)
    80003990:	0285b983          	ld	s3,40(a1)
    ld s4, 48(a1)
    80003994:	0305ba03          	ld	s4,48(a1)
    ld s5, 56(a1)
    80003998:	0385ba83          	ld	s5,56(a1)
    ld s6, 64(a1)
    8000399c:	0405bb03          	ld	s6,64(a1)
    ld s7, 72(a1)
    800039a0:	0485bb83          	ld	s7,72(a1)
    ld s8, 80(a1)
    800039a4:	0505bc03          	ld	s8,80(a1)
    ld s9, 88(a1)
    800039a8:	0585bc83          	ld	s9,88(a1)
    ld s10, 96(a1)
    800039ac:	0605bd03          	ld	s10,96(a1)
    ld s11, 104(a1)
    800039b0:	0685bd83          	ld	s11,104(a1)
    ret
    800039b4:	8082                	ret

00000000800039b6 <safestrcpy>:
        d[i] = 0;
    }
}
// 安全字符串拷贝函数
static void safestrcpy(char *dst, const char *src, int n)
{
    800039b6:	1141                	addi	sp,sp,-16
    800039b8:	e422                	sd	s0,8(sp)
    800039ba:	0800                	addi	s0,sp,16
    if (n <= 0)
    800039bc:	04c05063          	blez	a2,800039fc <safestrcpy+0x46>
    {
        return;
    }
    int i = 0;
    if (src)
    800039c0:	c1b9                	beqz	a1,80003a06 <safestrcpy+0x50>
    {
        for (; i < n - 1 && src[i]; i++)
    800039c2:	4785                	li	a5,1
    800039c4:	02c7df63          	bge	a5,a2,80003a02 <safestrcpy+0x4c>
    800039c8:	86aa                	mv	a3,a0
    800039ca:	fff6081b          	addiw	a6,a2,-1
    int i = 0;
    800039ce:	4781                	li	a5,0
        for (; i < n - 1 && src[i]; i++)
    800039d0:	0005c703          	lbu	a4,0(a1)
    800039d4:	cb09                	beqz	a4,800039e6 <safestrcpy+0x30>
        {
            dst[i] = src[i];
    800039d6:	00e68023          	sb	a4,0(a3)
        for (; i < n - 1 && src[i]; i++)
    800039da:	2785                	addiw	a5,a5,1
    800039dc:	0585                	addi	a1,a1,1
    800039de:	0685                	addi	a3,a3,1
    800039e0:	ff0798e3          	bne	a5,a6,800039d0 <safestrcpy+0x1a>
    800039e4:	87c2                	mv	a5,a6
        }
    }
    for (; i < n; i++)
    800039e6:	00c7db63          	bge	a5,a2,800039fc <safestrcpy+0x46>
    {
        dst[i] = 0;
    800039ea:	00f50733          	add	a4,a0,a5
    800039ee:	00070023          	sb	zero,0(a4)
    for (; i < n; i++)
    800039f2:	0785                	addi	a5,a5,1
    800039f4:	0007871b          	sext.w	a4,a5
    800039f8:	fec749e3          	blt	a4,a2,800039ea <safestrcpy+0x34>
    }
}
    800039fc:	6422                	ld	s0,8(sp)
    800039fe:	0141                	addi	sp,sp,16
    80003a00:	8082                	ret
        for (; i < n - 1 && src[i]; i++)
    80003a02:	4781                	li	a5,0
    80003a04:	b7dd                	j	800039ea <safestrcpy+0x34>
    80003a06:	4781                	li	a5,0
    80003a08:	b7cd                	j	800039ea <safestrcpy+0x34>

0000000080003a0a <find_proc_by_pid>:
    }
}

// 根据 PID 查找进程
static struct proc *find_proc_by_pid(int pid)
{
    80003a0a:	7179                	addi	sp,sp,-48
    80003a0c:	f406                	sd	ra,40(sp)
    80003a0e:	f022                	sd	s0,32(sp)
    80003a10:	ec26                	sd	s1,24(sp)
    80003a12:	e84a                	sd	s2,16(sp)
    80003a14:	e44e                	sd	s3,8(sp)
    80003a16:	e052                	sd	s4,0(sp)
    80003a18:	1800                	addi	s0,sp,48
    if (pid <= 0)
    80003a1a:	04a05b63          	blez	a0,80003a70 <find_proc_by_pid+0x66>
    80003a1e:	89aa                	mv	s3,a0
    80003a20:	0000c497          	auipc	s1,0xc
    80003a24:	48848493          	addi	s1,s1,1160 # 8000fea8 <proc>
    80003a28:	00010a17          	auipc	s4,0x10
    80003a2c:	c80a0a13          	addi	s4,s4,-896 # 800136a8 <priority_lock>
    80003a30:	a811                	j	80003a44 <find_proc_by_pid+0x3a>
        acquire(&p->lock);
        if (p->pid == pid && p->state != UNUSED)
        {
            return p; // 注意：调用者需要释放锁
        }
        release(&p->lock);
    80003a32:	854a                	mv	a0,s2
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	d92080e7          	jalr	-622(ra) # 800037c6 <release>
    for (int i = 0; i < NPROC; i++)
    80003a3c:	0e048493          	addi	s1,s1,224
    80003a40:	03448663          	beq	s1,s4,80003a6c <find_proc_by_pid+0x62>
        struct proc *p = &proc[i];
    80003a44:	8926                	mv	s2,s1
        acquire(&p->lock);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	d0e080e7          	jalr	-754(ra) # 80003756 <acquire>
        if (p->pid == pid && p->state != UNUSED)
    80003a50:	4cdc                	lw	a5,28(s1)
    80003a52:	ff3790e3          	bne	a5,s3,80003a32 <find_proc_by_pid+0x28>
    80003a56:	4c9c                	lw	a5,24(s1)
    80003a58:	dfe9                	beqz	a5,80003a32 <find_proc_by_pid+0x28>
    }
    return 0;
}
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	70a2                	ld	ra,40(sp)
    80003a5e:	7402                	ld	s0,32(sp)
    80003a60:	64e2                	ld	s1,24(sp)
    80003a62:	6942                	ld	s2,16(sp)
    80003a64:	69a2                	ld	s3,8(sp)
    80003a66:	6a02                	ld	s4,0(sp)
    80003a68:	6145                	addi	sp,sp,48
    80003a6a:	8082                	ret
    return 0;
    80003a6c:	4901                	li	s2,0
    80003a6e:	b7f5                	j	80003a5a <find_proc_by_pid+0x50>
        return 0;
    80003a70:	4901                	li	s2,0
    80003a72:	b7e5                	j	80003a5a <find_proc_by_pid+0x50>

0000000080003a74 <free_proc_locked>:
{
    80003a74:	1101                	addi	sp,sp,-32
    80003a76:	ec06                	sd	ra,24(sp)
    80003a78:	e822                	sd	s0,16(sp)
    80003a7a:	e426                	sd	s1,8(sp)
    80003a7c:	1000                	addi	s0,sp,32
    80003a7e:	84aa                	mv	s1,a0
    if (p->kstack)
    80003a80:	7508                	ld	a0,40(a0)
    80003a82:	c519                	beqz	a0,80003a90 <free_proc_locked+0x1c>
        free_page(p->kstack);
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	56e080e7          	jalr	1390(ra) # 80000ff2 <free_page>
        p->kstack = 0;
    80003a8c:	0204b423          	sd	zero,40(s1)
    p->pid = 0;
    80003a90:	0004ae23          	sw	zero,28(s1)
    p->parent = 0;
    80003a94:	0204b023          	sd	zero,32(s1)
    p->entry = 0;
    80003a98:	0a04b423          	sd	zero,168(s1)
    p->exit_status = 0;
    80003a9c:	0a04a823          	sw	zero,176(s1)
    p->killed = 0;
    80003aa0:	0a04aa23          	sw	zero,180(s1)
    p->chan = 0;
    80003aa4:	0a04b023          	sd	zero,160(s1)
    safestrcpy(p->name, 0, sizeof(p->name));
    80003aa8:	4641                	li	a2,16
    80003aaa:	4581                	li	a1,0
    80003aac:	0d048513          	addi	a0,s1,208
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	f06080e7          	jalr	-250(ra) # 800039b6 <safestrcpy>
    p->state = UNUSED;
    80003ab8:	0004ac23          	sw	zero,24(s1)
    p->priority = PRIORITY_DEFAULT;
    80003abc:	4795                	li	a5,5
    80003abe:	0af4ac23          	sw	a5,184(s1)
    p->ticks = 0;
    80003ac2:	0a04ae23          	sw	zero,188(s1)
    p->wait_time = 0;
    80003ac6:	0c04a023          	sw	zero,192(s1)
    for (int i = 0; i < n; i++)
    80003aca:	03048793          	addi	a5,s1,48
    80003ace:	0a048493          	addi	s1,s1,160
        d[i] = 0;
    80003ad2:	00078023          	sb	zero,0(a5)
    for (int i = 0; i < n; i++)
    80003ad6:	0785                	addi	a5,a5,1
    80003ad8:	fe979de3          	bne	a5,s1,80003ad2 <free_proc_locked+0x5e>
}
    80003adc:	60e2                	ld	ra,24(sp)
    80003ade:	6442                	ld	s0,16(sp)
    80003ae0:	64a2                	ld	s1,8(sp)
    80003ae2:	6105                	addi	sp,sp,32
    80003ae4:	8082                	ret

0000000080003ae6 <mycpu>:
{
    80003ae6:	1141                	addi	sp,sp,-16
    80003ae8:	e422                	sd	s0,8(sp)
    80003aea:	0800                	addi	s0,sp,16
}
    80003aec:	0000c517          	auipc	a0,0xc
    80003af0:	2f450513          	addi	a0,a0,756 # 8000fde0 <cpus>
    80003af4:	6422                	ld	s0,8(sp)
    80003af6:	0141                	addi	sp,sp,16
    80003af8:	8082                	ret

0000000080003afa <myproc>:
{
    80003afa:	1101                	addi	sp,sp,-32
    80003afc:	ec06                	sd	ra,24(sp)
    80003afe:	e822                	sd	s0,16(sp)
    80003b00:	e426                	sd	s1,8(sp)
    80003b02:	1000                	addi	s0,sp,32
    push_off();               // 禁用中断
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	b86080e7          	jalr	-1146(ra) # 8000368a <push_off>
    struct proc *p = c->proc; // 获取当前进程指针
    80003b0c:	0000c497          	auipc	s1,0xc
    80003b10:	2d44b483          	ld	s1,724(s1) # 8000fde0 <cpus>
    pop_off();                // 启用中断
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	bae080e7          	jalr	-1106(ra) # 800036c2 <pop_off>
}
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	60e2                	ld	ra,24(sp)
    80003b20:	6442                	ld	s0,16(sp)
    80003b22:	64a2                	ld	s1,8(sp)
    80003b24:	6105                	addi	sp,sp,32
    80003b26:	8082                	ret

0000000080003b28 <set_proc_name>:
    if (!p)
    80003b28:	c105                	beqz	a0,80003b48 <set_proc_name+0x20>
{
    80003b2a:	1141                	addi	sp,sp,-16
    80003b2c:	e406                	sd	ra,8(sp)
    80003b2e:	e022                	sd	s0,0(sp)
    80003b30:	0800                	addi	s0,sp,16
    safestrcpy(p->name, name, sizeof(p->name));
    80003b32:	4641                	li	a2,16
    80003b34:	0d050513          	addi	a0,a0,208
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	e7e080e7          	jalr	-386(ra) # 800039b6 <safestrcpy>
}
    80003b40:	60a2                	ld	ra,8(sp)
    80003b42:	6402                	ld	s0,0(sp)
    80003b44:	0141                	addi	sp,sp,16
    80003b46:	8082                	ret
    80003b48:	8082                	ret

0000000080003b4a <proc_init>:
{
    80003b4a:	7139                	addi	sp,sp,-64
    80003b4c:	fc06                	sd	ra,56(sp)
    80003b4e:	f822                	sd	s0,48(sp)
    80003b50:	f426                	sd	s1,40(sp)
    80003b52:	f04a                	sd	s2,32(sp)
    80003b54:	ec4e                	sd	s3,24(sp)
    80003b56:	e852                	sd	s4,16(sp)
    80003b58:	e456                	sd	s5,8(sp)
    80003b5a:	e05a                	sd	s6,0(sp)
    80003b5c:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid"); // 初始化pid锁
    80003b5e:	0000c497          	auipc	s1,0xc
    80003b62:	28248493          	addi	s1,s1,642 # 8000fde0 <cpus>
    80003b66:	00009597          	auipc	a1,0x9
    80003b6a:	89a58593          	addi	a1,a1,-1894 # 8000c400 <digits+0x2250>
    80003b6e:	0000c517          	auipc	a0,0xc
    80003b72:	32250513          	addi	a0,a0,802 # 8000fe90 <pid_lock>
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	afe080e7          	jalr	-1282(ra) # 80003674 <initlock>
        cpus[i].proc = 0;                                // 当前无进程运行
    80003b7e:	0004b023          	sd	zero,0(s1)
        cpus[i].noff = 0;                                // 初始化CPU中断次数
    80003b82:	0604ac23          	sw	zero,120(s1)
        cpus[i].intena = 0;                              // 初始化CPU中断使能
    80003b86:	0604ae23          	sw	zero,124(s1)
    for (int i = 0; i < n; i++)
    80003b8a:	0000c797          	auipc	a5,0xc
    80003b8e:	25e78793          	addi	a5,a5,606 # 8000fde8 <cpus+0x8>
    80003b92:	0000c717          	auipc	a4,0xc
    80003b96:	2c670713          	addi	a4,a4,710 # 8000fe58 <cpus+0x78>
        d[i] = 0;
    80003b9a:	00078023          	sb	zero,0(a5)
    for (int i = 0; i < n; i++)
    80003b9e:	0785                	addi	a5,a5,1
    80003ba0:	fee79de3          	bne	a5,a4,80003b9a <proc_init+0x50>
    80003ba4:	0000c797          	auipc	a5,0xc
    80003ba8:	2bc78793          	addi	a5,a5,700 # 8000fe60 <cpus+0x80>
    80003bac:	0000c717          	auipc	a4,0xc
    80003bb0:	2e070713          	addi	a4,a4,736 # 8000fe8c <cpus+0xac>
            cpus[i].last_scheduled_index[j] = 0;
    80003bb4:	0007a023          	sw	zero,0(a5)
        for (int j = 0; j <= PRIORITY_MAX; j++)
    80003bb8:	0791                	addi	a5,a5,4
    80003bba:	fee79de3          	bne	a5,a4,80003bb4 <proc_init+0x6a>
    for (int i = 0; i < NCPU; i++)
    80003bbe:	0000c997          	auipc	s3,0xc
    80003bc2:	31a98993          	addi	s3,s3,794 # 8000fed8 <proc+0x30>
    80003bc6:	0000c497          	auipc	s1,0xc
    80003bca:	38248493          	addi	s1,s1,898 # 8000ff48 <proc+0xa0>
    80003bce:	00010b17          	auipc	s6,0x10
    80003bd2:	b7ab0b13          	addi	s6,s6,-1158 # 80013748 <bcache+0x28>
        initlock(&proc[i].lock, "proc");                   // 初始化进程锁
    80003bd6:	00009a97          	auipc	s5,0x9
    80003bda:	832a8a93          	addi	s5,s5,-1998 # 8000c408 <digits+0x2258>
        proc[i].priority = PRIORITY_DEFAULT;               // 初始化优先级
    80003bde:	4a15                	li	s4,5
    80003be0:	a01d                	j	80003c06 <proc_init+0xbc>
    80003be2:	01492c23          	sw	s4,24(s2)
        proc[i].ticks = 0;                                 // 初始化 CPU 时间
    80003be6:	00092e23          	sw	zero,28(s2)
        proc[i].wait_time = 0;                             // 初始化等待时间
    80003bea:	02092023          	sw	zero,32(s2)
        proc[i].time_slice = 0;                            // 初始化时间片
    80003bee:	02092223          	sw	zero,36(s2)
        proc[i].time_slice_used = 0;                       // 初始化已用时间片
    80003bf2:	02092423          	sw	zero,40(s2)
        proc[i].consecutive_slices = 0;                    // 初始化连续时间片计数
    80003bf6:	02092623          	sw	zero,44(s2)
    for (int i = 0; i < NPROC; i++)
    80003bfa:	0e098993          	addi	s3,s3,224
    80003bfe:	0e048493          	addi	s1,s1,224
    80003c02:	05648363          	beq	s1,s6,80003c48 <proc_init+0xfe>
        initlock(&proc[i].lock, "proc");                   // 初始化进程锁
    80003c06:	85d6                	mv	a1,s5
    80003c08:	f6048513          	addi	a0,s1,-160
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	a68080e7          	jalr	-1432(ra) # 80003674 <initlock>
        proc[i].state = UNUSED;                            // 初始化进程状态，标记为未使用
    80003c14:	8926                	mv	s2,s1
    80003c16:	f604ac23          	sw	zero,-136(s1)
        proc[i].pid = 0;                                   // 初始化进程ID，pid为0表示无效
    80003c1a:	f604ae23          	sw	zero,-132(s1)
        proc[i].parent = 0;                                // 初始化进程父进程，无父进程
    80003c1e:	f804b023          	sd	zero,-128(s1)
        proc[i].kstack = 0;                                // 初始化进程栈，无内核栈
    80003c22:	f804b423          	sd	zero,-120(s1)
        proc[i].chan = 0;                                  // 初始化等待通道
    80003c26:	0004b023          	sd	zero,0(s1)
        safestrcpy(proc[i].name, 0, sizeof(proc[i].name)); // 初始化进程名称，清空名称
    80003c2a:	4641                	li	a2,16
    80003c2c:	4581                	li	a1,0
    80003c2e:	03048513          	addi	a0,s1,48
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	d84080e7          	jalr	-636(ra) # 800039b6 <safestrcpy>
    80003c3a:	87ce                	mv	a5,s3
        d[i] = 0;
    80003c3c:	00078023          	sb	zero,0(a5)
    for (int i = 0; i < n; i++)
    80003c40:	0785                	addi	a5,a5,1
    80003c42:	fe979de3          	bne	a5,s1,80003c3c <proc_init+0xf2>
    80003c46:	bf71                	j	80003be2 <proc_init+0x98>
}
    80003c48:	70e2                	ld	ra,56(sp)
    80003c4a:	7442                	ld	s0,48(sp)
    80003c4c:	74a2                	ld	s1,40(sp)
    80003c4e:	7902                	ld	s2,32(sp)
    80003c50:	69e2                	ld	s3,24(sp)
    80003c52:	6a42                	ld	s4,16(sp)
    80003c54:	6aa2                	ld	s5,8(sp)
    80003c56:	6b02                	ld	s6,0(sp)
    80003c58:	6121                	addi	sp,sp,64
    80003c5a:	8082                	ret

0000000080003c5c <alloc_process>:
{
    80003c5c:	715d                	addi	sp,sp,-80
    80003c5e:	e486                	sd	ra,72(sp)
    80003c60:	e0a2                	sd	s0,64(sp)
    80003c62:	fc26                	sd	s1,56(sp)
    80003c64:	f84a                	sd	s2,48(sp)
    80003c66:	f44e                	sd	s3,40(sp)
    80003c68:	f052                	sd	s4,32(sp)
    80003c6a:	ec56                	sd	s5,24(sp)
    80003c6c:	e85a                	sd	s6,16(sp)
    80003c6e:	e45e                	sd	s7,8(sp)
    80003c70:	0880                	addi	s0,sp,80
    for (int i = 0; i < NPROC; i++)
    80003c72:	0000c497          	auipc	s1,0xc
    80003c76:	23648493          	addi	s1,s1,566 # 8000fea8 <proc>
    80003c7a:	4901                	li	s2,0
    80003c7c:	04000a13          	li	s4,64
        struct proc *p = &proc[i];
    80003c80:	89a6                	mv	s3,s1
        acquire(&p->lock);
    80003c82:	8526                	mv	a0,s1
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	ad2080e7          	jalr	-1326(ra) # 80003756 <acquire>
        if (p->state == UNUSED)
    80003c8c:	4c9c                	lw	a5,24(s1)
    80003c8e:	cf89                	beqz	a5,80003ca8 <alloc_process+0x4c>
        release(&p->lock);
    80003c90:	8526                	mv	a0,s1
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	b34080e7          	jalr	-1228(ra) # 800037c6 <release>
    for (int i = 0; i < NPROC; i++)
    80003c9a:	2905                	addiw	s2,s2,1
    80003c9c:	0e048493          	addi	s1,s1,224
    80003ca0:	ff4910e3          	bne	s2,s4,80003c80 <alloc_process+0x24>
    return 0;
    80003ca4:	4981                	li	s3,0
    80003ca6:	a0e5                	j	80003d8e <alloc_process+0x132>
            p->state = USED;
    80003ca8:	0000ca97          	auipc	s5,0xc
    80003cac:	200a8a93          	addi	s5,s5,512 # 8000fea8 <proc>
    80003cb0:	00391493          	slli	s1,s2,0x3
    80003cb4:	41248a33          	sub	s4,s1,s2
    80003cb8:	0a16                	slli	s4,s4,0x5
    80003cba:	9a56                	add	s4,s4,s5
    80003cbc:	4785                	li	a5,1
    80003cbe:	00fa2c23          	sw	a5,24(s4)
    acquire(&pid_lock);
    80003cc2:	0000cb97          	auipc	s7,0xc
    80003cc6:	1ceb8b93          	addi	s7,s7,462 # 8000fe90 <pid_lock>
    80003cca:	855e                	mv	a0,s7
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	a8a080e7          	jalr	-1398(ra) # 80003756 <acquire>
    int pid = nextpid++;
    80003cd4:	0000c797          	auipc	a5,0xc
    80003cd8:	b5478793          	addi	a5,a5,-1196 # 8000f828 <nextpid>
    80003cdc:	0007ab03          	lw	s6,0(a5)
    80003ce0:	001b071b          	addiw	a4,s6,1
    80003ce4:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80003ce6:	855e                	mv	a0,s7
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	ade080e7          	jalr	-1314(ra) # 800037c6 <release>
            p->pid = allocpid();
    80003cf0:	016a2e23          	sw	s6,28(s4)
            p->parent = 0;
    80003cf4:	020a3023          	sd	zero,32(s4)
            p->entry = 0;
    80003cf8:	0a0a3423          	sd	zero,168(s4)
            p->exit_status = 0;
    80003cfc:	0a0a2823          	sw	zero,176(s4)
            p->killed = 0;
    80003d00:	0a0a2a23          	sw	zero,180(s4)
            safestrcpy(p->name, "proc", sizeof(p->name));
    80003d04:	412484b3          	sub	s1,s1,s2
    80003d08:	0496                	slli	s1,s1,0x5
    80003d0a:	0d048513          	addi	a0,s1,208
    80003d0e:	4641                	li	a2,16
    80003d10:	00008597          	auipc	a1,0x8
    80003d14:	6f858593          	addi	a1,a1,1784 # 8000c408 <digits+0x2258>
    80003d18:	9556                	add	a0,a0,s5
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	c9c080e7          	jalr	-868(ra) # 800039b6 <safestrcpy>
            p->kstack = alloc_page();
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	2b6080e7          	jalr	694(ra) # 80000fd8 <alloc_page>
    80003d2a:	8aaa                	mv	s5,a0
    80003d2c:	02aa3423          	sd	a0,40(s4)
            if (p->kstack == 0)
    80003d30:	c93d                	beqz	a0,80003da6 <alloc_process+0x14a>
            kzero(&p->context, sizeof(struct context));
    80003d32:	0000c797          	auipc	a5,0xc
    80003d36:	1a678793          	addi	a5,a5,422 # 8000fed8 <proc+0x30>
    80003d3a:	97a6                	add	a5,a5,s1
    80003d3c:	07078713          	addi	a4,a5,112
        d[i] = 0;
    80003d40:	00078023          	sb	zero,0(a5)
    for (int i = 0; i < n; i++)
    80003d44:	0785                	addi	a5,a5,1
    80003d46:	fee79de3          	bne	a5,a4,80003d40 <alloc_process+0xe4>
            p->chan = 0;
    80003d4a:	0000c697          	auipc	a3,0xc
    80003d4e:	15e68693          	addi	a3,a3,350 # 8000fea8 <proc>
    80003d52:	00391713          	slli	a4,s2,0x3
    80003d56:	412707b3          	sub	a5,a4,s2
    80003d5a:	0796                	slli	a5,a5,0x5
    80003d5c:	97b6                	add	a5,a5,a3
    80003d5e:	0a07b023          	sd	zero,160(a5)
            p->context.sp = (uint64)p->kstack + PGSIZE; // 栈顶地址
    80003d62:	7790                	ld	a2,40(a5)
    80003d64:	6585                	lui	a1,0x1
    80003d66:	962e                	add	a2,a2,a1
    80003d68:	ff90                	sd	a2,56(a5)
            p->context.ra = (uint64)process_start;      // 返回地址
    80003d6a:	00000617          	auipc	a2,0x0
    80003d6e:	71c60613          	addi	a2,a2,1820 # 80004486 <process_start>
    80003d72:	fb90                	sd	a2,48(a5)
            p->priority = PRIORITY_DEFAULT;
    80003d74:	4615                	li	a2,5
    80003d76:	0ac7ac23          	sw	a2,184(a5)
            p->ticks = 0;
    80003d7a:	0a07ae23          	sw	zero,188(a5)
            p->wait_time = 0;
    80003d7e:	0c07a023          	sw	zero,192(a5)
            p->time_slice = 0;
    80003d82:	0c07a223          	sw	zero,196(a5)
            p->time_slice_used = 0;
    80003d86:	0c07a423          	sw	zero,200(a5)
            p->consecutive_slices = 0;
    80003d8a:	0c07a623          	sw	zero,204(a5)
}
    80003d8e:	854e                	mv	a0,s3
    80003d90:	60a6                	ld	ra,72(sp)
    80003d92:	6406                	ld	s0,64(sp)
    80003d94:	74e2                	ld	s1,56(sp)
    80003d96:	7942                	ld	s2,48(sp)
    80003d98:	79a2                	ld	s3,40(sp)
    80003d9a:	7a02                	ld	s4,32(sp)
    80003d9c:	6ae2                	ld	s5,24(sp)
    80003d9e:	6b42                	ld	s6,16(sp)
    80003da0:	6ba2                	ld	s7,8(sp)
    80003da2:	6161                	addi	sp,sp,80
    80003da4:	8082                	ret
                free_proc_locked(p);
    80003da6:	854e                	mv	a0,s3
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	ccc080e7          	jalr	-820(ra) # 80003a74 <free_proc_locked>
                release(&p->lock);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	a14080e7          	jalr	-1516(ra) # 800037c6 <release>
                return 0;
    80003dba:	89d6                	mv	s3,s5
    80003dbc:	bfc9                	j	80003d8e <alloc_process+0x132>

0000000080003dbe <free_process>:
    if (p == 0)
    80003dbe:	c915                	beqz	a0,80003df2 <free_process+0x34>
{
    80003dc0:	1101                	addi	sp,sp,-32
    80003dc2:	ec06                	sd	ra,24(sp)
    80003dc4:	e822                	sd	s0,16(sp)
    80003dc6:	e426                	sd	s1,8(sp)
    80003dc8:	1000                	addi	s0,sp,32
    80003dca:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	98a080e7          	jalr	-1654(ra) # 80003756 <acquire>
    free_proc_locked(p);
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	c9e080e7          	jalr	-866(ra) # 80003a74 <free_proc_locked>
    release(&p->lock);
    80003dde:	8526                	mv	a0,s1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	9e6080e7          	jalr	-1562(ra) # 800037c6 <release>
}
    80003de8:	60e2                	ld	ra,24(sp)
    80003dea:	6442                	ld	s0,16(sp)
    80003dec:	64a2                	ld	s1,8(sp)
    80003dee:	6105                	addi	sp,sp,32
    80003df0:	8082                	ret
    80003df2:	8082                	ret

0000000080003df4 <create_process_with_priority>:
{
    80003df4:	7179                	addi	sp,sp,-48
    80003df6:	f406                	sd	ra,40(sp)
    80003df8:	f022                	sd	s0,32(sp)
    80003dfa:	ec26                	sd	s1,24(sp)
    80003dfc:	e84a                	sd	s2,16(sp)
    80003dfe:	e44e                	sd	s3,8(sp)
    80003e00:	1800                	addi	s0,sp,48
    80003e02:	89aa                	mv	s3,a0
    80003e04:	892e                	mv	s2,a1
    struct proc *p = alloc_process(); // 分配进程结构
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	e56080e7          	jalr	-426(ra) # 80003c5c <alloc_process>
    if (p == 0)
    80003e0e:	c125                	beqz	a0,80003e6e <create_process_with_priority+0x7a>
    80003e10:	84aa                	mv	s1,a0
    struct proc *parent = myproc(); // 获取当前进程作为父进程
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	ce8080e7          	jalr	-792(ra) # 80003afa <myproc>
    p->parent = parent;             // 设置父进程
    80003e1a:	f088                	sd	a0,32(s1)
    p->entry = entry;               // 设置入口函数
    80003e1c:	0b34b423          	sd	s3,168(s1)
    set_proc_name(p, "kthread");    // 设置进程名
    80003e20:	00008597          	auipc	a1,0x8
    80003e24:	5f058593          	addi	a1,a1,1520 # 8000c410 <digits+0x2260>
    80003e28:	8526                	mv	a0,s1
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	cfe080e7          	jalr	-770(ra) # 80003b28 <set_proc_name>
    p->priority = clamp_priority(priority);
    80003e32:	87ca                	mv	a5,s2
    80003e34:	4729                	li	a4,10
    80003e36:	01275363          	bge	a4,s2,80003e3c <create_process_with_priority+0x48>
    80003e3a:	47a9                	li	a5,10
    80003e3c:	873e                	mv	a4,a5
    80003e3e:	2781                	sext.w	a5,a5
    80003e40:	02f05563          	blez	a5,80003e6a <create_process_with_priority+0x76>
    80003e44:	0ae4ac23          	sw	a4,184(s1)
    p->state = RUNNABLE; // 设置进程状态为可运行
    80003e48:	478d                	li	a5,3
    80003e4a:	cc9c                	sw	a5,24(s1)
    int pid = p->pid;
    80003e4c:	01c4a903          	lw	s2,28(s1)
    release(&p->lock);
    80003e50:	8526                	mv	a0,s1
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	974080e7          	jalr	-1676(ra) # 800037c6 <release>
}
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	70a2                	ld	ra,40(sp)
    80003e5e:	7402                	ld	s0,32(sp)
    80003e60:	64e2                	ld	s1,24(sp)
    80003e62:	6942                	ld	s2,16(sp)
    80003e64:	69a2                	ld	s3,8(sp)
    80003e66:	6145                	addi	sp,sp,48
    80003e68:	8082                	ret
    p->priority = clamp_priority(priority);
    80003e6a:	4705                	li	a4,1
    80003e6c:	bfe1                	j	80003e44 <create_process_with_priority+0x50>
        return -1;
    80003e6e:	597d                	li	s2,-1
    80003e70:	b7ed                	j	80003e5a <create_process_with_priority+0x66>

0000000080003e72 <create_process>:
{
    80003e72:	1141                	addi	sp,sp,-16
    80003e74:	e406                	sd	ra,8(sp)
    80003e76:	e022                	sd	s0,0(sp)
    80003e78:	0800                	addi	s0,sp,16
    return create_process_with_priority(entry, PRIORITY_DEFAULT);
    80003e7a:	4595                	li	a1,5
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	f78080e7          	jalr	-136(ra) # 80003df4 <create_process_with_priority>
}
    80003e84:	60a2                	ld	ra,8(sp)
    80003e86:	6402                	ld	s0,0(sp)
    80003e88:	0141                	addi	sp,sp,16
    80003e8a:	8082                	ret

0000000080003e8c <sched>:
{
    80003e8c:	7179                	addi	sp,sp,-48
    80003e8e:	f406                	sd	ra,40(sp)
    80003e90:	f022                	sd	s0,32(sp)
    80003e92:	ec26                	sd	s1,24(sp)
    80003e94:	e84a                	sd	s2,16(sp)
    80003e96:	e44e                	sd	s3,8(sp)
    80003e98:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	c60080e7          	jalr	-928(ra) # 80003afa <myproc>
    80003ea2:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	884080e7          	jalr	-1916(ra) # 80003728 <holding>
    80003eac:	cd1d                	beqz	a0,80003eea <sched+0x5e>
    if (intr_get())
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	7b2080e7          	jalr	1970(ra) # 80003660 <intr_get>
    80003eb6:	e131                	bnez	a0,80003efa <sched+0x6e>
    int intena = c->intena;
    80003eb8:	0000c917          	auipc	s2,0xc
    80003ebc:	f2890913          	addi	s2,s2,-216 # 8000fde0 <cpus>
    80003ec0:	07c92983          	lw	s3,124(s2)
    swtch(&p->context, &c->context); // 切换到调度器上下文
    80003ec4:	0000c597          	auipc	a1,0xc
    80003ec8:	f2458593          	addi	a1,a1,-220 # 8000fde8 <cpus+0x8>
    80003ecc:	03048513          	addi	a0,s1,48
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	a7c080e7          	jalr	-1412(ra) # 8000394c <swtch>
    c->intena = intena;              // 恢复中断状态
    80003ed8:	07392e23          	sw	s3,124(s2)
}
    80003edc:	70a2                	ld	ra,40(sp)
    80003ede:	7402                	ld	s0,32(sp)
    80003ee0:	64e2                	ld	s1,24(sp)
    80003ee2:	6942                	ld	s2,16(sp)
    80003ee4:	69a2                	ld	s3,8(sp)
    80003ee6:	6145                	addi	sp,sp,48
    80003ee8:	8082                	ret
        panic("sched p->lock");
    80003eea:	00008517          	auipc	a0,0x8
    80003eee:	52e50513          	addi	a0,a0,1326 # 8000c418 <digits+0x2268>
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	b9a080e7          	jalr	-1126(ra) # 80002a8c <panic>
        panic("sched interruptible");
    80003efa:	00008517          	auipc	a0,0x8
    80003efe:	52e50513          	addi	a0,a0,1326 # 8000c428 <digits+0x2278>
    80003f02:	fffff097          	auipc	ra,0xfffff
    80003f06:	b8a080e7          	jalr	-1142(ra) # 80002a8c <panic>

0000000080003f0a <yield>:
{
    80003f0a:	1101                	addi	sp,sp,-32
    80003f0c:	ec06                	sd	ra,24(sp)
    80003f0e:	e822                	sd	s0,16(sp)
    80003f10:	e426                	sd	s1,8(sp)
    80003f12:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	be6080e7          	jalr	-1050(ra) # 80003afa <myproc>
    if (p == 0)
    80003f1c:	c51d                	beqz	a0,80003f4a <yield+0x40>
    80003f1e:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	836080e7          	jalr	-1994(ra) # 80003756 <acquire>
    if (p->time_slice > 0)
    80003f28:	0c44a783          	lw	a5,196(s1)
    80003f2c:	00f05463          	blez	a5,80003f34 <yield+0x2a>
        p->consecutive_slices = 0; // 重置连续时间片计数，表示交互式行为
    80003f30:	0c04a623          	sw	zero,204(s1)
    p->state = RUNNABLE;
    80003f34:	478d                	li	a5,3
    80003f36:	cc9c                	sw	a5,24(s1)
    sched();
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	f54080e7          	jalr	-172(ra) # 80003e8c <sched>
    release(&p->lock);
    80003f40:	8526                	mv	a0,s1
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	884080e7          	jalr	-1916(ra) # 800037c6 <release>
}
    80003f4a:	60e2                	ld	ra,24(sp)
    80003f4c:	6442                	ld	s0,16(sp)
    80003f4e:	64a2                	ld	s1,8(sp)
    80003f50:	6105                	addi	sp,sp,32
    80003f52:	8082                	ret

0000000080003f54 <scheduler>:
{
    80003f54:	7159                	addi	sp,sp,-112
    80003f56:	f486                	sd	ra,104(sp)
    80003f58:	f0a2                	sd	s0,96(sp)
    80003f5a:	eca6                	sd	s1,88(sp)
    80003f5c:	e8ca                	sd	s2,80(sp)
    80003f5e:	e4ce                	sd	s3,72(sp)
    80003f60:	e0d2                	sd	s4,64(sp)
    80003f62:	fc56                	sd	s5,56(sp)
    80003f64:	f85a                	sd	s6,48(sp)
    80003f66:	f45e                	sd	s7,40(sp)
    80003f68:	f062                	sd	s8,32(sp)
    80003f6a:	ec66                	sd	s9,24(sp)
    80003f6c:	e86a                	sd	s10,16(sp)
    80003f6e:	e46e                	sd	s11,8(sp)
    80003f70:	1880                	addi	s0,sp,112
    return &cpus[0]; // 单核实现，总是返回第一个CPU
    80003f72:	0000f917          	auipc	s2,0xf
    80003f76:	73690913          	addi	s2,s2,1846 # 800136a8 <priority_lock>
            else if (p->state == RUNNING)
    80003f7a:	4a11                	li	s4,4
                if (p->wait_time > AGING_THRESHOLD && p->priority < PRIORITY_MAX)
    80003f7c:	3e800a93          	li	s5,1000
                struct proc *p = &proc[i];
    80003f80:	0000cc17          	auipc	s8,0xc
    80003f84:	f28c0c13          	addi	s8,s8,-216 # 8000fea8 <proc>
    80003f88:	aa65                	j	80004140 <scheduler+0x1ec>
                p->wait_time++;
    80003f8a:	0c04a783          	lw	a5,192(s1)
    80003f8e:	2785                	addiw	a5,a5,1
    80003f90:	0007869b          	sext.w	a3,a5
    80003f94:	0cf4a023          	sw	a5,192(s1)
                if (p->wait_time > AGING_THRESHOLD && p->priority < PRIORITY_MAX)
    80003f98:	00dad663          	bge	s5,a3,80003fa4 <scheduler+0x50>
    80003f9c:	0b84a603          	lw	a2,184(s1)
    80003fa0:	02cb5963          	bge	s6,a2,80003fd2 <scheduler+0x7e>
            release(&p->lock);
    80003fa4:	856a                	mv	a0,s10
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	820080e7          	jalr	-2016(ra) # 800037c6 <release>
        for (int i = 0; i < NPROC; i++)
    80003fae:	0e048493          	addi	s1,s1,224
    80003fb2:	05248063          	beq	s1,s2,80003ff2 <scheduler+0x9e>
            acquire(&p->lock);
    80003fb6:	8d26                	mv	s10,s1
    80003fb8:	8526                	mv	a0,s1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	79c080e7          	jalr	1948(ra) # 80003756 <acquire>
            if (p->state == RUNNABLE)
    80003fc2:	4c9c                	lw	a5,24(s1)
    80003fc4:	fd3783e3          	beq	a5,s3,80003f8a <scheduler+0x36>
            else if (p->state == RUNNING)
    80003fc8:	fd479ee3          	bne	a5,s4,80003fa4 <scheduler+0x50>
                p->wait_time = 0;
    80003fcc:	0c04a023          	sw	zero,192(s1)
    80003fd0:	bfd1                	j	80003fa4 <scheduler+0x50>
                    p->priority++;
    80003fd2:	2605                	addiw	a2,a2,1
    80003fd4:	0ac4ac23          	sw	a2,184(s1)
                    p->wait_time = 0;          // 重置等待时间，避免持续提升
    80003fd8:	0c04a023          	sw	zero,192(s1)
                    p->consecutive_slices = 0; // 重置连续时间片计数（aging 提升时重置）
    80003fdc:	0c04a623          	sw	zero,204(s1)
                    printf("[MLFQ] PID %d promoted to priority %d (aging, waited %d ticks, threshold was %d)\n",
    80003fe0:	8756                	mv	a4,s5
    80003fe2:	2601                	sext.w	a2,a2
    80003fe4:	4ccc                	lw	a1,28(s1)
    80003fe6:	8566                	mv	a0,s9
    80003fe8:	ffffc097          	auipc	ra,0xffffc
    80003fec:	51c080e7          	jalr	1308(ra) # 80000504 <printf>
    80003ff0:	bf55                	j	80003fa4 <scheduler+0x50>
    80003ff2:	84de                	mv	s1,s7
        int best_priority = PRIORITY_MIN - 1;
    80003ff4:	4d81                	li	s11,0
    80003ff6:	a821                	j	8000400e <scheduler+0xba>
    80003ff8:	00078d9b          	sext.w	s11,a5
            release(&p->lock);
    80003ffc:	856a                	mv	a0,s10
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	7c8080e7          	jalr	1992(ra) # 800037c6 <release>
        for (int i = 0; i < NPROC; i++)
    80004006:	0e048493          	addi	s1,s1,224
    8000400a:	03248363          	beq	s1,s2,80004030 <scheduler+0xdc>
            acquire(&p->lock);
    8000400e:	8d26                	mv	s10,s1
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	744080e7          	jalr	1860(ra) # 80003756 <acquire>
            if (p->state == RUNNABLE)
    8000401a:	4c9c                	lw	a5,24(s1)
    8000401c:	ff3790e3          	bne	a5,s3,80003ffc <scheduler+0xa8>
                if (p->priority > best_priority)
    80004020:	0b84a783          	lw	a5,184(s1)
    80004024:	0007871b          	sext.w	a4,a5
    80004028:	fdb758e3          	bge	a4,s11,80003ff8 <scheduler+0xa4>
    8000402c:	87ee                	mv	a5,s11
    8000402e:	b7e9                	j	80003ff8 <scheduler+0xa4>
        if (best_priority >= PRIORITY_MIN)
    80004030:	01b04c63          	bgtz	s11,80004048 <scheduler+0xf4>
        intr_on(); // 开启中断
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	5fe080e7          	jalr	1534(ra) # 80003632 <intr_on>
        for (int i = 0; i < NPROC; i++)
    8000403c:	0000cb97          	auipc	s7,0xc
    80004040:	e6cb8b93          	addi	s7,s7,-404 # 8000fea8 <proc>
        intr_on(); // 开启中断
    80004044:	84de                	mv	s1,s7
    80004046:	bf85                	j	80003fb6 <scheduler+0x62>
            int start_index = c->last_scheduled_index[best_priority];
    80004048:	020d8793          	addi	a5,s11,32
    8000404c:	00279713          	slli	a4,a5,0x2
    80004050:	0000c797          	auipc	a5,0xc
    80004054:	d9078793          	addi	a5,a5,-624 # 8000fde0 <cpus>
    80004058:	97ba                	add	a5,a5,a4
    8000405a:	0007ab03          	lw	s6,0(a5)
    8000405e:	040b0d1b          	addiw	s10,s6,64
                if (p->state == RUNNABLE && p->priority == best_priority)
    80004062:	4c8d                	li	s9,3
    80004064:	a809                	j	80004076 <scheduler+0x122>
                release(&p->lock);
    80004066:	8526                	mv	a0,s1
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	75e080e7          	jalr	1886(ra) # 800037c6 <release>
            for (int offset = 0; offset < NPROC; offset++)
    80004070:	2b05                	addiw	s6,s6,1
    80004072:	0dab0e63          	beq	s6,s10,8000414e <scheduler+0x1fa>
                int i = (start_index + offset) % NPROC;
    80004076:	41fb599b          	sraiw	s3,s6,0x1f
    8000407a:	01a9d79b          	srliw	a5,s3,0x1a
    8000407e:	016789bb          	addw	s3,a5,s6
    80004082:	03f9f993          	andi	s3,s3,63
    80004086:	40f989bb          	subw	s3,s3,a5
                struct proc *p = &proc[i];
    8000408a:	00399493          	slli	s1,s3,0x3
    8000408e:	413484b3          	sub	s1,s1,s3
    80004092:	0496                	slli	s1,s1,0x5
    80004094:	94e2                	add	s1,s1,s8
                acquire(&p->lock);
    80004096:	8526                	mv	a0,s1
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	6be080e7          	jalr	1726(ra) # 80003756 <acquire>
                if (p->state == RUNNABLE && p->priority == best_priority)
    800040a0:	4c9c                	lw	a5,24(s1)
    800040a2:	fd9792e3          	bne	a5,s9,80004066 <scheduler+0x112>
    800040a6:	0b84a783          	lw	a5,184(s1)
    800040aa:	fbb79ee3          	bne	a5,s11,80004066 <scheduler+0x112>
                c->last_scheduled_index[best_priority] = (best_index + 1) % NPROC;
    800040ae:	020d8793          	addi	a5,s11,32
    800040b2:	078a                	slli	a5,a5,0x2
    800040b4:	0000c697          	auipc	a3,0xc
    800040b8:	d2c68693          	addi	a3,a3,-724 # 8000fde0 <cpus>
    800040bc:	96be                	add	a3,a3,a5
    800040be:	2985                	addiw	s3,s3,1
    800040c0:	41f9d79b          	sraiw	a5,s3,0x1f
    800040c4:	01a7d71b          	srliw	a4,a5,0x1a
    800040c8:	00e987bb          	addw	a5,s3,a4
    800040cc:	03f7f793          	andi	a5,a5,63
    800040d0:	9f99                	subw	a5,a5,a4
    800040d2:	c29c                	sw	a5,0(a3)
            best->state = RUNNING;
    800040d4:	0144ac23          	sw	s4,24(s1)
            best->wait_time = 0; // 被选中后重置等待时间
    800040d8:	0c04a023          	sw	zero,192(s1)
            if (best->time_slice <= 0)
    800040dc:	0c44a783          	lw	a5,196(s1)
    800040e0:	02f04963          	bgtz	a5,80004112 <scheduler+0x1be>
                best->time_slice = calculate_time_slice(best->priority);
    800040e4:	0b84a683          	lw	a3,184(s1)
    int multiplier = (PRIORITY_MAX - priority + 1) * TIME_SLICE_MULTIPLIER;
    800040e8:	47ad                	li	a5,11
    800040ea:	9f95                	subw	a5,a5,a3
    return TIME_SLICE_BASE * multiplier;
    800040ec:	0017961b          	slliw	a2,a5,0x1
    800040f0:	9e3d                	addw	a2,a2,a5
    800040f2:	0016161b          	slliw	a2,a2,0x1
                best->time_slice = calculate_time_slice(best->priority);
    800040f6:	0cc4a223          	sw	a2,196(s1)
                printf("[MLFQ] PID %d allocated time slice: %d (priority %d, consecutive_slices: %d)\n",
    800040fa:	0cc4a703          	lw	a4,204(s1)
    800040fe:	2601                	sext.w	a2,a2
    80004100:	4ccc                	lw	a1,28(s1)
    80004102:	00008517          	auipc	a0,0x8
    80004106:	39650513          	addi	a0,a0,918 # 8000c498 <digits+0x22e8>
    8000410a:	ffffc097          	auipc	ra,0xffffc
    8000410e:	3fa080e7          	jalr	1018(ra) # 80000504 <printf>
            c->proc = best;
    80004112:	0000c997          	auipc	s3,0xc
    80004116:	cce98993          	addi	s3,s3,-818 # 8000fde0 <cpus>
    8000411a:	0099b023          	sd	s1,0(s3)
            swtch(&c->context, &best->context);
    8000411e:	03048593          	addi	a1,s1,48
    80004122:	0000c517          	auipc	a0,0xc
    80004126:	cc650513          	addi	a0,a0,-826 # 8000fde8 <cpus+0x8>
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	822080e7          	jalr	-2014(ra) # 8000394c <swtch>
            c->proc = 0;
    80004132:	0009b023          	sd	zero,0(s3)
            release(&best->lock);
    80004136:	8526                	mv	a0,s1
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	68e080e7          	jalr	1678(ra) # 800037c6 <release>
            if (p->state == RUNNABLE)
    80004140:	498d                	li	s3,3
                if (p->wait_time > AGING_THRESHOLD && p->priority < PRIORITY_MAX)
    80004142:	4b25                	li	s6,9
                    printf("[MLFQ] PID %d promoted to priority %d (aging, waited %d ticks, threshold was %d)\n",
    80004144:	00008c97          	auipc	s9,0x8
    80004148:	2fcc8c93          	addi	s9,s9,764 # 8000c440 <digits+0x2290>
    8000414c:	b5e5                	j	80004034 <scheduler+0xe0>
                for (int i = 0; i < NPROC; i++)
    8000414e:	4981                	li	s3,0
                    if (p->state == RUNNABLE && p->priority == best_priority)
    80004150:	4c8d                	li	s9,3
                for (int i = 0; i < NPROC; i++)
    80004152:	04000b13          	li	s6,64
    80004156:	a819                	j	8000416c <scheduler+0x218>
                    release(&p->lock);
    80004158:	8526                	mv	a0,s1
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	66c080e7          	jalr	1644(ra) # 800037c6 <release>
                for (int i = 0; i < NPROC; i++)
    80004162:	2985                	addiw	s3,s3,1
    80004164:	0e0b8b93          	addi	s7,s7,224
    80004168:	fd698ce3          	beq	s3,s6,80004140 <scheduler+0x1ec>
                    struct proc *p = &proc[i];
    8000416c:	84de                	mv	s1,s7
                    acquire(&p->lock);
    8000416e:	855e                	mv	a0,s7
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	5e6080e7          	jalr	1510(ra) # 80003756 <acquire>
                    if (p->state == RUNNABLE && p->priority == best_priority)
    80004178:	018ba783          	lw	a5,24(s7)
    8000417c:	fd979ee3          	bne	a5,s9,80004158 <scheduler+0x204>
    80004180:	0b8ba783          	lw	a5,184(s7)
    80004184:	fdb79ae3          	bne	a5,s11,80004158 <scheduler+0x204>
    80004188:	b71d                	j	800040ae <scheduler+0x15a>

000000008000418a <ksleep>:
{
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	e426                	sd	s1,8(sp)
    80004192:	e04a                	sd	s2,0(sp)
    80004194:	1000                	addi	s0,sp,32
    80004196:	892a                	mv	s2,a0
    int start = timer_get_ticks(); // 获取起始时间
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	39c080e7          	jalr	924(ra) # 80003534 <timer_get_ticks>
    800041a0:	84aa                	mv	s1,a0
    while (timer_get_ticks() - start < ticks)
    800041a2:	a029                	j	800041ac <ksleep+0x22>
        yield();
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	d66080e7          	jalr	-666(ra) # 80003f0a <yield>
    while (timer_get_ticks() - start < ticks)
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	388080e7          	jalr	904(ra) # 80003534 <timer_get_ticks>
    800041b4:	9d05                	subw	a0,a0,s1
    800041b6:	ff2547e3          	blt	a0,s2,800041a4 <ksleep+0x1a>
}
    800041ba:	60e2                	ld	ra,24(sp)
    800041bc:	6442                	ld	s0,16(sp)
    800041be:	64a2                	ld	s1,8(sp)
    800041c0:	6902                	ld	s2,0(sp)
    800041c2:	6105                	addi	sp,sp,32
    800041c4:	8082                	ret

00000000800041c6 <sleep>:
{
    800041c6:	7179                	addi	sp,sp,-48
    800041c8:	f406                	sd	ra,40(sp)
    800041ca:	f022                	sd	s0,32(sp)
    800041cc:	ec26                	sd	s1,24(sp)
    800041ce:	e84a                	sd	s2,16(sp)
    800041d0:	e44e                	sd	s3,8(sp)
    800041d2:	1800                	addi	s0,sp,48
    800041d4:	89aa                	mv	s3,a0
    800041d6:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	922080e7          	jalr	-1758(ra) # 80003afa <myproc>
    if (p == 0)
    800041e0:	cd21                	beqz	a0,80004238 <sleep+0x72>
    800041e2:	84aa                	mv	s1,a0
    if (lk == 0)
    800041e4:	06090263          	beqz	s2,80004248 <sleep+0x82>
    if (chan == 0)
    800041e8:	06098863          	beqz	s3,80004258 <sleep+0x92>
    if (lk != &p->lock)
    800041ec:	07250e63          	beq	a0,s2,80004268 <sleep+0xa2>
        acquire(&p->lock);
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	566080e7          	jalr	1382(ra) # 80003756 <acquire>
        release(lk);
    800041f8:	854a                	mv	a0,s2
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	5cc080e7          	jalr	1484(ra) # 800037c6 <release>
    p->chan = chan;
    80004202:	0b34b023          	sd	s3,160(s1)
    p->state = SLEEPING;
    80004206:	4789                	li	a5,2
    80004208:	cc9c                	sw	a5,24(s1)
    sched();
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	c82080e7          	jalr	-894(ra) # 80003e8c <sched>
    p->chan = 0;
    80004212:	0a04b023          	sd	zero,160(s1)
        release(&p->lock);
    80004216:	8526                	mv	a0,s1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	5ae080e7          	jalr	1454(ra) # 800037c6 <release>
        acquire(lk);
    80004220:	854a                	mv	a0,s2
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	534080e7          	jalr	1332(ra) # 80003756 <acquire>
}
    8000422a:	70a2                	ld	ra,40(sp)
    8000422c:	7402                	ld	s0,32(sp)
    8000422e:	64e2                	ld	s1,24(sp)
    80004230:	6942                	ld	s2,16(sp)
    80004232:	69a2                	ld	s3,8(sp)
    80004234:	6145                	addi	sp,sp,48
    80004236:	8082                	ret
        panic("sleep without proc");
    80004238:	00008517          	auipc	a0,0x8
    8000423c:	2b050513          	addi	a0,a0,688 # 8000c4e8 <digits+0x2338>
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	84c080e7          	jalr	-1972(ra) # 80002a8c <panic>
        panic("sleep without lock");
    80004248:	00008517          	auipc	a0,0x8
    8000424c:	2b850513          	addi	a0,a0,696 # 8000c500 <digits+0x2350>
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	83c080e7          	jalr	-1988(ra) # 80002a8c <panic>
        panic("sleep without chan");
    80004258:	00008517          	auipc	a0,0x8
    8000425c:	2c050513          	addi	a0,a0,704 # 8000c518 <digits+0x2368>
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	82c080e7          	jalr	-2004(ra) # 80002a8c <panic>
    p->chan = chan;
    80004268:	0b353023          	sd	s3,160(a0)
    p->state = SLEEPING;
    8000426c:	4789                	li	a5,2
    8000426e:	cd1c                	sw	a5,24(a0)
    sched();
    80004270:	00000097          	auipc	ra,0x0
    80004274:	c1c080e7          	jalr	-996(ra) # 80003e8c <sched>
    p->chan = 0;
    80004278:	0a04b023          	sd	zero,160(s1)
    if (lk != &p->lock)
    8000427c:	b77d                	j	8000422a <sleep+0x64>

000000008000427e <wait_process>:
{
    8000427e:	711d                	addi	sp,sp,-96
    80004280:	ec86                	sd	ra,88(sp)
    80004282:	e8a2                	sd	s0,80(sp)
    80004284:	e4a6                	sd	s1,72(sp)
    80004286:	e0ca                	sd	s2,64(sp)
    80004288:	fc4e                	sd	s3,56(sp)
    8000428a:	f852                	sd	s4,48(sp)
    8000428c:	f456                	sd	s5,40(sp)
    8000428e:	f05a                	sd	s6,32(sp)
    80004290:	ec5e                	sd	s7,24(sp)
    80004292:	e862                	sd	s8,16(sp)
    80004294:	e466                	sd	s9,8(sp)
    80004296:	e06a                	sd	s10,0(sp)
    80004298:	1080                	addi	s0,sp,96
    8000429a:	8c2a                	mv	s8,a0
    struct proc *p = myproc();
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	85e080e7          	jalr	-1954(ra) # 80003afa <myproc>
        return -1;
    800042a4:	54fd                	li	s1,-1
    if (p == 0)
    800042a6:	e105                	bnez	a0,800042c6 <wait_process+0x48>
}
    800042a8:	8526                	mv	a0,s1
    800042aa:	60e6                	ld	ra,88(sp)
    800042ac:	6446                	ld	s0,80(sp)
    800042ae:	64a6                	ld	s1,72(sp)
    800042b0:	6906                	ld	s2,64(sp)
    800042b2:	79e2                	ld	s3,56(sp)
    800042b4:	7a42                	ld	s4,48(sp)
    800042b6:	7aa2                	ld	s5,40(sp)
    800042b8:	7b02                	ld	s6,32(sp)
    800042ba:	6be2                	ld	s7,24(sp)
    800042bc:	6c42                	ld	s8,16(sp)
    800042be:	6ca2                	ld	s9,8(sp)
    800042c0:	6d02                	ld	s10,0(sp)
    800042c2:	6125                	addi	sp,sp,96
    800042c4:	8082                	ret
    800042c6:	89aa                	mv	s3,a0
    acquire(&p->lock);
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	48e080e7          	jalr	1166(ra) # 80003756 <acquire>
        for (int i = 0; i < NPROC; i++)
    800042d0:	4c81                	li	s9,0
                if (child->state == ZOMBIE)
    800042d2:	4b15                	li	s6,5
                have_child = 1;
    800042d4:	4b85                	li	s7,1
        for (int i = 0; i < NPROC; i++)
    800042d6:	04000a93          	li	s5,64
    800042da:	0000c497          	auipc	s1,0xc
    800042de:	bce48493          	addi	s1,s1,-1074 # 8000fea8 <proc>
    800042e2:	8966                	mv	s2,s9
        int have_child = 0;
    800042e4:	8d66                	mv	s10,s9
    800042e6:	a095                	j	8000434a <wait_process+0xcc>
                    int pid = child->pid;
    800042e8:	00391793          	slli	a5,s2,0x3
    800042ec:	412787b3          	sub	a5,a5,s2
    800042f0:	0796                	slli	a5,a5,0x5
    800042f2:	0000c717          	auipc	a4,0xc
    800042f6:	bb670713          	addi	a4,a4,-1098 # 8000fea8 <proc>
    800042fa:	97ba                	add	a5,a5,a4
    800042fc:	4fc4                	lw	s1,28(a5)
                    if (status)
    800042fe:	000c0c63          	beqz	s8,80004316 <wait_process+0x98>
                        *status = child->exit_status;
    80004302:	00391793          	slli	a5,s2,0x3
    80004306:	412787b3          	sub	a5,a5,s2
    8000430a:	0796                	slli	a5,a5,0x5
    8000430c:	97ba                	add	a5,a5,a4
    8000430e:	0b07a783          	lw	a5,176(a5)
    80004312:	00fc2023          	sw	a5,0(s8)
                    free_proc_locked(child);
    80004316:	8552                	mv	a0,s4
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	75c080e7          	jalr	1884(ra) # 80003a74 <free_proc_locked>
                    release(&child->lock);
    80004320:	8552                	mv	a0,s4
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	4a4080e7          	jalr	1188(ra) # 800037c6 <release>
                    release(&p->lock);
    8000432a:	854e                	mv	a0,s3
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	49a080e7          	jalr	1178(ra) # 800037c6 <release>
                    return pid;
    80004334:	bf95                	j	800042a8 <wait_process+0x2a>
            release(&child->lock);
    80004336:	8552                	mv	a0,s4
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	48e080e7          	jalr	1166(ra) # 800037c6 <release>
        for (int i = 0; i < NPROC; i++)
    80004340:	2905                	addiw	s2,s2,1
    80004342:	0e048493          	addi	s1,s1,224
    80004346:	03590263          	beq	s2,s5,8000436a <wait_process+0xec>
            struct proc *child = &proc[i];
    8000434a:	8a26                	mv	s4,s1
            if (child == p)
    8000434c:	fe998ae3          	beq	s3,s1,80004340 <wait_process+0xc2>
            acquire(&child->lock);
    80004350:	8526                	mv	a0,s1
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	404080e7          	jalr	1028(ra) # 80003756 <acquire>
            if (child->parent == p)
    8000435a:	709c                	ld	a5,32(s1)
    8000435c:	fd379de3          	bne	a5,s3,80004336 <wait_process+0xb8>
                if (child->state == ZOMBIE)
    80004360:	4c9c                	lw	a5,24(s1)
    80004362:	f96783e3          	beq	a5,s6,800042e8 <wait_process+0x6a>
                have_child = 1;
    80004366:	8d5e                	mv	s10,s7
    80004368:	b7f9                	j	80004336 <wait_process+0xb8>
        if (!have_child)
    8000436a:	000d1963          	bnez	s10,8000437c <wait_process+0xfe>
            release(&p->lock);
    8000436e:	854e                	mv	a0,s3
    80004370:	fffff097          	auipc	ra,0xfffff
    80004374:	456080e7          	jalr	1110(ra) # 800037c6 <release>
            return -1;
    80004378:	54fd                	li	s1,-1
    8000437a:	b73d                	j	800042a8 <wait_process+0x2a>
        sleep(p, &p->lock);
    8000437c:	85ce                	mv	a1,s3
    8000437e:	854e                	mv	a0,s3
    80004380:	00000097          	auipc	ra,0x0
    80004384:	e46080e7          	jalr	-442(ra) # 800041c6 <sleep>
    {
    80004388:	bf89                	j	800042da <wait_process+0x5c>

000000008000438a <wakeup>:
    if (chan == 0)
    8000438a:	cd41                	beqz	a0,80004422 <wakeup+0x98>
{
    8000438c:	7139                	addi	sp,sp,-64
    8000438e:	fc06                	sd	ra,56(sp)
    80004390:	f822                	sd	s0,48(sp)
    80004392:	f426                	sd	s1,40(sp)
    80004394:	f04a                	sd	s2,32(sp)
    80004396:	ec4e                	sd	s3,24(sp)
    80004398:	e852                	sd	s4,16(sp)
    8000439a:	e456                	sd	s5,8(sp)
    8000439c:	e05a                	sd	s6,0(sp)
    8000439e:	0080                	addi	s0,sp,64
    800043a0:	8aaa                	mv	s5,a0
    800043a2:	0000c497          	auipc	s1,0xc
    800043a6:	b0648493          	addi	s1,s1,-1274 # 8000fea8 <proc>
    800043aa:	0000fa17          	auipc	s4,0xf
    800043ae:	2fea0a13          	addi	s4,s4,766 # 800136a8 <priority_lock>
        if (p->state == SLEEPING && p->chan == chan)
    800043b2:	4989                	li	s3,2
            p->state = RUNNABLE;
    800043b4:	4b0d                	li	s6,3
    800043b6:	a015                	j	800043da <wakeup+0x50>
        acquire(&p->lock);
    800043b8:	8526                	mv	a0,s1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	39c080e7          	jalr	924(ra) # 80003756 <acquire>
        if (p->state == SLEEPING && p->chan == chan)
    800043c2:	4c9c                	lw	a5,24(s1)
    800043c4:	03378d63          	beq	a5,s3,800043fe <wakeup+0x74>
        release(&p->lock);
    800043c8:	854a                	mv	a0,s2
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	3fc080e7          	jalr	1020(ra) # 800037c6 <release>
    for (int i = 0; i < NPROC; i++)
    800043d2:	0e048493          	addi	s1,s1,224
    800043d6:	03448c63          	beq	s1,s4,8000440e <wakeup+0x84>
        if (holding(&p->lock))
    800043da:	8926                	mv	s2,s1
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	34a080e7          	jalr	842(ra) # 80003728 <holding>
    800043e6:	d969                	beqz	a0,800043b8 <wakeup+0x2e>
            if (p->state == SLEEPING && p->chan == chan)
    800043e8:	4c9c                	lw	a5,24(s1)
    800043ea:	ff3794e3          	bne	a5,s3,800043d2 <wakeup+0x48>
    800043ee:	70dc                	ld	a5,160(s1)
    800043f0:	ff5791e3          	bne	a5,s5,800043d2 <wakeup+0x48>
                p->state = RUNNABLE;
    800043f4:	0164ac23          	sw	s6,24(s1)
                p->chan = 0;
    800043f8:	0a04b023          	sd	zero,160(s1)
    800043fc:	bfd9                	j	800043d2 <wakeup+0x48>
        if (p->state == SLEEPING && p->chan == chan)
    800043fe:	70dc                	ld	a5,160(s1)
    80004400:	fd5794e3          	bne	a5,s5,800043c8 <wakeup+0x3e>
            p->state = RUNNABLE;
    80004404:	0164ac23          	sw	s6,24(s1)
            p->chan = 0;
    80004408:	0a04b023          	sd	zero,160(s1)
    8000440c:	bf75                	j	800043c8 <wakeup+0x3e>
}
    8000440e:	70e2                	ld	ra,56(sp)
    80004410:	7442                	ld	s0,48(sp)
    80004412:	74a2                	ld	s1,40(sp)
    80004414:	7902                	ld	s2,32(sp)
    80004416:	69e2                	ld	s3,24(sp)
    80004418:	6a42                	ld	s4,16(sp)
    8000441a:	6aa2                	ld	s5,8(sp)
    8000441c:	6b02                	ld	s6,0(sp)
    8000441e:	6121                	addi	sp,sp,64
    80004420:	8082                	ret
    80004422:	8082                	ret

0000000080004424 <exit_process>:
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
    80004430:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	6c8080e7          	jalr	1736(ra) # 80003afa <myproc>
    if (p == 0)
    8000443a:	cd15                	beqz	a0,80004476 <exit_process+0x52>
    8000443c:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	318080e7          	jalr	792(ra) # 80003756 <acquire>
    p->exit_status = status;
    80004446:	0b24a823          	sw	s2,176(s1)
    p->state = ZOMBIE;
    8000444a:	4795                	li	a5,5
    8000444c:	cc9c                	sw	a5,24(s1)
    p->chan = 0;
    8000444e:	0a04b023          	sd	zero,160(s1)
    if (p->parent)
    80004452:	7088                	ld	a0,32(s1)
    80004454:	c509                	beqz	a0,8000445e <exit_process+0x3a>
        wakeup(p->parent);
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	f34080e7          	jalr	-204(ra) # 8000438a <wakeup>
    sched();
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	a2e080e7          	jalr	-1490(ra) # 80003e8c <sched>
    panic("zombie exit");
    80004466:	00008517          	auipc	a0,0x8
    8000446a:	0ea50513          	addi	a0,a0,234 # 8000c550 <digits+0x23a0>
    8000446e:	ffffe097          	auipc	ra,0xffffe
    80004472:	61e080e7          	jalr	1566(ra) # 80002a8c <panic>
        panic("exit_process without proc");
    80004476:	00008517          	auipc	a0,0x8
    8000447a:	0ba50513          	addi	a0,a0,186 # 8000c530 <digits+0x2380>
    8000447e:	ffffe097          	auipc	ra,0xffffe
    80004482:	60e080e7          	jalr	1550(ra) # 80002a8c <panic>

0000000080004486 <process_start>:
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	66a080e7          	jalr	1642(ra) # 80003afa <myproc>
    80004498:	84aa                	mv	s1,a0
    release(&p->lock); // 释放进程锁
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	32c080e7          	jalr	812(ra) # 800037c6 <release>
    intr_on();         // 启用中断
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	190080e7          	jalr	400(ra) # 80003632 <intr_on>
    if (p->entry)
    800044aa:	74dc                	ld	a5,168(s1)
    800044ac:	c391                	beqz	a5,800044b0 <process_start+0x2a>
        p->entry(); // 执行进程入口函数
    800044ae:	9782                	jalr	a5
    exit_process(0);
    800044b0:	4501                	li	a0,0
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	f72080e7          	jalr	-142(ra) # 80004424 <exit_process>

00000000800044ba <sys_setpriority>:

// 设置进程优先级
int sys_setpriority(int pid, int priority)
{
    // 验证优先级范围
    if (priority < PRIORITY_MIN || priority > PRIORITY_MAX)
    800044ba:	fff5871b          	addiw	a4,a1,-1
    800044be:	47a5                	li	a5,9
    800044c0:	04e7e463          	bltu	a5,a4,80004508 <sys_setpriority+0x4e>
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	1000                	addi	s0,sp,32
    800044ce:	84ae                	mv	s1,a1
    {
        return -1;
    }

    struct proc *p = find_proc_by_pid(pid);
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	53a080e7          	jalr	1338(ra) # 80003a0a <find_proc_by_pid>
    if (p == 0)
    800044d8:	c915                	beqz	a0,8000450c <sys_setpriority+0x52>
    {
        return -1; // 进程不存在
    }

    p->priority = clamp_priority(priority);
    800044da:	87a6                	mv	a5,s1
    800044dc:	4729                	li	a4,10
    800044de:	00975363          	bge	a4,s1,800044e4 <sys_setpriority+0x2a>
    800044e2:	47a9                	li	a5,10
    800044e4:	873e                	mv	a4,a5
    800044e6:	2781                	sext.w	a5,a5
    800044e8:	00f05e63          	blez	a5,80004504 <sys_setpriority+0x4a>
    800044ec:	0ae52c23          	sw	a4,184(a0)
    release(&p->lock);
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	2d6080e7          	jalr	726(ra) # 800037c6 <release>
    return 0;
    800044f8:	4501                	li	a0,0
}
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	64a2                	ld	s1,8(sp)
    80004500:	6105                	addi	sp,sp,32
    80004502:	8082                	ret
    p->priority = clamp_priority(priority);
    80004504:	4705                	li	a4,1
    80004506:	b7dd                	j	800044ec <sys_setpriority+0x32>
        return -1;
    80004508:	557d                	li	a0,-1
}
    8000450a:	8082                	ret
        return -1; // 进程不存在
    8000450c:	557d                	li	a0,-1
    8000450e:	b7f5                	j	800044fa <sys_setpriority+0x40>

0000000080004510 <sys_getpriority>:

// 获取进程优先级
int sys_getpriority(int pid)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	1000                	addi	s0,sp,32
    struct proc *p = find_proc_by_pid(pid);
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	4f0080e7          	jalr	1264(ra) # 80003a0a <find_proc_by_pid>
    if (p == 0)
    80004522:	cd09                	beqz	a0,8000453c <sys_getpriority+0x2c>
    {
        return -1; // 进程不存在
    }

    int priority = p->priority;
    80004524:	0b852483          	lw	s1,184(a0)
    release(&p->lock);
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	29e080e7          	jalr	670(ra) # 800037c6 <release>
    return priority;
}
    80004530:	8526                	mv	a0,s1
    80004532:	60e2                	ld	ra,24(sp)
    80004534:	6442                	ld	s0,16(sp)
    80004536:	64a2                	ld	s1,8(sp)
    80004538:	6105                	addi	sp,sp,32
    8000453a:	8082                	ret
        return -1; // 进程不存在
    8000453c:	54fd                	li	s1,-1
    8000453e:	bfcd                	j	80004530 <sys_getpriority+0x20>

0000000080004540 <assert>:
// ==================== 测试工具函数 ====================

static int test_failures = 0;

static void assert(int condition, const char *msg)
{
    80004540:	1141                	addi	sp,sp,-16
    80004542:	e406                	sd	ra,8(sp)
    80004544:	e022                	sd	s0,0(sp)
    80004546:	0800                	addi	s0,sp,16
    if (!condition)
    80004548:	e505                	bnez	a0,80004570 <assert+0x30>
    {
        printf("[ASSERT FAIL] %s\n", msg);
    8000454a:	00008517          	auipc	a0,0x8
    8000454e:	01650513          	addi	a0,a0,22 # 8000c560 <digits+0x23b0>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	fb2080e7          	jalr	-78(ra) # 80000504 <printf>
        test_failures++;
    8000455a:	0000b717          	auipc	a4,0xb
    8000455e:	35e70713          	addi	a4,a4,862 # 8000f8b8 <test_failures>
    80004562:	431c                	lw	a5,0(a4)
    80004564:	2785                	addiw	a5,a5,1
    80004566:	c31c                	sw	a5,0(a4)
    }
    else
    {
        printf("[ASSERT PASS] %s\n", msg);
    }
}
    80004568:	60a2                	ld	ra,8(sp)
    8000456a:	6402                	ld	s0,0(sp)
    8000456c:	0141                	addi	sp,sp,16
    8000456e:	8082                	ret
        printf("[ASSERT PASS] %s\n", msg);
    80004570:	00008517          	auipc	a0,0x8
    80004574:	00850513          	addi	a0,a0,8 # 8000c578 <digits+0x23c8>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	f8c080e7          	jalr	-116(ra) # 80000504 <printf>
}
    80004580:	b7e5                	j	80004568 <assert+0x28>

0000000080004582 <boundary_task>:
}

// ==================== 优先级边界测试 ====================

static void boundary_task(void)
{
    80004582:	1141                	addi	sp,sp,-16
    80004584:	e406                	sd	ra,8(sp)
    80004586:	e022                	sd	s0,0(sp)
    80004588:	0800                	addi	s0,sp,16
    exit_process(0);
    8000458a:	4501                	li	a0,0
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	e98080e7          	jalr	-360(ra) # 80004424 <exit_process>

0000000080004594 <t1_low_priority_task>:
    t1_high_completed = 1;
    exit_process(0);
}

static void t1_low_priority_task(void)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000459e:	fffff097          	auipc	ra,0xfffff
    800045a2:	55c080e7          	jalr	1372(ra) # 80003afa <myproc>
    800045a6:	84aa                	mv	s1,a0
    printf("[T1-low] PID %d (priority %d) starting...\n", p->pid, p->priority);
    800045a8:	0b852603          	lw	a2,184(a0)
    800045ac:	4d4c                	lw	a1,28(a0)
    800045ae:	00008517          	auipc	a0,0x8
    800045b2:	fe250513          	addi	a0,a0,-30 # 8000c590 <digits+0x23e0>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f4e080e7          	jalr	-178(ra) # 80000504 <printf>
    t1_low_started = 1;
    800045be:	4785                	li	a5,1
    800045c0:	0000b717          	auipc	a4,0xb
    800045c4:	2ef72623          	sw	a5,748(a4) # 8000f8ac <t1_low_started>

    // 检查高优先级是否已经完成
    if (t1_high_completed)
    800045c8:	0000b797          	auipc	a5,0xb
    800045cc:	2e87a783          	lw	a5,744(a5) # 8000f8b0 <t1_high_completed>
    800045d0:	c79d                	beqz	a5,800045fe <t1_low_priority_task+0x6a>
    {
        printf("✓ [T1-low] High priority task completed before low priority started\n");
    800045d2:	00008517          	auipc	a0,0x8
    800045d6:	fee50513          	addi	a0,a0,-18 # 8000c5c0 <digits+0x2410>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	f2a080e7          	jalr	-214(ra) # 80000504 <printf>
    else
    {
        printf("✗ [T1-low] Low priority task started before high priority completed\n");
    }

    printf("[T1-low] PID %d exiting\n", p->pid);
    800045e2:	4ccc                	lw	a1,28(s1)
    800045e4:	00008517          	auipc	a0,0x8
    800045e8:	06c50513          	addi	a0,a0,108 # 8000c650 <digits+0x24a0>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	f18080e7          	jalr	-232(ra) # 80000504 <printf>
    exit_process(0);
    800045f4:	4501                	li	a0,0
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	e2e080e7          	jalr	-466(ra) # 80004424 <exit_process>
        printf("✗ [T1-low] Low priority task started before high priority completed\n");
    800045fe:	00008517          	auipc	a0,0x8
    80004602:	00a50513          	addi	a0,a0,10 # 8000c608 <digits+0x2458>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	efe080e7          	jalr	-258(ra) # 80000504 <printf>
    8000460e:	bfd1                	j	800045e2 <t1_low_priority_task+0x4e>

0000000080004610 <t1_high_priority_task>:
{
    80004610:	7179                	addi	sp,sp,-48
    80004612:	f406                	sd	ra,40(sp)
    80004614:	f022                	sd	s0,32(sp)
    80004616:	ec26                	sd	s1,24(sp)
    80004618:	e84a                	sd	s2,16(sp)
    8000461a:	e44e                	sd	s3,8(sp)
    8000461c:	e052                	sd	s4,0(sp)
    8000461e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	4da080e7          	jalr	1242(ra) # 80003afa <myproc>
    80004628:	892a                	mv	s2,a0
    printf("[T1-high] PID %d (priority %d) starting...\n", p->pid, p->priority);
    8000462a:	0b852603          	lw	a2,184(a0)
    8000462e:	4d4c                	lw	a1,28(a0)
    80004630:	00008517          	auipc	a0,0x8
    80004634:	04050513          	addi	a0,a0,64 # 8000c670 <digits+0x24c0>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	ecc080e7          	jalr	-308(ra) # 80000504 <printf>
    for (int i = 0; i < 5; i++)
    80004640:	4481                	li	s1,0
        printf("[T1-high] PID %d working (iteration %d)\n", p->pid, i);
    80004642:	00008a17          	auipc	s4,0x8
    80004646:	05ea0a13          	addi	s4,s4,94 # 8000c6a0 <digits+0x24f0>
    for (int i = 0; i < 5; i++)
    8000464a:	4995                	li	s3,5
        printf("[T1-high] PID %d working (iteration %d)\n", p->pid, i);
    8000464c:	8626                	mv	a2,s1
    8000464e:	01c92583          	lw	a1,28(s2)
    80004652:	8552                	mv	a0,s4
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	eb0080e7          	jalr	-336(ra) # 80000504 <printf>
        ksleep(1);
    8000465c:	4505                	li	a0,1
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	b2c080e7          	jalr	-1236(ra) # 8000418a <ksleep>
    for (int i = 0; i < 5; i++)
    80004666:	2485                	addiw	s1,s1,1
    80004668:	ff3492e3          	bne	s1,s3,8000464c <t1_high_priority_task+0x3c>
    printf("[T1-high] PID %d completed\n", p->pid);
    8000466c:	01c92583          	lw	a1,28(s2)
    80004670:	00008517          	auipc	a0,0x8
    80004674:	06050513          	addi	a0,a0,96 # 8000c6d0 <digits+0x2520>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	e8c080e7          	jalr	-372(ra) # 80000504 <printf>
    t1_high_completed = 1;
    80004680:	4785                	li	a5,1
    80004682:	0000b717          	auipc	a4,0xb
    80004686:	22f72723          	sw	a5,558(a4) # 8000f8b0 <t1_high_completed>
    exit_process(0);
    8000468a:	4501                	li	a0,0
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	d98080e7          	jalr	-616(ra) # 80004424 <exit_process>

0000000080004694 <t3_mixed_task>:

static int t3_completed_count = 0;
static int t3_total_tasks = 0;

static void t3_mixed_task(void)
{
    80004694:	7179                	addi	sp,sp,-48
    80004696:	f406                	sd	ra,40(sp)
    80004698:	f022                	sd	s0,32(sp)
    8000469a:	ec26                	sd	s1,24(sp)
    8000469c:	e84a                	sd	s2,16(sp)
    8000469e:	e44e                	sd	s3,8(sp)
    800046a0:	e052                	sd	s4,0(sp)
    800046a2:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800046a4:	fffff097          	auipc	ra,0xfffff
    800046a8:	456080e7          	jalr	1110(ra) # 80003afa <myproc>
    800046ac:	892a                	mv	s2,a0
    printf("[T3] PID %d (priority %d) starting...\n", p->pid, p->priority);
    800046ae:	0b852603          	lw	a2,184(a0)
    800046b2:	4d4c                	lw	a1,28(a0)
    800046b4:	00008517          	auipc	a0,0x8
    800046b8:	03c50513          	addi	a0,a0,60 # 8000c6f0 <digits+0x2540>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	e48080e7          	jalr	-440(ra) # 80000504 <printf>

    // 执行一些工作
    for (int i = 0; i < 3; i++)
    800046c4:	4481                	li	s1,0
    {
        printf("[T3] PID %d working (iteration %d, priority %d)\n", p->pid, i, p->priority);
    800046c6:	00008a17          	auipc	s4,0x8
    800046ca:	052a0a13          	addi	s4,s4,82 # 8000c718 <digits+0x2568>
    for (int i = 0; i < 3; i++)
    800046ce:	498d                	li	s3,3
        printf("[T3] PID %d working (iteration %d, priority %d)\n", p->pid, i, p->priority);
    800046d0:	0b892683          	lw	a3,184(s2)
    800046d4:	8626                	mv	a2,s1
    800046d6:	01c92583          	lw	a1,28(s2)
    800046da:	8552                	mv	a0,s4
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	e28080e7          	jalr	-472(ra) # 80000504 <printf>
        ksleep(2);
    800046e4:	4509                	li	a0,2
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	aa4080e7          	jalr	-1372(ra) # 8000418a <ksleep>
    for (int i = 0; i < 3; i++)
    800046ee:	2485                	addiw	s1,s1,1
    800046f0:	ff3490e3          	bne	s1,s3,800046d0 <t3_mixed_task+0x3c>
    }

    printf("[T3] PID %d completed\n", p->pid);
    800046f4:	01c92583          	lw	a1,28(s2)
    800046f8:	00008517          	auipc	a0,0x8
    800046fc:	05850513          	addi	a0,a0,88 # 8000c750 <digits+0x25a0>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	e04080e7          	jalr	-508(ra) # 80000504 <printf>
    t3_completed_count++;
    80004708:	0000b717          	auipc	a4,0xb
    8000470c:	1a070713          	addi	a4,a4,416 # 8000f8a8 <t3_completed_count>
    80004710:	431c                	lw	a5,0(a4)
    80004712:	2785                	addiw	a5,a5,1
    80004714:	c31c                	sw	a5,0(a4)
    exit_process(0);
    80004716:	4501                	li	a0,0
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	d0c080e7          	jalr	-756(ra) # 80004424 <exit_process>

0000000080004720 <aging_test_task>:
}

// ==================== 系统调用和 Aging 测试 ====================

static void aging_test_task(void)
{
    80004720:	7179                	addi	sp,sp,-48
    80004722:	f406                	sd	ra,40(sp)
    80004724:	f022                	sd	s0,32(sp)
    80004726:	ec26                	sd	s1,24(sp)
    80004728:	e84a                	sd	s2,16(sp)
    8000472a:	e44e                	sd	s3,8(sp)
    8000472c:	e052                	sd	s4,0(sp)
    8000472e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	3ca080e7          	jalr	970(ra) # 80003afa <myproc>
    80004738:	892a                	mv	s2,a0
    printf("[aging_test] PID %d started with priority %d\n", p->pid, p->priority);
    8000473a:	0b852603          	lw	a2,184(a0)
    8000473e:	4d4c                	lw	a1,28(a0)
    80004740:	00008517          	auipc	a0,0x8
    80004744:	02850513          	addi	a0,a0,40 # 8000c768 <digits+0x25b8>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	dbc080e7          	jalr	-580(ra) # 80000504 <printf>

    // 执行一些工作
    for (int i = 0; i < 5; i++)
    80004750:	4481                	li	s1,0
    {
        printf("[aging_test] PID %d working (iteration %d)\n", p->pid, i);
    80004752:	00008a17          	auipc	s4,0x8
    80004756:	046a0a13          	addi	s4,s4,70 # 8000c798 <digits+0x25e8>
    for (int i = 0; i < 5; i++)
    8000475a:	4995                	li	s3,5
        printf("[aging_test] PID %d working (iteration %d)\n", p->pid, i);
    8000475c:	8626                	mv	a2,s1
    8000475e:	01c92583          	lw	a1,28(s2)
    80004762:	8552                	mv	a0,s4
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	da0080e7          	jalr	-608(ra) # 80000504 <printf>
        ksleep(2);
    8000476c:	4509                	li	a0,2
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	a1c080e7          	jalr	-1508(ra) # 8000418a <ksleep>
    for (int i = 0; i < 5; i++)
    80004776:	2485                	addiw	s1,s1,1
    80004778:	ff3492e3          	bne	s1,s3,8000475c <aging_test_task+0x3c>
    }

    printf("[aging_test] PID %d exiting\n", p->pid);
    8000477c:	01c92583          	lw	a1,28(s2)
    80004780:	00008517          	auipc	a0,0x8
    80004784:	04850513          	addi	a0,a0,72 # 8000c7c8 <digits+0x2618>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	d7c080e7          	jalr	-644(ra) # 80000504 <printf>
    exit_process(0);
    80004790:	4501                	li	a0,0
    80004792:	00000097          	auipc	ra,0x0
    80004796:	c92080e7          	jalr	-878(ra) # 80004424 <exit_process>

000000008000479a <mlfq_cpu_intensive_task>:
static volatile int mlfq_int_final_priority = -1;
static volatile int mlfq_cpu_intensive_count = 0;
static volatile int mlfq_interactive_count = 0;

static void mlfq_cpu_intensive_task(void)
{
    8000479a:	7119                	addi	sp,sp,-128
    8000479c:	fc86                	sd	ra,120(sp)
    8000479e:	f8a2                	sd	s0,112(sp)
    800047a0:	f4a6                	sd	s1,104(sp)
    800047a2:	f0ca                	sd	s2,96(sp)
    800047a4:	ecce                	sd	s3,88(sp)
    800047a6:	e8d2                	sd	s4,80(sp)
    800047a8:	e4d6                	sd	s5,72(sp)
    800047aa:	e0da                	sd	s6,64(sp)
    800047ac:	fc5e                	sd	s7,56(sp)
    800047ae:	f862                	sd	s8,48(sp)
    800047b0:	f466                	sd	s9,40(sp)
    800047b2:	f06a                	sd	s10,32(sp)
    800047b4:	ec6e                	sd	s11,24(sp)
    800047b6:	0100                	addi	s0,sp,128
    struct proc *p = myproc();
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	342080e7          	jalr	834(ra) # 80003afa <myproc>
    800047c0:	84aa                	mv	s1,a0
    mlfq_cpu_initial_priority = p->priority;
    800047c2:	0b852603          	lw	a2,184(a0)
    800047c6:	0000b797          	auipc	a5,0xb
    800047ca:	06c7a923          	sw	a2,114(a5) # 8000f838 <mlfq_cpu_initial_priority>
    printf("[MLFQ-CPU] PID %d (priority %d) starting CPU-intensive work...\n", p->pid, p->priority);
    800047ce:	4d4c                	lw	a1,28(a0)
    800047d0:	00008517          	auipc	a0,0x8
    800047d4:	01850513          	addi	a0,a0,24 # 8000c7e8 <digits+0x2638>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	d2c080e7          	jalr	-724(ra) # 80000504 <printf>
    printf("[MLFQ-CPU] Time slice: %d, need %d consecutive slices to trigger demotion\n",
    800047e0:	460d                	li	a2,3
    800047e2:	0c44a583          	lw	a1,196(s1)
    800047e6:	00008517          	auipc	a0,0x8
    800047ea:	04250513          	addi	a0,a0,66 # 8000c828 <digits+0x2678>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d16080e7          	jalr	-746(ra) # 80000504 <printf>
           p->time_slice, CPU_INTENSIVE_THRESHOLD);
    // printf("[MLFQ-CPU] Goal: Observe multiple demotions (priority %d -> ... -> lower)\n", p->priority);

    // CPU密集型任务：连续执行，不主动让出CPU（除非时间片用完）
    // 使用 volatile 和复杂计算，防止编译器优化
    volatile int dummy = 0;
    800047f6:	f8042623          	sw	zero,-116(s0)
    volatile int checksum = 0;
    800047fa:	f8042423          	sw	zero,-120(s0)
    int iteration = 0;
    int last_priority = p->priority;
    800047fe:	0b84ac03          	lw	s8,184(s1)
    int last_time_slice = p->time_slice;
    80004802:	0c44ad03          	lw	s10,196(s1)
    int last_consecutive_slices = p->consecutive_slices;
    80004806:	0cc4ac83          	lw	s9,204(s1)
    int demotion_count = 0; // 记录降级次数
    8000480a:	4b01                	li	s6,0
    int iteration = 0;
    8000480c:	4a81                	li	s5,0
        // CPU密集型工作：执行大量复杂计算，防止编译器优化
        // 使用 volatile 变量和复杂运算，确保编译器不会优化掉这些计算
        for (int i = 0; i < 100000; i++)
        {
            // 复杂计算，使用 volatile 防止优化
            dummy = (dummy * 3 + i) % 1000000;
    8000480e:	000f49b7          	lui	s3,0xf4
    80004812:	2409899b          	addiw	s3,s3,576
            {
                dummy = (dummy << 1) | (dummy >> 31); // 位运算
                checksum = checksum * 2 - checksum / 2;
            }
            // 使用除法，增加计算复杂度
            if (i % 100 == 0 && dummy != 0)
    80004816:	06400493          	li	s1,100
        for (int i = 0; i < 100000; i++)
    8000481a:	6961                	lui	s2,0x18
    8000481c:	6a090913          	addi	s2,s2,1696 # 186a0 <_entry-0x7ffe7960>
                       p->pid, last_consecutive_slices, p->consecutive_slices, p->priority, CPU_INTENSIVE_THRESHOLD);
                last_consecutive_slices = p->consecutive_slices;
            }

            // 检查优先级变化（这是最重要的检查）
            mlfq_cpu_final_priority = p->priority;
    80004820:	0000bb97          	auipc	s7,0xb
    80004824:	014b8b93          	addi	s7,s7,20 # 8000f834 <mlfq_cpu_final_priority>
                printf("[MLFQ-CPU] PID %d observed %d demotions, completing...\n", p->pid, demotion_count);
                break;
            }

            // 安全退出条件：如果迭代次数过多（防止死循环）
            if (iteration >= 500000)
    80004828:	0007adb7          	lui	s11,0x7a
    8000482c:	11fd8d93          	addi	s11,s11,287 # 7a11f <_entry-0x7ff85ee1>
    80004830:	a0dd                	j	80004916 <mlfq_cpu_intensive_task+0x17c>
        for (int i = 0; i < 100000; i++)
    80004832:	2705                	addiw	a4,a4,1
    80004834:	269d                	addiw	a3,a3,7
    80004836:	09270563          	beq	a4,s2,800048c0 <mlfq_cpu_intensive_task+0x126>
            dummy = (dummy * 3 + i) % 1000000;
    8000483a:	f8c42583          	lw	a1,-116(s0)
    8000483e:	0015979b          	slliw	a5,a1,0x1
    80004842:	9fad                	addw	a5,a5,a1
    80004844:	9fb9                	addw	a5,a5,a4
    80004846:	0337e7bb          	remw	a5,a5,s3
    8000484a:	f8f42623          	sw	a5,-116(s0)
            checksum = (checksum + dummy) ^ (i * 7);
    8000484e:	f8842783          	lw	a5,-120(s0)
    80004852:	f8c42583          	lw	a1,-116(s0)
    80004856:	9fad                	addw	a5,a5,a1
    80004858:	8fb5                	xor	a5,a5,a3
    8000485a:	2781                	sext.w	a5,a5
    8000485c:	f8f42423          	sw	a5,-120(s0)
            if (i % 50 == 0)
    80004860:	02c767bb          	remw	a5,a4,a2
    80004864:	eb9d                	bnez	a5,8000489a <mlfq_cpu_intensive_task+0x100>
                dummy = (dummy << 1) | (dummy >> 31); // 位运算
    80004866:	f8c42783          	lw	a5,-116(s0)
    8000486a:	f8c42583          	lw	a1,-116(s0)
    8000486e:	0017979b          	slliw	a5,a5,0x1
    80004872:	41f5d59b          	sraiw	a1,a1,0x1f
    80004876:	8fcd                	or	a5,a5,a1
    80004878:	2781                	sext.w	a5,a5
    8000487a:	f8f42623          	sw	a5,-116(s0)
                checksum = checksum * 2 - checksum / 2;
    8000487e:	f8842783          	lw	a5,-120(s0)
    80004882:	f8842503          	lw	a0,-120(s0)
    80004886:	0017979b          	slliw	a5,a5,0x1
    8000488a:	01f5559b          	srliw	a1,a0,0x1f
    8000488e:	9da9                	addw	a1,a1,a0
    80004890:	4015d59b          	sraiw	a1,a1,0x1
    80004894:	9f8d                	subw	a5,a5,a1
    80004896:	f8f42423          	sw	a5,-120(s0)
            if (i % 100 == 0 && dummy != 0)
    8000489a:	029767bb          	remw	a5,a4,s1
    8000489e:	fbd1                	bnez	a5,80004832 <mlfq_cpu_intensive_task+0x98>
    800048a0:	f8c42783          	lw	a5,-116(s0)
    800048a4:	2781                	sext.w	a5,a5
    800048a6:	d7d1                	beqz	a5,80004832 <mlfq_cpu_intensive_task+0x98>
                checksum = checksum / (dummy % 100 + 1);
    800048a8:	f8842583          	lw	a1,-120(s0)
    800048ac:	f8c42783          	lw	a5,-116(s0)
    800048b0:	0297e7bb          	remw	a5,a5,s1
    800048b4:	2785                	addiw	a5,a5,1
    800048b6:	02f5c7bb          	divw	a5,a1,a5
    800048ba:	f8f42423          	sw	a5,-120(s0)
    800048be:	bf95                	j	80004832 <mlfq_cpu_intensive_task+0x98>
        iteration++;
    800048c0:	001a879b          	addiw	a5,s5,1
    800048c4:	00078a9b          	sext.w	s5,a5
        if (iteration % 200 == 0)
    800048c8:	0c800713          	li	a4,200
    800048cc:	02e7e7bb          	remw	a5,a5,a4
    800048d0:	e3b9                	bnez	a5,80004916 <mlfq_cpu_intensive_task+0x17c>
            p = myproc(); // 重新获取进程指针，因为可能被重新调度
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	228080e7          	jalr	552(ra) # 80003afa <myproc>
    800048da:	8a2a                	mv	s4,a0
            if (p->time_slice > last_time_slice)
    800048dc:	0c452683          	lw	a3,196(a0)
    800048e0:	04dd4063          	blt	s10,a3,80004920 <mlfq_cpu_intensive_task+0x186>
            if (p->consecutive_slices > last_consecutive_slices)
    800048e4:	0cca2683          	lw	a3,204(s4)
    800048e8:	04dccd63          	blt	s9,a3,80004942 <mlfq_cpu_intensive_task+0x1a8>
            mlfq_cpu_final_priority = p->priority;
    800048ec:	0b8a2783          	lw	a5,184(s4)
    800048f0:	00fba023          	sw	a5,0(s7)
            if (mlfq_cpu_final_priority < last_priority)
    800048f4:	000ba783          	lw	a5,0(s7)
    800048f8:	2781                	sext.w	a5,a5
    800048fa:	0787c563          	blt	a5,s8,80004964 <mlfq_cpu_intensive_task+0x1ca>
            if (p->consecutive_slices >= CPU_INTENSIVE_THRESHOLD + 2 && demotion_count > 0)
    800048fe:	0cca2603          	lw	a2,204(s4)
    80004902:	4791                	li	a5,4
    80004904:	00c7d463          	bge	a5,a2,8000490c <mlfq_cpu_intensive_task+0x172>
    80004908:	0d604163          	bgtz	s6,800049ca <mlfq_cpu_intensive_task+0x230>
            if (demotion_count >= 2)
    8000490c:	4785                	li	a5,1
    8000490e:	0d67ca63          	blt	a5,s6,800049e2 <mlfq_cpu_intensive_task+0x248>
            if (iteration >= 500000)
    80004912:	155dc163          	blt	s11,s5,80004a54 <mlfq_cpu_intensive_task+0x2ba>
    int iteration = 0;
    80004916:	4681                	li	a3,0
        for (int i = 0; i < 100000; i++)
    80004918:	4701                	li	a4,0
            if (i % 50 == 0)
    8000491a:	03200613          	li	a2,50
    8000491e:	bf31                	j	8000483a <mlfq_cpu_intensive_task+0xa0>
                printf("[MLFQ-CPU] PID %d time slice replenished: %d -> %d (priority: %d, consecutive: %d)\n",
    80004920:	0cc52783          	lw	a5,204(a0)
    80004924:	0b852703          	lw	a4,184(a0)
    80004928:	866a                	mv	a2,s10
    8000492a:	4d4c                	lw	a1,28(a0)
    8000492c:	00008517          	auipc	a0,0x8
    80004930:	f4c50513          	addi	a0,a0,-180 # 8000c878 <digits+0x26c8>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	bd0080e7          	jalr	-1072(ra) # 80000504 <printf>
                last_time_slice = p->time_slice;
    8000493c:	0c4a2d03          	lw	s10,196(s4)
    80004940:	b755                	j	800048e4 <mlfq_cpu_intensive_task+0x14a>
                printf("[MLFQ-CPU] PID %d consecutive slices: %d -> %d (priority: %d, need %d for demotion)\n",
    80004942:	478d                	li	a5,3
    80004944:	0b8a2703          	lw	a4,184(s4)
    80004948:	8666                	mv	a2,s9
    8000494a:	01ca2583          	lw	a1,28(s4)
    8000494e:	00008517          	auipc	a0,0x8
    80004952:	f8250513          	addi	a0,a0,-126 # 8000c8d0 <digits+0x2720>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	bae080e7          	jalr	-1106(ra) # 80000504 <printf>
                last_consecutive_slices = p->consecutive_slices;
    8000495e:	0cca2c83          	lw	s9,204(s4)
    80004962:	b769                	j	800048ec <mlfq_cpu_intensive_task+0x152>
                demotion_count++;
    80004964:	2b05                	addiw	s6,s6,1
                printf("[MLFQ-CPU] *** DEMOTION #%d *** PID %d priority: %d -> %d (iteration %d, consecutive_slices: %d)\n",
    80004966:	000ba703          	lw	a4,0(s7)
    8000496a:	0cca2803          	lw	a6,204(s4)
    8000496e:	87d6                	mv	a5,s5
    80004970:	2701                	sext.w	a4,a4
    80004972:	86e2                	mv	a3,s8
    80004974:	01ca2603          	lw	a2,28(s4)
    80004978:	85da                	mv	a1,s6
    8000497a:	00008517          	auipc	a0,0x8
    8000497e:	fae50513          	addi	a0,a0,-82 # 8000c928 <digits+0x2778>
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	b82080e7          	jalr	-1150(ra) # 80000504 <printf>
                last_priority = mlfq_cpu_final_priority;
    8000498a:	000bac03          	lw	s8,0(s7)
    8000498e:	2c01                	sext.w	s8,s8
                if (mlfq_cpu_final_priority <= PRIORITY_MIN)
    80004990:	000ba783          	lw	a5,0(s7)
    80004994:	2781                	sext.w	a5,a5
    80004996:	4705                	li	a4,1
    80004998:	00f75d63          	bge	a4,a5,800049b2 <mlfq_cpu_intensive_task+0x218>
                printf("[MLFQ-CPU] PID %d continuing to observe more demotions...\n", p->pid);
    8000499c:	01ca2583          	lw	a1,28(s4)
    800049a0:	00008517          	auipc	a0,0x8
    800049a4:	03050513          	addi	a0,a0,48 # 8000c9d0 <digits+0x2820>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	b5c080e7          	jalr	-1188(ra) # 80000504 <printf>
    800049b0:	b7b9                	j	800048fe <mlfq_cpu_intensive_task+0x164>
                    printf("[MLFQ-CPU] PID %d reached minimum priority %d, completing...\n",
    800049b2:	4605                	li	a2,1
    800049b4:	01ca2583          	lw	a1,28(s4)
    800049b8:	00008517          	auipc	a0,0x8
    800049bc:	fd850513          	addi	a0,a0,-40 # 8000c990 <digits+0x27e0>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	b44080e7          	jalr	-1212(ra) # 80000504 <printf>
                    break;
    800049c8:	a0d1                	j	80004a8c <mlfq_cpu_intensive_task+0x2f2>
                printf("[MLFQ-CPU] PID %d used %d consecutive slices, observed %d demotion(s), completing...\n",
    800049ca:	86da                	mv	a3,s6
    800049cc:	01ca2583          	lw	a1,28(s4)
    800049d0:	00008517          	auipc	a0,0x8
    800049d4:	04050513          	addi	a0,a0,64 # 8000ca10 <digits+0x2860>
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	b2c080e7          	jalr	-1236(ra) # 80000504 <printf>
                break;
    800049e0:	a821                	j	800049f8 <mlfq_cpu_intensive_task+0x25e>
                printf("[MLFQ-CPU] PID %d observed %d demotions, completing...\n", p->pid, demotion_count);
    800049e2:	865a                	mv	a2,s6
    800049e4:	01ca2583          	lw	a1,28(s4)
    800049e8:	00008517          	auipc	a0,0x8
    800049ec:	08050513          	addi	a0,a0,128 # 8000ca68 <digits+0x28b8>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b14080e7          	jalr	-1260(ra) # 80000504 <printf>
                break;
            }
        }
    }

    p = myproc();
    800049f8:	fffff097          	auipc	ra,0xfffff
    800049fc:	102080e7          	jalr	258(ra) # 80003afa <myproc>
    80004a00:	84aa                	mv	s1,a0
    mlfq_cpu_final_priority = p->priority;
    80004a02:	0b852783          	lw	a5,184(a0)
    80004a06:	0000b717          	auipc	a4,0xb
    80004a0a:	e2f72723          	sw	a5,-466(a4) # 8000f834 <mlfq_cpu_final_priority>
    printf("[MLFQ-CPU] PID %d completed after %d iterations\n", p->pid, iteration);
    80004a0e:	8656                	mv	a2,s5
    80004a10:	4d4c                	lw	a1,28(a0)
    80004a12:	00008517          	auipc	a0,0x8
    80004a16:	12650513          	addi	a0,a0,294 # 8000cb38 <digits+0x2988>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	aea080e7          	jalr	-1302(ra) # 80000504 <printf>
    printf("[MLFQ-CPU] Priority progression: %d", mlfq_cpu_initial_priority);
    80004a22:	0000b597          	auipc	a1,0xb
    80004a26:	e165a583          	lw	a1,-490(a1) # 8000f838 <mlfq_cpu_initial_priority>
    80004a2a:	00008517          	auipc	a0,0x8
    80004a2e:	14650513          	addi	a0,a0,326 # 8000cb70 <digits+0x29c0>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	ad2080e7          	jalr	-1326(ra) # 80000504 <printf>
    if (demotion_count > 0)
    {
        printf(" -> %d", mlfq_cpu_final_priority);
    80004a3a:	0000b597          	auipc	a1,0xb
    80004a3e:	dfa5a583          	lw	a1,-518(a1) # 8000f834 <mlfq_cpu_final_priority>
    80004a42:	00008517          	auipc	a0,0x8
    80004a46:	15650513          	addi	a0,a0,342 # 8000cb98 <digits+0x29e8>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	aba080e7          	jalr	-1350(ra) # 80000504 <printf>
    80004a52:	a041                	j	80004ad2 <mlfq_cpu_intensive_task+0x338>
                printf("[MLFQ-CPU] PID %d reached max iterations (%d), completing...\n", p->pid, iteration);
    80004a54:	8656                	mv	a2,s5
    80004a56:	01ca2583          	lw	a1,28(s4)
    80004a5a:	00008517          	auipc	a0,0x8
    80004a5e:	04650513          	addi	a0,a0,70 # 8000caa0 <digits+0x28f0>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	aa2080e7          	jalr	-1374(ra) # 80000504 <printf>
                printf("[MLFQ-CPU] Final state: priority %d -> %d, consecutive_slices: %d, demotions: %d\n",
    80004a6a:	875a                	mv	a4,s6
    80004a6c:	0cca2683          	lw	a3,204(s4)
    80004a70:	0b8a2603          	lw	a2,184(s4)
    80004a74:	0000b597          	auipc	a1,0xb
    80004a78:	dc45a583          	lw	a1,-572(a1) # 8000f838 <mlfq_cpu_initial_priority>
    80004a7c:	00008517          	auipc	a0,0x8
    80004a80:	06450513          	addi	a0,a0,100 # 8000cae0 <digits+0x2930>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	a80080e7          	jalr	-1408(ra) # 80000504 <printf>
    p = myproc();
    80004a8c:	fffff097          	auipc	ra,0xfffff
    80004a90:	06e080e7          	jalr	110(ra) # 80003afa <myproc>
    80004a94:	84aa                	mv	s1,a0
    mlfq_cpu_final_priority = p->priority;
    80004a96:	0b852783          	lw	a5,184(a0)
    80004a9a:	0000b717          	auipc	a4,0xb
    80004a9e:	d8f72d23          	sw	a5,-614(a4) # 8000f834 <mlfq_cpu_final_priority>
    printf("[MLFQ-CPU] PID %d completed after %d iterations\n", p->pid, iteration);
    80004aa2:	8656                	mv	a2,s5
    80004aa4:	4d4c                	lw	a1,28(a0)
    80004aa6:	00008517          	auipc	a0,0x8
    80004aaa:	09250513          	addi	a0,a0,146 # 8000cb38 <digits+0x2988>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	a56080e7          	jalr	-1450(ra) # 80000504 <printf>
    printf("[MLFQ-CPU] Priority progression: %d", mlfq_cpu_initial_priority);
    80004ab6:	0000b597          	auipc	a1,0xb
    80004aba:	d825a583          	lw	a1,-638(a1) # 8000f838 <mlfq_cpu_initial_priority>
    80004abe:	00008517          	auipc	a0,0x8
    80004ac2:	0b250513          	addi	a0,a0,178 # 8000cb70 <digits+0x29c0>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a3e080e7          	jalr	-1474(ra) # 80000504 <printf>
    if (demotion_count > 0)
    80004ace:	f76046e3          	bgtz	s6,80004a3a <mlfq_cpu_intensive_task+0x2a0>
    }
    printf(" (%d demotion(s), final consecutive_slices: %d)\n", demotion_count, p->consecutive_slices);
    80004ad2:	0cc4a603          	lw	a2,204(s1)
    80004ad6:	85da                	mv	a1,s6
    80004ad8:	00008517          	auipc	a0,0x8
    80004adc:	0c850513          	addi	a0,a0,200 # 8000cba0 <digits+0x29f0>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	a24080e7          	jalr	-1500(ra) # 80000504 <printf>
    mlfq_cpu_intensive_count = 1;
    80004ae8:	4785                	li	a5,1
    80004aea:	0000b717          	auipc	a4,0xb
    80004aee:	daf72b23          	sw	a5,-586(a4) # 8000f8a0 <mlfq_cpu_intensive_count>
    exit_process(0);
    80004af2:	4501                	li	a0,0
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	930080e7          	jalr	-1744(ra) # 80004424 <exit_process>

0000000080004afc <record_priority_execution>:
{
    80004afc:	1101                	addi	sp,sp,-32
    80004afe:	ec06                	sd	ra,24(sp)
    80004b00:	e822                	sd	s0,16(sp)
    80004b02:	e426                	sd	s1,8(sp)
    80004b04:	e04a                	sd	s2,0(sp)
    80004b06:	1000                	addi	s0,sp,32
    80004b08:	84aa                	mv	s1,a0
    80004b0a:	892e                	mv	s2,a1
    acquire(&priority_lock);
    80004b0c:	0000f517          	auipc	a0,0xf
    80004b10:	b9c50513          	addi	a0,a0,-1124 # 800136a8 <priority_lock>
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	c42080e7          	jalr	-958(ra) # 80003756 <acquire>
    if (priority_order_count < 10)
    80004b1c:	0000b697          	auipc	a3,0xb
    80004b20:	d986a683          	lw	a3,-616(a3) # 8000f8b4 <priority_order_count>
    80004b24:	47a5                	li	a5,9
    80004b26:	02d7d063          	bge	a5,a3,80004b46 <record_priority_execution+0x4a>
    release(&priority_lock);
    80004b2a:	0000f517          	auipc	a0,0xf
    80004b2e:	b7e50513          	addi	a0,a0,-1154 # 800136a8 <priority_lock>
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	c94080e7          	jalr	-876(ra) # 800037c6 <release>
}
    80004b3a:	60e2                	ld	ra,24(sp)
    80004b3c:	6442                	ld	s0,16(sp)
    80004b3e:	64a2                	ld	s1,8(sp)
    80004b40:	6902                	ld	s2,0(sp)
    80004b42:	6105                	addi	sp,sp,32
    80004b44:	8082                	ret
        priority_execution_order[priority_order_count] = priority;
    80004b46:	00269713          	slli	a4,a3,0x2
    80004b4a:	0000f797          	auipc	a5,0xf
    80004b4e:	b5e78793          	addi	a5,a5,-1186 # 800136a8 <priority_lock>
    80004b52:	97ba                	add	a5,a5,a4
    80004b54:	cf84                	sw	s1,24(a5)
        priority_order_count++;
    80004b56:	2685                	addiw	a3,a3,1
    80004b58:	0000b797          	auipc	a5,0xb
    80004b5c:	d4d7ae23          	sw	a3,-676(a5) # 8000f8b4 <priority_order_count>
        printf("[priority] PID %d with priority %d executed (position %d)\n",
    80004b60:	2681                	sext.w	a3,a3
    80004b62:	8626                	mv	a2,s1
    80004b64:	85ca                	mv	a1,s2
    80004b66:	00008517          	auipc	a0,0x8
    80004b6a:	07250513          	addi	a0,a0,114 # 8000cbd8 <digits+0x2a28>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	996080e7          	jalr	-1642(ra) # 80000504 <printf>
    80004b76:	bf55                	j	80004b2a <record_priority_execution+0x2e>

0000000080004b78 <priority_task_high>:
{
    80004b78:	1101                	addi	sp,sp,-32
    80004b7a:	ec06                	sd	ra,24(sp)
    80004b7c:	e822                	sd	s0,16(sp)
    80004b7e:	e426                	sd	s1,8(sp)
    80004b80:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	f78080e7          	jalr	-136(ra) # 80003afa <myproc>
    80004b8a:	84aa                	mv	s1,a0
    record_priority_execution(PRIORITY_MAX, p->pid);
    80004b8c:	4d4c                	lw	a1,28(a0)
    80004b8e:	4529                	li	a0,10
    80004b90:	00000097          	auipc	ra,0x0
    80004b94:	f6c080e7          	jalr	-148(ra) # 80004afc <record_priority_execution>
    printf("[high_priority] PID %d running and exiting\n", p->pid);
    80004b98:	4ccc                	lw	a1,28(s1)
    80004b9a:	00008517          	auipc	a0,0x8
    80004b9e:	07e50513          	addi	a0,a0,126 # 8000cc18 <digits+0x2a68>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	962080e7          	jalr	-1694(ra) # 80000504 <printf>
    exit_process(0);
    80004baa:	4501                	li	a0,0
    80004bac:	00000097          	auipc	ra,0x0
    80004bb0:	878080e7          	jalr	-1928(ra) # 80004424 <exit_process>

0000000080004bb4 <priority_task_medium>:
{
    80004bb4:	1101                	addi	sp,sp,-32
    80004bb6:	ec06                	sd	ra,24(sp)
    80004bb8:	e822                	sd	s0,16(sp)
    80004bba:	e426                	sd	s1,8(sp)
    80004bbc:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	f3c080e7          	jalr	-196(ra) # 80003afa <myproc>
    80004bc6:	84aa                	mv	s1,a0
    record_priority_execution(PRIORITY_DEFAULT, p->pid);
    80004bc8:	4d4c                	lw	a1,28(a0)
    80004bca:	4515                	li	a0,5
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	f30080e7          	jalr	-208(ra) # 80004afc <record_priority_execution>
    printf("[medium_priority] PID %d running and exiting\n", p->pid);
    80004bd4:	4ccc                	lw	a1,28(s1)
    80004bd6:	00008517          	auipc	a0,0x8
    80004bda:	07250513          	addi	a0,a0,114 # 8000cc48 <digits+0x2a98>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	926080e7          	jalr	-1754(ra) # 80000504 <printf>
    exit_process(0);
    80004be6:	4501                	li	a0,0
    80004be8:	00000097          	auipc	ra,0x0
    80004bec:	83c080e7          	jalr	-1988(ra) # 80004424 <exit_process>

0000000080004bf0 <priority_task_low>:
{
    80004bf0:	1101                	addi	sp,sp,-32
    80004bf2:	ec06                	sd	ra,24(sp)
    80004bf4:	e822                	sd	s0,16(sp)
    80004bf6:	e426                	sd	s1,8(sp)
    80004bf8:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	f00080e7          	jalr	-256(ra) # 80003afa <myproc>
    80004c02:	84aa                	mv	s1,a0
    record_priority_execution(PRIORITY_MIN, p->pid);
    80004c04:	4d4c                	lw	a1,28(a0)
    80004c06:	4505                	li	a0,1
    80004c08:	00000097          	auipc	ra,0x0
    80004c0c:	ef4080e7          	jalr	-268(ra) # 80004afc <record_priority_execution>
    printf("[low_priority] PID %d running and exiting\n", p->pid);
    80004c10:	4ccc                	lw	a1,28(s1)
    80004c12:	00008517          	auipc	a0,0x8
    80004c16:	06650513          	addi	a0,a0,102 # 8000cc78 <digits+0x2ac8>
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	8ea080e7          	jalr	-1814(ra) # 80000504 <printf>
    exit_process(0);
    80004c22:	4501                	li	a0,0
    80004c24:	00000097          	auipc	ra,0x0
    80004c28:	800080e7          	jalr	-2048(ra) # 80004424 <exit_process>

0000000080004c2c <t2_same_priority_task>:
{
    80004c2c:	7139                	addi	sp,sp,-64
    80004c2e:	fc06                	sd	ra,56(sp)
    80004c30:	f822                	sd	s0,48(sp)
    80004c32:	f426                	sd	s1,40(sp)
    80004c34:	f04a                	sd	s2,32(sp)
    80004c36:	ec4e                	sd	s3,24(sp)
    80004c38:	e852                	sd	s4,16(sp)
    80004c3a:	e456                	sd	s5,8(sp)
    80004c3c:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	ebc080e7          	jalr	-324(ra) # 80003afa <myproc>
    80004c46:	89aa                	mv	s3,a0
        if (t2_pids[i] == p->pid)
    80004c48:	4d50                	lw	a2,28(a0)
    80004c4a:	0000f797          	auipc	a5,0xf
    80004c4e:	a9e7a783          	lw	a5,-1378(a5) # 800136e8 <t2_pids>
    80004c52:	0ac78163          	beq	a5,a2,80004cf4 <t2_same_priority_task+0xc8>
    80004c56:	0000f797          	auipc	a5,0xf
    80004c5a:	a967a783          	lw	a5,-1386(a5) # 800136ec <t2_pids+0x4>
    80004c5e:	08c78d63          	beq	a5,a2,80004cf8 <t2_same_priority_task+0xcc>
    80004c62:	0000f797          	auipc	a5,0xf
    80004c66:	a8e7a783          	lw	a5,-1394(a5) # 800136f0 <t2_pids+0x8>
    int task_id = -1;
    80004c6a:	5a7d                	li	s4,-1
        if (t2_pids[i] == p->pid)
    80004c6c:	08c78263          	beq	a5,a2,80004cf0 <t2_same_priority_task+0xc4>
    printf("[T2-task%d] PID %d (priority %d) starting...\n", task_id, p->pid, p->priority);
    80004c70:	0b89a683          	lw	a3,184(s3) # f40b8 <_entry-0x7ff0bf48>
    80004c74:	85d2                	mv	a1,s4
    80004c76:	00008517          	auipc	a0,0x8
    80004c7a:	03250513          	addi	a0,a0,50 # 8000cca8 <digits+0x2af8>
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	886080e7          	jalr	-1914(ra) # 80000504 <printf>
    80004c86:	4495                	li	s1,5
        t2_execution_count[task_id]++;
    80004c88:	002a1793          	slli	a5,s4,0x2
    80004c8c:	0000f917          	auipc	s2,0xf
    80004c90:	a1c90913          	addi	s2,s2,-1508 # 800136a8 <priority_lock>
    80004c94:	993e                	add	s2,s2,a5
        printf("[T2-task%d] PID %d execution count: %d\n", task_id, p->pid, t2_execution_count[task_id]);
    80004c96:	00008a97          	auipc	s5,0x8
    80004c9a:	042a8a93          	addi	s5,s5,66 # 8000ccd8 <digits+0x2b28>
        t2_execution_count[task_id]++;
    80004c9e:	05092683          	lw	a3,80(s2)
    80004ca2:	2685                	addiw	a3,a3,1
    80004ca4:	04d92823          	sw	a3,80(s2)
        printf("[T2-task%d] PID %d execution count: %d\n", task_id, p->pid, t2_execution_count[task_id]);
    80004ca8:	2681                	sext.w	a3,a3
    80004caa:	01c9a603          	lw	a2,28(s3)
    80004cae:	85d2                	mv	a1,s4
    80004cb0:	8556                	mv	a0,s5
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	852080e7          	jalr	-1966(ra) # 80000504 <printf>
        yield(); // 主动让出CPU，触发轮转
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	250080e7          	jalr	592(ra) # 80003f0a <yield>
        ksleep(1);
    80004cc2:	4505                	li	a0,1
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	4c6080e7          	jalr	1222(ra) # 8000418a <ksleep>
    for (int i = 0; i < 5; i++)
    80004ccc:	34fd                	addiw	s1,s1,-1
    80004cce:	f8e1                	bnez	s1,80004c9e <t2_same_priority_task+0x72>
    printf("[T2-task%d] PID %d completed\n", task_id, p->pid);
    80004cd0:	01c9a603          	lw	a2,28(s3)
    80004cd4:	85d2                	mv	a1,s4
    80004cd6:	00008517          	auipc	a0,0x8
    80004cda:	02a50513          	addi	a0,a0,42 # 8000cd00 <digits+0x2b50>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	826080e7          	jalr	-2010(ra) # 80000504 <printf>
    exit_process(0);
    80004ce6:	4501                	li	a0,0
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	73c080e7          	jalr	1852(ra) # 80004424 <exit_process>
    for (int i = 0; i < 3; i++)
    80004cf0:	4a09                	li	s4,2
    80004cf2:	bfbd                	j	80004c70 <t2_same_priority_task+0x44>
    80004cf4:	4a01                	li	s4,0
    80004cf6:	bfad                	j	80004c70 <t2_same_priority_task+0x44>
    80004cf8:	4a05                	li	s4,1
    80004cfa:	bf9d                	j	80004c70 <t2_same_priority_task+0x44>

0000000080004cfc <mlfq_interactive_task>:
}

static void mlfq_interactive_task(void)
{
    80004cfc:	711d                	addi	sp,sp,-96
    80004cfe:	ec86                	sd	ra,88(sp)
    80004d00:	e8a2                	sd	s0,80(sp)
    80004d02:	e4a6                	sd	s1,72(sp)
    80004d04:	e0ca                	sd	s2,64(sp)
    80004d06:	fc4e                	sd	s3,56(sp)
    80004d08:	f852                	sd	s4,48(sp)
    80004d0a:	f456                	sd	s5,40(sp)
    80004d0c:	f05a                	sd	s6,32(sp)
    80004d0e:	ec5e                	sd	s7,24(sp)
    80004d10:	e862                	sd	s8,16(sp)
    80004d12:	e466                	sd	s9,8(sp)
    80004d14:	e06a                	sd	s10,0(sp)
    80004d16:	1080                	addi	s0,sp,96
    struct proc *p = myproc();
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	de2080e7          	jalr	-542(ra) # 80003afa <myproc>
    80004d20:	84aa                	mv	s1,a0
    mlfq_int_initial_priority = p->priority;
    80004d22:	0b852603          	lw	a2,184(a0)
    80004d26:	0000b797          	auipc	a5,0xb
    80004d2a:	b0c7a523          	sw	a2,-1270(a5) # 8000f830 <mlfq_int_initial_priority>
    printf("[MLFQ-INT] PID %d (priority %d) starting interactive work...\n", p->pid, p->priority);
    80004d2e:	4d4c                	lw	a1,28(a0)
    80004d30:	00008517          	auipc	a0,0x8
    80004d34:	ff050513          	addi	a0,a0,-16 # 8000cd20 <digits+0x2b70>
    80004d38:	ffffb097          	auipc	ra,0xffffb
    80004d3c:	7cc080e7          	jalr	1996(ra) # 80000504 <printf>
    printf("[MLFQ-INT] Goal: Maintain high priority by frequently yielding (interactive behavior)\n");
    80004d40:	00008517          	auipc	a0,0x8
    80004d44:	02050513          	addi	a0,a0,32 # 8000cd60 <digits+0x2bb0>
    80004d48:	ffffb097          	auipc	ra,0xffffb
    80004d4c:	7bc080e7          	jalr	1980(ra) # 80000504 <printf>
    printf("[MLFQ-INT] Each yield() resets consecutive_slices, preventing demotion\n");
    80004d50:	00008517          	auipc	a0,0x8
    80004d54:	06850513          	addi	a0,a0,104 # 8000cdb8 <digits+0x2c08>
    80004d58:	ffffb097          	auipc	ra,0xffffb
    80004d5c:	7ac080e7          	jalr	1964(ra) # 80000504 <printf>

    int last_priority = p->priority;
    80004d60:	0b84aa03          	lw	s4,184(s1)
    int last_consecutive_slices = p->consecutive_slices;
    80004d64:	0cc4a983          	lw	s3,204(s1)

    // 交互式任务：频繁让出CPU，模拟 I/O 或用户交互
    for (int i = 0; i < 20; i++)
    80004d68:	4901                	li	s2,0
    {                 // 增加迭代次数，更好地展示行为
        p = myproc(); // 重新获取进程指针
        mlfq_int_final_priority = p->priority;
    80004d6a:	0000bb97          	auipc	s7,0xb
    80004d6e:	ac2b8b93          	addi	s7,s7,-1342 # 8000f82c <mlfq_int_final_priority>

        // 检查优先级和consecutive_slices状态
        if (p->priority != last_priority)
        {
            printf("[MLFQ-INT] PID %d priority changed: %d -> %d (iteration %d)\n",
    80004d72:	00008d17          	auipc	s10,0x8
    80004d76:	08ed0d13          	addi	s10,s10,142 # 8000ce00 <digits+0x2c50>
                   p->pid, last_priority, p->priority, i);
            last_priority = p->priority;
        }
        if (p->consecutive_slices != last_consecutive_slices)
        {
            printf("[MLFQ-INT] PID %d consecutive_slices: %d -> %d (iteration %d, priority %d)\n",
    80004d7a:	00008c97          	auipc	s9,0x8
    80004d7e:	0c6c8c93          	addi	s9,s9,198 # 8000ce40 <digits+0x2c90>
                   p->pid, last_consecutive_slices, p->consecutive_slices, i, p->priority);
            last_consecutive_slices = p->consecutive_slices;
        }

        printf("[MLFQ-INT] PID %d working (iteration %d, priority %d, consecutive_slices: %d)\n",
    80004d82:	00008b17          	auipc	s6,0x8
    80004d86:	10eb0b13          	addi	s6,s6,270 # 8000ce90 <digits+0x2ce0>
               p->pid, i, p->priority, p->consecutive_slices);

        yield();   // 主动让出CPU，表示交互式行为（会重置consecutive_slices）
        ksleep(3); // 模拟 I/O 等待（稍微增加等待时间）

        if (i == 19)
    80004d8a:	4acd                	li	s5,19
    for (int i = 0; i < 20; i++)
    80004d8c:	4c51                	li	s8,20
    80004d8e:	a0a9                	j	80004dd8 <mlfq_interactive_task+0xdc>
            printf("[MLFQ-INT] PID %d priority changed: %d -> %d (iteration %d)\n",
    80004d90:	874a                	mv	a4,s2
    80004d92:	8652                	mv	a2,s4
    80004d94:	4d4c                	lw	a1,28(a0)
    80004d96:	856a                	mv	a0,s10
    80004d98:	ffffb097          	auipc	ra,0xffffb
    80004d9c:	76c080e7          	jalr	1900(ra) # 80000504 <printf>
            last_priority = p->priority;
    80004da0:	0b84aa03          	lw	s4,184(s1)
    80004da4:	a0a9                	j	80004dee <mlfq_interactive_task+0xf2>
        printf("[MLFQ-INT] PID %d working (iteration %d, priority %d, consecutive_slices: %d)\n",
    80004da6:	0cc4a703          	lw	a4,204(s1)
    80004daa:	0b84a683          	lw	a3,184(s1)
    80004dae:	864a                	mv	a2,s2
    80004db0:	4ccc                	lw	a1,28(s1)
    80004db2:	855a                	mv	a0,s6
    80004db4:	ffffb097          	auipc	ra,0xffffb
    80004db8:	750080e7          	jalr	1872(ra) # 80000504 <printf>
        yield();   // 主动让出CPU，表示交互式行为（会重置consecutive_slices）
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	14e080e7          	jalr	334(ra) # 80003f0a <yield>
        ksleep(3); // 模拟 I/O 等待（稍微增加等待时间）
    80004dc4:	450d                	li	a0,3
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	3c4080e7          	jalr	964(ra) # 8000418a <ksleep>
        if (i == 19)
    80004dce:	05590163          	beq	s2,s5,80004e10 <mlfq_interactive_task+0x114>
    for (int i = 0; i < 20; i++)
    80004dd2:	2905                	addiw	s2,s2,1
    80004dd4:	05890463          	beq	s2,s8,80004e1c <mlfq_interactive_task+0x120>
        p = myproc(); // 重新获取进程指针
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	d22080e7          	jalr	-734(ra) # 80003afa <myproc>
    80004de0:	84aa                	mv	s1,a0
        mlfq_int_final_priority = p->priority;
    80004de2:	0b852683          	lw	a3,184(a0)
    80004de6:	00dba023          	sw	a3,0(s7)
        if (p->priority != last_priority)
    80004dea:	fb4693e3          	bne	a3,s4,80004d90 <mlfq_interactive_task+0x94>
        if (p->consecutive_slices != last_consecutive_slices)
    80004dee:	0cc4a683          	lw	a3,204(s1)
    80004df2:	fb368ae3          	beq	a3,s3,80004da6 <mlfq_interactive_task+0xaa>
            printf("[MLFQ-INT] PID %d consecutive_slices: %d -> %d (iteration %d, priority %d)\n",
    80004df6:	0b84a783          	lw	a5,184(s1)
    80004dfa:	874a                	mv	a4,s2
    80004dfc:	864e                	mv	a2,s3
    80004dfe:	4ccc                	lw	a1,28(s1)
    80004e00:	8566                	mv	a0,s9
    80004e02:	ffffb097          	auipc	ra,0xffffb
    80004e06:	702080e7          	jalr	1794(ra) # 80000504 <printf>
            last_consecutive_slices = p->consecutive_slices;
    80004e0a:	0cc4a983          	lw	s3,204(s1)
    80004e0e:	bf61                	j	80004da6 <mlfq_interactive_task+0xaa>
        { // 记录最终优先级
            mlfq_int_final_priority = p->priority;
    80004e10:	0b84a783          	lw	a5,184(s1)
    80004e14:	0000b717          	auipc	a4,0xb
    80004e18:	a0f72c23          	sw	a5,-1512(a4) # 8000f82c <mlfq_int_final_priority>
        }
    }

    p = myproc();
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	cde080e7          	jalr	-802(ra) # 80003afa <myproc>
    mlfq_int_final_priority = p->priority;
    80004e24:	0b852783          	lw	a5,184(a0)
    80004e28:	0000b497          	auipc	s1,0xb
    80004e2c:	a0448493          	addi	s1,s1,-1532 # 8000f82c <mlfq_int_final_priority>
    80004e30:	c09c                	sw	a5,0(s1)
    printf("[MLFQ-INT] PID %d completed (priority: %d -> %d, consecutive_slices: %d)\n",
    80004e32:	0000b617          	auipc	a2,0xb
    80004e36:	9fe62603          	lw	a2,-1538(a2) # 8000f830 <mlfq_int_initial_priority>
    80004e3a:	4094                	lw	a3,0(s1)
    80004e3c:	0cc52703          	lw	a4,204(a0)
    80004e40:	2681                	sext.w	a3,a3
    80004e42:	4d4c                	lw	a1,28(a0)
    80004e44:	00008517          	auipc	a0,0x8
    80004e48:	09c50513          	addi	a0,a0,156 # 8000cee0 <digits+0x2d30>
    80004e4c:	ffffb097          	auipc	ra,0xffffb
    80004e50:	6b8080e7          	jalr	1720(ra) # 80000504 <printf>
           p->pid, mlfq_int_initial_priority, mlfq_int_final_priority, p->consecutive_slices);

    if (mlfq_int_final_priority >= mlfq_int_initial_priority)
    80004e54:	409c                	lw	a5,0(s1)
    80004e56:	2781                	sext.w	a5,a5
    80004e58:	0000b717          	auipc	a4,0xb
    80004e5c:	9d872703          	lw	a4,-1576(a4) # 8000f830 <mlfq_int_initial_priority>
    80004e60:	02e7c463          	blt	a5,a4,80004e88 <mlfq_interactive_task+0x18c>
    {
        printf("[MLFQ-INT] ✓ Successfully maintained high priority through frequent yields!\n");
    80004e64:	00008517          	auipc	a0,0x8
    80004e68:	0cc50513          	addi	a0,a0,204 # 8000cf30 <digits+0x2d80>
    80004e6c:	ffffb097          	auipc	ra,0xffffb
    80004e70:	698080e7          	jalr	1688(ra) # 80000504 <printf>
    else
    {
        printf("[MLFQ-INT] ⚠ Priority decreased (may indicate issue with yield() mechanism)\n");
    }

    mlfq_interactive_count = 1;
    80004e74:	4785                	li	a5,1
    80004e76:	0000b717          	auipc	a4,0xb
    80004e7a:	a2f72323          	sw	a5,-1498(a4) # 8000f89c <mlfq_interactive_count>
    exit_process(0);
    80004e7e:	4501                	li	a0,0
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	5a4080e7          	jalr	1444(ra) # 80004424 <exit_process>
        printf("[MLFQ-INT] ⚠ Priority decreased (may indicate issue with yield() mechanism)\n");
    80004e88:	00008517          	auipc	a0,0x8
    80004e8c:	0f850513          	addi	a0,a0,248 # 8000cf80 <digits+0x2dd0>
    80004e90:	ffffb097          	auipc	ra,0xffffb
    80004e94:	674080e7          	jalr	1652(ra) # 80000504 <printf>
    80004e98:	bff1                	j	80004e74 <mlfq_interactive_task+0x178>

0000000080004e9a <test_priority_boundaries>:
{
    80004e9a:	7139                	addi	sp,sp,-64
    80004e9c:	fc06                	sd	ra,56(sp)
    80004e9e:	f822                	sd	s0,48(sp)
    80004ea0:	f426                	sd	s1,40(sp)
    80004ea2:	f04a                	sd	s2,32(sp)
    80004ea4:	ec4e                	sd	s3,24(sp)
    80004ea6:	0080                	addi	s0,sp,64
    printf("\n=== Testing Priority Boundaries ===\n");
    80004ea8:	00008517          	auipc	a0,0x8
    80004eac:	12850513          	addi	a0,a0,296 # 8000cfd0 <digits+0x2e20>
    80004eb0:	ffffb097          	auipc	ra,0xffffb
    80004eb4:	654080e7          	jalr	1620(ra) # 80000504 <printf>
    int pid1 = create_process_with_priority(boundary_task, PRIORITY_MIN);
    80004eb8:	4585                	li	a1,1
    80004eba:	fffff517          	auipc	a0,0xfffff
    80004ebe:	6c850513          	addi	a0,a0,1736 # 80004582 <boundary_task>
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	f32080e7          	jalr	-206(ra) # 80003df4 <create_process_with_priority>
    80004eca:	84aa                	mv	s1,a0
    assert(pid1 > 0, "Process with min priority should be created");
    80004ecc:	00008597          	auipc	a1,0x8
    80004ed0:	12c58593          	addi	a1,a1,300 # 8000cff8 <digits+0x2e48>
    80004ed4:	00a02533          	sgtz	a0,a0
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	668080e7          	jalr	1640(ra) # 80004540 <assert>
    assert(sys_getpriority(pid1) == PRIORITY_MIN, "Min priority should be 1");
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	62e080e7          	jalr	1582(ra) # 80004510 <sys_getpriority>
    80004eea:	157d                	addi	a0,a0,-1
    80004eec:	00008597          	auipc	a1,0x8
    80004ef0:	13c58593          	addi	a1,a1,316 # 8000d028 <digits+0x2e78>
    80004ef4:	00153513          	seqz	a0,a0
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	648080e7          	jalr	1608(ra) # 80004540 <assert>
    int pid2 = create_process_with_priority(boundary_task, PRIORITY_MAX);
    80004f00:	45a9                	li	a1,10
    80004f02:	fffff517          	auipc	a0,0xfffff
    80004f06:	68050513          	addi	a0,a0,1664 # 80004582 <boundary_task>
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	eea080e7          	jalr	-278(ra) # 80003df4 <create_process_with_priority>
    80004f12:	84aa                	mv	s1,a0
    assert(pid2 > 0, "Process with max priority should be created");
    80004f14:	00008597          	auipc	a1,0x8
    80004f18:	13458593          	addi	a1,a1,308 # 8000d048 <digits+0x2e98>
    80004f1c:	00a02533          	sgtz	a0,a0
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	620080e7          	jalr	1568(ra) # 80004540 <assert>
    assert(sys_getpriority(pid2) == PRIORITY_MAX, "Max priority should be 10");
    80004f28:	8526                	mv	a0,s1
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	5e6080e7          	jalr	1510(ra) # 80004510 <sys_getpriority>
    80004f32:	1559                	addi	a0,a0,-10
    80004f34:	00008597          	auipc	a1,0x8
    80004f38:	14458593          	addi	a1,a1,324 # 8000d078 <digits+0x2ec8>
    80004f3c:	00153513          	seqz	a0,a0
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	600080e7          	jalr	1536(ra) # 80004540 <assert>
    int pid3 = create_process_with_priority(boundary_task, 0);
    80004f48:	4581                	li	a1,0
    80004f4a:	fffff517          	auipc	a0,0xfffff
    80004f4e:	63850513          	addi	a0,a0,1592 # 80004582 <boundary_task>
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	ea2080e7          	jalr	-350(ra) # 80003df4 <create_process_with_priority>
    80004f5a:	84aa                	mv	s1,a0
    assert(pid3 > 0, "Process with clamped low priority should be created");
    80004f5c:	00008597          	auipc	a1,0x8
    80004f60:	13c58593          	addi	a1,a1,316 # 8000d098 <digits+0x2ee8>
    80004f64:	00a02533          	sgtz	a0,a0
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	5d8080e7          	jalr	1496(ra) # 80004540 <assert>
    assert(sys_getpriority(pid3) == PRIORITY_MIN, "Priority 0 should clamp to 1");
    80004f70:	8526                	mv	a0,s1
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	59e080e7          	jalr	1438(ra) # 80004510 <sys_getpriority>
    80004f7a:	157d                	addi	a0,a0,-1
    80004f7c:	00008597          	auipc	a1,0x8
    80004f80:	15458593          	addi	a1,a1,340 # 8000d0d0 <digits+0x2f20>
    80004f84:	00153513          	seqz	a0,a0
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	5b8080e7          	jalr	1464(ra) # 80004540 <assert>
    int pid4 = create_process_with_priority(boundary_task, 20);
    80004f90:	45d1                	li	a1,20
    80004f92:	fffff517          	auipc	a0,0xfffff
    80004f96:	5f050513          	addi	a0,a0,1520 # 80004582 <boundary_task>
    80004f9a:	fffff097          	auipc	ra,0xfffff
    80004f9e:	e5a080e7          	jalr	-422(ra) # 80003df4 <create_process_with_priority>
    80004fa2:	84aa                	mv	s1,a0
    assert(pid4 > 0, "Process with clamped high priority should be created");
    80004fa4:	00008597          	auipc	a1,0x8
    80004fa8:	14c58593          	addi	a1,a1,332 # 8000d0f0 <digits+0x2f40>
    80004fac:	00a02533          	sgtz	a0,a0
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	590080e7          	jalr	1424(ra) # 80004540 <assert>
    assert(sys_getpriority(pid4) == PRIORITY_MAX, "Priority 20 should clamp to 10");
    80004fb8:	8526                	mv	a0,s1
    80004fba:	fffff097          	auipc	ra,0xfffff
    80004fbe:	556080e7          	jalr	1366(ra) # 80004510 <sys_getpriority>
    80004fc2:	1559                	addi	a0,a0,-10
    80004fc4:	00008597          	auipc	a1,0x8
    80004fc8:	16458593          	addi	a1,a1,356 # 8000d128 <digits+0x2f78>
    80004fcc:	00153513          	seqz	a0,a0
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	570080e7          	jalr	1392(ra) # 80004540 <assert>
    80004fd8:	4491                	li	s1,4
        assert(reaped > 0, "Should reap boundary test process");
    80004fda:	00008997          	auipc	s3,0x8
    80004fde:	16e98993          	addi	s3,s3,366 # 8000d148 <digits+0x2f98>
        assert(status == 0, "Boundary test process should exit successfully");
    80004fe2:	00008917          	auipc	s2,0x8
    80004fe6:	18e90913          	addi	s2,s2,398 # 8000d170 <digits+0x2fc0>
        int reaped = wait_process(&status);
    80004fea:	fcc40513          	addi	a0,s0,-52
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	290080e7          	jalr	656(ra) # 8000427e <wait_process>
        assert(reaped > 0, "Should reap boundary test process");
    80004ff6:	85ce                	mv	a1,s3
    80004ff8:	00a02533          	sgtz	a0,a0
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	544080e7          	jalr	1348(ra) # 80004540 <assert>
        assert(status == 0, "Boundary test process should exit successfully");
    80005004:	fcc42503          	lw	a0,-52(s0)
    80005008:	85ca                	mv	a1,s2
    8000500a:	00153513          	seqz	a0,a0
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	532080e7          	jalr	1330(ra) # 80004540 <assert>
    for (int i = 0; i < 4; i++)
    80005016:	34fd                	addiw	s1,s1,-1
    80005018:	f8e9                	bnez	s1,80004fea <test_priority_boundaries+0x150>
    printf("✓ Priority boundary tests completed\n");
    8000501a:	00008517          	auipc	a0,0x8
    8000501e:	18650513          	addi	a0,a0,390 # 8000d1a0 <digits+0x2ff0>
    80005022:	ffffb097          	auipc	ra,0xffffb
    80005026:	4e2080e7          	jalr	1250(ra) # 80000504 <printf>
}
    8000502a:	70e2                	ld	ra,56(sp)
    8000502c:	7442                	ld	s0,48(sp)
    8000502e:	74a2                	ld	s1,40(sp)
    80005030:	7902                	ld	s2,32(sp)
    80005032:	69e2                	ld	s3,24(sp)
    80005034:	6121                	addi	sp,sp,64
    80005036:	8082                	ret

0000000080005038 <test_priority_scheduling>:
{
    80005038:	715d                	addi	sp,sp,-80
    8000503a:	e486                	sd	ra,72(sp)
    8000503c:	e0a2                	sd	s0,64(sp)
    8000503e:	fc26                	sd	s1,56(sp)
    80005040:	f84a                	sd	s2,48(sp)
    80005042:	f44e                	sd	s3,40(sp)
    80005044:	f052                	sd	s4,32(sp)
    80005046:	ec56                	sd	s5,24(sp)
    80005048:	e85a                	sd	s6,16(sp)
    8000504a:	0880                	addi	s0,sp,80
    printf("\n=== Testing Priority Scheduling ===\n");
    8000504c:	00008517          	auipc	a0,0x8
    80005050:	17c50513          	addi	a0,a0,380 # 8000d1c8 <digits+0x3018>
    80005054:	ffffb097          	auipc	ra,0xffffb
    80005058:	4b0080e7          	jalr	1200(ra) # 80000504 <printf>
    initlock(&priority_lock, "priority_test");
    8000505c:	00008597          	auipc	a1,0x8
    80005060:	19458593          	addi	a1,a1,404 # 8000d1f0 <digits+0x3040>
    80005064:	0000e517          	auipc	a0,0xe
    80005068:	64450513          	addi	a0,a0,1604 # 800136a8 <priority_lock>
    8000506c:	ffffe097          	auipc	ra,0xffffe
    80005070:	608080e7          	jalr	1544(ra) # 80003674 <initlock>
    priority_order_count = 0;
    80005074:	0000b797          	auipc	a5,0xb
    80005078:	8407a023          	sw	zero,-1984(a5) # 8000f8b4 <priority_order_count>
    for (int i = 0; i < 10; i++)
    8000507c:	0000e997          	auipc	s3,0xe
    80005080:	64498993          	addi	s3,s3,1604 # 800136c0 <priority_execution_order>
    80005084:	0000e697          	auipc	a3,0xe
    80005088:	66468693          	addi	a3,a3,1636 # 800136e8 <t2_pids>
    priority_order_count = 0;
    8000508c:	87ce                	mv	a5,s3
        priority_execution_order[i] = -1;
    8000508e:	577d                	li	a4,-1
    80005090:	c398                	sw	a4,0(a5)
    for (int i = 0; i < 10; i++)
    80005092:	0791                	addi	a5,a5,4
    80005094:	fed79ee3          	bne	a5,a3,80005090 <test_priority_scheduling+0x58>
    while (wait_process(NULL) > 0)
    80005098:	4501                	li	a0,0
    8000509a:	fffff097          	auipc	ra,0xfffff
    8000509e:	1e4080e7          	jalr	484(ra) # 8000427e <wait_process>
    800050a2:	fea04be3          	bgtz	a0,80005098 <test_priority_scheduling+0x60>
    printf("Creating priority test processes...\n");
    800050a6:	00008517          	auipc	a0,0x8
    800050aa:	15a50513          	addi	a0,a0,346 # 8000d200 <digits+0x3050>
    800050ae:	ffffb097          	auipc	ra,0xffffb
    800050b2:	456080e7          	jalr	1110(ra) # 80000504 <printf>
    int low_pid = create_process_with_priority(priority_task_low, PRIORITY_MIN);
    800050b6:	4585                	li	a1,1
    800050b8:	00000517          	auipc	a0,0x0
    800050bc:	b3850513          	addi	a0,a0,-1224 # 80004bf0 <priority_task_low>
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	d34080e7          	jalr	-716(ra) # 80003df4 <create_process_with_priority>
    800050c8:	84aa                	mv	s1,a0
    int medium_pid = create_process_with_priority(priority_task_medium, PRIORITY_DEFAULT);
    800050ca:	4595                	li	a1,5
    800050cc:	00000517          	auipc	a0,0x0
    800050d0:	ae850513          	addi	a0,a0,-1304 # 80004bb4 <priority_task_medium>
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	d20080e7          	jalr	-736(ra) # 80003df4 <create_process_with_priority>
    800050dc:	892a                	mv	s2,a0
    int high_pid = create_process_with_priority(priority_task_high, PRIORITY_MAX);
    800050de:	45a9                	li	a1,10
    800050e0:	00000517          	auipc	a0,0x0
    800050e4:	a9850513          	addi	a0,a0,-1384 # 80004b78 <priority_task_high>
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	d0c080e7          	jalr	-756(ra) # 80003df4 <create_process_with_priority>
    800050f0:	8a2a                	mv	s4,a0
    assert(low_pid > 0, "Low priority process creation should succeed");
    800050f2:	00008597          	auipc	a1,0x8
    800050f6:	13658593          	addi	a1,a1,310 # 8000d228 <digits+0x3078>
    800050fa:	00902533          	sgtz	a0,s1
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	442080e7          	jalr	1090(ra) # 80004540 <assert>
    assert(medium_pid > 0, "Medium priority process creation should succeed");
    80005106:	00008597          	auipc	a1,0x8
    8000510a:	15258593          	addi	a1,a1,338 # 8000d258 <digits+0x30a8>
    8000510e:	01202533          	sgtz	a0,s2
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	42e080e7          	jalr	1070(ra) # 80004540 <assert>
    assert(high_pid > 0, "High priority process creation should succeed");
    8000511a:	00008597          	auipc	a1,0x8
    8000511e:	16e58593          	addi	a1,a1,366 # 8000d288 <digits+0x30d8>
    80005122:	01402533          	sgtz	a0,s4
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	41a080e7          	jalr	1050(ra) # 80004540 <assert>
    printf("Created processes: low(PID %d, priority %d), medium(PID %d, priority %d), high(PID %d, priority %d)\n",
    8000512e:	4829                	li	a6,10
    80005130:	87d2                	mv	a5,s4
    80005132:	4715                	li	a4,5
    80005134:	86ca                	mv	a3,s2
    80005136:	4605                	li	a2,1
    80005138:	85a6                	mv	a1,s1
    8000513a:	00008517          	auipc	a0,0x8
    8000513e:	17e50513          	addi	a0,a0,382 # 8000d2b8 <digits+0x3108>
    80005142:	ffffb097          	auipc	ra,0xffffb
    80005146:	3c2080e7          	jalr	962(ra) # 80000504 <printf>
    ksleep(2);
    8000514a:	4509                	li	a0,2
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	03e080e7          	jalr	62(ra) # 8000418a <ksleep>
    printf("Waiting for priority test processes to complete...\n");
    80005154:	00008517          	auipc	a0,0x8
    80005158:	1cc50513          	addi	a0,a0,460 # 8000d320 <digits+0x3170>
    8000515c:	ffffb097          	auipc	ra,0xffffb
    80005160:	3a8080e7          	jalr	936(ra) # 80000504 <printf>
    80005164:	490d                	li	s2,3
        assert(reaped_pid > 0, "Should reap priority test process");
    80005166:	00008b17          	auipc	s6,0x8
    8000516a:	1f2b0b13          	addi	s6,s6,498 # 8000d358 <digits+0x31a8>
        assert(status == 0, "Priority task should exit successfully");
    8000516e:	00008a97          	auipc	s5,0x8
    80005172:	212a8a93          	addi	s5,s5,530 # 8000d380 <digits+0x31d0>
        printf("Reaped priority task PID %d\n", reaped_pid);
    80005176:	00008a17          	auipc	s4,0x8
    8000517a:	232a0a13          	addi	s4,s4,562 # 8000d3a8 <digits+0x31f8>
        int reaped_pid = wait_process(&status);
    8000517e:	fbc40513          	addi	a0,s0,-68
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	0fc080e7          	jalr	252(ra) # 8000427e <wait_process>
    8000518a:	84aa                	mv	s1,a0
        assert(reaped_pid > 0, "Should reap priority test process");
    8000518c:	85da                	mv	a1,s6
    8000518e:	00a02533          	sgtz	a0,a0
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	3ae080e7          	jalr	942(ra) # 80004540 <assert>
        assert(status == 0, "Priority task should exit successfully");
    8000519a:	fbc42503          	lw	a0,-68(s0)
    8000519e:	85d6                	mv	a1,s5
    800051a0:	00153513          	seqz	a0,a0
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	39c080e7          	jalr	924(ra) # 80004540 <assert>
        printf("Reaped priority task PID %d\n", reaped_pid);
    800051ac:	85a6                	mv	a1,s1
    800051ae:	8552                	mv	a0,s4
    800051b0:	ffffb097          	auipc	ra,0xffffb
    800051b4:	354080e7          	jalr	852(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    800051b8:	397d                	addiw	s2,s2,-1
    800051ba:	fc0912e3          	bnez	s2,8000517e <test_priority_scheduling+0x146>
    printf("Execution order recorded: ");
    800051be:	00008517          	auipc	a0,0x8
    800051c2:	20a50513          	addi	a0,a0,522 # 8000d3c8 <digits+0x3218>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	33e080e7          	jalr	830(ra) # 80000504 <printf>
    for (int i = 0; i < priority_order_count; i++)
    800051ce:	0000a797          	auipc	a5,0xa
    800051d2:	6e67a783          	lw	a5,1766(a5) # 8000f8b4 <priority_order_count>
    800051d6:	02f05963          	blez	a5,80005208 <test_priority_scheduling+0x1d0>
    800051da:	894e                	mv	s2,s3
    800051dc:	4481                	li	s1,0
        printf("%d ", priority_execution_order[i]);
    800051de:	00008a97          	auipc	s5,0x8
    800051e2:	20aa8a93          	addi	s5,s5,522 # 8000d3e8 <digits+0x3238>
    for (int i = 0; i < priority_order_count; i++)
    800051e6:	0000aa17          	auipc	s4,0xa
    800051ea:	6cea0a13          	addi	s4,s4,1742 # 8000f8b4 <priority_order_count>
        printf("%d ", priority_execution_order[i]);
    800051ee:	00092583          	lw	a1,0(s2)
    800051f2:	8556                	mv	a0,s5
    800051f4:	ffffb097          	auipc	ra,0xffffb
    800051f8:	310080e7          	jalr	784(ra) # 80000504 <printf>
    for (int i = 0; i < priority_order_count; i++)
    800051fc:	2485                	addiw	s1,s1,1
    800051fe:	0911                	addi	s2,s2,4
    80005200:	000a2783          	lw	a5,0(s4)
    80005204:	fef4c5e3          	blt	s1,a5,800051ee <test_priority_scheduling+0x1b6>
    printf("\n");
    80005208:	00006517          	auipc	a0,0x6
    8000520c:	5b050513          	addi	a0,a0,1456 # 8000b7b8 <digits+0x1608>
    80005210:	ffffb097          	auipc	ra,0xffffb
    80005214:	2f4080e7          	jalr	756(ra) # 80000504 <printf>
    if (priority_order_count >= 1)
    80005218:	0000a797          	auipc	a5,0xa
    8000521c:	69c7a783          	lw	a5,1692(a5) # 8000f8b4 <priority_order_count>
    80005220:	0cf05863          	blez	a5,800052f0 <test_priority_scheduling+0x2b8>
        int first_priority = priority_execution_order[0];
    80005224:	0000e597          	auipc	a1,0xe
    80005228:	49c5a583          	lw	a1,1180(a1) # 800136c0 <priority_execution_order>
        if (high_priority_first)
    8000522c:	4729                	li	a4,10
    8000522e:	04e58d63          	beq	a1,a4,80005288 <test_priority_scheduling+0x250>
            for (int i = 1; i < priority_order_count; i++)
    80005232:	4705                	li	a4,1
    80005234:	02f75363          	bge	a4,a5,8000525a <test_priority_scheduling+0x222>
    80005238:	ffe7871b          	addiw	a4,a5,-2
    8000523c:	1702                	slli	a4,a4,0x20
    8000523e:	9301                	srli	a4,a4,0x20
    80005240:	070a                	slli	a4,a4,0x2
    80005242:	0000e797          	auipc	a5,0xe
    80005246:	48278793          	addi	a5,a5,1154 # 800136c4 <priority_execution_order+0x4>
    8000524a:	973e                	add	a4,a4,a5
    8000524c:	87ce                	mv	a5,s3
                if (priority_execution_order[i] != first_priority)
    8000524e:	43d4                	lw	a3,4(a5)
    80005250:	00b69863          	bne	a3,a1,80005260 <test_priority_scheduling+0x228>
            for (int i = 1; i < priority_order_count; i++)
    80005254:	0791                	addi	a5,a5,4
    80005256:	fef71ce3          	bne	a4,a5,8000524e <test_priority_scheduling+0x216>
            if (all_same && first_priority >= PRIORITY_DEFAULT)
    8000525a:	4791                	li	a5,4
    8000525c:	02b7cf63          	blt	a5,a1,8000529a <test_priority_scheduling+0x262>
                printf("✗ High priority task did not execute first (first was priority %d)\n",
    80005260:	00008517          	auipc	a0,0x8
    80005264:	20050513          	addi	a0,a0,512 # 8000d460 <digits+0x32b0>
    80005268:	ffffb097          	auipc	ra,0xffffb
    8000526c:	29c080e7          	jalr	668(ra) # 80000504 <printf>
                for (int i = 0; i < priority_order_count; i++)
    80005270:	0000a697          	auipc	a3,0xa
    80005274:	6446a683          	lw	a3,1604(a3) # 8000f8b4 <priority_order_count>
    80005278:	06d05263          	blez	a3,800052dc <test_priority_scheduling+0x2a4>
    8000527c:	4781                	li	a5,0
                int low_found = 0;
    8000527e:	4501                	li	a0,0
                int high_found = 0;
    80005280:	4801                	li	a6,0
                    if (priority_execution_order[i] == PRIORITY_MAX)
    80005282:	4629                	li	a2,10
                    if (priority_execution_order[i] == PRIORITY_MIN)
    80005284:	4585                	li	a1,1
    80005286:	a805                	j	800052b6 <test_priority_scheduling+0x27e>
            printf("✓ High priority task executed first\n");
    80005288:	00008517          	auipc	a0,0x8
    8000528c:	16850513          	addi	a0,a0,360 # 8000d3f0 <digits+0x3240>
    80005290:	ffffb097          	auipc	ra,0xffffb
    80005294:	274080e7          	jalr	628(ra) # 80000504 <printf>
    80005298:	a0ad                	j	80005302 <test_priority_scheduling+0x2ca>
                printf("✓ All processes reached same priority due to aging (priority %d)\n", first_priority);
    8000529a:	00008517          	auipc	a0,0x8
    8000529e:	17e50513          	addi	a0,a0,382 # 8000d418 <digits+0x3268>
    800052a2:	ffffb097          	auipc	ra,0xffffb
    800052a6:	262080e7          	jalr	610(ra) # 80000504 <printf>
    800052aa:	a8a1                	j	80005302 <test_priority_scheduling+0x2ca>
    800052ac:	883e                	mv	a6,a5
                for (int i = 0; i < priority_order_count; i++)
    800052ae:	2785                	addiw	a5,a5,1
    800052b0:	0991                	addi	s3,s3,4
    800052b2:	00d78a63          	beq	a5,a3,800052c6 <test_priority_scheduling+0x28e>
                    if (priority_execution_order[i] == PRIORITY_MAX)
    800052b6:	0009a703          	lw	a4,0(s3)
    800052ba:	fec709e3          	beq	a4,a2,800052ac <test_priority_scheduling+0x274>
                    if (priority_execution_order[i] == PRIORITY_MIN)
    800052be:	feb718e3          	bne	a4,a1,800052ae <test_priority_scheduling+0x276>
    800052c2:	853e                	mv	a0,a5
    800052c4:	b7ed                	j	800052ae <test_priority_scheduling+0x276>
                if (high_found < low_found)
    800052c6:	00a85b63          	bge	a6,a0,800052dc <test_priority_scheduling+0x2a4>
                    printf("✓ High priority executed before low priority (acceptable)\n");
    800052ca:	00008517          	auipc	a0,0x8
    800052ce:	1de50513          	addi	a0,a0,478 # 8000d4a8 <digits+0x32f8>
    800052d2:	ffffb097          	auipc	ra,0xffffb
    800052d6:	232080e7          	jalr	562(ra) # 80000504 <printf>
    800052da:	a025                	j	80005302 <test_priority_scheduling+0x2ca>
                    assert(0, "Highest priority task should execute before lowest priority");
    800052dc:	00008597          	auipc	a1,0x8
    800052e0:	20c58593          	addi	a1,a1,524 # 8000d4e8 <digits+0x3338>
    800052e4:	4501                	li	a0,0
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	25a080e7          	jalr	602(ra) # 80004540 <assert>
    800052ee:	a811                	j	80005302 <test_priority_scheduling+0x2ca>
        assert(0, "No priority tasks executed");
    800052f0:	00008597          	auipc	a1,0x8
    800052f4:	23858593          	addi	a1,a1,568 # 8000d528 <digits+0x3378>
    800052f8:	4501                	li	a0,0
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	246080e7          	jalr	582(ra) # 80004540 <assert>
    printf("Priority scheduling test completed\n");
    80005302:	00008517          	auipc	a0,0x8
    80005306:	24650513          	addi	a0,a0,582 # 8000d548 <digits+0x3398>
    8000530a:	ffffb097          	auipc	ra,0xffffb
    8000530e:	1fa080e7          	jalr	506(ra) # 80000504 <printf>
}
    80005312:	60a6                	ld	ra,72(sp)
    80005314:	6406                	ld	s0,64(sp)
    80005316:	74e2                	ld	s1,56(sp)
    80005318:	7942                	ld	s2,48(sp)
    8000531a:	79a2                	ld	s3,40(sp)
    8000531c:	7a02                	ld	s4,32(sp)
    8000531e:	6ae2                	ld	s5,24(sp)
    80005320:	6b42                	ld	s6,16(sp)
    80005322:	6161                	addi	sp,sp,80
    80005324:	8082                	ret

0000000080005326 <test_t1_priority_gap>:
{
    80005326:	715d                	addi	sp,sp,-80
    80005328:	e486                	sd	ra,72(sp)
    8000532a:	e0a2                	sd	s0,64(sp)
    8000532c:	fc26                	sd	s1,56(sp)
    8000532e:	f84a                	sd	s2,48(sp)
    80005330:	f44e                	sd	s3,40(sp)
    80005332:	f052                	sd	s4,32(sp)
    80005334:	ec56                	sd	s5,24(sp)
    80005336:	0880                	addi	s0,sp,80
    printf("\n=== T1: Testing Large Priority Gap (High completes first) ===\n");
    80005338:	00008517          	auipc	a0,0x8
    8000533c:	23850513          	addi	a0,a0,568 # 8000d570 <digits+0x33c0>
    80005340:	ffffb097          	auipc	ra,0xffffb
    80005344:	1c4080e7          	jalr	452(ra) # 80000504 <printf>
    t1_high_completed = 0;
    80005348:	0000a797          	auipc	a5,0xa
    8000534c:	5607a423          	sw	zero,1384(a5) # 8000f8b0 <t1_high_completed>
    t1_low_started = 0;
    80005350:	0000a797          	auipc	a5,0xa
    80005354:	5407ae23          	sw	zero,1372(a5) # 8000f8ac <t1_low_started>
    while (wait_process(NULL) > 0)
    80005358:	4501                	li	a0,0
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	f24080e7          	jalr	-220(ra) # 8000427e <wait_process>
    80005362:	fea04be3          	bgtz	a0,80005358 <test_t1_priority_gap+0x32>
    printf("Creating two tasks with large priority gap...\n");
    80005366:	00008517          	auipc	a0,0x8
    8000536a:	24a50513          	addi	a0,a0,586 # 8000d5b0 <digits+0x3400>
    8000536e:	ffffb097          	auipc	ra,0xffffb
    80005372:	196080e7          	jalr	406(ra) # 80000504 <printf>
    int high_pid = create_process_with_priority(t1_high_priority_task, PRIORITY_MAX);
    80005376:	45a9                	li	a1,10
    80005378:	fffff517          	auipc	a0,0xfffff
    8000537c:	29850513          	addi	a0,a0,664 # 80004610 <t1_high_priority_task>
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	a74080e7          	jalr	-1420(ra) # 80003df4 <create_process_with_priority>
    80005388:	84aa                	mv	s1,a0
    assert(high_pid > 0, "High priority process creation should succeed");
    8000538a:	00008597          	auipc	a1,0x8
    8000538e:	efe58593          	addi	a1,a1,-258 # 8000d288 <digits+0x30d8>
    80005392:	00a02533          	sgtz	a0,a0
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	1aa080e7          	jalr	426(ra) # 80004540 <assert>
    int low_pid = create_process_with_priority(t1_low_priority_task, PRIORITY_MIN);
    8000539e:	4585                	li	a1,1
    800053a0:	fffff517          	auipc	a0,0xfffff
    800053a4:	1f450513          	addi	a0,a0,500 # 80004594 <t1_low_priority_task>
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	a4c080e7          	jalr	-1460(ra) # 80003df4 <create_process_with_priority>
    800053b0:	892a                	mv	s2,a0
    assert(low_pid > 0, "Low priority process creation should succeed");
    800053b2:	00008597          	auipc	a1,0x8
    800053b6:	e7658593          	addi	a1,a1,-394 # 8000d228 <digits+0x3078>
    800053ba:	00a02533          	sgtz	a0,a0
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	182080e7          	jalr	386(ra) # 80004540 <assert>
    printf("Created: high(PID %d, priority %d), low(PID %d, priority %d)\n",
    800053c6:	4705                	li	a4,1
    800053c8:	86ca                	mv	a3,s2
    800053ca:	4629                	li	a2,10
    800053cc:	85a6                	mv	a1,s1
    800053ce:	00008517          	auipc	a0,0x8
    800053d2:	21250513          	addi	a0,a0,530 # 8000d5e0 <digits+0x3430>
    800053d6:	ffffb097          	auipc	ra,0xffffb
    800053da:	12e080e7          	jalr	302(ra) # 80000504 <printf>
    yield();
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	b2c080e7          	jalr	-1236(ra) # 80003f0a <yield>
    printf("Waiting for tasks to complete...\n");
    800053e6:	00008517          	auipc	a0,0x8
    800053ea:	23a50513          	addi	a0,a0,570 # 8000d620 <digits+0x3470>
    800053ee:	ffffb097          	auipc	ra,0xffffb
    800053f2:	116080e7          	jalr	278(ra) # 80000504 <printf>
    800053f6:	4909                	li	s2,2
        assert(reaped_pid > 0, "Should reap test process");
    800053f8:	00008a97          	auipc	s5,0x8
    800053fc:	250a8a93          	addi	s5,s5,592 # 8000d648 <digits+0x3498>
        assert(status == 0, "Task should exit successfully");
    80005400:	00008a17          	auipc	s4,0x8
    80005404:	268a0a13          	addi	s4,s4,616 # 8000d668 <digits+0x34b8>
        printf("Reaped task PID %d\n", reaped_pid);
    80005408:	00008997          	auipc	s3,0x8
    8000540c:	28098993          	addi	s3,s3,640 # 8000d688 <digits+0x34d8>
        int reaped_pid = wait_process(&status);
    80005410:	fbc40513          	addi	a0,s0,-68
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	e6a080e7          	jalr	-406(ra) # 8000427e <wait_process>
    8000541c:	84aa                	mv	s1,a0
        assert(reaped_pid > 0, "Should reap test process");
    8000541e:	85d6                	mv	a1,s5
    80005420:	00a02533          	sgtz	a0,a0
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	11c080e7          	jalr	284(ra) # 80004540 <assert>
        assert(status == 0, "Task should exit successfully");
    8000542c:	fbc42503          	lw	a0,-68(s0)
    80005430:	85d2                	mv	a1,s4
    80005432:	00153513          	seqz	a0,a0
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	10a080e7          	jalr	266(ra) # 80004540 <assert>
        printf("Reaped task PID %d\n", reaped_pid);
    8000543e:	85a6                	mv	a1,s1
    80005440:	854e                	mv	a0,s3
    80005442:	ffffb097          	auipc	ra,0xffffb
    80005446:	0c2080e7          	jalr	194(ra) # 80000504 <printf>
    for (int i = 0; i < 2; i++)
    8000544a:	397d                	addiw	s2,s2,-1
    8000544c:	fc0912e3          	bnez	s2,80005410 <test_t1_priority_gap+0xea>
    assert(t1_high_completed == 1, "High priority task should complete");
    80005450:	0000a517          	auipc	a0,0xa
    80005454:	46052503          	lw	a0,1120(a0) # 8000f8b0 <t1_high_completed>
    80005458:	157d                	addi	a0,a0,-1
    8000545a:	00008597          	auipc	a1,0x8
    8000545e:	24658593          	addi	a1,a1,582 # 8000d6a0 <digits+0x34f0>
    80005462:	00153513          	seqz	a0,a0
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	0da080e7          	jalr	218(ra) # 80004540 <assert>
    if (!t1_low_started)
    8000546e:	0000a797          	auipc	a5,0xa
    80005472:	43e7a783          	lw	a5,1086(a5) # 8000f8ac <t1_low_started>
    80005476:	c395                	beqz	a5,8000549a <test_t1_priority_gap+0x174>
    printf("T1 test completed\n");
    80005478:	00008517          	auipc	a0,0x8
    8000547c:	2a850513          	addi	a0,a0,680 # 8000d720 <digits+0x3570>
    80005480:	ffffb097          	auipc	ra,0xffffb
    80005484:	084080e7          	jalr	132(ra) # 80000504 <printf>
}
    80005488:	60a6                	ld	ra,72(sp)
    8000548a:	6406                	ld	s0,64(sp)
    8000548c:	74e2                	ld	s1,56(sp)
    8000548e:	7942                	ld	s2,48(sp)
    80005490:	79a2                	ld	s3,40(sp)
    80005492:	7a02                	ld	s4,32(sp)
    80005494:	6ae2                	ld	s5,24(sp)
    80005496:	6161                	addi	sp,sp,80
    80005498:	8082                	ret
        printf("✓ T1 Test: High priority task completed before low priority started (ideal case)\n");
    8000549a:	00008517          	auipc	a0,0x8
    8000549e:	22e50513          	addi	a0,a0,558 # 8000d6c8 <digits+0x3518>
    800054a2:	ffffb097          	auipc	ra,0xffffb
    800054a6:	062080e7          	jalr	98(ra) # 80000504 <printf>
    800054aa:	b7f9                	j	80005478 <test_t1_priority_gap+0x152>

00000000800054ac <process_test_runner>:
}

// ==================== 主测试运行器 ====================

static void process_test_runner(void)
{
    800054ac:	1101                	addi	sp,sp,-32
    800054ae:	ec06                	sd	ra,24(sp)
    800054b0:	e822                	sd	s0,16(sp)
    800054b2:	e426                	sd	s1,8(sp)
    800054b4:	1000                	addi	s0,sp,32
    printf("\n");
    800054b6:	00006517          	auipc	a0,0x6
    800054ba:	30250513          	addi	a0,a0,770 # 8000b7b8 <digits+0x1608>
    800054be:	ffffb097          	auipc	ra,0xffffb
    800054c2:	046080e7          	jalr	70(ra) # 80000504 <printf>
    printf("========================================\n");
    800054c6:	00008517          	auipc	a0,0x8
    800054ca:	27250513          	addi	a0,a0,626 # 8000d738 <digits+0x3588>
    800054ce:	ffffb097          	auipc	ra,0xffffb
    800054d2:	036080e7          	jalr	54(ra) # 80000504 <printf>
    printf("    PRIORITY SCHEDULING TEST SUITE\n");
    800054d6:	00008517          	auipc	a0,0x8
    800054da:	29250513          	addi	a0,a0,658 # 8000d768 <digits+0x35b8>
    800054de:	ffffb097          	auipc	ra,0xffffb
    800054e2:	026080e7          	jalr	38(ra) # 80000504 <printf>
    printf("========================================\n");
    800054e6:	00008517          	auipc	a0,0x8
    800054ea:	25250513          	addi	a0,a0,594 # 8000d738 <digits+0x3588>
    800054ee:	ffffb097          	auipc	ra,0xffffb
    800054f2:	016080e7          	jalr	22(ra) # 80000504 <printf>

    test_failures = 0;
    800054f6:	0000a497          	auipc	s1,0xa
    800054fa:	3c248493          	addi	s1,s1,962 # 8000f8b8 <test_failures>
    800054fe:	0004a023          	sw	zero,0(s1)

    // 运行优先级调度相关测试
    test_priority_scheduling(); // 基础优先级调度测试
    80005502:	00000097          	auipc	ra,0x0
    80005506:	b36080e7          	jalr	-1226(ra) # 80005038 <test_priority_scheduling>
    test_t1_priority_gap();     // T1: 两个任务，优先级差距大
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	e1c080e7          	jalr	-484(ra) # 80005326 <test_t1_priority_gap>
    // test_priority_boundaries();     // 优先级边界值测试
    //  test_syscall_priority(); // 系统调用测试
    //  test_aging_mechanism();         // Aging机制测试

    // 输出最终结果
    printf("\n========================================\n");
    80005512:	00008517          	auipc	a0,0x8
    80005516:	27e50513          	addi	a0,a0,638 # 8000d790 <digits+0x35e0>
    8000551a:	ffffb097          	auipc	ra,0xffffb
    8000551e:	fea080e7          	jalr	-22(ra) # 80000504 <printf>
    if (test_failures == 0)
    80005522:	408c                	lw	a1,0(s1)
    80005524:	e595                	bnez	a1,80005550 <process_test_runner+0xa4>
    {
        printf("✓ ALL PRIORITY SCHEDULING TESTS PASSED\n");
    80005526:	00008517          	auipc	a0,0x8
    8000552a:	29a50513          	addi	a0,a0,666 # 8000d7c0 <digits+0x3610>
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	fd6080e7          	jalr	-42(ra) # 80000504 <printf>
    }
    else
    {
        printf("✗ %d TEST(S) FAILED\n", test_failures);
    }
    printf("========================================\n");
    80005536:	00008517          	auipc	a0,0x8
    8000553a:	20250513          	addi	a0,a0,514 # 8000d738 <digits+0x3588>
    8000553e:	ffffb097          	auipc	ra,0xffffb
    80005542:	fc6080e7          	jalr	-58(ra) # 80000504 <printf>

    exit_process(0);
    80005546:	4501                	li	a0,0
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	edc080e7          	jalr	-292(ra) # 80004424 <exit_process>
        printf("✗ %d TEST(S) FAILED\n", test_failures);
    80005550:	00008517          	auipc	a0,0x8
    80005554:	2a050513          	addi	a0,a0,672 # 8000d7f0 <digits+0x3640>
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	fac080e7          	jalr	-84(ra) # 80000504 <printf>
    80005560:	bfd9                	j	80005536 <process_test_runner+0x8a>

0000000080005562 <test_t2_same_priority_rr>:
{
    80005562:	715d                	addi	sp,sp,-80
    80005564:	e486                	sd	ra,72(sp)
    80005566:	e0a2                	sd	s0,64(sp)
    80005568:	fc26                	sd	s1,56(sp)
    8000556a:	f84a                	sd	s2,48(sp)
    8000556c:	f44e                	sd	s3,40(sp)
    8000556e:	f052                	sd	s4,32(sp)
    80005570:	ec56                	sd	s5,24(sp)
    80005572:	e85a                	sd	s6,16(sp)
    80005574:	0880                	addi	s0,sp,80
    printf("\n=== T2: Testing Same Priority (Round-Robin behavior) ===\n");
    80005576:	00008517          	auipc	a0,0x8
    8000557a:	29250513          	addi	a0,a0,658 # 8000d808 <digits+0x3658>
    8000557e:	ffffb097          	auipc	ra,0xffffb
    80005582:	f86080e7          	jalr	-122(ra) # 80000504 <printf>
        t2_execution_count[i] = 0;
    80005586:	0000e797          	auipc	a5,0xe
    8000558a:	12278793          	addi	a5,a5,290 # 800136a8 <priority_lock>
    8000558e:	0407a823          	sw	zero,80(a5)
        t2_pids[i] = 0;
    80005592:	0407a023          	sw	zero,64(a5)
        t2_execution_count[i] = 0;
    80005596:	0407aa23          	sw	zero,84(a5)
        t2_pids[i] = 0;
    8000559a:	0407a223          	sw	zero,68(a5)
        t2_execution_count[i] = 0;
    8000559e:	0407ac23          	sw	zero,88(a5)
        t2_pids[i] = 0;
    800055a2:	0407a423          	sw	zero,72(a5)
    while (wait_process(NULL) > 0)
    800055a6:	4501                	li	a0,0
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	cd6080e7          	jalr	-810(ra) # 8000427e <wait_process>
    800055b0:	fea04be3          	bgtz	a0,800055a6 <test_t2_same_priority_rr+0x44>
    printf("Creating 3 tasks with same priority (priority %d, max to avoid aging)...\n", PRIORITY_MAX);
    800055b4:	45a9                	li	a1,10
    800055b6:	00008517          	auipc	a0,0x8
    800055ba:	29250513          	addi	a0,a0,658 # 8000d848 <digits+0x3698>
    800055be:	ffffb097          	auipc	ra,0xffffb
    800055c2:	f46080e7          	jalr	-186(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    800055c6:	0000e917          	auipc	s2,0xe
    800055ca:	12290913          	addi	s2,s2,290 # 800136e8 <t2_pids>
    800055ce:	4481                	li	s1,0
        t2_pids[i] = create_process_with_priority(t2_same_priority_task, PRIORITY_MAX);
    800055d0:	fffffb17          	auipc	s6,0xfffff
    800055d4:	65cb0b13          	addi	s6,s6,1628 # 80004c2c <t2_same_priority_task>
        assert(t2_pids[i] > 0, "Process creation should succeed");
    800055d8:	00008a97          	auipc	s5,0x8
    800055dc:	2c0a8a93          	addi	s5,s5,704 # 8000d898 <digits+0x36e8>
        printf("Created task %d: PID %d (priority %d)\n", i, t2_pids[i], PRIORITY_MAX);
    800055e0:	00008a17          	auipc	s4,0x8
    800055e4:	2d8a0a13          	addi	s4,s4,728 # 8000d8b8 <digits+0x3708>
    for (int i = 0; i < 3; i++)
    800055e8:	498d                	li	s3,3
        t2_pids[i] = create_process_with_priority(t2_same_priority_task, PRIORITY_MAX);
    800055ea:	45a9                	li	a1,10
    800055ec:	855a                	mv	a0,s6
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	806080e7          	jalr	-2042(ra) # 80003df4 <create_process_with_priority>
    800055f6:	00a92023          	sw	a0,0(s2)
        assert(t2_pids[i] > 0, "Process creation should succeed");
    800055fa:	85d6                	mv	a1,s5
    800055fc:	00a02533          	sgtz	a0,a0
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	f40080e7          	jalr	-192(ra) # 80004540 <assert>
        printf("Created task %d: PID %d (priority %d)\n", i, t2_pids[i], PRIORITY_MAX);
    80005608:	46a9                	li	a3,10
    8000560a:	00092603          	lw	a2,0(s2)
    8000560e:	85a6                	mv	a1,s1
    80005610:	8552                	mv	a0,s4
    80005612:	ffffb097          	auipc	ra,0xffffb
    80005616:	ef2080e7          	jalr	-270(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    8000561a:	2485                	addiw	s1,s1,1
    8000561c:	0911                	addi	s2,s2,4
    8000561e:	fd3496e3          	bne	s1,s3,800055ea <test_t2_same_priority_rr+0x88>
    ksleep(1);
    80005622:	4505                	li	a0,1
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	b66080e7          	jalr	-1178(ra) # 8000418a <ksleep>
    printf("Waiting for tasks to complete...\n");
    8000562c:	00008517          	auipc	a0,0x8
    80005630:	ff450513          	addi	a0,a0,-12 # 8000d620 <digits+0x3470>
    80005634:	ffffb097          	auipc	ra,0xffffb
    80005638:	ed0080e7          	jalr	-304(ra) # 80000504 <printf>
    8000563c:	490d                	li	s2,3
        assert(reaped_pid > 0, "Should reap test process");
    8000563e:	00008a97          	auipc	s5,0x8
    80005642:	00aa8a93          	addi	s5,s5,10 # 8000d648 <digits+0x3498>
        assert(status == 0, "Task should exit successfully");
    80005646:	00008a17          	auipc	s4,0x8
    8000564a:	022a0a13          	addi	s4,s4,34 # 8000d668 <digits+0x34b8>
        printf("Reaped task PID %d\n", reaped_pid);
    8000564e:	00008997          	auipc	s3,0x8
    80005652:	03a98993          	addi	s3,s3,58 # 8000d688 <digits+0x34d8>
        int reaped_pid = wait_process(&status);
    80005656:	fbc40513          	addi	a0,s0,-68
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	c24080e7          	jalr	-988(ra) # 8000427e <wait_process>
    80005662:	84aa                	mv	s1,a0
        assert(reaped_pid > 0, "Should reap test process");
    80005664:	85d6                	mv	a1,s5
    80005666:	00a02533          	sgtz	a0,a0
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	ed6080e7          	jalr	-298(ra) # 80004540 <assert>
        assert(status == 0, "Task should exit successfully");
    80005672:	fbc42503          	lw	a0,-68(s0)
    80005676:	85d2                	mv	a1,s4
    80005678:	00153513          	seqz	a0,a0
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	ec4080e7          	jalr	-316(ra) # 80004540 <assert>
        printf("Reaped task PID %d\n", reaped_pid);
    80005684:	85a6                	mv	a1,s1
    80005686:	854e                	mv	a0,s3
    80005688:	ffffb097          	auipc	ra,0xffffb
    8000568c:	e7c080e7          	jalr	-388(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    80005690:	397d                	addiw	s2,s2,-1
    80005692:	fc0912e3          	bnez	s2,80005656 <test_t2_same_priority_rr+0xf4>
    printf("Execution counts: task0=%d, task1=%d, task2=%d\n",
    80005696:	0000e497          	auipc	s1,0xe
    8000569a:	01248493          	addi	s1,s1,18 # 800136a8 <priority_lock>
    8000569e:	4cb4                	lw	a3,88(s1)
    800056a0:	48f0                	lw	a2,84(s1)
    800056a2:	48ac                	lw	a1,80(s1)
    800056a4:	00008517          	auipc	a0,0x8
    800056a8:	23c50513          	addi	a0,a0,572 # 8000d8e0 <digits+0x3730>
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	e58080e7          	jalr	-424(ra) # 80000504 <printf>
        if (t2_execution_count[i] == 0)
    800056b4:	48a8                	lw	a0,80(s1)
    800056b6:	cd01                	beqz	a0,800056ce <test_t2_same_priority_rr+0x16c>
    800056b8:	0000e517          	auipc	a0,0xe
    800056bc:	04452503          	lw	a0,68(a0) # 800136fc <t2_execution_count+0x4>
    800056c0:	c519                	beqz	a0,800056ce <test_t2_same_priority_rr+0x16c>
    800056c2:	0000e517          	auipc	a0,0xe
    800056c6:	03e52503          	lw	a0,62(a0) # 80013700 <t2_execution_count+0x8>
            all_executed = 0;
    800056ca:	00a03533          	snez	a0,a0
    assert(all_executed, "All tasks with same priority should execute");
    800056ce:	00008597          	auipc	a1,0x8
    800056d2:	24258593          	addi	a1,a1,578 # 8000d910 <digits+0x3760>
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	e6a080e7          	jalr	-406(ra) # 80004540 <assert>
    if (t2_execution_count[0] > 0 && t2_execution_count[1] > 0 && t2_execution_count[2] > 0)
    800056de:	0000e797          	auipc	a5,0xe
    800056e2:	01a7a783          	lw	a5,26(a5) # 800136f8 <t2_execution_count>
    800056e6:	00f05e63          	blez	a5,80005702 <test_t2_same_priority_rr+0x1a0>
    800056ea:	0000e797          	auipc	a5,0xe
    800056ee:	0127a783          	lw	a5,18(a5) # 800136fc <t2_execution_count+0x4>
    800056f2:	00f05863          	blez	a5,80005702 <test_t2_same_priority_rr+0x1a0>
    800056f6:	0000e797          	auipc	a5,0xe
    800056fa:	00a7a783          	lw	a5,10(a5) # 80013700 <t2_execution_count+0x8>
    800056fe:	02f04d63          	bgtz	a5,80005738 <test_t2_same_priority_rr+0x1d6>
        assert(0, "Not all tasks executed");
    80005702:	00008597          	auipc	a1,0x8
    80005706:	28658593          	addi	a1,a1,646 # 8000d988 <digits+0x37d8>
    8000570a:	4501                	li	a0,0
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	e34080e7          	jalr	-460(ra) # 80004540 <assert>
    printf("T2 test completed\n");
    80005714:	00008517          	auipc	a0,0x8
    80005718:	28c50513          	addi	a0,a0,652 # 8000d9a0 <digits+0x37f0>
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	de8080e7          	jalr	-536(ra) # 80000504 <printf>
}
    80005724:	60a6                	ld	ra,72(sp)
    80005726:	6406                	ld	s0,64(sp)
    80005728:	74e2                	ld	s1,56(sp)
    8000572a:	7942                	ld	s2,48(sp)
    8000572c:	79a2                	ld	s3,40(sp)
    8000572e:	7a02                	ld	s4,32(sp)
    80005730:	6ae2                	ld	s5,24(sp)
    80005732:	6b42                	ld	s6,16(sp)
    80005734:	6161                	addi	sp,sp,80
    80005736:	8082                	ret
        printf("✓ T2 Test: All tasks with same priority executed (all got CPU time)\n");
    80005738:	00008517          	auipc	a0,0x8
    8000573c:	20850513          	addi	a0,a0,520 # 8000d940 <digits+0x3790>
    80005740:	ffffb097          	auipc	ra,0xffffb
    80005744:	dc4080e7          	jalr	-572(ra) # 80000504 <printf>
    80005748:	b7f1                	j	80005714 <test_t2_same_priority_rr+0x1b2>

000000008000574a <test_t3_mixed_priority_aging>:
{
    8000574a:	7159                	addi	sp,sp,-112
    8000574c:	f486                	sd	ra,104(sp)
    8000574e:	f0a2                	sd	s0,96(sp)
    80005750:	eca6                	sd	s1,88(sp)
    80005752:	e8ca                	sd	s2,80(sp)
    80005754:	e4ce                	sd	s3,72(sp)
    80005756:	e0d2                	sd	s4,64(sp)
    80005758:	fc56                	sd	s5,56(sp)
    8000575a:	f85a                	sd	s6,48(sp)
    8000575c:	f45e                	sd	s7,40(sp)
    8000575e:	f062                	sd	s8,32(sp)
    80005760:	1880                	addi	s0,sp,112
    printf("\n=== T3: Testing Mixed Priority + Aging (All tasks complete) ===\n");
    80005762:	00008517          	auipc	a0,0x8
    80005766:	25650513          	addi	a0,a0,598 # 8000d9b8 <digits+0x3808>
    8000576a:	ffffb097          	auipc	ra,0xffffb
    8000576e:	d9a080e7          	jalr	-614(ra) # 80000504 <printf>
    t3_completed_count = 0;
    80005772:	0000a797          	auipc	a5,0xa
    80005776:	1207ab23          	sw	zero,310(a5) # 8000f8a8 <t3_completed_count>
    while (wait_process(NULL) > 0)
    8000577a:	4501                	li	a0,0
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	b02080e7          	jalr	-1278(ra) # 8000427e <wait_process>
    80005784:	fea04be3          	bgtz	a0,8000577a <test_t3_mixed_priority_aging+0x30>
    printf("Creating mixed priority tasks (high + low)...\n");
    80005788:	00008517          	auipc	a0,0x8
    8000578c:	27850513          	addi	a0,a0,632 # 8000da00 <digits+0x3850>
    80005790:	ffffb097          	auipc	ra,0xffffb
    80005794:	d74080e7          	jalr	-652(ra) # 80000504 <printf>
    int high_pid = create_process_with_priority(t3_mixed_task, PRIORITY_MAX);
    80005798:	45a9                	li	a1,10
    8000579a:	fffff517          	auipc	a0,0xfffff
    8000579e:	efa50513          	addi	a0,a0,-262 # 80004694 <t3_mixed_task>
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	652080e7          	jalr	1618(ra) # 80003df4 <create_process_with_priority>
    800057aa:	84aa                	mv	s1,a0
    assert(high_pid > 0, "High priority process creation should succeed");
    800057ac:	00008597          	auipc	a1,0x8
    800057b0:	adc58593          	addi	a1,a1,-1316 # 8000d288 <digits+0x30d8>
    800057b4:	00a02533          	sgtz	a0,a0
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	d88080e7          	jalr	-632(ra) # 80004540 <assert>
    printf("Created high priority task: PID %d (priority %d)\n", high_pid, PRIORITY_MAX);
    800057c0:	4629                	li	a2,10
    800057c2:	85a6                	mv	a1,s1
    800057c4:	00008517          	auipc	a0,0x8
    800057c8:	26c50513          	addi	a0,a0,620 # 8000da30 <digits+0x3880>
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	d38080e7          	jalr	-712(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    800057d4:	fa040993          	addi	s3,s0,-96
    printf("Created high priority task: PID %d (priority %d)\n", high_pid, PRIORITY_MAX);
    800057d8:	8a4e                	mv	s4,s3
    for (int i = 0; i < 3; i++)
    800057da:	4901                	li	s2,0
        low_pids[i] = create_process_with_priority(t3_mixed_task, PRIORITY_MIN);
    800057dc:	fffffc17          	auipc	s8,0xfffff
    800057e0:	eb8c0c13          	addi	s8,s8,-328 # 80004694 <t3_mixed_task>
        assert(low_pids[i] > 0, "Low priority process creation should succeed");
    800057e4:	00008b97          	auipc	s7,0x8
    800057e8:	a44b8b93          	addi	s7,s7,-1468 # 8000d228 <digits+0x3078>
        printf("Created low priority task %d: PID %d (priority %d)\n", i, low_pids[i], PRIORITY_MIN);
    800057ec:	00008b17          	auipc	s6,0x8
    800057f0:	27cb0b13          	addi	s6,s6,636 # 8000da68 <digits+0x38b8>
    for (int i = 0; i < 3; i++)
    800057f4:	4a8d                	li	s5,3
        low_pids[i] = create_process_with_priority(t3_mixed_task, PRIORITY_MIN);
    800057f6:	4585                	li	a1,1
    800057f8:	8562                	mv	a0,s8
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	5fa080e7          	jalr	1530(ra) # 80003df4 <create_process_with_priority>
    80005802:	84aa                	mv	s1,a0
    80005804:	00aa2023          	sw	a0,0(s4)
        assert(low_pids[i] > 0, "Low priority process creation should succeed");
    80005808:	85de                	mv	a1,s7
    8000580a:	00a02533          	sgtz	a0,a0
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	d32080e7          	jalr	-718(ra) # 80004540 <assert>
        printf("Created low priority task %d: PID %d (priority %d)\n", i, low_pids[i], PRIORITY_MIN);
    80005816:	4685                	li	a3,1
    80005818:	8626                	mv	a2,s1
    8000581a:	85ca                	mv	a1,s2
    8000581c:	855a                	mv	a0,s6
    8000581e:	ffffb097          	auipc	ra,0xffffb
    80005822:	ce6080e7          	jalr	-794(ra) # 80000504 <printf>
        ksleep(1);
    80005826:	4505                	li	a0,1
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	962080e7          	jalr	-1694(ra) # 8000418a <ksleep>
    for (int i = 0; i < 3; i++)
    80005830:	2905                	addiw	s2,s2,1
    80005832:	0a11                	addi	s4,s4,4
    80005834:	fd5911e3          	bne	s2,s5,800057f6 <test_t3_mixed_priority_aging+0xac>
    t3_total_tasks = 4; // 1 high + 3 low
    80005838:	4791                	li	a5,4
    8000583a:	0000a717          	auipc	a4,0xa
    8000583e:	06f72523          	sw	a5,106(a4) # 8000f8a4 <t3_total_tasks>
    printf("Waiting for aging mechanism to take effect (waiting %d ticks)...\n", aging_wait);
    80005842:	05200593          	li	a1,82
    80005846:	00008517          	auipc	a0,0x8
    8000584a:	25a50513          	addi	a0,a0,602 # 8000daa0 <digits+0x38f0>
    8000584e:	ffffb097          	auipc	ra,0xffffb
    80005852:	cb6080e7          	jalr	-842(ra) # 80000504 <printf>
    ksleep(aging_wait);
    80005856:	05200513          	li	a0,82
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	930080e7          	jalr	-1744(ra) # 8000418a <ksleep>
    for (int i = 0; i < 3; i++)
    80005862:	4481                	li	s1,0
        printf("Low priority task %d (PID %d) current priority: %d\n", i, low_pids[i], priority);
    80005864:	00008a97          	auipc	s5,0x8
    80005868:	284a8a93          	addi	s5,s5,644 # 8000dae8 <digits+0x3938>
    for (int i = 0; i < 3; i++)
    8000586c:	4a0d                	li	s4,3
        int priority = sys_getpriority(low_pids[i]);
    8000586e:	0009a903          	lw	s2,0(s3)
    80005872:	854a                	mv	a0,s2
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	c9c080e7          	jalr	-868(ra) # 80004510 <sys_getpriority>
    8000587c:	86aa                	mv	a3,a0
        printf("Low priority task %d (PID %d) current priority: %d\n", i, low_pids[i], priority);
    8000587e:	864a                	mv	a2,s2
    80005880:	85a6                	mv	a1,s1
    80005882:	8556                	mv	a0,s5
    80005884:	ffffb097          	auipc	ra,0xffffb
    80005888:	c80080e7          	jalr	-896(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    8000588c:	2485                	addiw	s1,s1,1
    8000588e:	0991                	addi	s3,s3,4
    80005890:	fd449fe3          	bne	s1,s4,8000586e <test_t3_mixed_priority_aging+0x124>
    printf("Waiting for all tasks to complete...\n");
    80005894:	00008517          	auipc	a0,0x8
    80005898:	28c50513          	addi	a0,a0,652 # 8000db20 <digits+0x3970>
    8000589c:	ffffb097          	auipc	ra,0xffffb
    800058a0:	c68080e7          	jalr	-920(ra) # 80000504 <printf>
    for (int i = 0; i < t3_total_tasks; i++)
    800058a4:	0000a617          	auipc	a2,0xa
    800058a8:	00062603          	lw	a2,0(a2) # 8000f8a4 <t3_total_tasks>
    800058ac:	06c05563          	blez	a2,80005916 <test_t3_mixed_priority_aging+0x1cc>
    800058b0:	4901                	li	s2,0
        assert(reaped_pid > 0, "Should reap test process");
    800058b2:	00008b17          	auipc	s6,0x8
    800058b6:	d96b0b13          	addi	s6,s6,-618 # 8000d648 <digits+0x3498>
        assert(status == 0, "Task should exit successfully");
    800058ba:	00008a97          	auipc	s5,0x8
    800058be:	daea8a93          	addi	s5,s5,-594 # 8000d668 <digits+0x34b8>
        printf("Reaped task PID %d\n", reaped_pid);
    800058c2:	00008a17          	auipc	s4,0x8
    800058c6:	dc6a0a13          	addi	s4,s4,-570 # 8000d688 <digits+0x34d8>
    for (int i = 0; i < t3_total_tasks; i++)
    800058ca:	0000a997          	auipc	s3,0xa
    800058ce:	fda98993          	addi	s3,s3,-38 # 8000f8a4 <t3_total_tasks>
        int reaped_pid = wait_process(&status);
    800058d2:	f9c40513          	addi	a0,s0,-100
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	9a8080e7          	jalr	-1624(ra) # 8000427e <wait_process>
    800058de:	84aa                	mv	s1,a0
        assert(reaped_pid > 0, "Should reap test process");
    800058e0:	85da                	mv	a1,s6
    800058e2:	00a02533          	sgtz	a0,a0
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	c5a080e7          	jalr	-934(ra) # 80004540 <assert>
        assert(status == 0, "Task should exit successfully");
    800058ee:	f9c42503          	lw	a0,-100(s0)
    800058f2:	85d6                	mv	a1,s5
    800058f4:	00153513          	seqz	a0,a0
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	c48080e7          	jalr	-952(ra) # 80004540 <assert>
        printf("Reaped task PID %d\n", reaped_pid);
    80005900:	85a6                	mv	a1,s1
    80005902:	8552                	mv	a0,s4
    80005904:	ffffb097          	auipc	ra,0xffffb
    80005908:	c00080e7          	jalr	-1024(ra) # 80000504 <printf>
    for (int i = 0; i < t3_total_tasks; i++)
    8000590c:	2905                	addiw	s2,s2,1
    8000590e:	0009a603          	lw	a2,0(s3)
    80005912:	fcc940e3          	blt	s2,a2,800058d2 <test_t3_mixed_priority_aging+0x188>
    printf("Completed tasks: %d/%d\n", t3_completed_count, t3_total_tasks);
    80005916:	0000a497          	auipc	s1,0xa
    8000591a:	f9248493          	addi	s1,s1,-110 # 8000f8a8 <t3_completed_count>
    8000591e:	408c                	lw	a1,0(s1)
    80005920:	00008517          	auipc	a0,0x8
    80005924:	22850513          	addi	a0,a0,552 # 8000db48 <digits+0x3998>
    80005928:	ffffb097          	auipc	ra,0xffffb
    8000592c:	bdc080e7          	jalr	-1060(ra) # 80000504 <printf>
    assert(t3_completed_count == t3_total_tasks, "All tasks should complete (aging prevents starvation)");
    80005930:	4088                	lw	a0,0(s1)
    80005932:	0000a797          	auipc	a5,0xa
    80005936:	f727a783          	lw	a5,-142(a5) # 8000f8a4 <t3_total_tasks>
    8000593a:	8d1d                	sub	a0,a0,a5
    8000593c:	00008597          	auipc	a1,0x8
    80005940:	22458593          	addi	a1,a1,548 # 8000db60 <digits+0x39b0>
    80005944:	00153513          	seqz	a0,a0
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	bf8080e7          	jalr	-1032(ra) # 80004540 <assert>
    printf("✓ T3 Test: All tasks completed (aging mechanism working correctly)\n");
    80005950:	00008517          	auipc	a0,0x8
    80005954:	24850513          	addi	a0,a0,584 # 8000db98 <digits+0x39e8>
    80005958:	ffffb097          	auipc	ra,0xffffb
    8000595c:	bac080e7          	jalr	-1108(ra) # 80000504 <printf>
    printf("T3 test completed\n");
    80005960:	00008517          	auipc	a0,0x8
    80005964:	28050513          	addi	a0,a0,640 # 8000dbe0 <digits+0x3a30>
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	b9c080e7          	jalr	-1124(ra) # 80000504 <printf>
}
    80005970:	70a6                	ld	ra,104(sp)
    80005972:	7406                	ld	s0,96(sp)
    80005974:	64e6                	ld	s1,88(sp)
    80005976:	6946                	ld	s2,80(sp)
    80005978:	69a6                	ld	s3,72(sp)
    8000597a:	6a06                	ld	s4,64(sp)
    8000597c:	7ae2                	ld	s5,56(sp)
    8000597e:	7b42                	ld	s6,48(sp)
    80005980:	7ba2                	ld	s7,40(sp)
    80005982:	7c02                	ld	s8,32(sp)
    80005984:	6165                	addi	sp,sp,112
    80005986:	8082                	ret

0000000080005988 <test_syscall_priority>:
{
    80005988:	1101                	addi	sp,sp,-32
    8000598a:	ec06                	sd	ra,24(sp)
    8000598c:	e822                	sd	s0,16(sp)
    8000598e:	e426                	sd	s1,8(sp)
    80005990:	e04a                	sd	s2,0(sp)
    80005992:	1000                	addi	s0,sp,32
    printf("\n=== Testing Priority System Calls ===\n");
    80005994:	00008517          	auipc	a0,0x8
    80005998:	26450513          	addi	a0,a0,612 # 8000dbf8 <digits+0x3a48>
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	b68080e7          	jalr	-1176(ra) # 80000504 <printf>
    int test_pid = create_process(aging_test_task);
    800059a4:	fffff517          	auipc	a0,0xfffff
    800059a8:	d7c50513          	addi	a0,a0,-644 # 80004720 <aging_test_task>
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	4c6080e7          	jalr	1222(ra) # 80003e72 <create_process>
    800059b4:	84aa                	mv	s1,a0
    assert(test_pid > 0, "Test process creation should succeed");
    800059b6:	00008597          	auipc	a1,0x8
    800059ba:	26a58593          	addi	a1,a1,618 # 8000dc20 <digits+0x3a70>
    800059be:	00a02533          	sgtz	a0,a0
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	b7e080e7          	jalr	-1154(ra) # 80004540 <assert>
    printf("Testing sys_getpriority for PID %d (immediately after creation)...\n", test_pid);
    800059ca:	85a6                	mv	a1,s1
    800059cc:	00008517          	auipc	a0,0x8
    800059d0:	27c50513          	addi	a0,a0,636 # 8000dc48 <digits+0x3a98>
    800059d4:	ffffb097          	auipc	ra,0xffffb
    800059d8:	b30080e7          	jalr	-1232(ra) # 80000504 <printf>
    int priority = sys_getpriority(test_pid);
    800059dc:	8526                	mv	a0,s1
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	b32080e7          	jalr	-1230(ra) # 80004510 <sys_getpriority>
    800059e6:	892a                	mv	s2,a0
    assert(priority >= PRIORITY_DEFAULT && priority <= PRIORITY_MAX,
    800059e8:	356d                	addiw	a0,a0,-5
    800059ea:	00008597          	auipc	a1,0x8
    800059ee:	2a658593          	addi	a1,a1,678 # 8000dc90 <digits+0x3ae0>
    800059f2:	00653513          	sltiu	a0,a0,6
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	b4a080e7          	jalr	-1206(ra) # 80004540 <assert>
    printf("✓ Got priority %d for PID %d (expected default: %d, may be affected by aging)\n",
    800059fe:	4695                	li	a3,5
    80005a00:	8626                	mv	a2,s1
    80005a02:	85ca                	mv	a1,s2
    80005a04:	00008517          	auipc	a0,0x8
    80005a08:	2b450513          	addi	a0,a0,692 # 8000dcb8 <digits+0x3b08>
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	af8080e7          	jalr	-1288(ra) # 80000504 <printf>
    printf("Testing sys_setpriority: setting PID %d to priority %d...\n", test_pid, PRIORITY_MAX);
    80005a14:	4629                	li	a2,10
    80005a16:	85a6                	mv	a1,s1
    80005a18:	00008517          	auipc	a0,0x8
    80005a1c:	2f850513          	addi	a0,a0,760 # 8000dd10 <digits+0x3b60>
    80005a20:	ffffb097          	auipc	ra,0xffffb
    80005a24:	ae4080e7          	jalr	-1308(ra) # 80000504 <printf>
    int result = sys_setpriority(test_pid, PRIORITY_MAX);
    80005a28:	45a9                	li	a1,10
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	a8e080e7          	jalr	-1394(ra) # 800044ba <sys_setpriority>
    assert(result == 0, "sys_setpriority should succeed");
    80005a34:	00008597          	auipc	a1,0x8
    80005a38:	31c58593          	addi	a1,a1,796 # 8000dd50 <digits+0x3ba0>
    80005a3c:	00153513          	seqz	a0,a0
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	b00080e7          	jalr	-1280(ra) # 80004540 <assert>
    priority = sys_getpriority(test_pid);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	ac6080e7          	jalr	-1338(ra) # 80004510 <sys_getpriority>
    80005a52:	892a                	mv	s2,a0
    assert(priority == PRIORITY_MAX, "Priority should be updated to PRIORITY_MAX");
    80005a54:	1559                	addi	a0,a0,-10
    80005a56:	00008597          	auipc	a1,0x8
    80005a5a:	31a58593          	addi	a1,a1,794 # 8000dd70 <digits+0x3bc0>
    80005a5e:	00153513          	seqz	a0,a0
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	ade080e7          	jalr	-1314(ra) # 80004540 <assert>
    printf("✓ Priority updated to %d for PID %d\n", priority, test_pid);
    80005a6a:	8626                	mv	a2,s1
    80005a6c:	85ca                	mv	a1,s2
    80005a6e:	00008517          	auipc	a0,0x8
    80005a72:	33250513          	addi	a0,a0,818 # 8000dda0 <digits+0x3bf0>
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	a8e080e7          	jalr	-1394(ra) # 80000504 <printf>
    printf("Priority system call tests completed\n");
    80005a7e:	00008517          	auipc	a0,0x8
    80005a82:	34a50513          	addi	a0,a0,842 # 8000ddc8 <digits+0x3c18>
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	a7e080e7          	jalr	-1410(ra) # 80000504 <printf>
}
    80005a8e:	60e2                	ld	ra,24(sp)
    80005a90:	6442                	ld	s0,16(sp)
    80005a92:	64a2                	ld	s1,8(sp)
    80005a94:	6902                	ld	s2,0(sp)
    80005a96:	6105                	addi	sp,sp,32
    80005a98:	8082                	ret

0000000080005a9a <test_aging_mechanism>:
{
    80005a9a:	7159                	addi	sp,sp,-112
    80005a9c:	f486                	sd	ra,104(sp)
    80005a9e:	f0a2                	sd	s0,96(sp)
    80005aa0:	eca6                	sd	s1,88(sp)
    80005aa2:	e8ca                	sd	s2,80(sp)
    80005aa4:	e4ce                	sd	s3,72(sp)
    80005aa6:	e0d2                	sd	s4,64(sp)
    80005aa8:	fc56                	sd	s5,56(sp)
    80005aaa:	f85a                	sd	s6,48(sp)
    80005aac:	f45e                	sd	s7,40(sp)
    80005aae:	1880                	addi	s0,sp,112
    printf("\n=== Testing Aging Mechanism ===\n");
    80005ab0:	00008517          	auipc	a0,0x8
    80005ab4:	34050513          	addi	a0,a0,832 # 8000ddf0 <digits+0x3c40>
    80005ab8:	ffffb097          	auipc	ra,0xffffb
    80005abc:	a4c080e7          	jalr	-1460(ra) # 80000504 <printf>
    printf("Creating low priority processes to test aging...\n");
    80005ac0:	00008517          	auipc	a0,0x8
    80005ac4:	35850513          	addi	a0,a0,856 # 8000de18 <digits+0x3c68>
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	a3c080e7          	jalr	-1476(ra) # 80000504 <printf>
    for (int i = 0; i < 3; i++)
    80005ad0:	fa040913          	addi	s2,s0,-96
    80005ad4:	fac40a13          	addi	s4,s0,-84
    printf("Creating low priority processes to test aging...\n");
    80005ad8:	89ca                	mv	s3,s2
        pids[i] = create_process_with_priority(aging_test_task, PRIORITY_MIN);
    80005ada:	fffffb97          	auipc	s7,0xfffff
    80005ade:	c46b8b93          	addi	s7,s7,-954 # 80004720 <aging_test_task>
        assert(pids[i] > 0, "Process creation should succeed");
    80005ae2:	00008b17          	auipc	s6,0x8
    80005ae6:	db6b0b13          	addi	s6,s6,-586 # 8000d898 <digits+0x36e8>
        printf("Created process PID %d with priority %d\n", pids[i], PRIORITY_MIN);
    80005aea:	00008a97          	auipc	s5,0x8
    80005aee:	366a8a93          	addi	s5,s5,870 # 8000de50 <digits+0x3ca0>
        pids[i] = create_process_with_priority(aging_test_task, PRIORITY_MIN);
    80005af2:	4585                	li	a1,1
    80005af4:	855e                	mv	a0,s7
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	2fe080e7          	jalr	766(ra) # 80003df4 <create_process_with_priority>
    80005afe:	84aa                	mv	s1,a0
    80005b00:	00a9a023          	sw	a0,0(s3)
        assert(pids[i] > 0, "Process creation should succeed");
    80005b04:	85da                	mv	a1,s6
    80005b06:	00a02533          	sgtz	a0,a0
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	a36080e7          	jalr	-1482(ra) # 80004540 <assert>
        printf("Created process PID %d with priority %d\n", pids[i], PRIORITY_MIN);
    80005b12:	4605                	li	a2,1
    80005b14:	85a6                	mv	a1,s1
    80005b16:	8556                	mv	a0,s5
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	9ec080e7          	jalr	-1556(ra) # 80000504 <printf>
        ksleep(1);
    80005b20:	4505                	li	a0,1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	668080e7          	jalr	1640(ra) # 8000418a <ksleep>
    for (int i = 0; i < 3; i++)
    80005b2a:	0991                	addi	s3,s3,4
    80005b2c:	fd4993e3          	bne	s3,s4,80005af2 <test_aging_mechanism+0x58>
    printf("Waiting for aging mechanism to take effect (waiting %d ticks)...\n", aging_wait);
    80005b30:	09600593          	li	a1,150
    80005b34:	00008517          	auipc	a0,0x8
    80005b38:	f6c50513          	addi	a0,a0,-148 # 8000daa0 <digits+0x38f0>
    80005b3c:	ffffb097          	auipc	ra,0xffffb
    80005b40:	9c8080e7          	jalr	-1592(ra) # 80000504 <printf>
    ksleep(aging_wait);
    80005b44:	09600513          	li	a0,150
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	642080e7          	jalr	1602(ra) # 8000418a <ksleep>
        printf("PID %d current priority: %d (started at %d)\n", pids[i], priority, PRIORITY_MIN);
    80005b50:	00008b17          	auipc	s6,0x8
    80005b54:	330b0b13          	addi	s6,s6,816 # 8000de80 <digits+0x3cd0>
        assert(priority >= PRIORITY_MIN && priority <= PRIORITY_MAX,
    80005b58:	00008a97          	auipc	s5,0x8
    80005b5c:	138a8a93          	addi	s5,s5,312 # 8000dc90 <digits+0x3ae0>
        int priority = sys_getpriority(pids[i]);
    80005b60:	00092983          	lw	s3,0(s2)
    80005b64:	854e                	mv	a0,s3
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	9aa080e7          	jalr	-1622(ra) # 80004510 <sys_getpriority>
    80005b6e:	84aa                	mv	s1,a0
        printf("PID %d current priority: %d (started at %d)\n", pids[i], priority, PRIORITY_MIN);
    80005b70:	4685                	li	a3,1
    80005b72:	862a                	mv	a2,a0
    80005b74:	85ce                	mv	a1,s3
    80005b76:	855a                	mv	a0,s6
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	98c080e7          	jalr	-1652(ra) # 80000504 <printf>
        assert(priority >= PRIORITY_MIN && priority <= PRIORITY_MAX,
    80005b80:	fff4851b          	addiw	a0,s1,-1
    80005b84:	85d6                	mv	a1,s5
    80005b86:	00a53513          	sltiu	a0,a0,10
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	9b6080e7          	jalr	-1610(ra) # 80004540 <assert>
    for (int i = 0; i < 3; i++)
    80005b92:	0911                	addi	s2,s2,4
    80005b94:	fd4916e3          	bne	s2,s4,80005b60 <test_aging_mechanism+0xc6>
    printf("Waiting for test processes to complete...\n");
    80005b98:	00008517          	auipc	a0,0x8
    80005b9c:	31850513          	addi	a0,a0,792 # 8000deb0 <digits+0x3d00>
    80005ba0:	ffffb097          	auipc	ra,0xffffb
    80005ba4:	964080e7          	jalr	-1692(ra) # 80000504 <printf>
    80005ba8:	448d                	li	s1,3
        assert(reaped > 0, "Should reap test process");
    80005baa:	00008917          	auipc	s2,0x8
    80005bae:	a9e90913          	addi	s2,s2,-1378 # 8000d648 <digits+0x3498>
        int reaped = wait_process(&status);
    80005bb2:	f9c40513          	addi	a0,s0,-100
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	6c8080e7          	jalr	1736(ra) # 8000427e <wait_process>
        assert(reaped > 0, "Should reap test process");
    80005bbe:	85ca                	mv	a1,s2
    80005bc0:	00a02533          	sgtz	a0,a0
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	97c080e7          	jalr	-1668(ra) # 80004540 <assert>
    for (int i = 0; i < 3; i++)
    80005bcc:	34fd                	addiw	s1,s1,-1
    80005bce:	f0f5                	bnez	s1,80005bb2 <test_aging_mechanism+0x118>
    printf("Aging mechanism test completed\n");
    80005bd0:	00008517          	auipc	a0,0x8
    80005bd4:	31050513          	addi	a0,a0,784 # 8000dee0 <digits+0x3d30>
    80005bd8:	ffffb097          	auipc	ra,0xffffb
    80005bdc:	92c080e7          	jalr	-1748(ra) # 80000504 <printf>
}
    80005be0:	70a6                	ld	ra,104(sp)
    80005be2:	7406                	ld	s0,96(sp)
    80005be4:	64e6                	ld	s1,88(sp)
    80005be6:	6946                	ld	s2,80(sp)
    80005be8:	69a6                	ld	s3,72(sp)
    80005bea:	6a06                	ld	s4,64(sp)
    80005bec:	7ae2                	ld	s5,56(sp)
    80005bee:	7b42                	ld	s6,48(sp)
    80005bf0:	7ba2                	ld	s7,40(sp)
    80005bf2:	6165                	addi	sp,sp,112
    80005bf4:	8082                	ret

0000000080005bf6 <test_mlfq_scheduling>:
{
    80005bf6:	711d                	addi	sp,sp,-96
    80005bf8:	ec86                	sd	ra,88(sp)
    80005bfa:	e8a2                	sd	s0,80(sp)
    80005bfc:	e4a6                	sd	s1,72(sp)
    80005bfe:	e0ca                	sd	s2,64(sp)
    80005c00:	fc4e                	sd	s3,56(sp)
    80005c02:	f852                	sd	s4,48(sp)
    80005c04:	f456                	sd	s5,40(sp)
    80005c06:	f05a                	sd	s6,32(sp)
    80005c08:	ec5e                	sd	s7,24(sp)
    80005c0a:	1080                	addi	s0,sp,96
    printf("\n=== Testing MLFQ Scheduling ===\n");
    80005c0c:	00008517          	auipc	a0,0x8
    80005c10:	2f450513          	addi	a0,a0,756 # 8000df00 <digits+0x3d50>
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	8f0080e7          	jalr	-1808(ra) # 80000504 <printf>
    mlfq_cpu_initial_priority = -1;
    80005c1c:	57fd                	li	a5,-1
    80005c1e:	0000a717          	auipc	a4,0xa
    80005c22:	c0f72d23          	sw	a5,-998(a4) # 8000f838 <mlfq_cpu_initial_priority>
    mlfq_cpu_final_priority = -1;
    80005c26:	0000a717          	auipc	a4,0xa
    80005c2a:	c0f72723          	sw	a5,-1010(a4) # 8000f834 <mlfq_cpu_final_priority>
    mlfq_int_initial_priority = -1;
    80005c2e:	0000a717          	auipc	a4,0xa
    80005c32:	c0f72123          	sw	a5,-1022(a4) # 8000f830 <mlfq_int_initial_priority>
    mlfq_int_final_priority = -1;
    80005c36:	0000a717          	auipc	a4,0xa
    80005c3a:	bef72b23          	sw	a5,-1034(a4) # 8000f82c <mlfq_int_final_priority>
    mlfq_cpu_intensive_count = 0;
    80005c3e:	0000a797          	auipc	a5,0xa
    80005c42:	c607a123          	sw	zero,-926(a5) # 8000f8a0 <mlfq_cpu_intensive_count>
    mlfq_interactive_count = 0;
    80005c46:	0000a797          	auipc	a5,0xa
    80005c4a:	c407ab23          	sw	zero,-938(a5) # 8000f89c <mlfq_interactive_count>
    while (wait_process(NULL) > 0)
    80005c4e:	4501                	li	a0,0
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	62e080e7          	jalr	1582(ra) # 8000427e <wait_process>
    80005c58:	fea04be3          	bgtz	a0,80005c4e <test_mlfq_scheduling+0x58>
    printf("Creating tasks with different behaviors:\n");
    80005c5c:	00008517          	auipc	a0,0x8
    80005c60:	2cc50513          	addi	a0,a0,716 # 8000df28 <digits+0x3d78>
    80005c64:	ffffb097          	auipc	ra,0xffffb
    80005c68:	8a0080e7          	jalr	-1888(ra) # 80000504 <printf>
    printf("  CPU-intensive task: priority %d (will demote: %d -> %d -> ... after %d consecutive slices)\n",
    80005c6c:	470d                	li	a4,3
    80005c6e:	469d                	li	a3,7
    80005c70:	4621                	li	a2,8
    80005c72:	45a1                	li	a1,8
    80005c74:	00008517          	auipc	a0,0x8
    80005c78:	2e450513          	addi	a0,a0,740 # 8000df58 <digits+0x3da8>
    80005c7c:	ffffb097          	auipc	ra,0xffffb
    80005c80:	888080e7          	jalr	-1912(ra) # 80000504 <printf>
    printf("  Interactive task: priority %d (should maintain high priority via frequent yields)\n",
    80005c84:	45a5                	li	a1,9
    80005c86:	00008517          	auipc	a0,0x8
    80005c8a:	33250513          	addi	a0,a0,818 # 8000dfb8 <digits+0x3e08>
    80005c8e:	ffffb097          	auipc	ra,0xffffb
    80005c92:	876080e7          	jalr	-1930(ra) # 80000504 <printf>
    int cpu_pid = create_process_with_priority(mlfq_cpu_intensive_task, cpu_start_priority);
    80005c96:	45a1                	li	a1,8
    80005c98:	fffff517          	auipc	a0,0xfffff
    80005c9c:	b0250513          	addi	a0,a0,-1278 # 8000479a <mlfq_cpu_intensive_task>
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	154080e7          	jalr	340(ra) # 80003df4 <create_process_with_priority>
    80005ca8:	8a2a                	mv	s4,a0
    int int_pid = create_process_with_priority(mlfq_interactive_task, int_start_priority);
    80005caa:	45a5                	li	a1,9
    80005cac:	fffff517          	auipc	a0,0xfffff
    80005cb0:	05050513          	addi	a0,a0,80 # 80004cfc <mlfq_interactive_task>
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	140080e7          	jalr	320(ra) # 80003df4 <create_process_with_priority>
    80005cbc:	89aa                	mv	s3,a0
    assert(cpu_pid > 0, "CPU-intensive process creation should succeed");
    80005cbe:	00008597          	auipc	a1,0x8
    80005cc2:	35258593          	addi	a1,a1,850 # 8000e010 <digits+0x3e60>
    80005cc6:	01402533          	sgtz	a0,s4
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	876080e7          	jalr	-1930(ra) # 80004540 <assert>
    assert(int_pid > 0, "Interactive process creation should succeed");
    80005cd2:	00008597          	auipc	a1,0x8
    80005cd6:	36e58593          	addi	a1,a1,878 # 8000e040 <digits+0x3e90>
    80005cda:	01302533          	sgtz	a0,s3
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	862080e7          	jalr	-1950(ra) # 80004540 <assert>
    printf("Created: CPU-intensive(PID %d, priority %d), Interactive(PID %d, priority %d)\n",
    80005ce6:	4725                	li	a4,9
    80005ce8:	86ce                	mv	a3,s3
    80005cea:	4621                	li	a2,8
    80005cec:	85d2                	mv	a1,s4
    80005cee:	00008517          	auipc	a0,0x8
    80005cf2:	38250513          	addi	a0,a0,898 # 8000e070 <digits+0x3ec0>
    80005cf6:	ffffb097          	auipc	ra,0xffffb
    80005cfa:	80e080e7          	jalr	-2034(ra) # 80000504 <printf>
    printf("CPU-intensive task will use complex calculations to prevent compiler optimization.\n");
    80005cfe:	00008517          	auipc	a0,0x8
    80005d02:	3c250513          	addi	a0,a0,962 # 8000e0c0 <digits+0x3f10>
    80005d06:	ffffa097          	auipc	ra,0xffffa
    80005d0a:	7fe080e7          	jalr	2046(ra) # 80000504 <printf>
    printf("Interactive task will frequently yield to maintain high priority.\n");
    80005d0e:	00008517          	auipc	a0,0x8
    80005d12:	40a50513          	addi	a0,a0,1034 # 8000e118 <digits+0x3f68>
    80005d16:	ffffa097          	auipc	ra,0xffffa
    80005d1a:	7ee080e7          	jalr	2030(ra) # 80000504 <printf>
    printf("Waiting for tasks to complete...\n");
    80005d1e:	00008517          	auipc	a0,0x8
    80005d22:	90250513          	addi	a0,a0,-1790 # 8000d620 <digits+0x3470>
    80005d26:	ffffa097          	auipc	ra,0xffffa
    80005d2a:	7de080e7          	jalr	2014(ra) # 80000504 <printf>
    80005d2e:	4909                	li	s2,2
        assert(reaped_pid > 0, "Should reap test process");
    80005d30:	00008b97          	auipc	s7,0x8
    80005d34:	918b8b93          	addi	s7,s7,-1768 # 8000d648 <digits+0x3498>
        assert(status == 0, "Task should exit successfully");
    80005d38:	00008b17          	auipc	s6,0x8
    80005d3c:	930b0b13          	addi	s6,s6,-1744 # 8000d668 <digits+0x34b8>
        printf("Reaped task PID %d\n", reaped_pid);
    80005d40:	00008a97          	auipc	s5,0x8
    80005d44:	948a8a93          	addi	s5,s5,-1720 # 8000d688 <digits+0x34d8>
        int reaped_pid = wait_process(&status);
    80005d48:	fac40513          	addi	a0,s0,-84
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	532080e7          	jalr	1330(ra) # 8000427e <wait_process>
    80005d54:	84aa                	mv	s1,a0
        assert(reaped_pid > 0, "Should reap test process");
    80005d56:	85de                	mv	a1,s7
    80005d58:	00a02533          	sgtz	a0,a0
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	7e4080e7          	jalr	2020(ra) # 80004540 <assert>
        assert(status == 0, "Task should exit successfully");
    80005d64:	fac42503          	lw	a0,-84(s0)
    80005d68:	85da                	mv	a1,s6
    80005d6a:	00153513          	seqz	a0,a0
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	7d2080e7          	jalr	2002(ra) # 80004540 <assert>
        printf("Reaped task PID %d\n", reaped_pid);
    80005d76:	85a6                	mv	a1,s1
    80005d78:	8556                	mv	a0,s5
    80005d7a:	ffffa097          	auipc	ra,0xffffa
    80005d7e:	78a080e7          	jalr	1930(ra) # 80000504 <printf>
    for (int i = 0; i < 2; i++)
    80005d82:	397d                	addiw	s2,s2,-1
    80005d84:	fc0912e3          	bnez	s2,80005d48 <test_mlfq_scheduling+0x152>
    assert(mlfq_cpu_intensive_count == 1, "CPU-intensive task should complete");
    80005d88:	0000a517          	auipc	a0,0xa
    80005d8c:	b1852503          	lw	a0,-1256(a0) # 8000f8a0 <mlfq_cpu_intensive_count>
    80005d90:	157d                	addi	a0,a0,-1
    80005d92:	00008597          	auipc	a1,0x8
    80005d96:	3ce58593          	addi	a1,a1,974 # 8000e160 <digits+0x3fb0>
    80005d9a:	00153513          	seqz	a0,a0
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	7a2080e7          	jalr	1954(ra) # 80004540 <assert>
    assert(mlfq_interactive_count == 1, "Interactive task should complete");
    80005da6:	0000a517          	auipc	a0,0xa
    80005daa:	af652503          	lw	a0,-1290(a0) # 8000f89c <mlfq_interactive_count>
    80005dae:	157d                	addi	a0,a0,-1
    80005db0:	00008597          	auipc	a1,0x8
    80005db4:	3d858593          	addi	a1,a1,984 # 8000e188 <digits+0x3fd8>
    80005db8:	00153513          	seqz	a0,a0
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	784080e7          	jalr	1924(ra) # 80004540 <assert>
    printf("\nPriority changes:\n");
    80005dc4:	00008517          	auipc	a0,0x8
    80005dc8:	3ec50513          	addi	a0,a0,1004 # 8000e1b0 <digits+0x4000>
    80005dcc:	ffffa097          	auipc	ra,0xffffa
    80005dd0:	738080e7          	jalr	1848(ra) # 80000504 <printf>
    printf("  CPU-intensive (PID %d): %d -> %d\n",
    80005dd4:	0000a617          	auipc	a2,0xa
    80005dd8:	a6462603          	lw	a2,-1436(a2) # 8000f838 <mlfq_cpu_initial_priority>
    80005ddc:	0000a697          	auipc	a3,0xa
    80005de0:	a586a683          	lw	a3,-1448(a3) # 8000f834 <mlfq_cpu_final_priority>
    80005de4:	85d2                	mv	a1,s4
    80005de6:	00008517          	auipc	a0,0x8
    80005dea:	3e250513          	addi	a0,a0,994 # 8000e1c8 <digits+0x4018>
    80005dee:	ffffa097          	auipc	ra,0xffffa
    80005df2:	716080e7          	jalr	1814(ra) # 80000504 <printf>
    printf("  Interactive (PID %d): %d -> %d\n",
    80005df6:	0000a617          	auipc	a2,0xa
    80005dfa:	a3a62603          	lw	a2,-1478(a2) # 8000f830 <mlfq_int_initial_priority>
    80005dfe:	0000a697          	auipc	a3,0xa
    80005e02:	a2e6a683          	lw	a3,-1490(a3) # 8000f82c <mlfq_int_final_priority>
    80005e06:	85ce                	mv	a1,s3
    80005e08:	00008517          	auipc	a0,0x8
    80005e0c:	3e850513          	addi	a0,a0,1000 # 8000e1f0 <digits+0x4040>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	6f4080e7          	jalr	1780(ra) # 80000504 <printf>
    if (mlfq_cpu_final_priority != -1 && mlfq_cpu_final_priority < mlfq_cpu_initial_priority)
    80005e18:	0000a717          	auipc	a4,0xa
    80005e1c:	a1c72703          	lw	a4,-1508(a4) # 8000f834 <mlfq_cpu_final_priority>
    80005e20:	57fd                	li	a5,-1
    80005e22:	00f70c63          	beq	a4,a5,80005e3a <test_mlfq_scheduling+0x244>
    80005e26:	0000a717          	auipc	a4,0xa
    80005e2a:	a0e72703          	lw	a4,-1522(a4) # 8000f834 <mlfq_cpu_final_priority>
    80005e2e:	0000a797          	auipc	a5,0xa
    80005e32:	a0a7a783          	lw	a5,-1526(a5) # 8000f838 <mlfq_cpu_initial_priority>
    80005e36:	08f74863          	blt	a4,a5,80005ec6 <test_mlfq_scheduling+0x2d0>
    else if (mlfq_cpu_final_priority == mlfq_cpu_initial_priority)
    80005e3a:	0000a717          	auipc	a4,0xa
    80005e3e:	9fa72703          	lw	a4,-1542(a4) # 8000f834 <mlfq_cpu_final_priority>
    80005e42:	0000a797          	auipc	a5,0xa
    80005e46:	9f67a783          	lw	a5,-1546(a5) # 8000f838 <mlfq_cpu_initial_priority>
    80005e4a:	0cf70463          	beq	a4,a5,80005f12 <test_mlfq_scheduling+0x31c>
        printf("⚠ MLFQ Test: CPU-intensive task priority changed unexpectedly\n");
    80005e4e:	00008517          	auipc	a0,0x8
    80005e52:	4fa50513          	addi	a0,a0,1274 # 8000e348 <digits+0x4198>
    80005e56:	ffffa097          	auipc	ra,0xffffa
    80005e5a:	6ae080e7          	jalr	1710(ra) # 80000504 <printf>
    if (mlfq_int_final_priority != -1 && mlfq_int_final_priority >= mlfq_int_initial_priority)
    80005e5e:	0000a717          	auipc	a4,0xa
    80005e62:	9ce72703          	lw	a4,-1586(a4) # 8000f82c <mlfq_int_final_priority>
    80005e66:	57fd                	li	a5,-1
    80005e68:	00f70c63          	beq	a4,a5,80005e80 <test_mlfq_scheduling+0x28a>
    80005e6c:	0000a717          	auipc	a4,0xa
    80005e70:	9c072703          	lw	a4,-1600(a4) # 8000f82c <mlfq_int_final_priority>
    80005e74:	0000a797          	auipc	a5,0xa
    80005e78:	9bc7a783          	lw	a5,-1604(a5) # 8000f830 <mlfq_int_initial_priority>
    80005e7c:	0af75d63          	bge	a4,a5,80005f36 <test_mlfq_scheduling+0x340>
        printf("⚠ MLFQ Test: Interactive task priority decreased unexpectedly (%d -> %d)\n",
    80005e80:	0000a597          	auipc	a1,0xa
    80005e84:	9b05a583          	lw	a1,-1616(a1) # 8000f830 <mlfq_int_initial_priority>
    80005e88:	0000a617          	auipc	a2,0xa
    80005e8c:	9a462603          	lw	a2,-1628(a2) # 8000f82c <mlfq_int_final_priority>
    80005e90:	00008517          	auipc	a0,0x8
    80005e94:	55050513          	addi	a0,a0,1360 # 8000e3e0 <digits+0x4230>
    80005e98:	ffffa097          	auipc	ra,0xffffa
    80005e9c:	66c080e7          	jalr	1644(ra) # 80000504 <printf>
    printf("MLFQ test completed\n");
    80005ea0:	00008517          	auipc	a0,0x8
    80005ea4:	59050513          	addi	a0,a0,1424 # 8000e430 <digits+0x4280>
    80005ea8:	ffffa097          	auipc	ra,0xffffa
    80005eac:	65c080e7          	jalr	1628(ra) # 80000504 <printf>
}
    80005eb0:	60e6                	ld	ra,88(sp)
    80005eb2:	6446                	ld	s0,80(sp)
    80005eb4:	64a6                	ld	s1,72(sp)
    80005eb6:	6906                	ld	s2,64(sp)
    80005eb8:	79e2                	ld	s3,56(sp)
    80005eba:	7a42                	ld	s4,48(sp)
    80005ebc:	7aa2                	ld	s5,40(sp)
    80005ebe:	7b02                	ld	s6,32(sp)
    80005ec0:	6be2                	ld	s7,24(sp)
    80005ec2:	6125                	addi	sp,sp,96
    80005ec4:	8082                	ret
        int demotions = mlfq_cpu_initial_priority - mlfq_cpu_final_priority;
    80005ec6:	0000a497          	auipc	s1,0xa
    80005eca:	9724a483          	lw	s1,-1678(s1) # 8000f838 <mlfq_cpu_initial_priority>
    80005ece:	0000a797          	auipc	a5,0xa
    80005ed2:	9667a783          	lw	a5,-1690(a5) # 8000f834 <mlfq_cpu_final_priority>
    80005ed6:	9c9d                	subw	s1,s1,a5
        printf("✓ MLFQ Test: CPU-intensive task was demoted %d time(s) (priority %d -> %d)\n",
    80005ed8:	0000a617          	auipc	a2,0xa
    80005edc:	96062603          	lw	a2,-1696(a2) # 8000f838 <mlfq_cpu_initial_priority>
    80005ee0:	0000a697          	auipc	a3,0xa
    80005ee4:	9546a683          	lw	a3,-1708(a3) # 8000f834 <mlfq_cpu_final_priority>
    80005ee8:	85a6                	mv	a1,s1
    80005eea:	00008517          	auipc	a0,0x8
    80005eee:	32e50513          	addi	a0,a0,814 # 8000e218 <digits+0x4068>
    80005ef2:	ffffa097          	auipc	ra,0xffffa
    80005ef6:	612080e7          	jalr	1554(ra) # 80000504 <printf>
        if (demotions >= 2)
    80005efa:	4785                	li	a5,1
    80005efc:	f697d1e3          	bge	a5,s1,80005e5e <test_mlfq_scheduling+0x268>
            printf("✓✓ Successfully observed MULTIPLE demotions!\n");
    80005f00:	00008517          	auipc	a0,0x8
    80005f04:	36850513          	addi	a0,a0,872 # 8000e268 <digits+0x40b8>
    80005f08:	ffffa097          	auipc	ra,0xffffa
    80005f0c:	5fc080e7          	jalr	1532(ra) # 80000504 <printf>
    80005f10:	b7b9                	j	80005e5e <test_mlfq_scheduling+0x268>
        printf("⚠ MLFQ Test: CPU-intensive task priority unchanged (may not have used enough slices)\n");
    80005f12:	00008517          	auipc	a0,0x8
    80005f16:	38e50513          	addi	a0,a0,910 # 8000e2a0 <digits+0x40f0>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	5ea080e7          	jalr	1514(ra) # 80000504 <printf>
        printf("  Note: Task may have completed before using %d consecutive time slices\n",
    80005f22:	458d                	li	a1,3
    80005f24:	00008517          	auipc	a0,0x8
    80005f28:	3d450513          	addi	a0,a0,980 # 8000e2f8 <digits+0x4148>
    80005f2c:	ffffa097          	auipc	ra,0xffffa
    80005f30:	5d8080e7          	jalr	1496(ra) # 80000504 <printf>
    80005f34:	b72d                	j	80005e5e <test_mlfq_scheduling+0x268>
        printf("✓ MLFQ Test: Interactive task maintained or improved priority (%d -> %d)\n",
    80005f36:	0000a597          	auipc	a1,0xa
    80005f3a:	8fa5a583          	lw	a1,-1798(a1) # 8000f830 <mlfq_int_initial_priority>
    80005f3e:	0000a617          	auipc	a2,0xa
    80005f42:	8ee62603          	lw	a2,-1810(a2) # 8000f82c <mlfq_int_final_priority>
    80005f46:	00008517          	auipc	a0,0x8
    80005f4a:	44a50513          	addi	a0,a0,1098 # 8000e390 <digits+0x41e0>
    80005f4e:	ffffa097          	auipc	ra,0xffffa
    80005f52:	5b6080e7          	jalr	1462(ra) # 80000504 <printf>
    80005f56:	b7a9                	j	80005ea0 <test_mlfq_scheduling+0x2aa>

0000000080005f58 <run_process_tests>:
}

void run_process_tests(void)
{
    80005f58:	1141                	addi	sp,sp,-16
    80005f5a:	e406                	sd	ra,8(sp)
    80005f5c:	e022                	sd	s0,0(sp)
    80005f5e:	0800                	addi	s0,sp,16
    printf("Starting priority scheduling tests...\n");
    80005f60:	00008517          	auipc	a0,0x8
    80005f64:	4e850513          	addi	a0,a0,1256 # 8000e448 <digits+0x4298>
    80005f68:	ffffa097          	auipc	ra,0xffffa
    80005f6c:	59c080e7          	jalr	1436(ra) # 80000504 <printf>

    // 先等待一下确保系统稳定
    ksleep(10);
    80005f70:	4529                	li	a0,10
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	218080e7          	jalr	536(ra) # 8000418a <ksleep>

    int test_runner_pid = create_process(process_test_runner);
    80005f7a:	fffff517          	auipc	a0,0xfffff
    80005f7e:	53250513          	addi	a0,a0,1330 # 800054ac <process_test_runner>
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	ef0080e7          	jalr	-272(ra) # 80003e72 <create_process>

    if (test_runner_pid < 0)
    80005f8a:	00054f63          	bltz	a0,80005fa8 <run_process_tests+0x50>
    80005f8e:	85aa                	mv	a1,a0
    {
        printf("ERROR: Failed to create test runner process\n");
        return;
    }

    printf("Priority scheduling test runner started with PID %d\n", test_runner_pid);
    80005f90:	00008517          	auipc	a0,0x8
    80005f94:	51050513          	addi	a0,a0,1296 # 8000e4a0 <digits+0x42f0>
    80005f98:	ffffa097          	auipc	ra,0xffffa
    80005f9c:	56c080e7          	jalr	1388(ra) # 80000504 <printf>
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret
        printf("ERROR: Failed to create test runner process\n");
    80005fa8:	00008517          	auipc	a0,0x8
    80005fac:	4c850513          	addi	a0,a0,1224 # 8000e470 <digits+0x42c0>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	554080e7          	jalr	1364(ra) # 80000504 <printf>
        return;
    80005fb8:	b7e5                	j	80005fa0 <run_process_tests+0x48>

0000000080005fba <memmove>:
static struct spinlock ramdisk_lock;

// 简单的memmove实现
static void *
memmove(void *dst, const void *src, uint n)
{
    80005fba:	1141                	addi	sp,sp,-16
    80005fbc:	e422                	sd	s0,8(sp)
    80005fbe:	0800                	addi	s0,sp,16
    const char *s;
    char *d;

    s = src;
    d = dst;
    if (s < d && s + n > d)
    80005fc0:	02a5e563          	bltu	a1,a0,80005fea <memmove+0x30>
        d += n;
        while (n-- > 0)
            *--d = *--s;
    }
    else
        while (n-- > 0)
    80005fc4:	fff6069b          	addiw	a3,a2,-1
    80005fc8:	ce11                	beqz	a2,80005fe4 <memmove+0x2a>
    80005fca:	1682                	slli	a3,a3,0x20
    80005fcc:	9281                	srli	a3,a3,0x20
    80005fce:	0685                	addi	a3,a3,1
    80005fd0:	96ae                	add	a3,a3,a1
    80005fd2:	87aa                	mv	a5,a0
            *d++ = *s++;
    80005fd4:	0585                	addi	a1,a1,1
    80005fd6:	0785                	addi	a5,a5,1
    80005fd8:	fff5c703          	lbu	a4,-1(a1)
    80005fdc:	fee78fa3          	sb	a4,-1(a5)
        while (n-- > 0)
    80005fe0:	fed59ae3          	bne	a1,a3,80005fd4 <memmove+0x1a>
    return dst;
}
    80005fe4:	6422                	ld	s0,8(sp)
    80005fe6:	0141                	addi	sp,sp,16
    80005fe8:	8082                	ret
    if (s < d && s + n > d)
    80005fea:	02061713          	slli	a4,a2,0x20
    80005fee:	9301                	srli	a4,a4,0x20
    80005ff0:	00e587b3          	add	a5,a1,a4
    80005ff4:	fcf578e3          	bgeu	a0,a5,80005fc4 <memmove+0xa>
        d += n;
    80005ff8:	972a                	add	a4,a4,a0
        while (n-- > 0)
    80005ffa:	fff6069b          	addiw	a3,a2,-1
    80005ffe:	d27d                	beqz	a2,80005fe4 <memmove+0x2a>
    80006000:	02069613          	slli	a2,a3,0x20
    80006004:	9201                	srli	a2,a2,0x20
    80006006:	fff64613          	not	a2,a2
    8000600a:	963e                	add	a2,a2,a5
            *--d = *--s;
    8000600c:	17fd                	addi	a5,a5,-1
    8000600e:	177d                	addi	a4,a4,-1
    80006010:	0007c683          	lbu	a3,0(a5)
    80006014:	00d70023          	sb	a3,0(a4)
        while (n-- > 0)
    80006018:	fef61ae3          	bne	a2,a5,8000600c <memmove+0x52>
    8000601c:	b7e1                	j	80005fe4 <memmove+0x2a>

000000008000601e <binit>:
    // LRU链表
    struct buf head;
} bcache;

void binit(void)
{
    8000601e:	7139                	addi	sp,sp,-64
    80006020:	fc06                	sd	ra,56(sp)
    80006022:	f822                	sd	s0,48(sp)
    80006024:	f426                	sd	s1,40(sp)
    80006026:	f04a                	sd	s2,32(sp)
    80006028:	ec4e                	sd	s3,24(sp)
    8000602a:	e852                	sd	s4,16(sp)
    8000602c:	e456                	sd	s5,8(sp)
    8000602e:	0080                	addi	s0,sp,64
    struct buf *b;

    initlock(&bcache.lock, "bcache");
    80006030:	00008597          	auipc	a1,0x8
    80006034:	4a858593          	addi	a1,a1,1192 # 8000e4d8 <digits+0x4328>
    80006038:	0000d517          	auipc	a0,0xd
    8000603c:	6e850513          	addi	a0,a0,1768 # 80013720 <bcache>
    80006040:	ffffd097          	auipc	ra,0xffffd
    80006044:	634080e7          	jalr	1588(ra) # 80003674 <initlock>
    initlock(&ramdisk_lock, "ramdisk");
    80006048:	00008597          	auipc	a1,0x8
    8000604c:	49858593          	addi	a1,a1,1176 # 8000e4e0 <digits+0x4330>
    80006050:	0000d517          	auipc	a0,0xd
    80006054:	6b850513          	addi	a0,a0,1720 # 80013708 <ramdisk_lock>
    80006058:	ffffd097          	auipc	ra,0xffffd
    8000605c:	61c080e7          	jalr	1564(ra) # 80003674 <initlock>

    // 创建LRU链表
    bcache.head.prev = &bcache.head;
    80006060:	00073797          	auipc	a5,0x73
    80006064:	6c078793          	addi	a5,a5,1728 # 80079720 <bcache+0x66000>
    80006068:	00073717          	auipc	a4,0x73
    8000606c:	fd070713          	addi	a4,a4,-48 # 80079038 <bcache+0x65918>
    80006070:	94e7b423          	sd	a4,-1720(a5)
    bcache.head.next = &bcache.head;
    80006074:	94e7b823          	sd	a4,-1712(a5)
    for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80006078:	0000d497          	auipc	s1,0xd
    8000607c:	6c048493          	addi	s1,s1,1728 # 80013738 <bcache+0x18>
    {
        b->next = bcache.head.next;
    80006080:	893e                	mv	s2,a5
        b->prev = &bcache.head;
    80006082:	89ba                	mv	s3,a4
        initlock(&b->lock, "buffer");
    80006084:	00008a97          	auipc	s5,0x8
    80006088:	464a8a93          	addi	s5,s5,1124 # 8000e4e8 <digits+0x4338>
    for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    8000608c:	6a05                	lui	s4,0x1
    8000608e:	040a0a13          	addi	s4,s4,64 # 1040 <_entry-0x7fffefc0>
        b->next = bcache.head.next;
    80006092:	95093783          	ld	a5,-1712(s2)
    80006096:	fc9c                	sd	a5,56(s1)
        b->prev = &bcache.head;
    80006098:	0334b823          	sd	s3,48(s1)
        initlock(&b->lock, "buffer");
    8000609c:	85d6                	mv	a1,s5
    8000609e:	01048513          	addi	a0,s1,16
    800060a2:	ffffd097          	auipc	ra,0xffffd
    800060a6:	5d2080e7          	jalr	1490(ra) # 80003674 <initlock>
        bcache.head.next->prev = b;
    800060aa:	95093783          	ld	a5,-1712(s2)
    800060ae:	fb84                	sd	s1,48(a5)
        bcache.head.next = b;
    800060b0:	94993823          	sd	s1,-1712(s2)
    for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    800060b4:	94d2                	add	s1,s1,s4
    800060b6:	fd349ee3          	bne	s1,s3,80006092 <binit+0x74>
    }

    // 初始化内存文件系统（清零所有块）
    // 注意：ramdisk 是静态数组，已经初始化为0
    printf("Memory filesystem initialized (%d blocks, %d KB)\n",
    800060ba:	6605                	lui	a2,0x1
    800060bc:	fa060613          	addi	a2,a2,-96 # fa0 <_entry-0x7ffff060>
    800060c0:	3e800593          	li	a1,1000
    800060c4:	00008517          	auipc	a0,0x8
    800060c8:	42c50513          	addi	a0,a0,1068 # 8000e4f0 <digits+0x4340>
    800060cc:	ffffa097          	auipc	ra,0xffffa
    800060d0:	438080e7          	jalr	1080(ra) # 80000504 <printf>
           RAMDISK_SIZE / BSIZE, RAMDISK_SIZE / 1024);
}
    800060d4:	70e2                	ld	ra,56(sp)
    800060d6:	7442                	ld	s0,48(sp)
    800060d8:	74a2                	ld	s1,40(sp)
    800060da:	7902                	ld	s2,32(sp)
    800060dc:	69e2                	ld	s3,24(sp)
    800060de:	6a42                	ld	s4,16(sp)
    800060e0:	6aa2                	ld	s5,8(sp)
    800060e2:	6121                	addi	sp,sp,64
    800060e4:	8082                	ret

00000000800060e6 <bread>:
}

// 返回一个已缓存的块，必要时从内存文件系统读取
struct buf *
bread(uint dev, uint blockno)
{
    800060e6:	7179                	addi	sp,sp,-48
    800060e8:	f406                	sd	ra,40(sp)
    800060ea:	f022                	sd	s0,32(sp)
    800060ec:	ec26                	sd	s1,24(sp)
    800060ee:	e84a                	sd	s2,16(sp)
    800060f0:	e44e                	sd	s3,8(sp)
    800060f2:	1800                	addi	s0,sp,48
    800060f4:	892a                	mv	s2,a0
    800060f6:	89ae                	mv	s3,a1
    acquire(&bcache.lock);
    800060f8:	0000d517          	auipc	a0,0xd
    800060fc:	62850513          	addi	a0,a0,1576 # 80013720 <bcache>
    80006100:	ffffd097          	auipc	ra,0xffffd
    80006104:	656080e7          	jalr	1622(ra) # 80003756 <acquire>
    for (b = bcache.head.next; b != &bcache.head; b = b->next)
    80006108:	00073497          	auipc	s1,0x73
    8000610c:	f684b483          	ld	s1,-152(s1) # 80079070 <bcache+0x65950>
    80006110:	00073797          	auipc	a5,0x73
    80006114:	f2878793          	addi	a5,a5,-216 # 80079038 <bcache+0x65918>
    80006118:	02f48f63          	beq	s1,a5,80006156 <bread+0x70>
    8000611c:	873e                	mv	a4,a5
    8000611e:	a021                	j	80006126 <bread+0x40>
    80006120:	7c84                	ld	s1,56(s1)
    80006122:	02e48a63          	beq	s1,a4,80006156 <bread+0x70>
        if (b->dev == dev && b->blockno == blockno)
    80006126:	449c                	lw	a5,8(s1)
    80006128:	ff279ce3          	bne	a5,s2,80006120 <bread+0x3a>
    8000612c:	44dc                	lw	a5,12(s1)
    8000612e:	ff3799e3          	bne	a5,s3,80006120 <bread+0x3a>
            b->refcnt++;
    80006132:	549c                	lw	a5,40(s1)
    80006134:	2785                	addiw	a5,a5,1
    80006136:	d49c                	sw	a5,40(s1)
            release(&bcache.lock);
    80006138:	0000d517          	auipc	a0,0xd
    8000613c:	5e850513          	addi	a0,a0,1512 # 80013720 <bcache>
    80006140:	ffffd097          	auipc	ra,0xffffd
    80006144:	686080e7          	jalr	1670(ra) # 800037c6 <release>
            acquire(&b->lock);
    80006148:	01048513          	addi	a0,s1,16
    8000614c:	ffffd097          	auipc	ra,0xffffd
    80006150:	60a080e7          	jalr	1546(ra) # 80003756 <acquire>
            return b;
    80006154:	a8b9                	j	800061b2 <bread+0xcc>
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev)
    80006156:	00073497          	auipc	s1,0x73
    8000615a:	f124b483          	ld	s1,-238(s1) # 80079068 <bcache+0x65948>
    8000615e:	00073797          	auipc	a5,0x73
    80006162:	eda78793          	addi	a5,a5,-294 # 80079038 <bcache+0x65918>
    80006166:	00f48863          	beq	s1,a5,80006176 <bread+0x90>
    8000616a:	873e                	mv	a4,a5
        if (b->refcnt == 0)
    8000616c:	549c                	lw	a5,40(s1)
    8000616e:	cf81                	beqz	a5,80006186 <bread+0xa0>
    for (b = bcache.head.prev; b != &bcache.head; b = b->prev)
    80006170:	7884                	ld	s1,48(s1)
    80006172:	fee49de3          	bne	s1,a4,8000616c <bread+0x86>
    panic("bget: no buffers");
    80006176:	00008517          	auipc	a0,0x8
    8000617a:	3b250513          	addi	a0,a0,946 # 8000e528 <digits+0x4378>
    8000617e:	ffffd097          	auipc	ra,0xffffd
    80006182:	90e080e7          	jalr	-1778(ra) # 80002a8c <panic>
            b->dev = dev;
    80006186:	0124a423          	sw	s2,8(s1)
            b->blockno = blockno;
    8000618a:	0134a623          	sw	s3,12(s1)
            b->valid = 0;
    8000618e:	0004a023          	sw	zero,0(s1)
            b->refcnt = 1;
    80006192:	4785                	li	a5,1
    80006194:	d49c                	sw	a5,40(s1)
            release(&bcache.lock);
    80006196:	0000d517          	auipc	a0,0xd
    8000619a:	58a50513          	addi	a0,a0,1418 # 80013720 <bcache>
    8000619e:	ffffd097          	auipc	ra,0xffffd
    800061a2:	628080e7          	jalr	1576(ra) # 800037c6 <release>
            acquire(&b->lock);
    800061a6:	01048513          	addi	a0,s1,16
    800061aa:	ffffd097          	auipc	ra,0xffffd
    800061ae:	5ac080e7          	jalr	1452(ra) # 80003756 <acquire>
    struct buf *b;

    b = bget(dev, blockno);
    if (!b->valid)
    800061b2:	409c                	lw	a5,0(s1)
    800061b4:	eba1                	bnez	a5,80006204 <bread+0x11e>
    {
        // 从内存文件系统读取
        if (blockno * BSIZE >= RAMDISK_SIZE)
    800061b6:	00c9999b          	slliw	s3,s3,0xc
    800061ba:	0009871b          	sext.w	a4,s3
    800061be:	003e87b7          	lui	a5,0x3e8
    800061c2:	04f77963          	bgeu	a4,a5,80006214 <bread+0x12e>
        {
            panic("bread: blockno out of range");
        }
        acquire(&ramdisk_lock);
    800061c6:	0000d917          	auipc	s2,0xd
    800061ca:	54290913          	addi	s2,s2,1346 # 80013708 <ramdisk_lock>
    800061ce:	854a                	mv	a0,s2
    800061d0:	ffffd097          	auipc	ra,0xffffd
    800061d4:	586080e7          	jalr	1414(ra) # 80003756 <acquire>
        memmove(b->data, &ramdisk[blockno * BSIZE], BSIZE);
    800061d8:	1982                	slli	s3,s3,0x20
    800061da:	0209d993          	srli	s3,s3,0x20
    800061de:	6605                	lui	a2,0x1
    800061e0:	00074597          	auipc	a1,0x74
    800061e4:	e9858593          	addi	a1,a1,-360 # 8007a078 <ramdisk>
    800061e8:	95ce                	add	a1,a1,s3
    800061ea:	04048513          	addi	a0,s1,64
    800061ee:	00000097          	auipc	ra,0x0
    800061f2:	dcc080e7          	jalr	-564(ra) # 80005fba <memmove>
        release(&ramdisk_lock);
    800061f6:	854a                	mv	a0,s2
    800061f8:	ffffd097          	auipc	ra,0xffffd
    800061fc:	5ce080e7          	jalr	1486(ra) # 800037c6 <release>
        b->valid = 1;
    80006200:	4785                	li	a5,1
    80006202:	c09c                	sw	a5,0(s1)
    }
    return b;
}
    80006204:	8526                	mv	a0,s1
    80006206:	70a2                	ld	ra,40(sp)
    80006208:	7402                	ld	s0,32(sp)
    8000620a:	64e2                	ld	s1,24(sp)
    8000620c:	6942                	ld	s2,16(sp)
    8000620e:	69a2                	ld	s3,8(sp)
    80006210:	6145                	addi	sp,sp,48
    80006212:	8082                	ret
            panic("bread: blockno out of range");
    80006214:	00008517          	auipc	a0,0x8
    80006218:	32c50513          	addi	a0,a0,812 # 8000e540 <digits+0x4390>
    8000621c:	ffffd097          	auipc	ra,0xffffd
    80006220:	870080e7          	jalr	-1936(ra) # 80002a8c <panic>

0000000080006224 <bwrite>:

// 将缓存块写回内存文件系统
void bwrite(struct buf *b)
{
    80006224:	1101                	addi	sp,sp,-32
    80006226:	ec06                	sd	ra,24(sp)
    80006228:	e822                	sd	s0,16(sp)
    8000622a:	e426                	sd	s1,8(sp)
    8000622c:	e04a                	sd	s2,0(sp)
    8000622e:	1000                	addi	s0,sp,32
    80006230:	84aa                	mv	s1,a0
    if (!holding(&b->lock))
    80006232:	0541                	addi	a0,a0,16
    80006234:	ffffd097          	auipc	ra,0xffffd
    80006238:	4f4080e7          	jalr	1268(ra) # 80003728 <holding>
    8000623c:	cd39                	beqz	a0,8000629a <bwrite+0x76>
        panic("bwrite");
    b->disk = 1;
    8000623e:	4785                	li	a5,1
    80006240:	c0dc                	sw	a5,4(s1)
    // 写入到内存文件系统
    if (b->blockno * BSIZE >= RAMDISK_SIZE)
    80006242:	44dc                	lw	a5,12(s1)
    80006244:	00c7979b          	slliw	a5,a5,0xc
    80006248:	003e8737          	lui	a4,0x3e8
    8000624c:	04e7ff63          	bgeu	a5,a4,800062aa <bwrite+0x86>
    {
        panic("bwrite: blockno out of range");
    }
    acquire(&ramdisk_lock);
    80006250:	0000d917          	auipc	s2,0xd
    80006254:	4b890913          	addi	s2,s2,1208 # 80013708 <ramdisk_lock>
    80006258:	854a                	mv	a0,s2
    8000625a:	ffffd097          	auipc	ra,0xffffd
    8000625e:	4fc080e7          	jalr	1276(ra) # 80003756 <acquire>
    memmove(&ramdisk[b->blockno * BSIZE], b->data, BSIZE);
    80006262:	44dc                	lw	a5,12(s1)
    80006264:	00c7979b          	slliw	a5,a5,0xc
    80006268:	1782                	slli	a5,a5,0x20
    8000626a:	9381                	srli	a5,a5,0x20
    8000626c:	6605                	lui	a2,0x1
    8000626e:	04048593          	addi	a1,s1,64
    80006272:	00074517          	auipc	a0,0x74
    80006276:	e0650513          	addi	a0,a0,-506 # 8007a078 <ramdisk>
    8000627a:	953e                	add	a0,a0,a5
    8000627c:	00000097          	auipc	ra,0x0
    80006280:	d3e080e7          	jalr	-706(ra) # 80005fba <memmove>
    release(&ramdisk_lock);
    80006284:	854a                	mv	a0,s2
    80006286:	ffffd097          	auipc	ra,0xffffd
    8000628a:	540080e7          	jalr	1344(ra) # 800037c6 <release>
}
    8000628e:	60e2                	ld	ra,24(sp)
    80006290:	6442                	ld	s0,16(sp)
    80006292:	64a2                	ld	s1,8(sp)
    80006294:	6902                	ld	s2,0(sp)
    80006296:	6105                	addi	sp,sp,32
    80006298:	8082                	ret
        panic("bwrite");
    8000629a:	00008517          	auipc	a0,0x8
    8000629e:	2c650513          	addi	a0,a0,710 # 8000e560 <digits+0x43b0>
    800062a2:	ffffc097          	auipc	ra,0xffffc
    800062a6:	7ea080e7          	jalr	2026(ra) # 80002a8c <panic>
        panic("bwrite: blockno out of range");
    800062aa:	00008517          	auipc	a0,0x8
    800062ae:	2be50513          	addi	a0,a0,702 # 8000e568 <digits+0x43b8>
    800062b2:	ffffc097          	auipc	ra,0xffffc
    800062b6:	7da080e7          	jalr	2010(ra) # 80002a8c <panic>

00000000800062ba <brelse>:

// 释放对缓存块的引用
void brelse(struct buf *b)
{
    800062ba:	1101                	addi	sp,sp,-32
    800062bc:	ec06                	sd	ra,24(sp)
    800062be:	e822                	sd	s0,16(sp)
    800062c0:	e426                	sd	s1,8(sp)
    800062c2:	e04a                	sd	s2,0(sp)
    800062c4:	1000                	addi	s0,sp,32
    800062c6:	84aa                	mv	s1,a0
    if (!holding(&b->lock))
    800062c8:	01050913          	addi	s2,a0,16
    800062cc:	854a                	mv	a0,s2
    800062ce:	ffffd097          	auipc	ra,0xffffd
    800062d2:	45a080e7          	jalr	1114(ra) # 80003728 <holding>
    800062d6:	c92d                	beqz	a0,80006348 <brelse+0x8e>
        panic("brelse");

    release(&b->lock);
    800062d8:	854a                	mv	a0,s2
    800062da:	ffffd097          	auipc	ra,0xffffd
    800062de:	4ec080e7          	jalr	1260(ra) # 800037c6 <release>

    acquire(&bcache.lock);
    800062e2:	0000d517          	auipc	a0,0xd
    800062e6:	43e50513          	addi	a0,a0,1086 # 80013720 <bcache>
    800062ea:	ffffd097          	auipc	ra,0xffffd
    800062ee:	46c080e7          	jalr	1132(ra) # 80003756 <acquire>
    b->refcnt--;
    800062f2:	549c                	lw	a5,40(s1)
    800062f4:	37fd                	addiw	a5,a5,-1
    800062f6:	0007871b          	sext.w	a4,a5
    800062fa:	d49c                	sw	a5,40(s1)
    if (b->refcnt == 0)
    800062fc:	eb05                	bnez	a4,8000632c <brelse+0x72>
    {
        // 移动到LRU链表头部（最近使用）
        b->next->prev = b->prev;
    800062fe:	7c9c                	ld	a5,56(s1)
    80006300:	7898                	ld	a4,48(s1)
    80006302:	fb98                	sd	a4,48(a5)
        b->prev->next = b->next;
    80006304:	789c                	ld	a5,48(s1)
    80006306:	7c98                	ld	a4,56(s1)
    80006308:	ff98                	sd	a4,56(a5)
        b->next = bcache.head.next;
    8000630a:	00073797          	auipc	a5,0x73
    8000630e:	41678793          	addi	a5,a5,1046 # 80079720 <bcache+0x66000>
    80006312:	9507b703          	ld	a4,-1712(a5)
    80006316:	fc98                	sd	a4,56(s1)
        b->prev = &bcache.head;
    80006318:	00073717          	auipc	a4,0x73
    8000631c:	d2070713          	addi	a4,a4,-736 # 80079038 <bcache+0x65918>
    80006320:	f898                	sd	a4,48(s1)
        bcache.head.next->prev = b;
    80006322:	9507b703          	ld	a4,-1712(a5)
    80006326:	fb04                	sd	s1,48(a4)
        bcache.head.next = b;
    80006328:	9497b823          	sd	s1,-1712(a5)
    }
    release(&bcache.lock);
    8000632c:	0000d517          	auipc	a0,0xd
    80006330:	3f450513          	addi	a0,a0,1012 # 80013720 <bcache>
    80006334:	ffffd097          	auipc	ra,0xffffd
    80006338:	492080e7          	jalr	1170(ra) # 800037c6 <release>
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6902                	ld	s2,0(sp)
    80006344:	6105                	addi	sp,sp,32
    80006346:	8082                	ret
        panic("brelse");
    80006348:	00008517          	auipc	a0,0x8
    8000634c:	24050513          	addi	a0,a0,576 # 8000e588 <digits+0x43d8>
    80006350:	ffffc097          	auipc	ra,0xffffc
    80006354:	73c080e7          	jalr	1852(ra) # 80002a8c <panic>

0000000080006358 <bpin>:

// 增加引用计数（防止被LRU淘汰）
void bpin(struct buf *b)
{
    80006358:	1101                	addi	sp,sp,-32
    8000635a:	ec06                	sd	ra,24(sp)
    8000635c:	e822                	sd	s0,16(sp)
    8000635e:	e426                	sd	s1,8(sp)
    80006360:	1000                	addi	s0,sp,32
    80006362:	84aa                	mv	s1,a0
    acquire(&bcache.lock);
    80006364:	0000d517          	auipc	a0,0xd
    80006368:	3bc50513          	addi	a0,a0,956 # 80013720 <bcache>
    8000636c:	ffffd097          	auipc	ra,0xffffd
    80006370:	3ea080e7          	jalr	1002(ra) # 80003756 <acquire>
    b->refcnt++;
    80006374:	549c                	lw	a5,40(s1)
    80006376:	2785                	addiw	a5,a5,1
    80006378:	d49c                	sw	a5,40(s1)
    release(&bcache.lock);
    8000637a:	0000d517          	auipc	a0,0xd
    8000637e:	3a650513          	addi	a0,a0,934 # 80013720 <bcache>
    80006382:	ffffd097          	auipc	ra,0xffffd
    80006386:	444080e7          	jalr	1092(ra) # 800037c6 <release>
}
    8000638a:	60e2                	ld	ra,24(sp)
    8000638c:	6442                	ld	s0,16(sp)
    8000638e:	64a2                	ld	s1,8(sp)
    80006390:	6105                	addi	sp,sp,32
    80006392:	8082                	ret

0000000080006394 <bunpin>:

// 减少引用计数
void bunpin(struct buf *b)
{
    80006394:	1101                	addi	sp,sp,-32
    80006396:	ec06                	sd	ra,24(sp)
    80006398:	e822                	sd	s0,16(sp)
    8000639a:	e426                	sd	s1,8(sp)
    8000639c:	1000                	addi	s0,sp,32
    8000639e:	84aa                	mv	s1,a0
    acquire(&bcache.lock);
    800063a0:	0000d517          	auipc	a0,0xd
    800063a4:	38050513          	addi	a0,a0,896 # 80013720 <bcache>
    800063a8:	ffffd097          	auipc	ra,0xffffd
    800063ac:	3ae080e7          	jalr	942(ra) # 80003756 <acquire>
    b->refcnt--;
    800063b0:	549c                	lw	a5,40(s1)
    800063b2:	37fd                	addiw	a5,a5,-1
    800063b4:	d49c                	sw	a5,40(s1)
    release(&bcache.lock);
    800063b6:	0000d517          	auipc	a0,0xd
    800063ba:	36a50513          	addi	a0,a0,874 # 80013720 <bcache>
    800063be:	ffffd097          	auipc	ra,0xffffd
    800063c2:	408080e7          	jalr	1032(ra) # 800037c6 <release>
}
    800063c6:	60e2                	ld	ra,24(sp)
    800063c8:	6442                	ld	s0,16(sp)
    800063ca:	64a2                	ld	s1,8(sp)
    800063cc:	6105                	addi	sp,sp,32
    800063ce:	8082                	ret

00000000800063d0 <memmove>:
#include "log.h"

// 内存复制
static void *
memmove(void *dst, const void *src, uint n)
{
    800063d0:	1141                	addi	sp,sp,-16
    800063d2:	e422                	sd	s0,8(sp)
    800063d4:	0800                	addi	s0,sp,16
    const char *s;
    char *d;

    s = src;
    d = dst;
    if (s < d && s + n > d)
    800063d6:	02a5e563          	bltu	a1,a0,80006400 <memmove+0x30>
        d += n;
        while (n-- > 0)
            *--d = *--s;
    }
    else
        while (n-- > 0)
    800063da:	fff6069b          	addiw	a3,a2,-1
    800063de:	ce11                	beqz	a2,800063fa <memmove+0x2a>
    800063e0:	1682                	slli	a3,a3,0x20
    800063e2:	9281                	srli	a3,a3,0x20
    800063e4:	0685                	addi	a3,a3,1
    800063e6:	96ae                	add	a3,a3,a1
    800063e8:	87aa                	mv	a5,a0
            *d++ = *s++;
    800063ea:	0585                	addi	a1,a1,1
    800063ec:	0785                	addi	a5,a5,1
    800063ee:	fff5c703          	lbu	a4,-1(a1)
    800063f2:	fee78fa3          	sb	a4,-1(a5)
        while (n-- > 0)
    800063f6:	fed59ae3          	bne	a1,a3,800063ea <memmove+0x1a>
    return dst;
}
    800063fa:	6422                	ld	s0,8(sp)
    800063fc:	0141                	addi	sp,sp,16
    800063fe:	8082                	ret
    if (s < d && s + n > d)
    80006400:	02061713          	slli	a4,a2,0x20
    80006404:	9301                	srli	a4,a4,0x20
    80006406:	00e587b3          	add	a5,a1,a4
    8000640a:	fcf578e3          	bgeu	a0,a5,800063da <memmove+0xa>
        d += n;
    8000640e:	972a                	add	a4,a4,a0
        while (n-- > 0)
    80006410:	fff6069b          	addiw	a3,a2,-1
    80006414:	d27d                	beqz	a2,800063fa <memmove+0x2a>
    80006416:	02069613          	slli	a2,a3,0x20
    8000641a:	9201                	srli	a2,a2,0x20
    8000641c:	fff64613          	not	a2,a2
    80006420:	963e                	add	a2,a2,a5
            *--d = *--s;
    80006422:	17fd                	addi	a5,a5,-1
    80006424:	177d                	addi	a4,a4,-1
    80006426:	0007c683          	lbu	a3,0(a5)
    8000642a:	00d70023          	sb	a3,0(a4)
        while (n-- > 0)
    8000642e:	fef61ae3          	bne	a2,a5,80006422 <memmove+0x52>
    80006432:	b7e1                	j	800063fa <memmove+0x2a>

0000000080006434 <install_trans>:
static void
install_trans(int recovering)
{
    int tail;

    for (tail = 0; tail < log.lh.n; tail++)
    80006434:	0045c797          	auipc	a5,0x45c
    80006438:	c707a783          	lw	a5,-912(a5) # 804620a4 <log+0x2c>
    8000643c:	0af05063          	blez	a5,800064dc <install_trans+0xa8>
{
    80006440:	7139                	addi	sp,sp,-64
    80006442:	fc06                	sd	ra,56(sp)
    80006444:	f822                	sd	s0,48(sp)
    80006446:	f426                	sd	s1,40(sp)
    80006448:	f04a                	sd	s2,32(sp)
    8000644a:	ec4e                	sd	s3,24(sp)
    8000644c:	e852                	sd	s4,16(sp)
    8000644e:	e456                	sd	s5,8(sp)
    80006450:	0080                	addi	s0,sp,64
    80006452:	0045ca97          	auipc	s5,0x45c
    80006456:	c56a8a93          	addi	s5,s5,-938 # 804620a8 <log+0x30>
    for (tail = 0; tail < log.lh.n; tail++)
    8000645a:	4a01                	li	s4,0
    {
        struct buf *lbuf = bread(log.dev, log.start + tail + 1); // 日志块
    8000645c:	0045c997          	auipc	s3,0x45c
    80006460:	c1c98993          	addi	s3,s3,-996 # 80462078 <log>
    80006464:	0189a583          	lw	a1,24(s3)
    80006468:	014585bb          	addw	a1,a1,s4
    8000646c:	2585                	addiw	a1,a1,1
    8000646e:	0289a503          	lw	a0,40(s3)
    80006472:	00000097          	auipc	ra,0x0
    80006476:	c74080e7          	jalr	-908(ra) # 800060e6 <bread>
    8000647a:	892a                	mv	s2,a0
        struct buf *dbuf = bread(log.dev, log.lh.block[tail]);   // 目标块
    8000647c:	000aa583          	lw	a1,0(s5)
    80006480:	0289a503          	lw	a0,40(s3)
    80006484:	00000097          	auipc	ra,0x0
    80006488:	c62080e7          	jalr	-926(ra) # 800060e6 <bread>
    8000648c:	84aa                	mv	s1,a0
        memmove(dbuf->data, lbuf->data, BSIZE);
    8000648e:	6605                	lui	a2,0x1
    80006490:	04090593          	addi	a1,s2,64
    80006494:	04050513          	addi	a0,a0,64
    80006498:	00000097          	auipc	ra,0x0
    8000649c:	f38080e7          	jalr	-200(ra) # 800063d0 <memmove>
        bwrite(dbuf); // 写入磁盘
    800064a0:	8526                	mv	a0,s1
    800064a2:	00000097          	auipc	ra,0x0
    800064a6:	d82080e7          	jalr	-638(ra) # 80006224 <bwrite>
        brelse(lbuf);
    800064aa:	854a                	mv	a0,s2
    800064ac:	00000097          	auipc	ra,0x0
    800064b0:	e0e080e7          	jalr	-498(ra) # 800062ba <brelse>
        brelse(dbuf);
    800064b4:	8526                	mv	a0,s1
    800064b6:	00000097          	auipc	ra,0x0
    800064ba:	e04080e7          	jalr	-508(ra) # 800062ba <brelse>
    for (tail = 0; tail < log.lh.n; tail++)
    800064be:	2a05                	addiw	s4,s4,1
    800064c0:	0a91                	addi	s5,s5,4
    800064c2:	02c9a783          	lw	a5,44(s3)
    800064c6:	f8fa4fe3          	blt	s4,a5,80006464 <install_trans+0x30>
    }
}
    800064ca:	70e2                	ld	ra,56(sp)
    800064cc:	7442                	ld	s0,48(sp)
    800064ce:	74a2                	ld	s1,40(sp)
    800064d0:	7902                	ld	s2,32(sp)
    800064d2:	69e2                	ld	s3,24(sp)
    800064d4:	6a42                	ld	s4,16(sp)
    800064d6:	6aa2                	ld	s5,8(sp)
    800064d8:	6121                	addi	sp,sp,64
    800064da:	8082                	ret
    800064dc:	8082                	ret

00000000800064de <write_head>:
{
    800064de:	1101                	addi	sp,sp,-32
    800064e0:	ec06                	sd	ra,24(sp)
    800064e2:	e822                	sd	s0,16(sp)
    800064e4:	e426                	sd	s1,8(sp)
    800064e6:	e04a                	sd	s2,0(sp)
    800064e8:	1000                	addi	s0,sp,32
    struct buf *buf = bread(log.dev, log.start);
    800064ea:	0045c917          	auipc	s2,0x45c
    800064ee:	b8e90913          	addi	s2,s2,-1138 # 80462078 <log>
    800064f2:	01892583          	lw	a1,24(s2)
    800064f6:	02892503          	lw	a0,40(s2)
    800064fa:	00000097          	auipc	ra,0x0
    800064fe:	bec080e7          	jalr	-1044(ra) # 800060e6 <bread>
    80006502:	84aa                	mv	s1,a0
    lh->n = log.lh.n;
    80006504:	02c92683          	lw	a3,44(s2)
    80006508:	c134                	sw	a3,64(a0)
    for (i = 0; i < log.lh.n; i++)
    8000650a:	02d05763          	blez	a3,80006538 <write_head+0x5a>
    8000650e:	0045c797          	auipc	a5,0x45c
    80006512:	b9a78793          	addi	a5,a5,-1126 # 804620a8 <log+0x30>
    80006516:	04450713          	addi	a4,a0,68
    8000651a:	36fd                	addiw	a3,a3,-1
    8000651c:	1682                	slli	a3,a3,0x20
    8000651e:	9281                	srli	a3,a3,0x20
    80006520:	068a                	slli	a3,a3,0x2
    80006522:	0045c617          	auipc	a2,0x45c
    80006526:	b8a60613          	addi	a2,a2,-1142 # 804620ac <log+0x34>
    8000652a:	96b2                	add	a3,a3,a2
        lh->block[i] = log.lh.block[i];
    8000652c:	4390                	lw	a2,0(a5)
    8000652e:	c310                	sw	a2,0(a4)
    for (i = 0; i < log.lh.n; i++)
    80006530:	0791                	addi	a5,a5,4
    80006532:	0711                	addi	a4,a4,4
    80006534:	fed79ce3          	bne	a5,a3,8000652c <write_head+0x4e>
    bwrite(buf);
    80006538:	8526                	mv	a0,s1
    8000653a:	00000097          	auipc	ra,0x0
    8000653e:	cea080e7          	jalr	-790(ra) # 80006224 <bwrite>
    brelse(buf);
    80006542:	8526                	mv	a0,s1
    80006544:	00000097          	auipc	ra,0x0
    80006548:	d76080e7          	jalr	-650(ra) # 800062ba <brelse>
}
    8000654c:	60e2                	ld	ra,24(sp)
    8000654e:	6442                	ld	s0,16(sp)
    80006550:	64a2                	ld	s1,8(sp)
    80006552:	6902                	ld	s2,0(sp)
    80006554:	6105                	addi	sp,sp,32
    80006556:	8082                	ret

0000000080006558 <recover_from_log>:
{
    80006558:	1101                	addi	sp,sp,-32
    8000655a:	ec06                	sd	ra,24(sp)
    8000655c:	e822                	sd	s0,16(sp)
    8000655e:	e426                	sd	s1,8(sp)
    80006560:	1000                	addi	s0,sp,32
    struct buf *buf = bread(log.dev, log.start);
    80006562:	0045c497          	auipc	s1,0x45c
    80006566:	b1648493          	addi	s1,s1,-1258 # 80462078 <log>
    8000656a:	4c8c                	lw	a1,24(s1)
    8000656c:	5488                	lw	a0,40(s1)
    8000656e:	00000097          	auipc	ra,0x0
    80006572:	b78080e7          	jalr	-1160(ra) # 800060e6 <bread>
    log.lh.n = lh->n;
    80006576:	4134                	lw	a3,64(a0)
    80006578:	d4d4                	sw	a3,44(s1)
    for (i = 0; i < log.lh.n; i++)
    8000657a:	02d05563          	blez	a3,800065a4 <recover_from_log+0x4c>
    8000657e:	04450793          	addi	a5,a0,68
    80006582:	0045c717          	auipc	a4,0x45c
    80006586:	b2670713          	addi	a4,a4,-1242 # 804620a8 <log+0x30>
    8000658a:	36fd                	addiw	a3,a3,-1
    8000658c:	1682                	slli	a3,a3,0x20
    8000658e:	9281                	srli	a3,a3,0x20
    80006590:	068a                	slli	a3,a3,0x2
    80006592:	04850613          	addi	a2,a0,72
    80006596:	96b2                	add	a3,a3,a2
        log.lh.block[i] = lh->block[i];
    80006598:	4390                	lw	a2,0(a5)
    8000659a:	c310                	sw	a2,0(a4)
    for (i = 0; i < log.lh.n; i++)
    8000659c:	0791                	addi	a5,a5,4
    8000659e:	0711                	addi	a4,a4,4
    800065a0:	fed79ce3          	bne	a5,a3,80006598 <recover_from_log+0x40>
    brelse(buf);
    800065a4:	00000097          	auipc	ra,0x0
    800065a8:	d16080e7          	jalr	-746(ra) # 800062ba <brelse>
    install_trans(1); // 如果是恢复，标记为1
    800065ac:	4505                	li	a0,1
    800065ae:	00000097          	auipc	ra,0x0
    800065b2:	e86080e7          	jalr	-378(ra) # 80006434 <install_trans>
    log.lh.n = 0;
    800065b6:	0045c797          	auipc	a5,0x45c
    800065ba:	ae07a723          	sw	zero,-1298(a5) # 804620a4 <log+0x2c>
    write_head(); // 清除日志
    800065be:	00000097          	auipc	ra,0x0
    800065c2:	f20080e7          	jalr	-224(ra) # 800064de <write_head>
}
    800065c6:	60e2                	ld	ra,24(sp)
    800065c8:	6442                	ld	s0,16(sp)
    800065ca:	64a2                	ld	s1,8(sp)
    800065cc:	6105                	addi	sp,sp,32
    800065ce:	8082                	ret

00000000800065d0 <initlog>:
{
    800065d0:	7179                	addi	sp,sp,-48
    800065d2:	f406                	sd	ra,40(sp)
    800065d4:	f022                	sd	s0,32(sp)
    800065d6:	ec26                	sd	s1,24(sp)
    800065d8:	e84a                	sd	s2,16(sp)
    800065da:	e44e                	sd	s3,8(sp)
    800065dc:	1800                	addi	s0,sp,48
    800065de:	89aa                	mv	s3,a0
    800065e0:	892e                	mv	s2,a1
    initlock(&log.lock, "log");
    800065e2:	0045c497          	auipc	s1,0x45c
    800065e6:	a9648493          	addi	s1,s1,-1386 # 80462078 <log>
    800065ea:	00008597          	auipc	a1,0x8
    800065ee:	fa658593          	addi	a1,a1,-90 # 8000e590 <digits+0x43e0>
    800065f2:	8526                	mv	a0,s1
    800065f4:	ffffd097          	auipc	ra,0xffffd
    800065f8:	080080e7          	jalr	128(ra) # 80003674 <initlock>
    log.start = sb->logstart;
    800065fc:	01492783          	lw	a5,20(s2)
    80006600:	cc9c                	sw	a5,24(s1)
    log.size = sb->nlog;
    80006602:	01092783          	lw	a5,16(s2)
    80006606:	ccdc                	sw	a5,28(s1)
    log.dev = dev;
    80006608:	0334a423          	sw	s3,40(s1)
    recover_from_log();
    8000660c:	00000097          	auipc	ra,0x0
    80006610:	f4c080e7          	jalr	-180(ra) # 80006558 <recover_from_log>
}
    80006614:	70a2                	ld	ra,40(sp)
    80006616:	7402                	ld	s0,32(sp)
    80006618:	64e2                	ld	s1,24(sp)
    8000661a:	6942                	ld	s2,16(sp)
    8000661c:	69a2                	ld	s3,8(sp)
    8000661e:	6145                	addi	sp,sp,48
    80006620:	8082                	ret

0000000080006622 <begin_op>:

// 开始一个系统调用的事务
void begin_op(void)
{
    80006622:	1101                	addi	sp,sp,-32
    80006624:	ec06                	sd	ra,24(sp)
    80006626:	e822                	sd	s0,16(sp)
    80006628:	e426                	sd	s1,8(sp)
    8000662a:	e04a                	sd	s2,0(sp)
    8000662c:	1000                	addi	s0,sp,32
    acquire(&log.lock);
    8000662e:	0045c517          	auipc	a0,0x45c
    80006632:	a4a50513          	addi	a0,a0,-1462 # 80462078 <log>
    80006636:	ffffd097          	auipc	ra,0xffffd
    8000663a:	120080e7          	jalr	288(ra) # 80003756 <acquire>
    while (1)
    {
        if (log.committing)
    8000663e:	0045c497          	auipc	s1,0x45c
    80006642:	a3a48493          	addi	s1,s1,-1478 # 80462078 <log>
            acquire(&log.lock);
            // 如果还在 committing，说明有bug，但继续尝试
            if (log.committing)
                continue;
        }
        else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE)
    80006646:	4979                	li	s2,30
    80006648:	a819                	j	8000665e <begin_op+0x3c>
            release(&log.lock);
    8000664a:	8526                	mv	a0,s1
    8000664c:	ffffd097          	auipc	ra,0xffffd
    80006650:	17a080e7          	jalr	378(ra) # 800037c6 <release>
            acquire(&log.lock);
    80006654:	8526                	mv	a0,s1
    80006656:	ffffd097          	auipc	ra,0xffffd
    8000665a:	100080e7          	jalr	256(ra) # 80003756 <acquire>
        if (log.committing)
    8000665e:	50dc                	lw	a5,36(s1)
    80006660:	f7ed                	bnez	a5,8000664a <begin_op+0x28>
        else if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE)
    80006662:	509c                	lw	a5,32(s1)
    80006664:	0017871b          	addiw	a4,a5,1
    80006668:	0007069b          	sext.w	a3,a4
    8000666c:	0027179b          	slliw	a5,a4,0x2
    80006670:	9fb9                	addw	a5,a5,a4
    80006672:	0017979b          	slliw	a5,a5,0x1
    80006676:	54d8                	lw	a4,44(s1)
    80006678:	9fb9                	addw	a5,a5,a4
    8000667a:	00f95d63          	bge	s2,a5,80006694 <begin_op+0x72>
        {
            // 日志空间不足，等待 - 在单进程环境中，这不应该发生
            release(&log.lock);
    8000667e:	8526                	mv	a0,s1
    80006680:	ffffd097          	auipc	ra,0xffffd
    80006684:	146080e7          	jalr	326(ra) # 800037c6 <release>
            acquire(&log.lock);
    80006688:	8526                	mv	a0,s1
    8000668a:	ffffd097          	auipc	ra,0xffffd
    8000668e:	0cc080e7          	jalr	204(ra) # 80003756 <acquire>
            // 如果空间还是不足，说明有bug，但继续尝试
            if (log.lh.n + (log.outstanding + 1) * MAXOPBLOCKS > LOGSIZE)
    80006692:	b7f1                	j	8000665e <begin_op+0x3c>
                continue;
        }
        else
        {
            log.outstanding += 1;
    80006694:	0045c517          	auipc	a0,0x45c
    80006698:	9e450513          	addi	a0,a0,-1564 # 80462078 <log>
    8000669c:	d114                	sw	a3,32(a0)
            release(&log.lock);
    8000669e:	ffffd097          	auipc	ra,0xffffd
    800066a2:	128080e7          	jalr	296(ra) # 800037c6 <release>
            break;
        }
    }
}
    800066a6:	60e2                	ld	ra,24(sp)
    800066a8:	6442                	ld	s0,16(sp)
    800066aa:	64a2                	ld	s1,8(sp)
    800066ac:	6902                	ld	s2,0(sp)
    800066ae:	6105                	addi	sp,sp,32
    800066b0:	8082                	ret

00000000800066b2 <end_op>:

// 结束一个系统调用的事务
void end_op(void)
{
    800066b2:	7179                	addi	sp,sp,-48
    800066b4:	f406                	sd	ra,40(sp)
    800066b6:	f022                	sd	s0,32(sp)
    800066b8:	ec26                	sd	s1,24(sp)
    800066ba:	e84a                	sd	s2,16(sp)
    800066bc:	e44e                	sd	s3,8(sp)
    800066be:	e052                	sd	s4,0(sp)
    800066c0:	1800                	addi	s0,sp,48
    int do_commit = 0;

    acquire(&log.lock);
    800066c2:	0045c497          	auipc	s1,0x45c
    800066c6:	9b648493          	addi	s1,s1,-1610 # 80462078 <log>
    800066ca:	8526                	mv	a0,s1
    800066cc:	ffffd097          	auipc	ra,0xffffd
    800066d0:	08a080e7          	jalr	138(ra) # 80003756 <acquire>
    log.outstanding -= 1;
    800066d4:	509c                	lw	a5,32(s1)
    800066d6:	37fd                	addiw	a5,a5,-1
    800066d8:	0007871b          	sext.w	a4,a5
    800066dc:	d09c                	sw	a5,32(s1)
    if (log.committing)
    800066de:	50dc                	lw	a5,36(s1)
    800066e0:	e3a9                	bnez	a5,80006722 <end_op+0x70>
        panic("log.committing");
    if (log.outstanding == 0)
    800066e2:	e779                	bnez	a4,800067b0 <end_op+0xfe>
    {
        do_commit = 1;
        log.committing = 1;
    800066e4:	0045c497          	auipc	s1,0x45c
    800066e8:	99448493          	addi	s1,s1,-1644 # 80462078 <log>
    800066ec:	4785                	li	a5,1
    800066ee:	d0dc                	sw	a5,36(s1)
    }
    else
    {
        // 唤醒等待的进程
    }
    release(&log.lock);
    800066f0:	8526                	mv	a0,s1
    800066f2:	ffffd097          	auipc	ra,0xffffd
    800066f6:	0d4080e7          	jalr	212(ra) # 800037c6 <release>

// 提交事务
static void
commit(void)
{
    if (log.lh.n > 0)
    800066fa:	54dc                	lw	a5,44(s1)
    800066fc:	02f04b63          	bgtz	a5,80006732 <end_op+0x80>
        acquire(&log.lock);
    80006700:	0045c497          	auipc	s1,0x45c
    80006704:	97848493          	addi	s1,s1,-1672 # 80462078 <log>
    80006708:	8526                	mv	a0,s1
    8000670a:	ffffd097          	auipc	ra,0xffffd
    8000670e:	04c080e7          	jalr	76(ra) # 80003756 <acquire>
        log.committing = 0;
    80006712:	0204a223          	sw	zero,36(s1)
        release(&log.lock);
    80006716:	8526                	mv	a0,s1
    80006718:	ffffd097          	auipc	ra,0xffffd
    8000671c:	0ae080e7          	jalr	174(ra) # 800037c6 <release>
}
    80006720:	a045                	j	800067c0 <end_op+0x10e>
        panic("log.committing");
    80006722:	00008517          	auipc	a0,0x8
    80006726:	e7650513          	addi	a0,a0,-394 # 8000e598 <digits+0x43e8>
    8000672a:	ffffc097          	auipc	ra,0xffffc
    8000672e:	362080e7          	jalr	866(ra) # 80002a8c <panic>
    {
        write_head();     // 写入日志头
    80006732:	00000097          	auipc	ra,0x0
    80006736:	dac080e7          	jalr	-596(ra) # 800064de <write_head>
        install_trans(0); // 安装到文件系统
    8000673a:	4501                	li	a0,0
    8000673c:	00000097          	auipc	ra,0x0
    80006740:	cf8080e7          	jalr	-776(ra) # 80006434 <install_trans>
        // 释放所有固定的缓冲区（必须在清除log.lh.n之前）
        int n = log.lh.n;
    80006744:	0045c797          	auipc	a5,0x45c
    80006748:	9607a783          	lw	a5,-1696(a5) # 804620a4 <log+0x2c>
        for (int i = 0; i < n; i++)
    8000674c:	04f05963          	blez	a5,8000679e <end_op+0xec>
    80006750:	0045c497          	auipc	s1,0x45c
    80006754:	95848493          	addi	s1,s1,-1704 # 804620a8 <log+0x30>
    80006758:	fff7899b          	addiw	s3,a5,-1
    8000675c:	1982                	slli	s3,s3,0x20
    8000675e:	0209d993          	srli	s3,s3,0x20
    80006762:	098a                	slli	s3,s3,0x2
    80006764:	0045c797          	auipc	a5,0x45c
    80006768:	94878793          	addi	a5,a5,-1720 # 804620ac <log+0x34>
    8000676c:	99be                	add	s3,s3,a5
        {
            struct buf *b = bread(log.dev, log.lh.block[i]);
    8000676e:	0045ca17          	auipc	s4,0x45c
    80006772:	90aa0a13          	addi	s4,s4,-1782 # 80462078 <log>
    80006776:	408c                	lw	a1,0(s1)
    80006778:	028a2503          	lw	a0,40(s4)
    8000677c:	00000097          	auipc	ra,0x0
    80006780:	96a080e7          	jalr	-1686(ra) # 800060e6 <bread>
    80006784:	892a                	mv	s2,a0
            bunpin(b);
    80006786:	00000097          	auipc	ra,0x0
    8000678a:	c0e080e7          	jalr	-1010(ra) # 80006394 <bunpin>
            brelse(b);
    8000678e:	854a                	mv	a0,s2
    80006790:	00000097          	auipc	ra,0x0
    80006794:	b2a080e7          	jalr	-1238(ra) # 800062ba <brelse>
        for (int i = 0; i < n; i++)
    80006798:	0491                	addi	s1,s1,4
    8000679a:	fd349ee3          	bne	s1,s3,80006776 <end_op+0xc4>
        }
        log.lh.n = 0;
    8000679e:	0045c797          	auipc	a5,0x45c
    800067a2:	9007a323          	sw	zero,-1786(a5) # 804620a4 <log+0x2c>
        write_head(); // 清除日志
    800067a6:	00000097          	auipc	ra,0x0
    800067aa:	d38080e7          	jalr	-712(ra) # 800064de <write_head>
    800067ae:	bf89                	j	80006700 <end_op+0x4e>
    release(&log.lock);
    800067b0:	0045c517          	auipc	a0,0x45c
    800067b4:	8c850513          	addi	a0,a0,-1848 # 80462078 <log>
    800067b8:	ffffd097          	auipc	ra,0xffffd
    800067bc:	00e080e7          	jalr	14(ra) # 800037c6 <release>
}
    800067c0:	70a2                	ld	ra,40(sp)
    800067c2:	7402                	ld	s0,32(sp)
    800067c4:	64e2                	ld	s1,24(sp)
    800067c6:	6942                	ld	s2,16(sp)
    800067c8:	69a2                	ld	s3,8(sp)
    800067ca:	6a02                	ld	s4,0(sp)
    800067cc:	6145                	addi	sp,sp,48
    800067ce:	8082                	ret

00000000800067d0 <log_write>:
{
    800067d0:	7179                	addi	sp,sp,-48
    800067d2:	f406                	sd	ra,40(sp)
    800067d4:	f022                	sd	s0,32(sp)
    800067d6:	ec26                	sd	s1,24(sp)
    800067d8:	e84a                	sd	s2,16(sp)
    800067da:	e44e                	sd	s3,8(sp)
    800067dc:	1800                	addi	s0,sp,48
    if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800067de:	0045c717          	auipc	a4,0x45c
    800067e2:	8c672703          	lw	a4,-1850(a4) # 804620a4 <log+0x2c>
    800067e6:	47f5                	li	a5,29
    800067e8:	0ae7cf63          	blt	a5,a4,800068a6 <log_write+0xd6>
    800067ec:	892a                	mv	s2,a0
    800067ee:	0045c797          	auipc	a5,0x45c
    800067f2:	8a67a783          	lw	a5,-1882(a5) # 80462094 <log+0x1c>
    800067f6:	37fd                	addiw	a5,a5,-1
    800067f8:	0af75763          	bge	a4,a5,800068a6 <log_write+0xd6>
    if (log.outstanding < 1)
    800067fc:	0045c797          	auipc	a5,0x45c
    80006800:	89c7a783          	lw	a5,-1892(a5) # 80462098 <log+0x20>
    80006804:	0af05963          	blez	a5,800068b6 <log_write+0xe6>
    acquire(&log.lock);
    80006808:	0045c497          	auipc	s1,0x45c
    8000680c:	87048493          	addi	s1,s1,-1936 # 80462078 <log>
    80006810:	8526                	mv	a0,s1
    80006812:	ffffd097          	auipc	ra,0xffffd
    80006816:	f44080e7          	jalr	-188(ra) # 80003756 <acquire>
    for (i = 0; i < log.lh.n; i++)
    8000681a:	54c4                	lw	s1,44(s1)
    8000681c:	0e905d63          	blez	s1,80006916 <log_write+0x146>
        if (log.lh.block[i] == b->blockno)
    80006820:	00c92683          	lw	a3,12(s2)
    80006824:	0045c797          	auipc	a5,0x45c
    80006828:	88478793          	addi	a5,a5,-1916 # 804620a8 <log+0x30>
    for (i = 0; i < log.lh.n; i++)
    8000682c:	4581                	li	a1,0
        if (log.lh.block[i] == b->blockno)
    8000682e:	4398                	lw	a4,0(a5)
    80006830:	08d70b63          	beq	a4,a3,800068c6 <log_write+0xf6>
    for (i = 0; i < log.lh.n; i++)
    80006834:	2585                	addiw	a1,a1,1
    80006836:	0791                	addi	a5,a5,4
    80006838:	fe959be3          	bne	a1,s1,8000682e <log_write+0x5e>
    log.lh.block[i] = b->blockno;
    8000683c:	00848793          	addi	a5,s1,8
    80006840:	00279713          	slli	a4,a5,0x2
    80006844:	0045c797          	auipc	a5,0x45c
    80006848:	83478793          	addi	a5,a5,-1996 # 80462078 <log>
    8000684c:	97ba                	add	a5,a5,a4
    8000684e:	00c92703          	lw	a4,12(s2)
    80006852:	cb98                	sw	a4,16(a5)
        bpin(b);
    80006854:	854a                	mv	a0,s2
    80006856:	00000097          	auipc	ra,0x0
    8000685a:	b02080e7          	jalr	-1278(ra) # 80006358 <bpin>
        log.lh.n++;
    8000685e:	0045c797          	auipc	a5,0x45c
    80006862:	81a78793          	addi	a5,a5,-2022 # 80462078 <log>
    80006866:	57d8                	lw	a4,44(a5)
    80006868:	2705                	addiw	a4,a4,1
    8000686a:	d7d8                	sw	a4,44(a5)
        struct buf *lbuf = bread(log.dev, log.start + i + 1);
    8000686c:	4f8c                	lw	a1,24(a5)
    8000686e:	9da5                	addw	a1,a1,s1
    80006870:	2585                	addiw	a1,a1,1
    80006872:	5788                	lw	a0,40(a5)
    80006874:	00000097          	auipc	ra,0x0
    80006878:	872080e7          	jalr	-1934(ra) # 800060e6 <bread>
    8000687c:	84aa                	mv	s1,a0
        memmove(lbuf->data, b->data, BSIZE);
    8000687e:	6605                	lui	a2,0x1
    80006880:	04090593          	addi	a1,s2,64
    80006884:	04050513          	addi	a0,a0,64
    80006888:	00000097          	auipc	ra,0x0
    8000688c:	b48080e7          	jalr	-1208(ra) # 800063d0 <memmove>
        bwrite(lbuf);
    80006890:	8526                	mv	a0,s1
    80006892:	00000097          	auipc	ra,0x0
    80006896:	992080e7          	jalr	-1646(ra) # 80006224 <bwrite>
        brelse(lbuf);
    8000689a:	8526                	mv	a0,s1
    8000689c:	00000097          	auipc	ra,0x0
    800068a0:	a1e080e7          	jalr	-1506(ra) # 800062ba <brelse>
    800068a4:	a041                	j	80006924 <log_write+0x154>
        panic("too big a transaction");
    800068a6:	00008517          	auipc	a0,0x8
    800068aa:	d0250513          	addi	a0,a0,-766 # 8000e5a8 <digits+0x43f8>
    800068ae:	ffffc097          	auipc	ra,0xffffc
    800068b2:	1de080e7          	jalr	478(ra) # 80002a8c <panic>
        panic("log_write outside of trans");
    800068b6:	00008517          	auipc	a0,0x8
    800068ba:	d0a50513          	addi	a0,a0,-758 # 8000e5c0 <digits+0x4410>
    800068be:	ffffc097          	auipc	ra,0xffffc
    800068c2:	1ce080e7          	jalr	462(ra) # 80002a8c <panic>
            struct buf *lbuf = bread(log.dev, log.start + i + 1);
    800068c6:	0045b997          	auipc	s3,0x45b
    800068ca:	7b298993          	addi	s3,s3,1970 # 80462078 <log>
    800068ce:	0189a783          	lw	a5,24(s3)
    800068d2:	9dbd                	addw	a1,a1,a5
    800068d4:	2585                	addiw	a1,a1,1
    800068d6:	0289a503          	lw	a0,40(s3)
    800068da:	00000097          	auipc	ra,0x0
    800068de:	80c080e7          	jalr	-2036(ra) # 800060e6 <bread>
    800068e2:	84aa                	mv	s1,a0
            memmove(lbuf->data, b->data, BSIZE);
    800068e4:	6605                	lui	a2,0x1
    800068e6:	04090593          	addi	a1,s2,64
    800068ea:	04050513          	addi	a0,a0,64
    800068ee:	00000097          	auipc	ra,0x0
    800068f2:	ae2080e7          	jalr	-1310(ra) # 800063d0 <memmove>
            bwrite(lbuf);
    800068f6:	8526                	mv	a0,s1
    800068f8:	00000097          	auipc	ra,0x0
    800068fc:	92c080e7          	jalr	-1748(ra) # 80006224 <bwrite>
            brelse(lbuf);
    80006900:	8526                	mv	a0,s1
    80006902:	00000097          	auipc	ra,0x0
    80006906:	9b8080e7          	jalr	-1608(ra) # 800062ba <brelse>
            release(&log.lock);
    8000690a:	854e                	mv	a0,s3
    8000690c:	ffffd097          	auipc	ra,0xffffd
    80006910:	eba080e7          	jalr	-326(ra) # 800037c6 <release>
            return;
    80006914:	a005                	j	80006934 <log_write+0x164>
    log.lh.block[i] = b->blockno;
    80006916:	00c92783          	lw	a5,12(s2)
    8000691a:	0045b717          	auipc	a4,0x45b
    8000691e:	78f72723          	sw	a5,1934(a4) # 804620a8 <log+0x30>
    if (i == log.lh.n)
    80006922:	d88d                	beqz	s1,80006854 <log_write+0x84>
    release(&log.lock);
    80006924:	0045b517          	auipc	a0,0x45b
    80006928:	75450513          	addi	a0,a0,1876 # 80462078 <log>
    8000692c:	ffffd097          	auipc	ra,0xffffd
    80006930:	e9a080e7          	jalr	-358(ra) # 800037c6 <release>
}
    80006934:	70a2                	ld	ra,40(sp)
    80006936:	7402                	ld	s0,32(sp)
    80006938:	64e2                	ld	s1,24(sp)
    8000693a:	6942                	ld	s2,16(sp)
    8000693c:	69a2                	ld	s3,8(sp)
    8000693e:	6145                	addi	sp,sp,48
    80006940:	8082                	ret

0000000080006942 <initlog_wrapper>:
    }
}

// 公共接口
void initlog_wrapper(int dev, struct superblock *sbp)
{
    80006942:	1101                	addi	sp,sp,-32
    80006944:	ec06                	sd	ra,24(sp)
    80006946:	e822                	sd	s0,16(sp)
    80006948:	e426                	sd	s1,8(sp)
    8000694a:	1000                	addi	s0,sp,32
    8000694c:	84aa                	mv	s1,a0
    memmove(&sb, sbp, sizeof(sb));
    8000694e:	02000613          	li	a2,32
    80006952:	0045b517          	auipc	a0,0x45b
    80006956:	7ce50513          	addi	a0,a0,1998 # 80462120 <sb>
    8000695a:	00000097          	auipc	ra,0x0
    8000695e:	a76080e7          	jalr	-1418(ra) # 800063d0 <memmove>
    initlog(dev, &sb);
    80006962:	0045b597          	auipc	a1,0x45b
    80006966:	7be58593          	addi	a1,a1,1982 # 80462120 <sb>
    8000696a:	8526                	mv	a0,s1
    8000696c:	00000097          	auipc	ra,0x0
    80006970:	c64080e7          	jalr	-924(ra) # 800065d0 <initlog>
}
    80006974:	60e2                	ld	ra,24(sp)
    80006976:	6442                	ld	s0,16(sp)
    80006978:	64a2                	ld	s1,8(sp)
    8000697a:	6105                	addi	sp,sp,32
    8000697c:	8082                	ret

000000008000697e <memmove>:
}

// 内存复制
static void *
memmove(void *dst, const void *src, uint n)
{
    8000697e:	1141                	addi	sp,sp,-16
    80006980:	e422                	sd	s0,8(sp)
    80006982:	0800                	addi	s0,sp,16
    const char *s;
    char *d;

    s = src;
    d = dst;
    if (s < d && s + n > d)
    80006984:	02a5e563          	bltu	a1,a0,800069ae <memmove+0x30>
        d += n;
        while (n-- > 0)
            *--d = *--s;
    }
    else
        while (n-- > 0)
    80006988:	fff6069b          	addiw	a3,a2,-1
    8000698c:	ce11                	beqz	a2,800069a8 <memmove+0x2a>
    8000698e:	1682                	slli	a3,a3,0x20
    80006990:	9281                	srli	a3,a3,0x20
    80006992:	0685                	addi	a3,a3,1
    80006994:	96ae                	add	a3,a3,a1
    80006996:	87aa                	mv	a5,a0
            *d++ = *s++;
    80006998:	0585                	addi	a1,a1,1
    8000699a:	0785                	addi	a5,a5,1
    8000699c:	fff5c703          	lbu	a4,-1(a1)
    800069a0:	fee78fa3          	sb	a4,-1(a5)
        while (n-- > 0)
    800069a4:	fed59ae3          	bne	a1,a3,80006998 <memmove+0x1a>
    return dst;
}
    800069a8:	6422                	ld	s0,8(sp)
    800069aa:	0141                	addi	sp,sp,16
    800069ac:	8082                	ret
    if (s < d && s + n > d)
    800069ae:	02061713          	slli	a4,a2,0x20
    800069b2:	9301                	srli	a4,a4,0x20
    800069b4:	00e587b3          	add	a5,a1,a4
    800069b8:	fcf578e3          	bgeu	a0,a5,80006988 <memmove+0xa>
        d += n;
    800069bc:	972a                	add	a4,a4,a0
        while (n-- > 0)
    800069be:	fff6069b          	addiw	a3,a2,-1
    800069c2:	d27d                	beqz	a2,800069a8 <memmove+0x2a>
    800069c4:	02069613          	slli	a2,a3,0x20
    800069c8:	9201                	srli	a2,a2,0x20
    800069ca:	fff64613          	not	a2,a2
    800069ce:	963e                	add	a2,a2,a5
            *--d = *--s;
    800069d0:	17fd                	addi	a5,a5,-1
    800069d2:	177d                	addi	a4,a4,-1
    800069d4:	0007c683          	lbu	a3,0(a5)
    800069d8:	00d70023          	sb	a3,0(a4)
        while (n-- > 0)
    800069dc:	fef61ae3          	bne	a2,a5,800069d0 <memmove+0x52>
    800069e0:	b7e1                	j	800069a8 <memmove+0x2a>

00000000800069e2 <iinit>:
{
    800069e2:	7179                	addi	sp,sp,-48
    800069e4:	f406                	sd	ra,40(sp)
    800069e6:	f022                	sd	s0,32(sp)
    800069e8:	ec26                	sd	s1,24(sp)
    800069ea:	e84a                	sd	s2,16(sp)
    800069ec:	e44e                	sd	s3,8(sp)
    800069ee:	1800                	addi	s0,sp,48
    initlock(&icache.lock, "icache");
    800069f0:	00008597          	auipc	a1,0x8
    800069f4:	bf058593          	addi	a1,a1,-1040 # 8000e5e0 <digits+0x4430>
    800069f8:	0045b517          	auipc	a0,0x45b
    800069fc:	74850513          	addi	a0,a0,1864 # 80462140 <icache>
    80006a00:	ffffd097          	auipc	ra,0xffffd
    80006a04:	c74080e7          	jalr	-908(ra) # 80003674 <initlock>
    for (i = 0; i < NINODE; i++)
    80006a08:	0045b497          	auipc	s1,0x45b
    80006a0c:	76048493          	addi	s1,s1,1888 # 80462168 <icache+0x28>
    80006a10:	0045d997          	auipc	s3,0x45d
    80006a14:	50898993          	addi	s3,s3,1288 # 80463f18 <ftable+0x10>
        initsleeplock(&icache.inode[i].lock, "inode");
    80006a18:	00008917          	auipc	s2,0x8
    80006a1c:	bd090913          	addi	s2,s2,-1072 # 8000e5e8 <digits+0x4438>
    80006a20:	85ca                	mv	a1,s2
    80006a22:	8526                	mv	a0,s1
    80006a24:	ffffd097          	auipc	ra,0xffffd
    80006a28:	de6080e7          	jalr	-538(ra) # 8000380a <initsleeplock>
    for (i = 0; i < NINODE; i++)
    80006a2c:	09848493          	addi	s1,s1,152
    80006a30:	ff3498e3          	bne	s1,s3,80006a20 <iinit+0x3e>
}
    80006a34:	70a2                	ld	ra,40(sp)
    80006a36:	7402                	ld	s0,32(sp)
    80006a38:	64e2                	ld	s1,24(sp)
    80006a3a:	6942                	ld	s2,16(sp)
    80006a3c:	69a2                	ld	s3,8(sp)
    80006a3e:	6145                	addi	sp,sp,48
    80006a40:	8082                	ret

0000000080006a42 <ilock>:
{
    80006a42:	7179                	addi	sp,sp,-48
    80006a44:	f406                	sd	ra,40(sp)
    80006a46:	f022                	sd	s0,32(sp)
    80006a48:	ec26                	sd	s1,24(sp)
    80006a4a:	e84a                	sd	s2,16(sp)
    80006a4c:	e44e                	sd	s3,8(sp)
    80006a4e:	e052                	sd	s4,0(sp)
    80006a50:	1800                	addi	s0,sp,48
    if (ip == 0 || ip->ref < 1)
    80006a52:	c505                	beqz	a0,80006a7a <ilock+0x38>
    80006a54:	84aa                	mv	s1,a0
    80006a56:	451c                	lw	a5,8(a0)
    80006a58:	02f05163          	blez	a5,80006a7a <ilock+0x38>
    acquiresleep(&ip->lock);
    80006a5c:	0541                	addi	a0,a0,16
    80006a5e:	ffffd097          	auipc	ra,0xffffd
    80006a62:	de6080e7          	jalr	-538(ra) # 80003844 <acquiresleep>
    if (ip->valid == 0)
    80006a66:	40bc                	lw	a5,64(s1)
    80006a68:	c38d                	beqz	a5,80006a8a <ilock+0x48>
}
    80006a6a:	70a2                	ld	ra,40(sp)
    80006a6c:	7402                	ld	s0,32(sp)
    80006a6e:	64e2                	ld	s1,24(sp)
    80006a70:	6942                	ld	s2,16(sp)
    80006a72:	69a2                	ld	s3,8(sp)
    80006a74:	6a02                	ld	s4,0(sp)
    80006a76:	6145                	addi	sp,sp,48
    80006a78:	8082                	ret
        panic("ilock");
    80006a7a:	00008517          	auipc	a0,0x8
    80006a7e:	b7650513          	addi	a0,a0,-1162 # 8000e5f0 <digits+0x4440>
    80006a82:	ffffc097          	auipc	ra,0xffffc
    80006a86:	00a080e7          	jalr	10(ra) # 80002a8c <panic>
        bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80006a8a:	40dc                	lw	a5,4(s1)
    80006a8c:	03000a13          	li	s4,48
    80006a90:	0347d7bb          	divuw	a5,a5,s4
    80006a94:	0045b597          	auipc	a1,0x45b
    80006a98:	6a45a583          	lw	a1,1700(a1) # 80462138 <sb+0x18>
    80006a9c:	9dbd                	addw	a1,a1,a5
    80006a9e:	4088                	lw	a0,0(s1)
    80006aa0:	fffff097          	auipc	ra,0xfffff
    80006aa4:	646080e7          	jalr	1606(ra) # 800060e6 <bread>
    80006aa8:	89aa                	mv	s3,a0
        dip = (struct dinode *)bp->data + (ip->inum % IPB);
    80006aaa:	04050913          	addi	s2,a0,64
    80006aae:	40dc                	lw	a5,4(s1)
    80006ab0:	0347f7bb          	remuw	a5,a5,s4
    80006ab4:	1782                	slli	a5,a5,0x20
    80006ab6:	9381                	srli	a5,a5,0x20
    80006ab8:	05400713          	li	a4,84
    80006abc:	02e787b3          	mul	a5,a5,a4
    80006ac0:	993e                	add	s2,s2,a5
        ip->type = dip->type;
    80006ac2:	00c91783          	lh	a5,12(s2)
    80006ac6:	04f49223          	sh	a5,68(s1)
        ip->mode = dip->mode;
    80006aca:	00095783          	lhu	a5,0(s2)
    80006ace:	04f49423          	sh	a5,72(s1)
        ip->uid = dip->uid;
    80006ad2:	00295783          	lhu	a5,2(s2)
    80006ad6:	04f49523          	sh	a5,74(s1)
        ip->size = dip->size;
    80006ada:	00492783          	lw	a5,4(s2)
    80006ade:	c4fc                	sw	a5,76(s1)
        ip->blocks = dip->blocks;
    80006ae0:	00892783          	lw	a5,8(s2)
    80006ae4:	c8bc                	sw	a5,80(s1)
        ip->atime = dip->atime;
    80006ae6:	01092783          	lw	a5,16(s2)
    80006aea:	c8fc                	sw	a5,84(s1)
        ip->mtime = dip->mtime;
    80006aec:	01492783          	lw	a5,20(s2)
    80006af0:	ccbc                	sw	a5,88(s1)
        ip->ctime = dip->ctime;
    80006af2:	01892783          	lw	a5,24(s2)
    80006af6:	ccfc                	sw	a5,92(s1)
        memmove(ip->direct, dip->direct, sizeof(ip->direct));
    80006af8:	03000613          	li	a2,48
    80006afc:	01c90593          	addi	a1,s2,28
    80006b00:	06048513          	addi	a0,s1,96
    80006b04:	00000097          	auipc	ra,0x0
    80006b08:	e7a080e7          	jalr	-390(ra) # 8000697e <memmove>
        ip->indirect = dip->indirect;
    80006b0c:	04c92783          	lw	a5,76(s2)
    80006b10:	08f4a823          	sw	a5,144(s1)
        ip->double_indirect = dip->double_indirect;
    80006b14:	05092783          	lw	a5,80(s2)
    80006b18:	08f4aa23          	sw	a5,148(s1)
        ip->nlink = dip->nlink;
    80006b1c:	00e91783          	lh	a5,14(s2)
    80006b20:	04f49323          	sh	a5,70(s1)
        ip->type = dip->type;
    80006b24:	00c91783          	lh	a5,12(s2)
    80006b28:	04f49223          	sh	a5,68(s1)
        brelse(bp);
    80006b2c:	854e                	mv	a0,s3
    80006b2e:	fffff097          	auipc	ra,0xfffff
    80006b32:	78c080e7          	jalr	1932(ra) # 800062ba <brelse>
        ip->valid = 1;
    80006b36:	4785                	li	a5,1
    80006b38:	c0bc                	sw	a5,64(s1)
}
    80006b3a:	bf05                	j	80006a6a <ilock+0x28>

0000000080006b3c <iunlock>:
{
    80006b3c:	1101                	addi	sp,sp,-32
    80006b3e:	ec06                	sd	ra,24(sp)
    80006b40:	e822                	sd	s0,16(sp)
    80006b42:	e426                	sd	s1,8(sp)
    80006b44:	e04a                	sd	s2,0(sp)
    80006b46:	1000                	addi	s0,sp,32
    if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80006b48:	c905                	beqz	a0,80006b78 <iunlock+0x3c>
    80006b4a:	84aa                	mv	s1,a0
    80006b4c:	01050913          	addi	s2,a0,16
    80006b50:	854a                	mv	a0,s2
    80006b52:	ffffd097          	auipc	ra,0xffffd
    80006b56:	d9e080e7          	jalr	-610(ra) # 800038f0 <holdingsleep>
    80006b5a:	cd19                	beqz	a0,80006b78 <iunlock+0x3c>
    80006b5c:	449c                	lw	a5,8(s1)
    80006b5e:	00f05d63          	blez	a5,80006b78 <iunlock+0x3c>
    releasesleep(&ip->lock);
    80006b62:	854a                	mv	a0,s2
    80006b64:	ffffd097          	auipc	ra,0xffffd
    80006b68:	d52080e7          	jalr	-686(ra) # 800038b6 <releasesleep>
}
    80006b6c:	60e2                	ld	ra,24(sp)
    80006b6e:	6442                	ld	s0,16(sp)
    80006b70:	64a2                	ld	s1,8(sp)
    80006b72:	6902                	ld	s2,0(sp)
    80006b74:	6105                	addi	sp,sp,32
    80006b76:	8082                	ret
        panic("iunlock");
    80006b78:	00008517          	auipc	a0,0x8
    80006b7c:	a8050513          	addi	a0,a0,-1408 # 8000e5f8 <digits+0x4448>
    80006b80:	ffffc097          	auipc	ra,0xffffc
    80006b84:	f0c080e7          	jalr	-244(ra) # 80002a8c <panic>

0000000080006b88 <iget>:
{
    80006b88:	7179                	addi	sp,sp,-48
    80006b8a:	f406                	sd	ra,40(sp)
    80006b8c:	f022                	sd	s0,32(sp)
    80006b8e:	ec26                	sd	s1,24(sp)
    80006b90:	e84a                	sd	s2,16(sp)
    80006b92:	e44e                	sd	s3,8(sp)
    80006b94:	e052                	sd	s4,0(sp)
    80006b96:	1800                	addi	s0,sp,48
    80006b98:	89aa                	mv	s3,a0
    80006b9a:	8a2e                	mv	s4,a1
    acquire(&icache.lock);
    80006b9c:	0045b517          	auipc	a0,0x45b
    80006ba0:	5a450513          	addi	a0,a0,1444 # 80462140 <icache>
    80006ba4:	ffffd097          	auipc	ra,0xffffd
    80006ba8:	bb2080e7          	jalr	-1102(ra) # 80003756 <acquire>
    empty = 0;
    80006bac:	4901                	li	s2,0
    for (ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++)
    80006bae:	0045b497          	auipc	s1,0x45b
    80006bb2:	5aa48493          	addi	s1,s1,1450 # 80462158 <icache+0x18>
    80006bb6:	0045d697          	auipc	a3,0x45d
    80006bba:	35268693          	addi	a3,a3,850 # 80463f08 <ftable>
    80006bbe:	a039                	j	80006bcc <iget+0x44>
        if (empty == 0 && ip->ref == 0)
    80006bc0:	02090b63          	beqz	s2,80006bf6 <iget+0x6e>
    for (ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++)
    80006bc4:	09848493          	addi	s1,s1,152
    80006bc8:	02d48a63          	beq	s1,a3,80006bfc <iget+0x74>
        if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    80006bcc:	449c                	lw	a5,8(s1)
    80006bce:	fef059e3          	blez	a5,80006bc0 <iget+0x38>
    80006bd2:	4098                	lw	a4,0(s1)
    80006bd4:	ff3716e3          	bne	a4,s3,80006bc0 <iget+0x38>
    80006bd8:	40d8                	lw	a4,4(s1)
    80006bda:	ff4713e3          	bne	a4,s4,80006bc0 <iget+0x38>
            ip->ref++;
    80006bde:	2785                	addiw	a5,a5,1
    80006be0:	c49c                	sw	a5,8(s1)
            release(&icache.lock);
    80006be2:	0045b517          	auipc	a0,0x45b
    80006be6:	55e50513          	addi	a0,a0,1374 # 80462140 <icache>
    80006bea:	ffffd097          	auipc	ra,0xffffd
    80006bee:	bdc080e7          	jalr	-1060(ra) # 800037c6 <release>
            return ip;
    80006bf2:	8926                	mv	s2,s1
    80006bf4:	a03d                	j	80006c22 <iget+0x9a>
        if (empty == 0 && ip->ref == 0)
    80006bf6:	f7f9                	bnez	a5,80006bc4 <iget+0x3c>
    80006bf8:	8926                	mv	s2,s1
    80006bfa:	b7e9                	j	80006bc4 <iget+0x3c>
    if (empty == 0)
    80006bfc:	02090c63          	beqz	s2,80006c34 <iget+0xac>
    ip->dev = dev;
    80006c00:	01392023          	sw	s3,0(s2)
    ip->inum = inum;
    80006c04:	01492223          	sw	s4,4(s2)
    ip->ref = 1;
    80006c08:	4785                	li	a5,1
    80006c0a:	00f92423          	sw	a5,8(s2)
    ip->valid = 0;
    80006c0e:	04092023          	sw	zero,64(s2)
    release(&icache.lock);
    80006c12:	0045b517          	auipc	a0,0x45b
    80006c16:	52e50513          	addi	a0,a0,1326 # 80462140 <icache>
    80006c1a:	ffffd097          	auipc	ra,0xffffd
    80006c1e:	bac080e7          	jalr	-1108(ra) # 800037c6 <release>
}
    80006c22:	854a                	mv	a0,s2
    80006c24:	70a2                	ld	ra,40(sp)
    80006c26:	7402                	ld	s0,32(sp)
    80006c28:	64e2                	ld	s1,24(sp)
    80006c2a:	6942                	ld	s2,16(sp)
    80006c2c:	69a2                	ld	s3,8(sp)
    80006c2e:	6a02                	ld	s4,0(sp)
    80006c30:	6145                	addi	sp,sp,48
    80006c32:	8082                	ret
        panic("iget: no inodes");
    80006c34:	00008517          	auipc	a0,0x8
    80006c38:	9cc50513          	addi	a0,a0,-1588 # 8000e600 <digits+0x4450>
    80006c3c:	ffffc097          	auipc	ra,0xffffc
    80006c40:	e50080e7          	jalr	-432(ra) # 80002a8c <panic>

0000000080006c44 <ialloc>:
{
    80006c44:	715d                	addi	sp,sp,-80
    80006c46:	e486                	sd	ra,72(sp)
    80006c48:	e0a2                	sd	s0,64(sp)
    80006c4a:	fc26                	sd	s1,56(sp)
    80006c4c:	f84a                	sd	s2,48(sp)
    80006c4e:	f44e                	sd	s3,40(sp)
    80006c50:	f052                	sd	s4,32(sp)
    80006c52:	ec56                	sd	s5,24(sp)
    80006c54:	e85a                	sd	s6,16(sp)
    80006c56:	e45e                	sd	s7,8(sp)
    80006c58:	e062                	sd	s8,0(sp)
    80006c5a:	0880                	addi	s0,sp,80
    if (sb.magic != FSMAGIC)
    80006c5c:	0045b717          	auipc	a4,0x45b
    80006c60:	4c472703          	lw	a4,1220(a4) # 80462120 <sb>
    80006c64:	102037b7          	lui	a5,0x10203
    80006c68:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80006c6c:	06f71e63          	bne	a4,a5,80006ce8 <ialloc+0xa4>
    80006c70:	8aaa                	mv	s5,a0
    80006c72:	8c2e                	mv	s8,a1
    for (inum = 1; inum < sb.ninodes; inum++)
    80006c74:	0045b717          	auipc	a4,0x45b
    80006c78:	4b872703          	lw	a4,1208(a4) # 8046212c <sb+0xc>
    80006c7c:	4785                	li	a5,1
    80006c7e:	4485                	li	s1,1
    80006c80:	04e7fc63          	bgeu	a5,a4,80006cd8 <ialloc+0x94>
        bp = bread(dev, IBLOCK(inum, sb));
    80006c84:	03000993          	li	s3,48
    80006c88:	0045ba17          	auipc	s4,0x45b
    80006c8c:	498a0a13          	addi	s4,s4,1176 # 80462120 <sb>
        dip = (struct dinode *)bp->data + (inum % IPB);
    80006c90:	05400b93          	li	s7,84
    80006c94:	00048b1b          	sext.w	s6,s1
        bp = bread(dev, IBLOCK(inum, sb));
    80006c98:	0334d7b3          	divu	a5,s1,s3
    80006c9c:	018a2583          	lw	a1,24(s4)
    80006ca0:	9dbd                	addw	a1,a1,a5
    80006ca2:	8556                	mv	a0,s5
    80006ca4:	fffff097          	auipc	ra,0xfffff
    80006ca8:	442080e7          	jalr	1090(ra) # 800060e6 <bread>
    80006cac:	892a                	mv	s2,a0
        dip = (struct dinode *)bp->data + (inum % IPB);
    80006cae:	04050793          	addi	a5,a0,64
    80006cb2:	0334f733          	remu	a4,s1,s3
    80006cb6:	03770733          	mul	a4,a4,s7
    80006cba:	97ba                	add	a5,a5,a4
        if (dip->type == 0)
    80006cbc:	00c79703          	lh	a4,12(a5)
    80006cc0:	cf05                	beqz	a4,80006cf8 <ialloc+0xb4>
        brelse(bp);
    80006cc2:	fffff097          	auipc	ra,0xfffff
    80006cc6:	5f8080e7          	jalr	1528(ra) # 800062ba <brelse>
    for (inum = 1; inum < sb.ninodes; inum++)
    80006cca:	0485                	addi	s1,s1,1
    80006ccc:	00ca2703          	lw	a4,12(s4)
    80006cd0:	0004879b          	sext.w	a5,s1
    80006cd4:	fce7e0e3          	bltu	a5,a4,80006c94 <ialloc+0x50>
    panic("ialloc: no inodes");
    80006cd8:	00008517          	auipc	a0,0x8
    80006cdc:	96050513          	addi	a0,a0,-1696 # 8000e638 <digits+0x4488>
    80006ce0:	ffffc097          	auipc	ra,0xffffc
    80006ce4:	dac080e7          	jalr	-596(ra) # 80002a8c <panic>
        panic("ialloc: superblock not initialized");
    80006ce8:	00008517          	auipc	a0,0x8
    80006cec:	92850513          	addi	a0,a0,-1752 # 8000e610 <digits+0x4460>
    80006cf0:	ffffc097          	auipc	ra,0xffffc
    80006cf4:	d9c080e7          	jalr	-612(ra) # 80002a8c <panic>
    80006cf8:	873e                	mv	a4,a5
    80006cfa:	05478693          	addi	a3,a5,84
memset(void *dst, int c, uint n)
{
    char *cdst = (char *)dst;
    for (int i = 0; i < n; i++)
    {
        cdst[i] = c;
    80006cfe:	00070023          	sb	zero,0(a4)
    for (int i = 0; i < n; i++)
    80006d02:	0705                	addi	a4,a4,1
    80006d04:	fed71de3          	bne	a4,a3,80006cfe <ialloc+0xba>
            dip->type = type;
    80006d08:	01879623          	sh	s8,12(a5)
            if (log.dev != 0)
    80006d0c:	0045b797          	auipc	a5,0x45b
    80006d10:	3947a783          	lw	a5,916(a5) # 804620a0 <log+0x28>
    80006d14:	cf8d                	beqz	a5,80006d4e <ialloc+0x10a>
                log_write(bp);
    80006d16:	854a                	mv	a0,s2
    80006d18:	00000097          	auipc	ra,0x0
    80006d1c:	ab8080e7          	jalr	-1352(ra) # 800067d0 <log_write>
            brelse(bp);
    80006d20:	854a                	mv	a0,s2
    80006d22:	fffff097          	auipc	ra,0xfffff
    80006d26:	598080e7          	jalr	1432(ra) # 800062ba <brelse>
            return iget(dev, inum);
    80006d2a:	85da                	mv	a1,s6
    80006d2c:	8556                	mv	a0,s5
    80006d2e:	00000097          	auipc	ra,0x0
    80006d32:	e5a080e7          	jalr	-422(ra) # 80006b88 <iget>
}
    80006d36:	60a6                	ld	ra,72(sp)
    80006d38:	6406                	ld	s0,64(sp)
    80006d3a:	74e2                	ld	s1,56(sp)
    80006d3c:	7942                	ld	s2,48(sp)
    80006d3e:	79a2                	ld	s3,40(sp)
    80006d40:	7a02                	ld	s4,32(sp)
    80006d42:	6ae2                	ld	s5,24(sp)
    80006d44:	6b42                	ld	s6,16(sp)
    80006d46:	6ba2                	ld	s7,8(sp)
    80006d48:	6c02                	ld	s8,0(sp)
    80006d4a:	6161                	addi	sp,sp,80
    80006d4c:	8082                	ret
                bwrite(bp);
    80006d4e:	854a                	mv	a0,s2
    80006d50:	fffff097          	auipc	ra,0xfffff
    80006d54:	4d4080e7          	jalr	1236(ra) # 80006224 <bwrite>
    80006d58:	b7e1                	j	80006d20 <ialloc+0xdc>

0000000080006d5a <idup>:
{
    80006d5a:	1101                	addi	sp,sp,-32
    80006d5c:	ec06                	sd	ra,24(sp)
    80006d5e:	e822                	sd	s0,16(sp)
    80006d60:	e426                	sd	s1,8(sp)
    80006d62:	1000                	addi	s0,sp,32
    80006d64:	84aa                	mv	s1,a0
    acquire(&icache.lock);
    80006d66:	0045b517          	auipc	a0,0x45b
    80006d6a:	3da50513          	addi	a0,a0,986 # 80462140 <icache>
    80006d6e:	ffffd097          	auipc	ra,0xffffd
    80006d72:	9e8080e7          	jalr	-1560(ra) # 80003756 <acquire>
    ip->ref++;
    80006d76:	449c                	lw	a5,8(s1)
    80006d78:	2785                	addiw	a5,a5,1
    80006d7a:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    80006d7c:	0045b517          	auipc	a0,0x45b
    80006d80:	3c450513          	addi	a0,a0,964 # 80462140 <icache>
    80006d84:	ffffd097          	auipc	ra,0xffffd
    80006d88:	a42080e7          	jalr	-1470(ra) # 800037c6 <release>
}
    80006d8c:	8526                	mv	a0,s1
    80006d8e:	60e2                	ld	ra,24(sp)
    80006d90:	6442                	ld	s0,16(sp)
    80006d92:	64a2                	ld	s1,8(sp)
    80006d94:	6105                	addi	sp,sp,32
    80006d96:	8082                	ret

0000000080006d98 <iupdate>:
{
    80006d98:	7179                	addi	sp,sp,-48
    80006d9a:	f406                	sd	ra,40(sp)
    80006d9c:	f022                	sd	s0,32(sp)
    80006d9e:	ec26                	sd	s1,24(sp)
    80006da0:	e84a                	sd	s2,16(sp)
    80006da2:	e44e                	sd	s3,8(sp)
    80006da4:	e052                	sd	s4,0(sp)
    80006da6:	1800                	addi	s0,sp,48
    80006da8:	84aa                	mv	s1,a0
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80006daa:	415c                	lw	a5,4(a0)
    80006dac:	03000a13          	li	s4,48
    80006db0:	0347d7bb          	divuw	a5,a5,s4
    80006db4:	0045b597          	auipc	a1,0x45b
    80006db8:	3845a583          	lw	a1,900(a1) # 80462138 <sb+0x18>
    80006dbc:	9dbd                	addw	a1,a1,a5
    80006dbe:	4108                	lw	a0,0(a0)
    80006dc0:	fffff097          	auipc	ra,0xfffff
    80006dc4:	326080e7          	jalr	806(ra) # 800060e6 <bread>
    80006dc8:	89aa                	mv	s3,a0
    dip = (struct dinode *)bp->data + (ip->inum % IPB);
    80006dca:	04050913          	addi	s2,a0,64
    80006dce:	40dc                	lw	a5,4(s1)
    80006dd0:	0347f7bb          	remuw	a5,a5,s4
    80006dd4:	1782                	slli	a5,a5,0x20
    80006dd6:	9381                	srli	a5,a5,0x20
    80006dd8:	05400713          	li	a4,84
    80006ddc:	02e787b3          	mul	a5,a5,a4
    80006de0:	993e                	add	s2,s2,a5
    dip->type = ip->type;
    80006de2:	04449783          	lh	a5,68(s1)
    80006de6:	00f91623          	sh	a5,12(s2)
    dip->nlink = ip->nlink;
    80006dea:	04649783          	lh	a5,70(s1)
    80006dee:	00f91723          	sh	a5,14(s2)
    dip->mode = ip->mode;
    80006df2:	0484d783          	lhu	a5,72(s1)
    80006df6:	00f91023          	sh	a5,0(s2)
    dip->uid = ip->uid;
    80006dfa:	04a4d783          	lhu	a5,74(s1)
    80006dfe:	00f91123          	sh	a5,2(s2)
    dip->size = ip->size;
    80006e02:	44fc                	lw	a5,76(s1)
    80006e04:	00f92223          	sw	a5,4(s2)
    dip->blocks = ip->blocks;
    80006e08:	48bc                	lw	a5,80(s1)
    80006e0a:	00f92423          	sw	a5,8(s2)
    dip->atime = ip->atime;
    80006e0e:	48fc                	lw	a5,84(s1)
    80006e10:	00f92823          	sw	a5,16(s2)
    dip->mtime = ip->mtime;
    80006e14:	4cbc                	lw	a5,88(s1)
    80006e16:	00f92a23          	sw	a5,20(s2)
    dip->ctime = ip->ctime;
    80006e1a:	4cfc                	lw	a5,92(s1)
    80006e1c:	00f92c23          	sw	a5,24(s2)
    memmove(dip->direct, ip->direct, sizeof(ip->direct));
    80006e20:	03000613          	li	a2,48
    80006e24:	06048593          	addi	a1,s1,96
    80006e28:	01c90513          	addi	a0,s2,28
    80006e2c:	00000097          	auipc	ra,0x0
    80006e30:	b52080e7          	jalr	-1198(ra) # 8000697e <memmove>
    dip->indirect = ip->indirect;
    80006e34:	0904a783          	lw	a5,144(s1)
    80006e38:	04f92623          	sw	a5,76(s2)
    dip->double_indirect = ip->double_indirect;
    80006e3c:	0944a783          	lw	a5,148(s1)
    80006e40:	04f92823          	sw	a5,80(s2)
    if (log.dev != 0)
    80006e44:	0045b797          	auipc	a5,0x45b
    80006e48:	25c7a783          	lw	a5,604(a5) # 804620a0 <log+0x28>
    80006e4c:	c39d                	beqz	a5,80006e72 <iupdate+0xda>
        log_write(bp);
    80006e4e:	854e                	mv	a0,s3
    80006e50:	00000097          	auipc	ra,0x0
    80006e54:	980080e7          	jalr	-1664(ra) # 800067d0 <log_write>
    brelse(bp);
    80006e58:	854e                	mv	a0,s3
    80006e5a:	fffff097          	auipc	ra,0xfffff
    80006e5e:	460080e7          	jalr	1120(ra) # 800062ba <brelse>
}
    80006e62:	70a2                	ld	ra,40(sp)
    80006e64:	7402                	ld	s0,32(sp)
    80006e66:	64e2                	ld	s1,24(sp)
    80006e68:	6942                	ld	s2,16(sp)
    80006e6a:	69a2                	ld	s3,8(sp)
    80006e6c:	6a02                	ld	s4,0(sp)
    80006e6e:	6145                	addi	sp,sp,48
    80006e70:	8082                	ret
        bwrite(bp);
    80006e72:	854e                	mv	a0,s3
    80006e74:	fffff097          	auipc	ra,0xfffff
    80006e78:	3b0080e7          	jalr	944(ra) # 80006224 <bwrite>
    80006e7c:	bff1                	j	80006e58 <iupdate+0xc0>

0000000080006e7e <balloc>:
    return 0;
}

// 块分配和释放（需要实现）
uint balloc(uint dev)
{
    80006e7e:	711d                	addi	sp,sp,-96
    80006e80:	ec86                	sd	ra,88(sp)
    80006e82:	e8a2                	sd	s0,80(sp)
    80006e84:	e4a6                	sd	s1,72(sp)
    80006e86:	e0ca                	sd	s2,64(sp)
    80006e88:	fc4e                	sd	s3,56(sp)
    80006e8a:	f852                	sd	s4,48(sp)
    80006e8c:	f456                	sd	s5,40(sp)
    80006e8e:	f05a                	sd	s6,32(sp)
    80006e90:	ec5e                	sd	s7,24(sp)
    80006e92:	e862                	sd	s8,16(sp)
    80006e94:	e466                	sd	s9,8(sp)
    80006e96:	1080                	addi	s0,sp,96

    bp = 0;
    // 从数据块开始查找（跳过元数据块）
    // 元数据块包括：引导块(0)、超级块(1)、日志区、inode区、位图区
    // 数据块从 nmeta 开始，nmeta = bmapstart + (size / BPB) + 1
    int nmeta = sb.bmapstart + (sb.size / BPB) + 1;
    80006e98:	0045b717          	auipc	a4,0x45b
    80006e9c:	28870713          	addi	a4,a4,648 # 80462120 <sb>
    80006ea0:	435c                	lw	a5,4(a4)
    80006ea2:	01c72a83          	lw	s5,28(a4)
    80006ea6:	2a85                	addiw	s5,s5,1
    80006ea8:	00f7d71b          	srliw	a4,a5,0xf
    80006eac:	00ea8abb          	addw	s5,s5,a4
    80006eb0:	000a871b          	sext.w	a4,s5
    for (b = nmeta; b < sb.size; b += BPB)
    80006eb4:	12f77a63          	bgeu	a4,a5,80006fe8 <balloc+0x16a>
    80006eb8:	8baa                	mv	s7,a0
    80006eba:	8aba                	mv	s5,a4
    {
        bp = bread(dev, BBLOCK(b, sb));
    80006ebc:	0045bb17          	auipc	s6,0x45b
    80006ec0:	264b0b13          	addi	s6,s6,612 # 80462120 <sb>
        for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006ec4:	4c01                	li	s8,0
        {
            m = 1 << (bi % 8);
    80006ec6:	4985                	li	s3,1
        for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006ec8:	6a21                	lui	s4,0x8
    for (b = nmeta; b < sb.size; b += BPB)
    80006eca:	6ca1                	lui	s9,0x8
    80006ecc:	a865                	j	80006f84 <balloc+0x106>
            if ((bp->data[bi / 8] & m) == 0)
            {                          // 空闲块
                bp->data[bi / 8] |= m; // 标记为已使用
    80006ece:	974a                	add	a4,a4,s2
    80006ed0:	8fd5                	or	a5,a5,a3
    80006ed2:	04f70023          	sb	a5,64(a4)
                // 如果日志系统已初始化，使用日志；否则直接写入
                extern struct log log;
                if (log.dev != 0)
    80006ed6:	0045b797          	auipc	a5,0x45b
    80006eda:	1ca7a783          	lw	a5,458(a5) # 804620a0 <log+0x28>
    80006ede:	cbb5                	beqz	a5,80006f52 <balloc+0xd4>
                {
                    log_write(bp);
    80006ee0:	854a                	mv	a0,s2
    80006ee2:	00000097          	auipc	ra,0x0
    80006ee6:	8ee080e7          	jalr	-1810(ra) # 800067d0 <log_write>
                }
                else
                {
                    bwrite(bp);
                }
                brelse(bp);
    80006eea:	854a                	mv	a0,s2
    80006eec:	fffff097          	auipc	ra,0xfffff
    80006ef0:	3ce080e7          	jalr	974(ra) # 800062ba <brelse>
static void
bzero(int dev, int bno)
{
    struct buf *bp;

    bp = bread(dev, bno);
    80006ef4:	85a6                	mv	a1,s1
    80006ef6:	855e                	mv	a0,s7
    80006ef8:	fffff097          	auipc	ra,0xfffff
    80006efc:	1ee080e7          	jalr	494(ra) # 800060e6 <bread>
    80006f00:	892a                	mv	s2,a0
    for (int i = 0; i < n; i++)
    80006f02:	04050793          	addi	a5,a0,64
    80006f06:	6705                	lui	a4,0x1
    80006f08:	04070713          	addi	a4,a4,64 # 1040 <_entry-0x7fffefc0>
    80006f0c:	972a                	add	a4,a4,a0
        cdst[i] = c;
    80006f0e:	00078023          	sb	zero,0(a5)
    for (int i = 0; i < n; i++)
    80006f12:	0785                	addi	a5,a5,1
    80006f14:	fee79de3          	bne	a5,a4,80006f0e <balloc+0x90>
    memset(bp->data, 0, BSIZE);
    // 如果日志系统已初始化，使用日志；否则直接写入
    extern struct log log;
    if (log.dev != 0)
    80006f18:	0045b797          	auipc	a5,0x45b
    80006f1c:	1887a783          	lw	a5,392(a5) # 804620a0 <log+0x28>
    80006f20:	cf9d                	beqz	a5,80006f5e <balloc+0xe0>
    {
        log_write(bp);
    80006f22:	854a                	mv	a0,s2
    80006f24:	00000097          	auipc	ra,0x0
    80006f28:	8ac080e7          	jalr	-1876(ra) # 800067d0 <log_write>
    }
    else
    {
        bwrite(bp);
    }
    brelse(bp);
    80006f2c:	854a                	mv	a0,s2
    80006f2e:	fffff097          	auipc	ra,0xfffff
    80006f32:	38c080e7          	jalr	908(ra) # 800062ba <brelse>
}
    80006f36:	8526                	mv	a0,s1
    80006f38:	60e6                	ld	ra,88(sp)
    80006f3a:	6446                	ld	s0,80(sp)
    80006f3c:	64a6                	ld	s1,72(sp)
    80006f3e:	6906                	ld	s2,64(sp)
    80006f40:	79e2                	ld	s3,56(sp)
    80006f42:	7a42                	ld	s4,48(sp)
    80006f44:	7aa2                	ld	s5,40(sp)
    80006f46:	7b02                	ld	s6,32(sp)
    80006f48:	6be2                	ld	s7,24(sp)
    80006f4a:	6c42                	ld	s8,16(sp)
    80006f4c:	6ca2                	ld	s9,8(sp)
    80006f4e:	6125                	addi	sp,sp,96
    80006f50:	8082                	ret
                    bwrite(bp);
    80006f52:	854a                	mv	a0,s2
    80006f54:	fffff097          	auipc	ra,0xfffff
    80006f58:	2d0080e7          	jalr	720(ra) # 80006224 <bwrite>
    80006f5c:	b779                	j	80006eea <balloc+0x6c>
        bwrite(bp);
    80006f5e:	854a                	mv	a0,s2
    80006f60:	fffff097          	auipc	ra,0xfffff
    80006f64:	2c4080e7          	jalr	708(ra) # 80006224 <bwrite>
    80006f68:	b7d1                	j	80006f2c <balloc+0xae>
        brelse(bp);
    80006f6a:	854a                	mv	a0,s2
    80006f6c:	fffff097          	auipc	ra,0xfffff
    80006f70:	34e080e7          	jalr	846(ra) # 800062ba <brelse>
    for (b = nmeta; b < sb.size; b += BPB)
    80006f74:	015c87bb          	addw	a5,s9,s5
    80006f78:	00078a9b          	sext.w	s5,a5
    80006f7c:	004b2703          	lw	a4,4(s6)
    80006f80:	06eaf463          	bgeu	s5,a4,80006fe8 <balloc+0x16a>
        bp = bread(dev, BBLOCK(b, sb));
    80006f84:	41fad79b          	sraiw	a5,s5,0x1f
    80006f88:	0117d79b          	srliw	a5,a5,0x11
    80006f8c:	015787bb          	addw	a5,a5,s5
    80006f90:	40f7d79b          	sraiw	a5,a5,0xf
    80006f94:	01cb2583          	lw	a1,28(s6)
    80006f98:	9dbd                	addw	a1,a1,a5
    80006f9a:	855e                	mv	a0,s7
    80006f9c:	fffff097          	auipc	ra,0xfffff
    80006fa0:	14a080e7          	jalr	330(ra) # 800060e6 <bread>
    80006fa4:	892a                	mv	s2,a0
        for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006fa6:	004b2503          	lw	a0,4(s6)
    80006faa:	000a849b          	sext.w	s1,s5
    80006fae:	8662                	mv	a2,s8
    80006fb0:	faa4fde3          	bgeu	s1,a0,80006f6a <balloc+0xec>
            m = 1 << (bi % 8);
    80006fb4:	41f6579b          	sraiw	a5,a2,0x1f
    80006fb8:	01d7d69b          	srliw	a3,a5,0x1d
    80006fbc:	00c6873b          	addw	a4,a3,a2
    80006fc0:	00777793          	andi	a5,a4,7
    80006fc4:	9f95                	subw	a5,a5,a3
    80006fc6:	00f997bb          	sllw	a5,s3,a5
            if ((bp->data[bi / 8] & m) == 0)
    80006fca:	4037571b          	sraiw	a4,a4,0x3
    80006fce:	00e906b3          	add	a3,s2,a4
    80006fd2:	0406c683          	lbu	a3,64(a3)
    80006fd6:	00d7f5b3          	and	a1,a5,a3
    80006fda:	ee058ae3          	beqz	a1,80006ece <balloc+0x50>
        for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006fde:	2605                	addiw	a2,a2,1
    80006fe0:	2485                	addiw	s1,s1,1
    80006fe2:	fd4617e3          	bne	a2,s4,80006fb0 <balloc+0x132>
    80006fe6:	b751                	j	80006f6a <balloc+0xec>
    panic("balloc: out of blocks");
    80006fe8:	00007517          	auipc	a0,0x7
    80006fec:	66850513          	addi	a0,a0,1640 # 8000e650 <digits+0x44a0>
    80006ff0:	ffffc097          	auipc	ra,0xffffc
    80006ff4:	a9c080e7          	jalr	-1380(ra) # 80002a8c <panic>

0000000080006ff8 <bmap>:
{
    80006ff8:	7179                	addi	sp,sp,-48
    80006ffa:	f406                	sd	ra,40(sp)
    80006ffc:	f022                	sd	s0,32(sp)
    80006ffe:	ec26                	sd	s1,24(sp)
    80007000:	e84a                	sd	s2,16(sp)
    80007002:	e44e                	sd	s3,8(sp)
    80007004:	e052                	sd	s4,0(sp)
    80007006:	1800                	addi	s0,sp,48
    80007008:	892a                	mv	s2,a0
    if (bn < 12)
    8000700a:	47ad                	li	a5,11
    8000700c:	04b7fe63          	bgeu	a5,a1,80007068 <bmap+0x70>
    bn -= 12;
    80007010:	ff45849b          	addiw	s1,a1,-12
    80007014:	0004871b          	sext.w	a4,s1
    if (bn < BSIZE / sizeof(uint))
    80007018:	3ff00793          	li	a5,1023
    8000701c:	0ae7e363          	bltu	a5,a4,800070c2 <bmap+0xca>
        if ((addr = ip->indirect) == 0)
    80007020:	09052583          	lw	a1,144(a0)
    80007024:	c5ad                	beqz	a1,8000708e <bmap+0x96>
        bp = bread(ip->dev, addr);
    80007026:	00092503          	lw	a0,0(s2)
    8000702a:	fffff097          	auipc	ra,0xfffff
    8000702e:	0bc080e7          	jalr	188(ra) # 800060e6 <bread>
    80007032:	8a2a                	mv	s4,a0
        a = (uint *)bp->data;
    80007034:	04050793          	addi	a5,a0,64
        if ((addr = a[bn]) == 0)
    80007038:	02049593          	slli	a1,s1,0x20
    8000703c:	9181                	srli	a1,a1,0x20
    8000703e:	058a                	slli	a1,a1,0x2
    80007040:	00b784b3          	add	s1,a5,a1
    80007044:	0004a983          	lw	s3,0(s1)
    80007048:	04098d63          	beqz	s3,800070a2 <bmap+0xaa>
        brelse(bp);
    8000704c:	8552                	mv	a0,s4
    8000704e:	fffff097          	auipc	ra,0xfffff
    80007052:	26c080e7          	jalr	620(ra) # 800062ba <brelse>
}
    80007056:	854e                	mv	a0,s3
    80007058:	70a2                	ld	ra,40(sp)
    8000705a:	7402                	ld	s0,32(sp)
    8000705c:	64e2                	ld	s1,24(sp)
    8000705e:	6942                	ld	s2,16(sp)
    80007060:	69a2                	ld	s3,8(sp)
    80007062:	6a02                	ld	s4,0(sp)
    80007064:	6145                	addi	sp,sp,48
    80007066:	8082                	ret
        if ((addr = ip->direct[bn]) == 0)
    80007068:	02059493          	slli	s1,a1,0x20
    8000706c:	9081                	srli	s1,s1,0x20
    8000706e:	048a                	slli	s1,s1,0x2
    80007070:	94aa                	add	s1,s1,a0
    80007072:	0604a983          	lw	s3,96(s1)
    80007076:	fe0990e3          	bnez	s3,80007056 <bmap+0x5e>
            ip->direct[bn] = addr = balloc(ip->dev);
    8000707a:	4108                	lw	a0,0(a0)
    8000707c:	00000097          	auipc	ra,0x0
    80007080:	e02080e7          	jalr	-510(ra) # 80006e7e <balloc>
    80007084:	0005099b          	sext.w	s3,a0
    80007088:	0734a023          	sw	s3,96(s1)
    8000708c:	b7e9                	j	80007056 <bmap+0x5e>
            ip->indirect = addr = balloc(ip->dev);
    8000708e:	4108                	lw	a0,0(a0)
    80007090:	00000097          	auipc	ra,0x0
    80007094:	dee080e7          	jalr	-530(ra) # 80006e7e <balloc>
    80007098:	0005059b          	sext.w	a1,a0
    8000709c:	08b92823          	sw	a1,144(s2)
    800070a0:	b759                	j	80007026 <bmap+0x2e>
            a[bn] = addr = balloc(ip->dev);
    800070a2:	00092503          	lw	a0,0(s2)
    800070a6:	00000097          	auipc	ra,0x0
    800070aa:	dd8080e7          	jalr	-552(ra) # 80006e7e <balloc>
    800070ae:	0005099b          	sext.w	s3,a0
    800070b2:	0134a023          	sw	s3,0(s1)
            log_write(bp);
    800070b6:	8552                	mv	a0,s4
    800070b8:	fffff097          	auipc	ra,0xfffff
    800070bc:	718080e7          	jalr	1816(ra) # 800067d0 <log_write>
    800070c0:	b771                	j	8000704c <bmap+0x54>
    panic("bmap: out of range");
    800070c2:	00007517          	auipc	a0,0x7
    800070c6:	5a650513          	addi	a0,a0,1446 # 8000e668 <digits+0x44b8>
    800070ca:	ffffc097          	auipc	ra,0xffffc
    800070ce:	9c2080e7          	jalr	-1598(ra) # 80002a8c <panic>

00000000800070d2 <readi>:
    if (off > ip->size || off + n < off)
    800070d2:	457c                	lw	a5,76(a0)
    800070d4:	0cd7ea63          	bltu	a5,a3,800071a8 <readi+0xd6>
{
    800070d8:	711d                	addi	sp,sp,-96
    800070da:	ec86                	sd	ra,88(sp)
    800070dc:	e8a2                	sd	s0,80(sp)
    800070de:	e4a6                	sd	s1,72(sp)
    800070e0:	e0ca                	sd	s2,64(sp)
    800070e2:	fc4e                	sd	s3,56(sp)
    800070e4:	f852                	sd	s4,48(sp)
    800070e6:	f456                	sd	s5,40(sp)
    800070e8:	f05a                	sd	s6,32(sp)
    800070ea:	ec5e                	sd	s7,24(sp)
    800070ec:	e862                	sd	s8,16(sp)
    800070ee:	e466                	sd	s9,8(sp)
    800070f0:	1080                	addi	s0,sp,96
    800070f2:	8baa                	mv	s7,a0
    800070f4:	8ab2                	mv	s5,a2
    800070f6:	89b6                	mv	s3,a3
    800070f8:	8b3a                	mv	s6,a4
    if (off > ip->size || off + n < off)
    800070fa:	9f35                	addw	a4,a4,a3
    800070fc:	0ad76863          	bltu	a4,a3,800071ac <readi+0xda>
    if (off + n > ip->size)
    80007100:	00e7f463          	bgeu	a5,a4,80007108 <readi+0x36>
        n = ip->size - off;
    80007104:	40d78b3b          	subw	s6,a5,a3
    for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80007108:	080b0063          	beqz	s6,80007188 <readi+0xb6>
    8000710c:	4a01                	li	s4,0
        m = min(n - tot, BSIZE - off % BSIZE);
    8000710e:	6c05                	lui	s8,0x1
    80007110:	1c7d                	addi	s8,s8,-1
    80007112:	6c85                	lui	s9,0x1
    80007114:	a81d                	j	8000714a <readi+0x78>
        if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80007116:	04090593          	addi	a1,s2,64
    8000711a:	1782                	slli	a5,a5,0x20
    8000711c:	9381                	srli	a5,a5,0x20
    memmove((void *)dst, src, len);
    8000711e:	0004861b          	sext.w	a2,s1
    80007122:	95be                	add	a1,a1,a5
    80007124:	8556                	mv	a0,s5
    80007126:	00000097          	auipc	ra,0x0
    8000712a:	858080e7          	jalr	-1960(ra) # 8000697e <memmove>
        brelse(bp);
    8000712e:	854a                	mv	a0,s2
    80007130:	fffff097          	auipc	ra,0xfffff
    80007134:	18a080e7          	jalr	394(ra) # 800062ba <brelse>
    for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80007138:	01448a3b          	addw	s4,s1,s4
    8000713c:	013489bb          	addw	s3,s1,s3
        if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80007140:	1482                	slli	s1,s1,0x20
    80007142:	9081                	srli	s1,s1,0x20
    for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80007144:	9aa6                	add	s5,s5,s1
    80007146:	056a7263          	bgeu	s4,s6,8000718a <readi+0xb8>
        bp = bread(ip->dev, bmap(ip, off / BSIZE));
    8000714a:	000ba483          	lw	s1,0(s7)
    8000714e:	00c9d59b          	srliw	a1,s3,0xc
    80007152:	855e                	mv	a0,s7
    80007154:	00000097          	auipc	ra,0x0
    80007158:	ea4080e7          	jalr	-348(ra) # 80006ff8 <bmap>
    8000715c:	0005059b          	sext.w	a1,a0
    80007160:	8526                	mv	a0,s1
    80007162:	fffff097          	auipc	ra,0xfffff
    80007166:	f84080e7          	jalr	-124(ra) # 800060e6 <bread>
    8000716a:	892a                	mv	s2,a0
        m = min(n - tot, BSIZE - off % BSIZE);
    8000716c:	0189f7b3          	and	a5,s3,s8
    80007170:	40fc873b          	subw	a4,s9,a5
    80007174:	414b06bb          	subw	a3,s6,s4
    80007178:	84ba                	mv	s1,a4
    8000717a:	2701                	sext.w	a4,a4
    8000717c:	0006861b          	sext.w	a2,a3
    80007180:	f8e67be3          	bgeu	a2,a4,80007116 <readi+0x44>
    80007184:	84b6                	mv	s1,a3
    80007186:	bf41                	j	80007116 <readi+0x44>
    for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80007188:	8a5a                	mv	s4,s6
    return tot;
    8000718a:	000a051b          	sext.w	a0,s4
}
    8000718e:	60e6                	ld	ra,88(sp)
    80007190:	6446                	ld	s0,80(sp)
    80007192:	64a6                	ld	s1,72(sp)
    80007194:	6906                	ld	s2,64(sp)
    80007196:	79e2                	ld	s3,56(sp)
    80007198:	7a42                	ld	s4,48(sp)
    8000719a:	7aa2                	ld	s5,40(sp)
    8000719c:	7b02                	ld	s6,32(sp)
    8000719e:	6be2                	ld	s7,24(sp)
    800071a0:	6c42                	ld	s8,16(sp)
    800071a2:	6ca2                	ld	s9,8(sp)
    800071a4:	6125                	addi	sp,sp,96
    800071a6:	8082                	ret
        return -1;
    800071a8:	557d                	li	a0,-1
}
    800071aa:	8082                	ret
        return -1;
    800071ac:	557d                	li	a0,-1
    800071ae:	b7c5                	j	8000718e <readi+0xbc>

00000000800071b0 <dirlookup>:
{
    800071b0:	715d                	addi	sp,sp,-80
    800071b2:	e486                	sd	ra,72(sp)
    800071b4:	e0a2                	sd	s0,64(sp)
    800071b6:	fc26                	sd	s1,56(sp)
    800071b8:	f84a                	sd	s2,48(sp)
    800071ba:	f44e                	sd	s3,40(sp)
    800071bc:	f052                	sd	s4,32(sp)
    800071be:	ec56                	sd	s5,24(sp)
    800071c0:	e85a                	sd	s6,16(sp)
    800071c2:	0880                	addi	s0,sp,80
    if (dp->type != T_DIR)
    800071c4:	04451703          	lh	a4,68(a0)
    800071c8:	4785                	li	a5,1
    800071ca:	00f71f63          	bne	a4,a5,800071e8 <dirlookup+0x38>
    800071ce:	89aa                	mv	s3,a0
    800071d0:	8a2e                	mv	s4,a1
    800071d2:	8b32                	mv	s6,a2
    for (off = 0; off < dp->size; off += sizeof(de))
    800071d4:	457c                	lw	a5,76(a0)
    800071d6:	4901                	li	s2,0
    800071d8:	c791                	beqz	a5,800071e4 <dirlookup+0x34>
    800071da:	00e58493          	addi	s1,a1,14
    800071de:	00e58a9b          	addiw	s5,a1,14
    800071e2:	a081                	j	80007222 <dirlookup+0x72>
    return 0;
    800071e4:	4501                	li	a0,0
    800071e6:	a851                	j	8000727a <dirlookup+0xca>
        panic("dirlookup not DIR");
    800071e8:	00007517          	auipc	a0,0x7
    800071ec:	49850513          	addi	a0,a0,1176 # 8000e680 <digits+0x44d0>
    800071f0:	ffffc097          	auipc	ra,0xffffc
    800071f4:	89c080e7          	jalr	-1892(ra) # 80002a8c <panic>
            panic("dirlookup read");
    800071f8:	00007517          	auipc	a0,0x7
    800071fc:	4a050513          	addi	a0,a0,1184 # 8000e698 <digits+0x44e8>
    80007200:	ffffc097          	auipc	ra,0xffffc
    80007204:	88c080e7          	jalr	-1908(ra) # 80002a8c <panic>
    if (n == 0)
    80007208:	051a8d63          	beq	s5,a7,80007262 <dirlookup+0xb2>
        if (namecmp(name, de.name) == 0)
    8000720c:	0007c683          	lbu	a3,0(a5)
    80007210:	00074783          	lbu	a5,0(a4)
    80007214:	04f68763          	beq	a3,a5,80007262 <dirlookup+0xb2>
    for (off = 0; off < dp->size; off += sizeof(de))
    80007218:	2941                	addiw	s2,s2,16
    8000721a:	04c9a783          	lw	a5,76(s3)
    8000721e:	04f97d63          	bgeu	s2,a5,80007278 <dirlookup+0xc8>
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80007222:	4741                	li	a4,16
    80007224:	86ca                	mv	a3,s2
    80007226:	fb040613          	addi	a2,s0,-80
    8000722a:	4581                	li	a1,0
    8000722c:	854e                	mv	a0,s3
    8000722e:	00000097          	auipc	ra,0x0
    80007232:	ea4080e7          	jalr	-348(ra) # 800070d2 <readi>
    80007236:	47c1                	li	a5,16
    80007238:	fcf510e3          	bne	a0,a5,800071f8 <dirlookup+0x48>
        if (de.inum == 0)
    8000723c:	fb045583          	lhu	a1,-80(s0)
    80007240:	dde1                	beqz	a1,80007218 <dirlookup+0x68>
    80007242:	87d2                	mv	a5,s4
    80007244:	fb240713          	addi	a4,s0,-78
    80007248:	0007889b          	sext.w	a7,a5
    while (n > 0 && *p && *p == *q)
    8000724c:	0007c683          	lbu	a3,0(a5)
    80007250:	dec5                	beqz	a3,80007208 <dirlookup+0x58>
    80007252:	00074803          	lbu	a6,0(a4)
    80007256:	fad819e3          	bne	a6,a3,80007208 <dirlookup+0x58>
        n--, p++, q++;
    8000725a:	0785                	addi	a5,a5,1
    8000725c:	0705                	addi	a4,a4,1
    while (n > 0 && *p && *p == *q)
    8000725e:	fe9795e3          	bne	a5,s1,80007248 <dirlookup+0x98>
            if (poff)
    80007262:	000b0463          	beqz	s6,8000726a <dirlookup+0xba>
                *poff = off;
    80007266:	012b2023          	sw	s2,0(s6)
            return iget(dp->dev, inum);
    8000726a:	0009a503          	lw	a0,0(s3)
    8000726e:	00000097          	auipc	ra,0x0
    80007272:	91a080e7          	jalr	-1766(ra) # 80006b88 <iget>
    80007276:	a011                	j	8000727a <dirlookup+0xca>
    return 0;
    80007278:	4501                	li	a0,0
}
    8000727a:	60a6                	ld	ra,72(sp)
    8000727c:	6406                	ld	s0,64(sp)
    8000727e:	74e2                	ld	s1,56(sp)
    80007280:	7942                	ld	s2,48(sp)
    80007282:	79a2                	ld	s3,40(sp)
    80007284:	7a02                	ld	s4,32(sp)
    80007286:	6ae2                	ld	s5,24(sp)
    80007288:	6b42                	ld	s6,16(sp)
    8000728a:	6161                	addi	sp,sp,80
    8000728c:	8082                	ret

000000008000728e <writei>:
    if (off > ip->size || off + n < off)
    8000728e:	457c                	lw	a5,76(a0)
    80007290:	0ed7e763          	bltu	a5,a3,8000737e <writei+0xf0>
{
    80007294:	711d                	addi	sp,sp,-96
    80007296:	ec86                	sd	ra,88(sp)
    80007298:	e8a2                	sd	s0,80(sp)
    8000729a:	e4a6                	sd	s1,72(sp)
    8000729c:	e0ca                	sd	s2,64(sp)
    8000729e:	fc4e                	sd	s3,56(sp)
    800072a0:	f852                	sd	s4,48(sp)
    800072a2:	f456                	sd	s5,40(sp)
    800072a4:	f05a                	sd	s6,32(sp)
    800072a6:	ec5e                	sd	s7,24(sp)
    800072a8:	e862                	sd	s8,16(sp)
    800072aa:	e466                	sd	s9,8(sp)
    800072ac:	1080                	addi	s0,sp,96
    800072ae:	8b2a                	mv	s6,a0
    800072b0:	8ab2                	mv	s5,a2
    800072b2:	89b6                	mv	s3,a3
    800072b4:	8bba                	mv	s7,a4
    if (off > ip->size || off + n < off)
    800072b6:	00e687bb          	addw	a5,a3,a4
    800072ba:	0cd7e463          	bltu	a5,a3,80007382 <writei+0xf4>
    for (tot = 0; tot < n; tot += m, off += m, src += m)
    800072be:	cf55                	beqz	a4,8000737a <writei+0xec>
    800072c0:	4a01                	li	s4,0
        m = min(n - tot, BSIZE - off % BSIZE);
    800072c2:	6c05                	lui	s8,0x1
    800072c4:	1c7d                	addi	s8,s8,-1
    800072c6:	6c85                	lui	s9,0x1
    800072c8:	a081                	j	80007308 <writei+0x7a>
        if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    800072ca:	04090513          	addi	a0,s2,64
    800072ce:	1782                	slli	a5,a5,0x20
    800072d0:	9381                	srli	a5,a5,0x20
    memmove(dst, (void *)src, len);
    800072d2:	0004861b          	sext.w	a2,s1
    800072d6:	85d6                	mv	a1,s5
    800072d8:	953e                	add	a0,a0,a5
    800072da:	fffff097          	auipc	ra,0xfffff
    800072de:	6a4080e7          	jalr	1700(ra) # 8000697e <memmove>
        log_write(bp);
    800072e2:	854a                	mv	a0,s2
    800072e4:	fffff097          	auipc	ra,0xfffff
    800072e8:	4ec080e7          	jalr	1260(ra) # 800067d0 <log_write>
        brelse(bp);
    800072ec:	854a                	mv	a0,s2
    800072ee:	fffff097          	auipc	ra,0xfffff
    800072f2:	fcc080e7          	jalr	-52(ra) # 800062ba <brelse>
    for (tot = 0; tot < n; tot += m, off += m, src += m)
    800072f6:	01448a3b          	addw	s4,s1,s4
    800072fa:	013489bb          	addw	s3,s1,s3
        if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    800072fe:	1482                	slli	s1,s1,0x20
    80007300:	9081                	srli	s1,s1,0x20
    for (tot = 0; tot < n; tot += m, off += m, src += m)
    80007302:	9aa6                	add	s5,s5,s1
    80007304:	057a7163          	bgeu	s4,s7,80007346 <writei+0xb8>
        bp = bread(ip->dev, bmap(ip, off / BSIZE));
    80007308:	000b2483          	lw	s1,0(s6)
    8000730c:	00c9d59b          	srliw	a1,s3,0xc
    80007310:	855a                	mv	a0,s6
    80007312:	00000097          	auipc	ra,0x0
    80007316:	ce6080e7          	jalr	-794(ra) # 80006ff8 <bmap>
    8000731a:	0005059b          	sext.w	a1,a0
    8000731e:	8526                	mv	a0,s1
    80007320:	fffff097          	auipc	ra,0xfffff
    80007324:	dc6080e7          	jalr	-570(ra) # 800060e6 <bread>
    80007328:	892a                	mv	s2,a0
        m = min(n - tot, BSIZE - off % BSIZE);
    8000732a:	0189f7b3          	and	a5,s3,s8
    8000732e:	40fc873b          	subw	a4,s9,a5
    80007332:	414b86bb          	subw	a3,s7,s4
    80007336:	84ba                	mv	s1,a4
    80007338:	2701                	sext.w	a4,a4
    8000733a:	0006861b          	sext.w	a2,a3
    8000733e:	f8e676e3          	bgeu	a2,a4,800072ca <writei+0x3c>
    80007342:	84b6                	mv	s1,a3
    80007344:	b759                	j	800072ca <writei+0x3c>
    if (off > ip->size)
    80007346:	04cb2783          	lw	a5,76(s6)
    8000734a:	0137f463          	bgeu	a5,s3,80007352 <writei+0xc4>
        ip->size = off;
    8000734e:	053b2623          	sw	s3,76(s6)
    iupdate(ip);
    80007352:	855a                	mv	a0,s6
    80007354:	00000097          	auipc	ra,0x0
    80007358:	a44080e7          	jalr	-1468(ra) # 80006d98 <iupdate>
    return tot;
    8000735c:	000a051b          	sext.w	a0,s4
}
    80007360:	60e6                	ld	ra,88(sp)
    80007362:	6446                	ld	s0,80(sp)
    80007364:	64a6                	ld	s1,72(sp)
    80007366:	6906                	ld	s2,64(sp)
    80007368:	79e2                	ld	s3,56(sp)
    8000736a:	7a42                	ld	s4,48(sp)
    8000736c:	7aa2                	ld	s5,40(sp)
    8000736e:	7b02                	ld	s6,32(sp)
    80007370:	6be2                	ld	s7,24(sp)
    80007372:	6c42                	ld	s8,16(sp)
    80007374:	6ca2                	ld	s9,8(sp)
    80007376:	6125                	addi	sp,sp,96
    80007378:	8082                	ret
    for (tot = 0; tot < n; tot += m, off += m, src += m)
    8000737a:	8a3a                	mv	s4,a4
    8000737c:	bfd9                	j	80007352 <writei+0xc4>
        return -1;
    8000737e:	557d                	li	a0,-1
}
    80007380:	8082                	ret
        return -1;
    80007382:	557d                	li	a0,-1
    80007384:	bff1                	j	80007360 <writei+0xd2>

0000000080007386 <bfree>:
{
    80007386:	1101                	addi	sp,sp,-32
    80007388:	ec06                	sd	ra,24(sp)
    8000738a:	e822                	sd	s0,16(sp)
    8000738c:	e426                	sd	s1,8(sp)
    8000738e:	e04a                	sd	s2,0(sp)
    80007390:	1000                	addi	s0,sp,32
    80007392:	84ae                	mv	s1,a1
    bp = bread(dev, BBLOCK(b, sb));
    80007394:	00f5d59b          	srliw	a1,a1,0xf
    80007398:	0045b797          	auipc	a5,0x45b
    8000739c:	da47a783          	lw	a5,-604(a5) # 8046213c <sb+0x1c>
    800073a0:	9dbd                	addw	a1,a1,a5
    800073a2:	fffff097          	auipc	ra,0xfffff
    800073a6:	d44080e7          	jalr	-700(ra) # 800060e6 <bread>
    800073aa:	892a                	mv	s2,a0
    m = 1 << (bi % 8);
    800073ac:	0074f713          	andi	a4,s1,7
    800073b0:	4785                	li	a5,1
    800073b2:	00e797bb          	sllw	a5,a5,a4
    if ((bp->data[bi / 8] & m) == 0)
    800073b6:	14c6                	slli	s1,s1,0x31
    800073b8:	90d1                	srli	s1,s1,0x34
    800073ba:	00950733          	add	a4,a0,s1
    800073be:	04074703          	lbu	a4,64(a4)
    800073c2:	00e7f6b3          	and	a3,a5,a4
    800073c6:	c695                	beqz	a3,800073f2 <bfree+0x6c>
    bp->data[bi / 8] &= ~m;
    800073c8:	94aa                	add	s1,s1,a0
    800073ca:	fff7c793          	not	a5,a5
    800073ce:	8ff9                	and	a5,a5,a4
    800073d0:	04f48023          	sb	a5,64(s1)
    log_write(bp);
    800073d4:	fffff097          	auipc	ra,0xfffff
    800073d8:	3fc080e7          	jalr	1020(ra) # 800067d0 <log_write>
    brelse(bp);
    800073dc:	854a                	mv	a0,s2
    800073de:	fffff097          	auipc	ra,0xfffff
    800073e2:	edc080e7          	jalr	-292(ra) # 800062ba <brelse>
}
    800073e6:	60e2                	ld	ra,24(sp)
    800073e8:	6442                	ld	s0,16(sp)
    800073ea:	64a2                	ld	s1,8(sp)
    800073ec:	6902                	ld	s2,0(sp)
    800073ee:	6105                	addi	sp,sp,32
    800073f0:	8082                	ret
        brelse(bp);
    800073f2:	fffff097          	auipc	ra,0xfffff
    800073f6:	ec8080e7          	jalr	-312(ra) # 800062ba <brelse>
        return;
    800073fa:	b7f5                	j	800073e6 <bfree+0x60>

00000000800073fc <itrunc>:
{
    800073fc:	7139                	addi	sp,sp,-64
    800073fe:	fc06                	sd	ra,56(sp)
    80007400:	f822                	sd	s0,48(sp)
    80007402:	f426                	sd	s1,40(sp)
    80007404:	f04a                	sd	s2,32(sp)
    80007406:	ec4e                	sd	s3,24(sp)
    80007408:	e852                	sd	s4,16(sp)
    8000740a:	e456                	sd	s5,8(sp)
    8000740c:	0080                	addi	s0,sp,64
    8000740e:	89aa                	mv	s3,a0
    for (i = 0; i < 12; i++)
    80007410:	06050493          	addi	s1,a0,96
    80007414:	09050913          	addi	s2,a0,144
    80007418:	a021                	j	80007420 <itrunc+0x24>
    8000741a:	0491                	addi	s1,s1,4
    8000741c:	01248d63          	beq	s1,s2,80007436 <itrunc+0x3a>
        if (ip->direct[i])
    80007420:	408c                	lw	a1,0(s1)
    80007422:	dde5                	beqz	a1,8000741a <itrunc+0x1e>
            bfree(ip->dev, ip->direct[i]);
    80007424:	0009a503          	lw	a0,0(s3)
    80007428:	00000097          	auipc	ra,0x0
    8000742c:	f5e080e7          	jalr	-162(ra) # 80007386 <bfree>
            ip->direct[i] = 0;
    80007430:	0004a023          	sw	zero,0(s1)
    80007434:	b7dd                	j	8000741a <itrunc+0x1e>
    indirect = ip->indirect;
    80007436:	0909aa03          	lw	s4,144(s3)
    ip->indirect = 0;
    8000743a:	0809a823          	sw	zero,144(s3)
    if (indirect)
    8000743e:	020a1263          	bnez	s4,80007462 <itrunc+0x66>
    ip->size = 0;
    80007442:	0409a623          	sw	zero,76(s3)
    iupdate(ip);
    80007446:	854e                	mv	a0,s3
    80007448:	00000097          	auipc	ra,0x0
    8000744c:	950080e7          	jalr	-1712(ra) # 80006d98 <iupdate>
}
    80007450:	70e2                	ld	ra,56(sp)
    80007452:	7442                	ld	s0,48(sp)
    80007454:	74a2                	ld	s1,40(sp)
    80007456:	7902                	ld	s2,32(sp)
    80007458:	69e2                	ld	s3,24(sp)
    8000745a:	6a42                	ld	s4,16(sp)
    8000745c:	6aa2                	ld	s5,8(sp)
    8000745e:	6121                	addi	sp,sp,64
    80007460:	8082                	ret
        bp = bread(ip->dev, indirect);
    80007462:	85d2                	mv	a1,s4
    80007464:	0009a503          	lw	a0,0(s3)
    80007468:	fffff097          	auipc	ra,0xfffff
    8000746c:	c7e080e7          	jalr	-898(ra) # 800060e6 <bread>
    80007470:	8aaa                	mv	s5,a0
        for (j = 0; j < BSIZE / sizeof(uint); j++)
    80007472:	04050493          	addi	s1,a0,64
    80007476:	6905                	lui	s2,0x1
    80007478:	04090913          	addi	s2,s2,64 # 1040 <_entry-0x7fffefc0>
    8000747c:	992a                	add	s2,s2,a0
    8000747e:	a021                	j	80007486 <itrunc+0x8a>
    80007480:	0491                	addi	s1,s1,4
    80007482:	01248b63          	beq	s1,s2,80007498 <itrunc+0x9c>
            if (a[j])
    80007486:	408c                	lw	a1,0(s1)
    80007488:	dde5                	beqz	a1,80007480 <itrunc+0x84>
                bfree(ip->dev, a[j]);
    8000748a:	0009a503          	lw	a0,0(s3)
    8000748e:	00000097          	auipc	ra,0x0
    80007492:	ef8080e7          	jalr	-264(ra) # 80007386 <bfree>
    80007496:	b7ed                	j	80007480 <itrunc+0x84>
        brelse(bp);
    80007498:	8556                	mv	a0,s5
    8000749a:	fffff097          	auipc	ra,0xfffff
    8000749e:	e20080e7          	jalr	-480(ra) # 800062ba <brelse>
        bfree(ip->dev, indirect);
    800074a2:	85d2                	mv	a1,s4
    800074a4:	0009a503          	lw	a0,0(s3)
    800074a8:	00000097          	auipc	ra,0x0
    800074ac:	ede080e7          	jalr	-290(ra) # 80007386 <bfree>
    800074b0:	bf49                	j	80007442 <itrunc+0x46>

00000000800074b2 <iput>:
{
    800074b2:	1101                	addi	sp,sp,-32
    800074b4:	ec06                	sd	ra,24(sp)
    800074b6:	e822                	sd	s0,16(sp)
    800074b8:	e426                	sd	s1,8(sp)
    800074ba:	1000                	addi	s0,sp,32
    800074bc:	84aa                	mv	s1,a0
    acquire(&icache.lock);
    800074be:	0045b517          	auipc	a0,0x45b
    800074c2:	c8250513          	addi	a0,a0,-894 # 80462140 <icache>
    800074c6:	ffffc097          	auipc	ra,0xffffc
    800074ca:	290080e7          	jalr	656(ra) # 80003756 <acquire>
    if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    800074ce:	4498                	lw	a4,8(s1)
    800074d0:	4785                	li	a5,1
    800074d2:	02f70263          	beq	a4,a5,800074f6 <iput+0x44>
    ip->ref--;
    800074d6:	449c                	lw	a5,8(s1)
    800074d8:	37fd                	addiw	a5,a5,-1
    800074da:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    800074dc:	0045b517          	auipc	a0,0x45b
    800074e0:	c6450513          	addi	a0,a0,-924 # 80462140 <icache>
    800074e4:	ffffc097          	auipc	ra,0xffffc
    800074e8:	2e2080e7          	jalr	738(ra) # 800037c6 <release>
}
    800074ec:	60e2                	ld	ra,24(sp)
    800074ee:	6442                	ld	s0,16(sp)
    800074f0:	64a2                	ld	s1,8(sp)
    800074f2:	6105                	addi	sp,sp,32
    800074f4:	8082                	ret
    if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    800074f6:	40bc                	lw	a5,64(s1)
    800074f8:	dff9                	beqz	a5,800074d6 <iput+0x24>
    800074fa:	04649783          	lh	a5,70(s1)
    800074fe:	ffe1                	bnez	a5,800074d6 <iput+0x24>
        release(&icache.lock);
    80007500:	0045b517          	auipc	a0,0x45b
    80007504:	c4050513          	addi	a0,a0,-960 # 80462140 <icache>
    80007508:	ffffc097          	auipc	ra,0xffffc
    8000750c:	2be080e7          	jalr	702(ra) # 800037c6 <release>
        ilock(ip);
    80007510:	8526                	mv	a0,s1
    80007512:	fffff097          	auipc	ra,0xfffff
    80007516:	530080e7          	jalr	1328(ra) # 80006a42 <ilock>
        itrunc(ip);
    8000751a:	8526                	mv	a0,s1
    8000751c:	00000097          	auipc	ra,0x0
    80007520:	ee0080e7          	jalr	-288(ra) # 800073fc <itrunc>
        ip->type = 0;
    80007524:	04049223          	sh	zero,68(s1)
        iupdate(ip);
    80007528:	8526                	mv	a0,s1
    8000752a:	00000097          	auipc	ra,0x0
    8000752e:	86e080e7          	jalr	-1938(ra) # 80006d98 <iupdate>
        iunlock(ip);
    80007532:	8526                	mv	a0,s1
    80007534:	fffff097          	auipc	ra,0xfffff
    80007538:	608080e7          	jalr	1544(ra) # 80006b3c <iunlock>
        acquire(&icache.lock);
    8000753c:	0045b517          	auipc	a0,0x45b
    80007540:	c0450513          	addi	a0,a0,-1020 # 80462140 <icache>
    80007544:	ffffc097          	auipc	ra,0xffffc
    80007548:	212080e7          	jalr	530(ra) # 80003756 <acquire>
        ip->valid = 0;
    8000754c:	0404a023          	sw	zero,64(s1)
    80007550:	b759                	j	800074d6 <iput+0x24>

0000000080007552 <dirlink>:
{
    80007552:	7139                	addi	sp,sp,-64
    80007554:	fc06                	sd	ra,56(sp)
    80007556:	f822                	sd	s0,48(sp)
    80007558:	f426                	sd	s1,40(sp)
    8000755a:	f04a                	sd	s2,32(sp)
    8000755c:	ec4e                	sd	s3,24(sp)
    8000755e:	e852                	sd	s4,16(sp)
    80007560:	0080                	addi	s0,sp,64
    80007562:	892a                	mv	s2,a0
    80007564:	89ae                	mv	s3,a1
    80007566:	8a32                	mv	s4,a2
    if ((ip = dirlookup(dp, name, 0)) != 0)
    80007568:	4601                	li	a2,0
    8000756a:	00000097          	auipc	ra,0x0
    8000756e:	c46080e7          	jalr	-954(ra) # 800071b0 <dirlookup>
    80007572:	e931                	bnez	a0,800075c6 <dirlink+0x74>
    for (off = 0; off < dp->size; off += sizeof(de))
    80007574:	04c92483          	lw	s1,76(s2)
    80007578:	c49d                	beqz	s1,800075a6 <dirlink+0x54>
    8000757a:	4481                	li	s1,0
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000757c:	4741                	li	a4,16
    8000757e:	86a6                	mv	a3,s1
    80007580:	fc040613          	addi	a2,s0,-64
    80007584:	4581                	li	a1,0
    80007586:	854a                	mv	a0,s2
    80007588:	00000097          	auipc	ra,0x0
    8000758c:	b4a080e7          	jalr	-1206(ra) # 800070d2 <readi>
    80007590:	47c1                	li	a5,16
    80007592:	04f51063          	bne	a0,a5,800075d2 <dirlink+0x80>
        if (de.inum == 0)
    80007596:	fc045783          	lhu	a5,-64(s0)
    8000759a:	c791                	beqz	a5,800075a6 <dirlink+0x54>
    for (off = 0; off < dp->size; off += sizeof(de))
    8000759c:	24c1                	addiw	s1,s1,16
    8000759e:	04c92783          	lw	a5,76(s2)
    800075a2:	fcf4ede3          	bltu	s1,a5,8000757c <dirlink+0x2a>
    while (n-- > 0 && (*s++ = *t++) != 0)
    800075a6:	85ce                	mv	a1,s3
    for (off = 0; off < dp->size; off += sizeof(de))
    800075a8:	fc240793          	addi	a5,s0,-62
    while (n-- > 0 && (*s++ = *t++) != 0)
    800075ac:	4735                	li	a4,13
    800075ae:	567d                	li	a2,-1
    800075b0:	0785                	addi	a5,a5,1
    800075b2:	0005c683          	lbu	a3,0(a1)
    800075b6:	fed78fa3          	sb	a3,-1(a5)
    800075ba:	c685                	beqz	a3,800075e2 <dirlink+0x90>
    800075bc:	377d                	addiw	a4,a4,-1
    800075be:	0585                	addi	a1,a1,1
    800075c0:	fec718e3          	bne	a4,a2,800075b0 <dirlink+0x5e>
    800075c4:	a80d                	j	800075f6 <dirlink+0xa4>
        iput(ip);
    800075c6:	00000097          	auipc	ra,0x0
    800075ca:	eec080e7          	jalr	-276(ra) # 800074b2 <iput>
        return -1;
    800075ce:	557d                	li	a0,-1
    800075d0:	a0a1                	j	80007618 <dirlink+0xc6>
            panic("dirlink read");
    800075d2:	00007517          	auipc	a0,0x7
    800075d6:	0d650513          	addi	a0,a0,214 # 8000e6a8 <digits+0x44f8>
    800075da:	ffffb097          	auipc	ra,0xffffb
    800075de:	4b2080e7          	jalr	1202(ra) # 80002a8c <panic>
    while (n-- > 0)
    800075e2:	00e05a63          	blez	a4,800075f6 <dirlink+0xa4>
    800075e6:	1702                	slli	a4,a4,0x20
    800075e8:	9301                	srli	a4,a4,0x20
    800075ea:	973e                	add	a4,a4,a5
        *s++ = 0;
    800075ec:	0785                	addi	a5,a5,1
    800075ee:	fe078fa3          	sb	zero,-1(a5)
    while (n-- > 0)
    800075f2:	fee79de3          	bne	a5,a4,800075ec <dirlink+0x9a>
    de.inum = inum;
    800075f6:	fd441023          	sh	s4,-64(s0)
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800075fa:	4741                	li	a4,16
    800075fc:	86a6                	mv	a3,s1
    800075fe:	fc040613          	addi	a2,s0,-64
    80007602:	4581                	li	a1,0
    80007604:	854a                	mv	a0,s2
    80007606:	00000097          	auipc	ra,0x0
    8000760a:	c88080e7          	jalr	-888(ra) # 8000728e <writei>
    8000760e:	872a                	mv	a4,a0
    80007610:	47c1                	li	a5,16
    return 0;
    80007612:	4501                	li	a0,0
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80007614:	00f71a63          	bne	a4,a5,80007628 <dirlink+0xd6>
}
    80007618:	70e2                	ld	ra,56(sp)
    8000761a:	7442                	ld	s0,48(sp)
    8000761c:	74a2                	ld	s1,40(sp)
    8000761e:	7902                	ld	s2,32(sp)
    80007620:	69e2                	ld	s3,24(sp)
    80007622:	6a42                	ld	s4,16(sp)
    80007624:	6121                	addi	sp,sp,64
    80007626:	8082                	ret
        panic("dirlink");
    80007628:	00007517          	auipc	a0,0x7
    8000762c:	25050513          	addi	a0,a0,592 # 8000e878 <digits+0x46c8>
    80007630:	ffffb097          	auipc	ra,0xffffb
    80007634:	45c080e7          	jalr	1116(ra) # 80002a8c <panic>

0000000080007638 <dirunlink>:
{
    80007638:	7139                	addi	sp,sp,-64
    8000763a:	fc06                	sd	ra,56(sp)
    8000763c:	f822                	sd	s0,48(sp)
    8000763e:	f426                	sd	s1,40(sp)
    80007640:	f04a                	sd	s2,32(sp)
    80007642:	0080                	addi	s0,sp,64
    80007644:	84aa                	mv	s1,a0
    if ((ip = dirlookup(dp, name, &off)) == 0)
    80007646:	fcc40613          	addi	a2,s0,-52
    8000764a:	00000097          	auipc	ra,0x0
    8000764e:	b66080e7          	jalr	-1178(ra) # 800071b0 <dirlookup>
    80007652:	c949                	beqz	a0,800076e4 <dirunlink+0xac>
    inum = ip->inum;
    80007654:	00452903          	lw	s2,4(a0)
    iput(ip);
    80007658:	00000097          	auipc	ra,0x0
    8000765c:	e5a080e7          	jalr	-422(ra) # 800074b2 <iput>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80007660:	4741                	li	a4,16
    80007662:	fcc42683          	lw	a3,-52(s0)
    80007666:	fd040613          	addi	a2,s0,-48
    8000766a:	4581                	li	a1,0
    8000766c:	8526                	mv	a0,s1
    8000766e:	00000097          	auipc	ra,0x0
    80007672:	a64080e7          	jalr	-1436(ra) # 800070d2 <readi>
    80007676:	47c1                	li	a5,16
    80007678:	02f51e63          	bne	a0,a5,800076b4 <dirunlink+0x7c>
    if (de.inum != inum)
    8000767c:	fd045783          	lhu	a5,-48(s0)
    80007680:	05279263          	bne	a5,s2,800076c4 <dirunlink+0x8c>
    de.inum = 0; // 标记为空闲
    80007684:	fc041823          	sh	zero,-48(s0)
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80007688:	4741                	li	a4,16
    8000768a:	fcc42683          	lw	a3,-52(s0)
    8000768e:	fd040613          	addi	a2,s0,-48
    80007692:	4581                	li	a1,0
    80007694:	8526                	mv	a0,s1
    80007696:	00000097          	auipc	ra,0x0
    8000769a:	bf8080e7          	jalr	-1032(ra) # 8000728e <writei>
    8000769e:	872a                	mv	a4,a0
    800076a0:	47c1                	li	a5,16
    return 0;
    800076a2:	4501                	li	a0,0
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800076a4:	02f71863          	bne	a4,a5,800076d4 <dirunlink+0x9c>
}
    800076a8:	70e2                	ld	ra,56(sp)
    800076aa:	7442                	ld	s0,48(sp)
    800076ac:	74a2                	ld	s1,40(sp)
    800076ae:	7902                	ld	s2,32(sp)
    800076b0:	6121                	addi	sp,sp,64
    800076b2:	8082                	ret
        panic("dirunlink read");
    800076b4:	00007517          	auipc	a0,0x7
    800076b8:	00450513          	addi	a0,a0,4 # 8000e6b8 <digits+0x4508>
    800076bc:	ffffb097          	auipc	ra,0xffffb
    800076c0:	3d0080e7          	jalr	976(ra) # 80002a8c <panic>
        panic("dirunlink: name mismatch");
    800076c4:	00007517          	auipc	a0,0x7
    800076c8:	00450513          	addi	a0,a0,4 # 8000e6c8 <digits+0x4518>
    800076cc:	ffffb097          	auipc	ra,0xffffb
    800076d0:	3c0080e7          	jalr	960(ra) # 80002a8c <panic>
        panic("dirunlink write");
    800076d4:	00007517          	auipc	a0,0x7
    800076d8:	01450513          	addi	a0,a0,20 # 8000e6e8 <digits+0x4538>
    800076dc:	ffffb097          	auipc	ra,0xffffb
    800076e0:	3b0080e7          	jalr	944(ra) # 80002a8c <panic>
        return -1;
    800076e4:	557d                	li	a0,-1
    800076e6:	b7c9                	j	800076a8 <dirunlink+0x70>

00000000800076e8 <iunlockput>:
// 全局超级块
struct superblock sb;

// 需要添加iunlockput（已在fs.h中声明）
void iunlockput(struct inode *ip)
{
    800076e8:	1101                	addi	sp,sp,-32
    800076ea:	ec06                	sd	ra,24(sp)
    800076ec:	e822                	sd	s0,16(sp)
    800076ee:	e426                	sd	s1,8(sp)
    800076f0:	1000                	addi	s0,sp,32
    800076f2:	84aa                	mv	s1,a0
    iunlock(ip);
    800076f4:	fffff097          	auipc	ra,0xfffff
    800076f8:	448080e7          	jalr	1096(ra) # 80006b3c <iunlock>
    iput(ip);
    800076fc:	8526                	mv	a0,s1
    800076fe:	00000097          	auipc	ra,0x0
    80007702:	db4080e7          	jalr	-588(ra) # 800074b2 <iput>
}
    80007706:	60e2                	ld	ra,24(sp)
    80007708:	6442                	ld	s0,16(sp)
    8000770a:	64a2                	ld	s1,8(sp)
    8000770c:	6105                	addi	sp,sp,32
    8000770e:	8082                	ret

0000000080007710 <namex>:
{
    80007710:	711d                	addi	sp,sp,-96
    80007712:	ec86                	sd	ra,88(sp)
    80007714:	e8a2                	sd	s0,80(sp)
    80007716:	e4a6                	sd	s1,72(sp)
    80007718:	e0ca                	sd	s2,64(sp)
    8000771a:	fc4e                	sd	s3,56(sp)
    8000771c:	f852                	sd	s4,48(sp)
    8000771e:	f456                	sd	s5,40(sp)
    80007720:	f05a                	sd	s6,32(sp)
    80007722:	ec5e                	sd	s7,24(sp)
    80007724:	e862                	sd	s8,16(sp)
    80007726:	e466                	sd	s9,8(sp)
    80007728:	1080                	addi	s0,sp,96
    8000772a:	84aa                	mv	s1,a0
    8000772c:	8aae                	mv	s5,a1
    8000772e:	8a32                	mv	s4,a2
    if (*path == '/')
    80007730:	00054703          	lbu	a4,0(a0)
    80007734:	02f00793          	li	a5,47
    80007738:	00f70f63          	beq	a4,a5,80007756 <namex+0x46>
        ip = iget(ROOTDEV, ROOTINO);
    8000773c:	4585                	li	a1,1
    8000773e:	4505                	li	a0,1
    80007740:	fffff097          	auipc	ra,0xfffff
    80007744:	448080e7          	jalr	1096(ra) # 80006b88 <iget>
    80007748:	89aa                	mv	s3,a0
    while (*path == '/')
    8000774a:	02f00913          	li	s2,47
    len = path - s;
    8000774e:	4b01                	li	s6,0
    if (len >= DIRSIZ)
    80007750:	4c35                	li	s8,13
        if (ip->type != T_DIR)
    80007752:	4b85                	li	s7,1
    80007754:	a0e1                	j	8000781c <namex+0x10c>
        ip = iget(ROOTDEV, ROOTINO);
    80007756:	4585                	li	a1,1
    80007758:	4505                	li	a0,1
    8000775a:	fffff097          	auipc	ra,0xfffff
    8000775e:	42e080e7          	jalr	1070(ra) # 80006b88 <iget>
    80007762:	89aa                	mv	s3,a0
    80007764:	b7dd                	j	8000774a <namex+0x3a>
            iunlockput(ip);
    80007766:	854e                	mv	a0,s3
    80007768:	00000097          	auipc	ra,0x0
    8000776c:	f80080e7          	jalr	-128(ra) # 800076e8 <iunlockput>
            return 0;
    80007770:	4981                	li	s3,0
}
    80007772:	854e                	mv	a0,s3
    80007774:	60e6                	ld	ra,88(sp)
    80007776:	6446                	ld	s0,80(sp)
    80007778:	64a6                	ld	s1,72(sp)
    8000777a:	6906                	ld	s2,64(sp)
    8000777c:	79e2                	ld	s3,56(sp)
    8000777e:	7a42                	ld	s4,48(sp)
    80007780:	7aa2                	ld	s5,40(sp)
    80007782:	7b02                	ld	s6,32(sp)
    80007784:	6be2                	ld	s7,24(sp)
    80007786:	6c42                	ld	s8,16(sp)
    80007788:	6ca2                	ld	s9,8(sp)
    8000778a:	6125                	addi	sp,sp,96
    8000778c:	8082                	ret
            iunlock(ip);
    8000778e:	854e                	mv	a0,s3
    80007790:	fffff097          	auipc	ra,0xfffff
    80007794:	3ac080e7          	jalr	940(ra) # 80006b3c <iunlock>
            return ip;
    80007798:	bfe9                	j	80007772 <namex+0x62>
            if (nameiparent)
    8000779a:	000a8863          	beqz	s5,800077aa <namex+0x9a>
                iunlock(ip);
    8000779e:	854e                	mv	a0,s3
    800077a0:	fffff097          	auipc	ra,0xfffff
    800077a4:	39c080e7          	jalr	924(ra) # 80006b3c <iunlock>
                return ip;
    800077a8:	b7e9                	j	80007772 <namex+0x62>
            iunlockput(ip);
    800077aa:	854e                	mv	a0,s3
    800077ac:	00000097          	auipc	ra,0x0
    800077b0:	f3c080e7          	jalr	-196(ra) # 800076e8 <iunlockput>
            return 0;
    800077b4:	89e6                	mv	s3,s9
    800077b6:	bf75                	j	80007772 <namex+0x62>
    len = path - s;
    800077b8:	40b48633          	sub	a2,s1,a1
    800077bc:	00060c9b          	sext.w	s9,a2
    if (len >= DIRSIZ)
    800077c0:	099c5463          	bge	s8,s9,80007848 <namex+0x138>
        memmove(name, s, DIRSIZ);
    800077c4:	4639                	li	a2,14
    800077c6:	8552                	mv	a0,s4
    800077c8:	fffff097          	auipc	ra,0xfffff
    800077cc:	1b6080e7          	jalr	438(ra) # 8000697e <memmove>
    while (*path == '/')
    800077d0:	0004c783          	lbu	a5,0(s1)
    800077d4:	01279763          	bne	a5,s2,800077e2 <namex+0xd2>
        path++;
    800077d8:	0485                	addi	s1,s1,1
    while (*path == '/')
    800077da:	0004c783          	lbu	a5,0(s1)
    800077de:	ff278de3          	beq	a5,s2,800077d8 <namex+0xc8>
        ilock(ip);
    800077e2:	854e                	mv	a0,s3
    800077e4:	fffff097          	auipc	ra,0xfffff
    800077e8:	25e080e7          	jalr	606(ra) # 80006a42 <ilock>
        if (ip->type != T_DIR)
    800077ec:	04499783          	lh	a5,68(s3)
    800077f0:	f7779be3          	bne	a5,s7,80007766 <namex+0x56>
        if (nameiparent && *path == '\0')
    800077f4:	000a8563          	beqz	s5,800077fe <namex+0xee>
    800077f8:	0004c783          	lbu	a5,0(s1)
    800077fc:	dbc9                	beqz	a5,8000778e <namex+0x7e>
        if ((next = dirlookup(ip, name, 0)) == 0)
    800077fe:	865a                	mv	a2,s6
    80007800:	85d2                	mv	a1,s4
    80007802:	854e                	mv	a0,s3
    80007804:	00000097          	auipc	ra,0x0
    80007808:	9ac080e7          	jalr	-1620(ra) # 800071b0 <dirlookup>
    8000780c:	8caa                	mv	s9,a0
    8000780e:	d551                	beqz	a0,8000779a <namex+0x8a>
        iunlockput(ip);
    80007810:	854e                	mv	a0,s3
    80007812:	00000097          	auipc	ra,0x0
    80007816:	ed6080e7          	jalr	-298(ra) # 800076e8 <iunlockput>
        ip = next;
    8000781a:	89e6                	mv	s3,s9
    while (*path == '/')
    8000781c:	0004c783          	lbu	a5,0(s1)
    80007820:	05279763          	bne	a5,s2,8000786e <namex+0x15e>
        path++;
    80007824:	0485                	addi	s1,s1,1
    while (*path == '/')
    80007826:	0004c783          	lbu	a5,0(s1)
    8000782a:	ff278de3          	beq	a5,s2,80007824 <namex+0x114>
    if (*path == 0)
    8000782e:	c79d                	beqz	a5,8000785c <namex+0x14c>
        path++;
    80007830:	85a6                	mv	a1,s1
    len = path - s;
    80007832:	8cda                	mv	s9,s6
    80007834:	865a                	mv	a2,s6
    while (*path != '/' && *path != 0)
    80007836:	01278963          	beq	a5,s2,80007848 <namex+0x138>
    8000783a:	dfbd                	beqz	a5,800077b8 <namex+0xa8>
        path++;
    8000783c:	0485                	addi	s1,s1,1
    while (*path != '/' && *path != 0)
    8000783e:	0004c783          	lbu	a5,0(s1)
    80007842:	ff279ce3          	bne	a5,s2,8000783a <namex+0x12a>
    80007846:	bf8d                	j	800077b8 <namex+0xa8>
        memmove(name, s, len);
    80007848:	2601                	sext.w	a2,a2
    8000784a:	8552                	mv	a0,s4
    8000784c:	fffff097          	auipc	ra,0xfffff
    80007850:	132080e7          	jalr	306(ra) # 8000697e <memmove>
        name[len] = 0;
    80007854:	9cd2                	add	s9,s9,s4
    80007856:	000c8023          	sb	zero,0(s9) # 1000 <_entry-0x7ffff000>
    8000785a:	bf9d                	j	800077d0 <namex+0xc0>
    if (nameiparent)
    8000785c:	f00a8be3          	beqz	s5,80007772 <namex+0x62>
        iput(ip);
    80007860:	854e                	mv	a0,s3
    80007862:	00000097          	auipc	ra,0x0
    80007866:	c50080e7          	jalr	-944(ra) # 800074b2 <iput>
        return 0;
    8000786a:	4981                	li	s3,0
    8000786c:	b719                	j	80007772 <namex+0x62>
    if (*path == 0)
    8000786e:	d7fd                	beqz	a5,8000785c <namex+0x14c>
    while (*path != '/' && *path != 0)
    80007870:	0004c783          	lbu	a5,0(s1)
    80007874:	85a6                	mv	a1,s1
    80007876:	b7d1                	j	8000783a <namex+0x12a>

0000000080007878 <namei>:
{
    80007878:	1101                	addi	sp,sp,-32
    8000787a:	ec06                	sd	ra,24(sp)
    8000787c:	e822                	sd	s0,16(sp)
    8000787e:	1000                	addi	s0,sp,32
    return namex(path, 0, name);
    80007880:	fe040613          	addi	a2,s0,-32
    80007884:	4581                	li	a1,0
    80007886:	00000097          	auipc	ra,0x0
    8000788a:	e8a080e7          	jalr	-374(ra) # 80007710 <namex>
}
    8000788e:	60e2                	ld	ra,24(sp)
    80007890:	6442                	ld	s0,16(sp)
    80007892:	6105                	addi	sp,sp,32
    80007894:	8082                	ret

0000000080007896 <nameiparent>:
{
    80007896:	1141                	addi	sp,sp,-16
    80007898:	e406                	sd	ra,8(sp)
    8000789a:	e022                	sd	s0,0(sp)
    8000789c:	0800                	addi	s0,sp,16
    8000789e:	862e                	mv	a2,a1
    return namex(path, 1, name);
    800078a0:	4585                	li	a1,1
    800078a2:	00000097          	auipc	ra,0x0
    800078a6:	e6e080e7          	jalr	-402(ra) # 80007710 <namex>
}
    800078aa:	60a2                	ld	ra,8(sp)
    800078ac:	6402                	ld	s0,0(sp)
    800078ae:	0141                	addi	sp,sp,16
    800078b0:	8082                	ret

00000000800078b2 <stati>:

// 需要添加stati（已在fs.h中声明）
void stati(struct inode *ip, struct stat *st)
{
    800078b2:	1141                	addi	sp,sp,-16
    800078b4:	e422                	sd	s0,8(sp)
    800078b6:	0800                	addi	s0,sp,16
    st->dev = ip->dev;
    800078b8:	411c                	lw	a5,0(a0)
    800078ba:	c19c                	sw	a5,0(a1)
    st->ino = ip->inum;
    800078bc:	415c                	lw	a5,4(a0)
    800078be:	c1dc                	sw	a5,4(a1)
    st->type = ip->type;
    800078c0:	04451783          	lh	a5,68(a0)
    800078c4:	00f59423          	sh	a5,8(a1)
    st->nlink = ip->nlink;
    800078c8:	04651783          	lh	a5,70(a0)
    800078cc:	00f59523          	sh	a5,10(a1)
    st->size = ip->size;
    800078d0:	04c56783          	lwu	a5,76(a0)
    800078d4:	e99c                	sd	a5,16(a1)
}
    800078d6:	6422                	ld	s0,8(sp)
    800078d8:	0141                	addi	sp,sp,16
    800078da:	8082                	ret

00000000800078dc <strncpy>:
}

// 字符串复制
static char*
strncpy(char *s, const char *t, int n)
{
    800078dc:	1141                	addi	sp,sp,-16
    800078de:	e422                	sd	s0,8(sp)
    800078e0:	0800                	addi	s0,sp,16
    char *os = s;
    while(n-- > 0 && (*s++ = *t++) != 0)
    800078e2:	872a                	mv	a4,a0
    800078e4:	8832                	mv	a6,a2
    800078e6:	367d                	addiw	a2,a2,-1
    800078e8:	01005963          	blez	a6,800078fa <strncpy+0x1e>
    800078ec:	0705                	addi	a4,a4,1
    800078ee:	0005c783          	lbu	a5,0(a1)
    800078f2:	fef70fa3          	sb	a5,-1(a4)
    800078f6:	0585                	addi	a1,a1,1
    800078f8:	f7f5                	bnez	a5,800078e4 <strncpy+0x8>
        ;
    while(n-- > 0)
    800078fa:	86ba                	mv	a3,a4
    800078fc:	00c05c63          	blez	a2,80007914 <strncpy+0x38>
        *s++ = 0;
    80007900:	0685                	addi	a3,a3,1
    80007902:	fe068fa3          	sb	zero,-1(a3)
    while(n-- > 0)
    80007906:	fff6c793          	not	a5,a3
    8000790a:	9fb9                	addw	a5,a5,a4
    8000790c:	010787bb          	addw	a5,a5,a6
    80007910:	fef048e3          	bgtz	a5,80007900 <strncpy+0x24>
    return os;
}
    80007914:	6422                	ld	s0,8(sp)
    80007916:	0141                	addi	sp,sp,16
    80007918:	8082                	ret

000000008000791a <readsb>:

// 读取超级块
static void
readsb(int dev, struct superblock *sb)
{
    8000791a:	1101                	addi	sp,sp,-32
    8000791c:	ec06                	sd	ra,24(sp)
    8000791e:	e822                	sd	s0,16(sp)
    80007920:	e426                	sd	s1,8(sp)
    80007922:	1000                	addi	s0,sp,32
    80007924:	84ae                	mv	s1,a1
    struct buf *bp;

    bp = bread(dev, SUPERBLOCK_NUM);
    80007926:	4585                	li	a1,1
    80007928:	ffffe097          	auipc	ra,0xffffe
    8000792c:	7be080e7          	jalr	1982(ra) # 800060e6 <bread>
    memmove(sb, bp->data, sizeof(*sb));
    80007930:	04050793          	addi	a5,a0,64
    if(s < d && s + n > d){
    80007934:	0297e563          	bltu	a5,s1,8000795e <readsb+0x44>
        while(n-- > 0)
    80007938:	06050693          	addi	a3,a0,96
            *d++ = *s++;
    8000793c:	0785                	addi	a5,a5,1
    8000793e:	0485                	addi	s1,s1,1
    80007940:	fff7c703          	lbu	a4,-1(a5)
    80007944:	fee48fa3          	sb	a4,-1(s1)
        while(n-- > 0)
    80007948:	fed79ae3          	bne	a5,a3,8000793c <readsb+0x22>
    brelse(bp);
    8000794c:	fffff097          	auipc	ra,0xfffff
    80007950:	96e080e7          	jalr	-1682(ra) # 800062ba <brelse>
}
    80007954:	60e2                	ld	ra,24(sp)
    80007956:	6442                	ld	s0,16(sp)
    80007958:	64a2                	ld	s1,8(sp)
    8000795a:	6105                	addi	sp,sp,32
    8000795c:	8082                	ret
    if(s < d && s + n > d){
    8000795e:	06050713          	addi	a4,a0,96
    80007962:	fce4fbe3          	bgeu	s1,a4,80007938 <readsb+0x1e>
        d += n;
    80007966:	02048493          	addi	s1,s1,32
        while(n-- > 0)
    8000796a:	04050693          	addi	a3,a0,64
            *--d = *--s;
    8000796e:	177d                	addi	a4,a4,-1
    80007970:	14fd                	addi	s1,s1,-1
    80007972:	00074783          	lbu	a5,0(a4)
    80007976:	00f48023          	sb	a5,0(s1)
        while(n-- > 0)
    8000797a:	fed71ae3          	bne	a4,a3,8000796e <readsb+0x54>
    8000797e:	b7f9                	j	8000794c <readsb+0x32>

0000000080007980 <fsinit>:
static void mkfs(int dev);

// 文件系统初始化
void
fsinit(int dev)
{
    80007980:	7159                	addi	sp,sp,-112
    80007982:	f486                	sd	ra,104(sp)
    80007984:	f0a2                	sd	s0,96(sp)
    80007986:	eca6                	sd	s1,88(sp)
    80007988:	e8ca                	sd	s2,80(sp)
    8000798a:	e4ce                	sd	s3,72(sp)
    8000798c:	e0d2                	sd	s4,64(sp)
    8000798e:	fc56                	sd	s5,56(sp)
    80007990:	f85a                	sd	s6,48(sp)
    80007992:	f45e                	sd	s7,40(sp)
    80007994:	f062                	sd	s8,32(sp)
    80007996:	ec66                	sd	s9,24(sp)
    80007998:	e86a                	sd	s10,16(sp)
    8000799a:	e46e                	sd	s11,8(sp)
    8000799c:	1880                	addi	s0,sp,112
    8000799e:	8c2a                	mv	s8,a0
    readsb(dev, &sb);
    800079a0:	0045a597          	auipc	a1,0x45a
    800079a4:	78058593          	addi	a1,a1,1920 # 80462120 <sb>
    800079a8:	00000097          	auipc	ra,0x0
    800079ac:	f72080e7          	jalr	-142(ra) # 8000791a <readsb>
    if(sb.magic != FSMAGIC) {
    800079b0:	0045a717          	auipc	a4,0x45a
    800079b4:	77072703          	lw	a4,1904(a4) # 80462120 <sb>
    800079b8:	102037b7          	lui	a5,0x10203
    800079bc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800079c0:	34f70b63          	beq	a4,a5,80007d16 <fsinit+0x396>
        // 文件系统未格式化，进行初始化
        printf("Filesystem not formatted, initializing...\n");
    800079c4:	00007517          	auipc	a0,0x7
    800079c8:	d3450513          	addi	a0,a0,-716 # 8000e6f8 <digits+0x4548>
    800079cc:	ffff9097          	auipc	ra,0xffff9
    800079d0:	b38080e7          	jalr	-1224(ra) # 80000504 <printf>
    int inodestart = logstart + nlog;
    int bmapstart = inodestart + (ninodes / IPB) + 1;
    int nmeta = bmapstart + (nblocks / BPB) + 1;
    int nblocks_data = nblocks - nmeta;
    
    printf("mkfs: creating filesystem with %d blocks, %d inodes\n", nblocks, ninodes);
    800079d4:	0c800613          	li	a2,200
    800079d8:	3e800593          	li	a1,1000
    800079dc:	00007517          	auipc	a0,0x7
    800079e0:	d4c50513          	addi	a0,a0,-692 # 8000e728 <digits+0x4578>
    800079e4:	ffff9097          	auipc	ra,0xffff9
    800079e8:	b20080e7          	jalr	-1248(ra) # 80000504 <printf>
    printf("  log: %d blocks at %d\n", nlog, logstart);
    800079ec:	4609                	li	a2,2
    800079ee:	45f9                	li	a1,30
    800079f0:	00007517          	auipc	a0,0x7
    800079f4:	d7050513          	addi	a0,a0,-656 # 8000e760 <digits+0x45b0>
    800079f8:	ffff9097          	auipc	ra,0xffff9
    800079fc:	b0c080e7          	jalr	-1268(ra) # 80000504 <printf>
    printf("  inodes: %d at %d\n", ninodes, inodestart);
    80007a00:	02000613          	li	a2,32
    80007a04:	0c800593          	li	a1,200
    80007a08:	00007517          	auipc	a0,0x7
    80007a0c:	d7050513          	addi	a0,a0,-656 # 8000e778 <digits+0x45c8>
    80007a10:	ffff9097          	auipc	ra,0xffff9
    80007a14:	af4080e7          	jalr	-1292(ra) # 80000504 <printf>
    printf("  bitmap: at %d\n", bmapstart);
    80007a18:	02500593          	li	a1,37
    80007a1c:	00007517          	auipc	a0,0x7
    80007a20:	d7450513          	addi	a0,a0,-652 # 8000e790 <digits+0x45e0>
    80007a24:	ffff9097          	auipc	ra,0xffff9
    80007a28:	ae0080e7          	jalr	-1312(ra) # 80000504 <printf>
    
    // 初始化超级块
    struct buf *sbp_buf = bread(dev, SUPERBLOCK_NUM);
    80007a2c:	000c0a1b          	sext.w	s4,s8
    80007a30:	4585                	li	a1,1
    80007a32:	8552                	mv	a0,s4
    80007a34:	ffffe097          	auipc	ra,0xffffe
    80007a38:	6b2080e7          	jalr	1714(ra) # 800060e6 <bread>
    80007a3c:	84aa                	mv	s1,a0
    struct superblock *sbp = (struct superblock*)sbp_buf->data;
    sbp->magic = FSMAGIC;
    80007a3e:	10203937          	lui	s2,0x10203
    80007a42:	04090913          	addi	s2,s2,64 # 10203040 <_entry-0x6fdfcfc0>
    80007a46:	05252023          	sw	s2,64(a0)
    sbp->size = nblocks;
    80007a4a:	3e800d93          	li	s11,1000
    80007a4e:	05b52223          	sw	s11,68(a0)
    sbp->nblocks = nblocks_data;
    80007a52:	3c200d13          	li	s10,962
    80007a56:	05a52423          	sw	s10,72(a0)
    sbp->ninodes = ninodes;
    80007a5a:	0c800c93          	li	s9,200
    80007a5e:	05952623          	sw	s9,76(a0)
    sbp->nlog = nlog;
    80007a62:	4bf9                	li	s7,30
    80007a64:	05752823          	sw	s7,80(a0)
    sbp->logstart = logstart;
    80007a68:	4b09                	li	s6,2
    80007a6a:	05652a23          	sw	s6,84(a0)
    sbp->inodestart = inodestart;
    80007a6e:	02000a93          	li	s5,32
    80007a72:	05552c23          	sw	s5,88(a0)
    sbp->bmapstart = bmapstart;
    80007a76:	02500993          	li	s3,37
    80007a7a:	05352e23          	sw	s3,92(a0)
    bwrite(sbp_buf);
    80007a7e:	ffffe097          	auipc	ra,0xffffe
    80007a82:	7a6080e7          	jalr	1958(ra) # 80006224 <bwrite>
    brelse(sbp_buf);
    80007a86:	8526                	mv	a0,s1
    80007a88:	fffff097          	auipc	ra,0xfffff
    80007a8c:	832080e7          	jalr	-1998(ra) # 800062ba <brelse>
    
    // 更新全局超级块变量（供ialloc等函数使用）
    sb.magic = FSMAGIC;
    80007a90:	0045a797          	auipc	a5,0x45a
    80007a94:	69078793          	addi	a5,a5,1680 # 80462120 <sb>
    80007a98:	0127a023          	sw	s2,0(a5)
    sb.size = nblocks;
    80007a9c:	01b7a223          	sw	s11,4(a5)
    sb.nblocks = nblocks_data;
    80007aa0:	01a7a423          	sw	s10,8(a5)
    sb.ninodes = ninodes;
    80007aa4:	0197a623          	sw	s9,12(a5)
    sb.nlog = nlog;
    80007aa8:	0177a823          	sw	s7,16(a5)
    sb.logstart = logstart;
    80007aac:	0167aa23          	sw	s6,20(a5)
    sb.inodestart = inodestart;
    80007ab0:	0157ac23          	sw	s5,24(a5)
    sb.bmapstart = bmapstart;
    80007ab4:	0137ae23          	sw	s3,28(a5)
    80007ab8:	4909                	li	s2,2
    80007aba:	6985                	lui	s3,0x1
    80007abc:	04098993          	addi	s3,s3,64 # 1040 <_entry-0x7fffefc0>
    80007ac0:	a831                	j	80007adc <fsinit+0x15c>
    
    // 清零日志区
    for(int i = 0; i < nlog; i++) {
        bp = bread(dev, logstart + i);
        memset(bp->data, 0, BSIZE);
        bwrite(bp);
    80007ac2:	8526                	mv	a0,s1
    80007ac4:	ffffe097          	auipc	ra,0xffffe
    80007ac8:	760080e7          	jalr	1888(ra) # 80006224 <bwrite>
        brelse(bp);
    80007acc:	8526                	mv	a0,s1
    80007ace:	ffffe097          	auipc	ra,0xffffe
    80007ad2:	7ec080e7          	jalr	2028(ra) # 800062ba <brelse>
    for(int i = 0; i < nlog; i++) {
    80007ad6:	2905                	addiw	s2,s2,1
    80007ad8:	03590363          	beq	s2,s5,80007afe <fsinit+0x17e>
        bp = bread(dev, logstart + i);
    80007adc:	85ca                	mv	a1,s2
    80007ade:	8552                	mv	a0,s4
    80007ae0:	ffffe097          	auipc	ra,0xffffe
    80007ae4:	606080e7          	jalr	1542(ra) # 800060e6 <bread>
    80007ae8:	84aa                	mv	s1,a0
    for(int i = 0; i < n; i++){
    80007aea:	04050793          	addi	a5,a0,64
    80007aee:	01350733          	add	a4,a0,s3
        cdst[i] = c;
    80007af2:	00078023          	sb	zero,0(a5)
    for(int i = 0; i < n; i++){
    80007af6:	0785                	addi	a5,a5,1
    80007af8:	fef71de3          	bne	a4,a5,80007af2 <fsinit+0x172>
    80007afc:	b7d9                	j	80007ac2 <fsinit+0x142>
    80007afe:	6985                	lui	s3,0x1
    80007b00:	04098993          	addi	s3,s3,64 # 1040 <_entry-0x7fffefc0>
    }
    
    // 清零inode区
    for(int i = 0; i < (ninodes / IPB) + 1; i++) {
    80007b04:	02500a93          	li	s5,37
        bp = bread(dev, inodestart + i);
    80007b08:	85ca                	mv	a1,s2
    80007b0a:	8552                	mv	a0,s4
    80007b0c:	ffffe097          	auipc	ra,0xffffe
    80007b10:	5da080e7          	jalr	1498(ra) # 800060e6 <bread>
    80007b14:	84aa                	mv	s1,a0
    for(int i = 0; i < n; i++){
    80007b16:	04050793          	addi	a5,a0,64
    80007b1a:	01350733          	add	a4,a0,s3
        cdst[i] = c;
    80007b1e:	00078023          	sb	zero,0(a5)
    for(int i = 0; i < n; i++){
    80007b22:	0785                	addi	a5,a5,1
    80007b24:	fef71de3          	bne	a4,a5,80007b1e <fsinit+0x19e>
        memset(bp->data, 0, BSIZE);
        bwrite(bp);
    80007b28:	8526                	mv	a0,s1
    80007b2a:	ffffe097          	auipc	ra,0xffffe
    80007b2e:	6fa080e7          	jalr	1786(ra) # 80006224 <bwrite>
        brelse(bp);
    80007b32:	8526                	mv	a0,s1
    80007b34:	ffffe097          	auipc	ra,0xffffe
    80007b38:	786080e7          	jalr	1926(ra) # 800062ba <brelse>
    for(int i = 0; i < (ninodes / IPB) + 1; i++) {
    80007b3c:	2905                	addiw	s2,s2,1
    80007b3e:	fd5915e3          	bne	s2,s5,80007b08 <fsinit+0x188>
    }
    
    // 初始化位图（所有块都标记为已使用）
    for(int i = 0; i < (nblocks / BPB) + 1; i++) {
        bp = bread(dev, bmapstart + i);
    80007b42:	02500593          	li	a1,37
    80007b46:	8552                	mv	a0,s4
    80007b48:	ffffe097          	auipc	ra,0xffffe
    80007b4c:	59e080e7          	jalr	1438(ra) # 800060e6 <bread>
    80007b50:	84aa                	mv	s1,a0
    for(int i = 0; i < n; i++){
    80007b52:	04050793          	addi	a5,a0,64
    80007b56:	6705                	lui	a4,0x1
    80007b58:	04070713          	addi	a4,a4,64 # 1040 <_entry-0x7fffefc0>
    80007b5c:	972a                	add	a4,a4,a0
        cdst[i] = c;
    80007b5e:	56fd                	li	a3,-1
    80007b60:	00d78023          	sb	a3,0(a5)
    for(int i = 0; i < n; i++){
    80007b64:	0785                	addi	a5,a5,1
    80007b66:	fef71de3          	bne	a4,a5,80007b60 <fsinit+0x1e0>
        memset(bp->data, 0xFF, BSIZE);  // 全部标记为已使用
        bwrite(bp);
    80007b6a:	8526                	mv	a0,s1
    80007b6c:	ffffe097          	auipc	ra,0xffffe
    80007b70:	6b8080e7          	jalr	1720(ra) # 80006224 <bwrite>
        brelse(bp);
    80007b74:	8526                	mv	a0,s1
    80007b76:	ffffe097          	auipc	ra,0xffffe
    80007b7a:	744080e7          	jalr	1860(ra) # 800062ba <brelse>
    for(int i = 0; i < (nblocks / BPB) + 1; i++) {
    80007b7e:	02600913          	li	s2,38
    // 从nmeta开始的数据块标记为空闲
    
    // 标记数据块为空闲
    for(int i = 0; i < nblocks_data; i++) {
        uint b = nmeta + i;
        bp = bread(dev, BBLOCK(b, sb));
    80007b82:	0045ab97          	auipc	s7,0x45a
    80007b86:	59eb8b93          	addi	s7,s7,1438 # 80462120 <sb>
        int bi = b % BPB;
        int m = 1 << (bi % 8);
    80007b8a:	4b05                	li	s6,1
    for(int i = 0; i < nblocks_data; i++) {
    80007b8c:	3e800a93          	li	s5,1000
        uint b = nmeta + i;
    80007b90:	0009049b          	sext.w	s1,s2
        bp = bread(dev, BBLOCK(b, sb));
    80007b94:	00f9559b          	srliw	a1,s2,0xf
    80007b98:	01cba783          	lw	a5,28(s7)
    80007b9c:	9dbd                	addw	a1,a1,a5
    80007b9e:	8552                	mv	a0,s4
    80007ba0:	ffffe097          	auipc	ra,0xffffe
    80007ba4:	546080e7          	jalr	1350(ra) # 800060e6 <bread>
    80007ba8:	89aa                	mv	s3,a0
        bp->data[bi/8] &= ~m;  // 标记为空闲
    80007baa:	41f4d79b          	sraiw	a5,s1,0x1f
    80007bae:	01d7d79b          	srliw	a5,a5,0x1d
    80007bb2:	9fa5                	addw	a5,a5,s1
    80007bb4:	4037d79b          	sraiw	a5,a5,0x3
    80007bb8:	97aa                	add	a5,a5,a0
        int m = 1 << (bi % 8);
    80007bba:	889d                	andi	s1,s1,7
    80007bbc:	009b14bb          	sllw	s1,s6,s1
        bp->data[bi/8] &= ~m;  // 标记为空闲
    80007bc0:	fff4c493          	not	s1,s1
    80007bc4:	0407c703          	lbu	a4,64(a5)
    80007bc8:	8cf9                	and	s1,s1,a4
    80007bca:	04978023          	sb	s1,64(a5)
        bwrite(bp);
    80007bce:	ffffe097          	auipc	ra,0xffffe
    80007bd2:	656080e7          	jalr	1622(ra) # 80006224 <bwrite>
        brelse(bp);
    80007bd6:	854e                	mv	a0,s3
    80007bd8:	ffffe097          	auipc	ra,0xffffe
    80007bdc:	6e2080e7          	jalr	1762(ra) # 800062ba <brelse>
    for(int i = 0; i < nblocks_data; i++) {
    80007be0:	2905                	addiw	s2,s2,1
    80007be2:	fb5917e3          	bne	s2,s5,80007b90 <fsinit+0x210>
    // 在mkfs中，我们直接写入磁盘，不使用日志系统
    // 因为日志系统还没有初始化
    
    // 直接分配inode 1作为根目录
    int inum = 1;
    bp = bread(dev, IBLOCK(inum, sb));
    80007be6:	0045a597          	auipc	a1,0x45a
    80007bea:	5525a583          	lw	a1,1362(a1) # 80462138 <sb+0x18>
    80007bee:	8552                	mv	a0,s4
    80007bf0:	ffffe097          	auipc	ra,0xffffe
    80007bf4:	4f6080e7          	jalr	1270(ra) # 800060e6 <bread>
    80007bf8:	84aa                	mv	s1,a0
    for(int i = 0; i < n; i++){
    80007bfa:	09450793          	addi	a5,a0,148
    80007bfe:	0e850713          	addi	a4,a0,232
        cdst[i] = c;
    80007c02:	00078023          	sb	zero,0(a5)
    for(int i = 0; i < n; i++){
    80007c06:	0785                	addi	a5,a5,1
    80007c08:	fee79de3          	bne	a5,a4,80007c02 <fsinit+0x282>
    struct dinode *dip = (struct dinode*)bp->data + (inum % IPB);
    memset(dip, 0, sizeof(*dip));
    dip->type = T_DIR;
    80007c0c:	4985                	li	s3,1
    80007c0e:	0b349023          	sh	s3,160(s1)
    dip->nlink = 2;  // . 和 ..
    80007c12:	4789                	li	a5,2
    80007c14:	0af49123          	sh	a5,162(s1)
    bwrite(bp);  // 直接写入，不使用日志
    80007c18:	8526                	mv	a0,s1
    80007c1a:	ffffe097          	auipc	ra,0xffffe
    80007c1e:	60a080e7          	jalr	1546(ra) # 80006224 <bwrite>
    brelse(bp);
    80007c22:	8526                	mv	a0,s1
    80007c24:	ffffe097          	auipc	ra,0xffffe
    80007c28:	696080e7          	jalr	1686(ra) # 800062ba <brelse>
    
    // 获取inode并创建目录项
    struct inode *root = iget(dev, inum);
    80007c2c:	4585                	li	a1,1
    80007c2e:	8552                	mv	a0,s4
    80007c30:	fffff097          	auipc	ra,0xfffff
    80007c34:	f58080e7          	jalr	-168(ra) # 80006b88 <iget>
    80007c38:	892a                	mv	s2,a0
    ilock(root);
    80007c3a:	fffff097          	auipc	ra,0xfffff
    80007c3e:	e08080e7          	jalr	-504(ra) # 80006a42 <ilock>
    
    // 先分配数据块
    uint bno = balloc(dev);
    80007c42:	8552                	mv	a0,s4
    80007c44:	fffff097          	auipc	ra,0xfffff
    80007c48:	23a080e7          	jalr	570(ra) # 80006e7e <balloc>
    80007c4c:	0005049b          	sext.w	s1,a0
    root->direct[0] = bno;
    80007c50:	06992023          	sw	s1,96(s2)
    root->size = 2 * sizeof(struct dirent);
    80007c54:	02000793          	li	a5,32
    80007c58:	04f92623          	sw	a5,76(s2)
    root->blocks = 1;
    80007c5c:	05392823          	sw	s3,80(s2)
    iupdate(root);  // 更新inode（会检查日志系统）
    80007c60:	854a                	mv	a0,s2
    80007c62:	fffff097          	auipc	ra,0xfffff
    80007c66:	136080e7          	jalr	310(ra) # 80006d98 <iupdate>
    
    // 创建 . 和 .. 目录项（直接写入，不使用日志）
    bp = bread(dev, bno);
    80007c6a:	85a6                	mv	a1,s1
    80007c6c:	8552                	mv	a0,s4
    80007c6e:	ffffe097          	auipc	ra,0xffffe
    80007c72:	478080e7          	jalr	1144(ra) # 800060e6 <bread>
    80007c76:	84aa                	mv	s1,a0
    struct dirent *de = (struct dirent*)bp->data;
    
    // . 目录项
    de[0].inum = inum;
    80007c78:	05351023          	sh	s3,64(a0)
    strncpy(de[0].name, ".", DIRSIZ);
    80007c7c:	4639                	li	a2,14
    80007c7e:	00007597          	auipc	a1,0x7
    80007c82:	b2a58593          	addi	a1,a1,-1238 # 8000e7a8 <digits+0x45f8>
    80007c86:	04250513          	addi	a0,a0,66
    80007c8a:	00000097          	auipc	ra,0x0
    80007c8e:	c52080e7          	jalr	-942(ra) # 800078dc <strncpy>
    
    // .. 目录项
    de[1].inum = inum;
    80007c92:	05349823          	sh	s3,80(s1)
    strncpy(de[1].name, "..", DIRSIZ);
    80007c96:	4639                	li	a2,14
    80007c98:	00007597          	auipc	a1,0x7
    80007c9c:	b1858593          	addi	a1,a1,-1256 # 8000e7b0 <digits+0x4600>
    80007ca0:	05248513          	addi	a0,s1,82
    80007ca4:	00000097          	auipc	ra,0x0
    80007ca8:	c38080e7          	jalr	-968(ra) # 800078dc <strncpy>
    
    // 清零其余目录项
    for(int i = 2; i < BSIZE/sizeof(struct dirent); i++) {
    80007cac:	06048793          	addi	a5,s1,96
    80007cb0:	6705                	lui	a4,0x1
    80007cb2:	04070713          	addi	a4,a4,64 # 1040 <_entry-0x7fffefc0>
    80007cb6:	9726                	add	a4,a4,s1
        de[i].inum = 0;
    80007cb8:	00079023          	sh	zero,0(a5)
    for(int i = 2; i < BSIZE/sizeof(struct dirent); i++) {
    80007cbc:	07c1                	addi	a5,a5,16
    80007cbe:	fef71de3          	bne	a4,a5,80007cb8 <fsinit+0x338>
    }
    
    bwrite(bp);  // 直接写入
    80007cc2:	8526                	mv	a0,s1
    80007cc4:	ffffe097          	auipc	ra,0xffffe
    80007cc8:	560080e7          	jalr	1376(ra) # 80006224 <bwrite>
    brelse(bp);
    80007ccc:	8526                	mv	a0,s1
    80007cce:	ffffe097          	auipc	ra,0xffffe
    80007cd2:	5ec080e7          	jalr	1516(ra) # 800062ba <brelse>
    
    iunlockput(root);
    80007cd6:	854a                	mv	a0,s2
    80007cd8:	00000097          	auipc	ra,0x0
    80007cdc:	a10080e7          	jalr	-1520(ra) # 800076e8 <iunlockput>
    
    printf("mkfs: filesystem created successfully\n");
    80007ce0:	00007517          	auipc	a0,0x7
    80007ce4:	ad850513          	addi	a0,a0,-1320 # 8000e7b8 <digits+0x4608>
    80007ce8:	ffff9097          	auipc	ra,0xffff9
    80007cec:	81c080e7          	jalr	-2020(ra) # 80000504 <printf>
        readsb(dev, &sb);
    80007cf0:	0045a597          	auipc	a1,0x45a
    80007cf4:	43058593          	addi	a1,a1,1072 # 80462120 <sb>
    80007cf8:	8562                	mv	a0,s8
    80007cfa:	00000097          	auipc	ra,0x0
    80007cfe:	c20080e7          	jalr	-992(ra) # 8000791a <readsb>
        if(sb.magic != FSMAGIC)
    80007d02:	0045a717          	auipc	a4,0x45a
    80007d06:	41e72703          	lw	a4,1054(a4) # 80462120 <sb>
    80007d0a:	102037b7          	lui	a5,0x10203
    80007d0e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80007d12:	02f71a63          	bne	a4,a5,80007d46 <fsinit+0x3c6>
    initlog_wrapper(dev, &sb);
    80007d16:	0045a597          	auipc	a1,0x45a
    80007d1a:	40a58593          	addi	a1,a1,1034 # 80462120 <sb>
    80007d1e:	8562                	mv	a0,s8
    80007d20:	fffff097          	auipc	ra,0xfffff
    80007d24:	c22080e7          	jalr	-990(ra) # 80006942 <initlog_wrapper>
}
    80007d28:	70a6                	ld	ra,104(sp)
    80007d2a:	7406                	ld	s0,96(sp)
    80007d2c:	64e6                	ld	s1,88(sp)
    80007d2e:	6946                	ld	s2,80(sp)
    80007d30:	69a6                	ld	s3,72(sp)
    80007d32:	6a06                	ld	s4,64(sp)
    80007d34:	7ae2                	ld	s5,56(sp)
    80007d36:	7b42                	ld	s6,48(sp)
    80007d38:	7ba2                	ld	s7,40(sp)
    80007d3a:	7c02                	ld	s8,32(sp)
    80007d3c:	6ce2                	ld	s9,24(sp)
    80007d3e:	6d42                	ld	s10,16(sp)
    80007d40:	6da2                	ld	s11,8(sp)
    80007d42:	6165                	addi	sp,sp,112
    80007d44:	8082                	ret
            panic("invalid file system after mkfs");
    80007d46:	00007517          	auipc	a0,0x7
    80007d4a:	a9a50513          	addi	a0,a0,-1382 # 8000e7e0 <digits+0x4630>
    80007d4e:	ffffb097          	auipc	ra,0xffffb
    80007d52:	d3e080e7          	jalr	-706(ra) # 80002a8c <panic>

0000000080007d56 <fileinit>:

// 文件描述符表：将小的整数fd映射到file结构
// 简化实现：直接使用file数组索引作为fd

void fileinit(void)
{
    80007d56:	1141                	addi	sp,sp,-16
    80007d58:	e406                	sd	ra,8(sp)
    80007d5a:	e022                	sd	s0,0(sp)
    80007d5c:	0800                	addi	s0,sp,16
    initlock(&ftable.lock, "ftable");
    80007d5e:	00007597          	auipc	a1,0x7
    80007d62:	aa258593          	addi	a1,a1,-1374 # 8000e800 <digits+0x4650>
    80007d66:	0045d517          	auipc	a0,0x45d
    80007d6a:	e2250513          	addi	a0,a0,-478 # 80464b88 <ftable+0xc80>
    80007d6e:	ffffc097          	auipc	ra,0xffffc
    80007d72:	906080e7          	jalr	-1786(ra) # 80003674 <initlock>
}
    80007d76:	60a2                	ld	ra,8(sp)
    80007d78:	6402                	ld	s0,0(sp)
    80007d7a:	0141                	addi	sp,sp,16
    80007d7c:	8082                	ret

0000000080007d7e <filealloc>:

// 分配一个文件结构
struct file *
filealloc(void)
{
    80007d7e:	1101                	addi	sp,sp,-32
    80007d80:	ec06                	sd	ra,24(sp)
    80007d82:	e822                	sd	s0,16(sp)
    80007d84:	e426                	sd	s1,8(sp)
    80007d86:	1000                	addi	s0,sp,32
    struct file *f;

    acquire(&ftable.lock);
    80007d88:	0045d517          	auipc	a0,0x45d
    80007d8c:	e0050513          	addi	a0,a0,-512 # 80464b88 <ftable+0xc80>
    80007d90:	ffffc097          	auipc	ra,0xffffc
    80007d94:	9c6080e7          	jalr	-1594(ra) # 80003756 <acquire>
    for (f = ftable.file; f < ftable.file + NFILE; f++)
    80007d98:	0045c497          	auipc	s1,0x45c
    80007d9c:	17048493          	addi	s1,s1,368 # 80463f08 <ftable>
    80007da0:	0045d717          	auipc	a4,0x45d
    80007da4:	de870713          	addi	a4,a4,-536 # 80464b88 <ftable+0xc80>
    {
        if (f->ref == 0)
    80007da8:	40dc                	lw	a5,4(s1)
    80007daa:	cf99                	beqz	a5,80007dc8 <filealloc+0x4a>
    for (f = ftable.file; f < ftable.file + NFILE; f++)
    80007dac:	02048493          	addi	s1,s1,32
    80007db0:	fee49ce3          	bne	s1,a4,80007da8 <filealloc+0x2a>
            f->ref = 1;
            release(&ftable.lock);
            return f;
        }
    }
    release(&ftable.lock);
    80007db4:	0045d517          	auipc	a0,0x45d
    80007db8:	dd450513          	addi	a0,a0,-556 # 80464b88 <ftable+0xc80>
    80007dbc:	ffffc097          	auipc	ra,0xffffc
    80007dc0:	a0a080e7          	jalr	-1526(ra) # 800037c6 <release>
    return 0;
    80007dc4:	4481                	li	s1,0
    80007dc6:	a819                	j	80007ddc <filealloc+0x5e>
            f->ref = 1;
    80007dc8:	4785                	li	a5,1
    80007dca:	c0dc                	sw	a5,4(s1)
            release(&ftable.lock);
    80007dcc:	0045d517          	auipc	a0,0x45d
    80007dd0:	dbc50513          	addi	a0,a0,-580 # 80464b88 <ftable+0xc80>
    80007dd4:	ffffc097          	auipc	ra,0xffffc
    80007dd8:	9f2080e7          	jalr	-1550(ra) # 800037c6 <release>
}
    80007ddc:	8526                	mv	a0,s1
    80007dde:	60e2                	ld	ra,24(sp)
    80007de0:	6442                	ld	s0,16(sp)
    80007de2:	64a2                	ld	s1,8(sp)
    80007de4:	6105                	addi	sp,sp,32
    80007de6:	8082                	ret

0000000080007de8 <filedup>:

// 增加文件引用计数
struct file *
filedup(struct file *f)
{
    80007de8:	1101                	addi	sp,sp,-32
    80007dea:	ec06                	sd	ra,24(sp)
    80007dec:	e822                	sd	s0,16(sp)
    80007dee:	e426                	sd	s1,8(sp)
    80007df0:	1000                	addi	s0,sp,32
    80007df2:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    80007df4:	0045d517          	auipc	a0,0x45d
    80007df8:	d9450513          	addi	a0,a0,-620 # 80464b88 <ftable+0xc80>
    80007dfc:	ffffc097          	auipc	ra,0xffffc
    80007e00:	95a080e7          	jalr	-1702(ra) # 80003756 <acquire>
    if (f->ref < 1)
    80007e04:	40dc                	lw	a5,4(s1)
    80007e06:	02f05263          	blez	a5,80007e2a <filedup+0x42>
        panic("filedup");
    f->ref++;
    80007e0a:	2785                	addiw	a5,a5,1
    80007e0c:	c0dc                	sw	a5,4(s1)
    release(&ftable.lock);
    80007e0e:	0045d517          	auipc	a0,0x45d
    80007e12:	d7a50513          	addi	a0,a0,-646 # 80464b88 <ftable+0xc80>
    80007e16:	ffffc097          	auipc	ra,0xffffc
    80007e1a:	9b0080e7          	jalr	-1616(ra) # 800037c6 <release>
    return f;
}
    80007e1e:	8526                	mv	a0,s1
    80007e20:	60e2                	ld	ra,24(sp)
    80007e22:	6442                	ld	s0,16(sp)
    80007e24:	64a2                	ld	s1,8(sp)
    80007e26:	6105                	addi	sp,sp,32
    80007e28:	8082                	ret
        panic("filedup");
    80007e2a:	00007517          	auipc	a0,0x7
    80007e2e:	9de50513          	addi	a0,a0,-1570 # 8000e808 <digits+0x4658>
    80007e32:	ffffb097          	auipc	ra,0xffffb
    80007e36:	c5a080e7          	jalr	-934(ra) # 80002a8c <panic>

0000000080007e3a <fileclose>:

// 关闭文件
void fileclose(struct file *f)
{
    80007e3a:	7179                	addi	sp,sp,-48
    80007e3c:	f406                	sd	ra,40(sp)
    80007e3e:	f022                	sd	s0,32(sp)
    80007e40:	ec26                	sd	s1,24(sp)
    80007e42:	e84a                	sd	s2,16(sp)
    80007e44:	e44e                	sd	s3,8(sp)
    80007e46:	1800                	addi	s0,sp,48
    80007e48:	84aa                	mv	s1,a0
    struct file ff;

    acquire(&ftable.lock);
    80007e4a:	0045d517          	auipc	a0,0x45d
    80007e4e:	d3e50513          	addi	a0,a0,-706 # 80464b88 <ftable+0xc80>
    80007e52:	ffffc097          	auipc	ra,0xffffc
    80007e56:	904080e7          	jalr	-1788(ra) # 80003756 <acquire>
    if (f->ref < 1)
    80007e5a:	40dc                	lw	a5,4(s1)
    80007e5c:	04f05263          	blez	a5,80007ea0 <fileclose+0x66>
        panic("fileclose");
    if (--f->ref > 0)
    80007e60:	37fd                	addiw	a5,a5,-1
    80007e62:	0007871b          	sext.w	a4,a5
    80007e66:	c0dc                	sw	a5,4(s1)
    80007e68:	04e04463          	bgtz	a4,80007eb0 <fileclose+0x76>
    {
        release(&ftable.lock);
        return;
    }
    ff = *f;
    80007e6c:	0004a903          	lw	s2,0(s1)
    80007e70:	0104b983          	ld	s3,16(s1)
    f->ref = 0;
    80007e74:	0004a223          	sw	zero,4(s1)
    f->type = FD_NONE;
    80007e78:	0004a023          	sw	zero,0(s1)
    release(&ftable.lock);
    80007e7c:	0045d517          	auipc	a0,0x45d
    80007e80:	d0c50513          	addi	a0,a0,-756 # 80464b88 <ftable+0xc80>
    80007e84:	ffffc097          	auipc	ra,0xffffc
    80007e88:	942080e7          	jalr	-1726(ra) # 800037c6 <release>

    if (ff.type == FD_INODE)
    80007e8c:	4789                	li	a5,2
    80007e8e:	02f90a63          	beq	s2,a5,80007ec2 <fileclose+0x88>
    {
        iput(ff.ip);
    }
}
    80007e92:	70a2                	ld	ra,40(sp)
    80007e94:	7402                	ld	s0,32(sp)
    80007e96:	64e2                	ld	s1,24(sp)
    80007e98:	6942                	ld	s2,16(sp)
    80007e9a:	69a2                	ld	s3,8(sp)
    80007e9c:	6145                	addi	sp,sp,48
    80007e9e:	8082                	ret
        panic("fileclose");
    80007ea0:	00007517          	auipc	a0,0x7
    80007ea4:	97050513          	addi	a0,a0,-1680 # 8000e810 <digits+0x4660>
    80007ea8:	ffffb097          	auipc	ra,0xffffb
    80007eac:	be4080e7          	jalr	-1052(ra) # 80002a8c <panic>
        release(&ftable.lock);
    80007eb0:	0045d517          	auipc	a0,0x45d
    80007eb4:	cd850513          	addi	a0,a0,-808 # 80464b88 <ftable+0xc80>
    80007eb8:	ffffc097          	auipc	ra,0xffffc
    80007ebc:	90e080e7          	jalr	-1778(ra) # 800037c6 <release>
        return;
    80007ec0:	bfc9                	j	80007e92 <fileclose+0x58>
        iput(ff.ip);
    80007ec2:	854e                	mv	a0,s3
    80007ec4:	fffff097          	auipc	ra,0xfffff
    80007ec8:	5ee080e7          	jalr	1518(ra) # 800074b2 <iput>
    80007ecc:	b7d9                	j	80007e92 <fileclose+0x58>

0000000080007ece <fileread>:

// 从文件读取
int fileread(struct file *f, uint64 addr, int n)
{
    80007ece:	7179                	addi	sp,sp,-48
    80007ed0:	f406                	sd	ra,40(sp)
    80007ed2:	f022                	sd	s0,32(sp)
    80007ed4:	ec26                	sd	s1,24(sp)
    80007ed6:	e84a                	sd	s2,16(sp)
    80007ed8:	e44e                	sd	s3,8(sp)
    80007eda:	1800                	addi	s0,sp,48
    int r = 0;

    if (f->readable == 0)
    80007edc:	00854783          	lbu	a5,8(a0)
    80007ee0:	c3ad                	beqz	a5,80007f42 <fileread+0x74>
    80007ee2:	84aa                	mv	s1,a0
    80007ee4:	892e                	mv	s2,a1
    80007ee6:	89b2                	mv	s3,a2
        return -1;

    if (f->type == FD_INODE)
    80007ee8:	4118                	lw	a4,0(a0)
    80007eea:	4789                	li	a5,2
    80007eec:	04f71363          	bne	a4,a5,80007f32 <fileread+0x64>
    {
        ilock(f->ip);
    80007ef0:	6908                	ld	a0,16(a0)
    80007ef2:	fffff097          	auipc	ra,0xfffff
    80007ef6:	b50080e7          	jalr	-1200(ra) # 80006a42 <ilock>
        if ((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80007efa:	874e                	mv	a4,s3
    80007efc:	4c94                	lw	a3,24(s1)
    80007efe:	864a                	mv	a2,s2
    80007f00:	4585                	li	a1,1
    80007f02:	6888                	ld	a0,16(s1)
    80007f04:	fffff097          	auipc	ra,0xfffff
    80007f08:	1ce080e7          	jalr	462(ra) # 800070d2 <readi>
    80007f0c:	892a                	mv	s2,a0
    80007f0e:	00a05563          	blez	a0,80007f18 <fileread+0x4a>
            f->off += r;
    80007f12:	4c9c                	lw	a5,24(s1)
    80007f14:	9fa9                	addw	a5,a5,a0
    80007f16:	cc9c                	sw	a5,24(s1)
        iunlock(f->ip);
    80007f18:	6888                	ld	a0,16(s1)
    80007f1a:	fffff097          	auipc	ra,0xfffff
    80007f1e:	c22080e7          	jalr	-990(ra) # 80006b3c <iunlock>
    {
        panic("fileread");
    }

    return r;
}
    80007f22:	854a                	mv	a0,s2
    80007f24:	70a2                	ld	ra,40(sp)
    80007f26:	7402                	ld	s0,32(sp)
    80007f28:	64e2                	ld	s1,24(sp)
    80007f2a:	6942                	ld	s2,16(sp)
    80007f2c:	69a2                	ld	s3,8(sp)
    80007f2e:	6145                	addi	sp,sp,48
    80007f30:	8082                	ret
        panic("fileread");
    80007f32:	00007517          	auipc	a0,0x7
    80007f36:	8ee50513          	addi	a0,a0,-1810 # 8000e820 <digits+0x4670>
    80007f3a:	ffffb097          	auipc	ra,0xffffb
    80007f3e:	b52080e7          	jalr	-1198(ra) # 80002a8c <panic>
        return -1;
    80007f42:	597d                	li	s2,-1
    80007f44:	bff9                	j	80007f22 <fileread+0x54>

0000000080007f46 <filewrite>:

// 写入文件
int filewrite(struct file *f, uint64 addr, int n)
{
    80007f46:	715d                	addi	sp,sp,-80
    80007f48:	e486                	sd	ra,72(sp)
    80007f4a:	e0a2                	sd	s0,64(sp)
    80007f4c:	fc26                	sd	s1,56(sp)
    80007f4e:	f84a                	sd	s2,48(sp)
    80007f50:	f44e                	sd	s3,40(sp)
    80007f52:	f052                	sd	s4,32(sp)
    80007f54:	ec56                	sd	s5,24(sp)
    80007f56:	e85a                	sd	s6,16(sp)
    80007f58:	e45e                	sd	s7,8(sp)
    80007f5a:	e062                	sd	s8,0(sp)
    80007f5c:	0880                	addi	s0,sp,80
    int r, ret = 0;

    if (f->writable == 0)
    80007f5e:	00954783          	lbu	a5,9(a0)
    80007f62:	c7ed                	beqz	a5,8000804c <filewrite+0x106>
    80007f64:	892a                	mv	s2,a0
    80007f66:	8aae                	mv	s5,a1
    80007f68:	8a32                	mv	s4,a2
        return -1;

    if (f->type == FD_INODE)
    80007f6a:	4118                	lw	a4,0(a0)
    80007f6c:	4789                	li	a5,2
    80007f6e:	0cf71763          	bne	a4,a5,8000803c <filewrite+0xf6>
    {
        int max = ((MAXOPBLOCKS - 1 - 1 - 2) / 2) * BSIZE;
        int i = 0;
        while (i < n)
    80007f72:	0cc05163          	blez	a2,80008034 <filewrite+0xee>
        int i = 0;
    80007f76:	4981                	li	s3,0
    80007f78:	6b0d                	lui	s6,0x3
    80007f7a:	6b8d                	lui	s7,0x3
    80007f7c:	a08d                	j	80007fde <filewrite+0x98>
    80007f7e:	00048c1b          	sext.w	s8,s1
        {
            int n1 = n - i;
            if (n1 > max)
                n1 = max;

            begin_op();
    80007f82:	ffffe097          	auipc	ra,0xffffe
    80007f86:	6a0080e7          	jalr	1696(ra) # 80006622 <begin_op>
            ilock(f->ip);
    80007f8a:	01093503          	ld	a0,16(s2)
    80007f8e:	fffff097          	auipc	ra,0xfffff
    80007f92:	ab4080e7          	jalr	-1356(ra) # 80006a42 <ilock>
            if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80007f96:	8762                	mv	a4,s8
    80007f98:	01892683          	lw	a3,24(s2)
    80007f9c:	01598633          	add	a2,s3,s5
    80007fa0:	4585                	li	a1,1
    80007fa2:	01093503          	ld	a0,16(s2)
    80007fa6:	fffff097          	auipc	ra,0xfffff
    80007faa:	2e8080e7          	jalr	744(ra) # 8000728e <writei>
    80007fae:	84aa                	mv	s1,a0
    80007fb0:	02a05f63          	blez	a0,80007fee <filewrite+0xa8>
                f->off += r;
    80007fb4:	01892783          	lw	a5,24(s2)
    80007fb8:	9fa9                	addw	a5,a5,a0
    80007fba:	00f92c23          	sw	a5,24(s2)
            iunlock(f->ip);
    80007fbe:	01093503          	ld	a0,16(s2)
    80007fc2:	fffff097          	auipc	ra,0xfffff
    80007fc6:	b7a080e7          	jalr	-1158(ra) # 80006b3c <iunlock>
            end_op();
    80007fca:	ffffe097          	auipc	ra,0xffffe
    80007fce:	6e8080e7          	jalr	1768(ra) # 800066b2 <end_op>

            if (r < 0)
                break;
            if (r != n1)
    80007fd2:	049c1963          	bne	s8,s1,80008024 <filewrite+0xde>
                panic("short filewrite");
            i += r;
    80007fd6:	013489bb          	addw	s3,s1,s3
        while (i < n)
    80007fda:	0349d663          	bge	s3,s4,80008006 <filewrite+0xc0>
            int n1 = n - i;
    80007fde:	413a07bb          	subw	a5,s4,s3
            if (n1 > max)
    80007fe2:	84be                	mv	s1,a5
    80007fe4:	2781                	sext.w	a5,a5
    80007fe6:	f8fb5ce3          	bge	s6,a5,80007f7e <filewrite+0x38>
    80007fea:	84de                	mv	s1,s7
    80007fec:	bf49                	j	80007f7e <filewrite+0x38>
            iunlock(f->ip);
    80007fee:	01093503          	ld	a0,16(s2)
    80007ff2:	fffff097          	auipc	ra,0xfffff
    80007ff6:	b4a080e7          	jalr	-1206(ra) # 80006b3c <iunlock>
            end_op();
    80007ffa:	ffffe097          	auipc	ra,0xffffe
    80007ffe:	6b8080e7          	jalr	1720(ra) # 800066b2 <end_op>
            if (r < 0)
    80008002:	fc04d8e3          	bgez	s1,80007fd2 <filewrite+0x8c>
        }
        ret = (i == n ? n : -1);
    80008006:	033a1963          	bne	s4,s3,80008038 <filewrite+0xf2>
    {
        panic("filewrite");
    }

    return ret;
}
    8000800a:	8552                	mv	a0,s4
    8000800c:	60a6                	ld	ra,72(sp)
    8000800e:	6406                	ld	s0,64(sp)
    80008010:	74e2                	ld	s1,56(sp)
    80008012:	7942                	ld	s2,48(sp)
    80008014:	79a2                	ld	s3,40(sp)
    80008016:	7a02                	ld	s4,32(sp)
    80008018:	6ae2                	ld	s5,24(sp)
    8000801a:	6b42                	ld	s6,16(sp)
    8000801c:	6ba2                	ld	s7,8(sp)
    8000801e:	6c02                	ld	s8,0(sp)
    80008020:	6161                	addi	sp,sp,80
    80008022:	8082                	ret
                panic("short filewrite");
    80008024:	00007517          	auipc	a0,0x7
    80008028:	80c50513          	addi	a0,a0,-2036 # 8000e830 <digits+0x4680>
    8000802c:	ffffb097          	auipc	ra,0xffffb
    80008030:	a60080e7          	jalr	-1440(ra) # 80002a8c <panic>
        int i = 0;
    80008034:	4981                	li	s3,0
    80008036:	bfc1                	j	80008006 <filewrite+0xc0>
        ret = (i == n ? n : -1);
    80008038:	5a7d                	li	s4,-1
    8000803a:	bfc1                	j	8000800a <filewrite+0xc4>
        panic("filewrite");
    8000803c:	00007517          	auipc	a0,0x7
    80008040:	80450513          	addi	a0,a0,-2044 # 8000e840 <digits+0x4690>
    80008044:	ffffb097          	auipc	ra,0xffffb
    80008048:	a48080e7          	jalr	-1464(ra) # 80002a8c <panic>
        return -1;
    8000804c:	5a7d                	li	s4,-1
    8000804e:	bf75                	j	8000800a <filewrite+0xc4>

0000000080008050 <filestat>:
// 获取文件统计信息
int filestat(struct file *f, uint64 addr)
{
    struct stat st;

    if (f->type == FD_INODE)
    80008050:	4118                	lw	a4,0(a0)
    80008052:	4789                	li	a5,2
    80008054:	08f71f63          	bne	a4,a5,800080f2 <filestat+0xa2>
{
    80008058:	715d                	addi	sp,sp,-80
    8000805a:	e486                	sd	ra,72(sp)
    8000805c:	e0a2                	sd	s0,64(sp)
    8000805e:	fc26                	sd	s1,56(sp)
    80008060:	f84a                	sd	s2,48(sp)
    80008062:	f44e                	sd	s3,40(sp)
    80008064:	0880                	addi	s0,sp,80
    80008066:	892a                	mv	s2,a0
    80008068:	84ae                	mv	s1,a1
    {
        ilock(f->ip);
    8000806a:	6908                	ld	a0,16(a0)
    8000806c:	fffff097          	auipc	ra,0xfffff
    80008070:	9d6080e7          	jalr	-1578(ra) # 80006a42 <ilock>
        stati(f->ip, &st);
    80008074:	fb840993          	addi	s3,s0,-72
    80008078:	85ce                	mv	a1,s3
    8000807a:	01093503          	ld	a0,16(s2)
    8000807e:	00000097          	auipc	ra,0x0
    80008082:	834080e7          	jalr	-1996(ra) # 800078b2 <stati>
        iunlock(f->ip);
    80008086:	01093503          	ld	a0,16(s2)
    8000808a:	fffff097          	auipc	ra,0xfffff
    8000808e:	ab2080e7          	jalr	-1358(ra) # 80006b3c <iunlock>
    if (s < d && s + n > d)
    80008092:	0299f463          	bgeu	s3,s1,800080ba <filestat+0x6a>
    80008096:	fd040713          	addi	a4,s0,-48
    8000809a:	04e4f963          	bgeu	s1,a4,800080ec <filestat+0x9c>
        s += n;
    8000809e:	87ba                	mv	a5,a4
            *--d = *--s;
    800080a0:	86ce                	mv	a3,s3
    800080a2:	17fd                	addi	a5,a5,-1
    800080a4:	40d78733          	sub	a4,a5,a3
    800080a8:	9726                	add	a4,a4,s1
    800080aa:	0007c603          	lbu	a2,0(a5)
    800080ae:	00c70023          	sb	a2,0(a4)
        while (n-- > 0)
    800080b2:	fed798e3          	bne	a5,a3,800080a2 <filestat+0x52>
        // 简化：直接复制到地址
        memmove((void *)addr, (void *)&st, sizeof(st));
        return 0;
    800080b6:	4501                	li	a0,0
    800080b8:	a01d                	j	800080de <filestat+0x8e>
    800080ba:	fb840793          	addi	a5,s0,-72
    800080be:	fb840593          	addi	a1,s0,-72
    800080c2:	40b485b3          	sub	a1,s1,a1
    800080c6:	00b78733          	add	a4,a5,a1
            *d++ = *s++;
    800080ca:	0785                	addi	a5,a5,1
    800080cc:	fff7c683          	lbu	a3,-1(a5)
    800080d0:	00d70023          	sb	a3,0(a4)
        while (n-- > 0)
    800080d4:	fd040713          	addi	a4,s0,-48
    800080d8:	fee797e3          	bne	a5,a4,800080c6 <filestat+0x76>
        return 0;
    800080dc:	4501                	li	a0,0
    }
    return -1;
}
    800080de:	60a6                	ld	ra,72(sp)
    800080e0:	6406                	ld	s0,64(sp)
    800080e2:	74e2                	ld	s1,56(sp)
    800080e4:	7942                	ld	s2,48(sp)
    800080e6:	79a2                	ld	s3,40(sp)
    800080e8:	6161                	addi	sp,sp,80
    800080ea:	8082                	ret
    800080ec:	fb840793          	addi	a5,s0,-72
    800080f0:	b7f9                	j	800080be <filestat+0x6e>
    return -1;
    800080f2:	557d                	li	a0,-1
}
    800080f4:	8082                	ret

00000000800080f6 <sys_close>:

// 根据文件描述符获取file结构
static struct file *
fd2file(int fd)
{
    if (fd < 0 || fd >= NFILE)
    800080f6:	06300713          	li	a4,99
    800080fa:	02a76a63          	bltu	a4,a0,8000812e <sys_close+0x38>
        return 0;

    struct file *f = &ftable.file[fd];
    800080fe:	0516                	slli	a0,a0,0x5
    80008100:	0045c797          	auipc	a5,0x45c
    80008104:	e0878793          	addi	a5,a5,-504 # 80463f08 <ftable>
    80008108:	953e                	add	a0,a0,a5
    if (f->ref < 1)
    8000810a:	415c                	lw	a5,4(a0)
    8000810c:	00f05f63          	blez	a5,8000812a <sys_close+0x34>
    return f;
}

// 系统调用：关闭文件
int sys_close(int fd)
{
    80008110:	1141                	addi	sp,sp,-16
    80008112:	e406                	sd	ra,8(sp)
    80008114:	e022                	sd	s0,0(sp)
    80008116:	0800                	addi	s0,sp,16
    struct file *f = fd2file(fd);

    if (f == 0)
        return -1;
    fileclose(f);
    80008118:	00000097          	auipc	ra,0x0
    8000811c:	d22080e7          	jalr	-734(ra) # 80007e3a <fileclose>
    return 0;
    80008120:	4501                	li	a0,0
}
    80008122:	60a2                	ld	ra,8(sp)
    80008124:	6402                	ld	s0,0(sp)
    80008126:	0141                	addi	sp,sp,16
    80008128:	8082                	ret
        return -1;
    8000812a:	557d                	li	a0,-1
    8000812c:	8082                	ret
    8000812e:	557d                	li	a0,-1
}
    80008130:	8082                	ret

0000000080008132 <sys_read>:
    if (fd < 0 || fd >= NFILE)
    80008132:	06300713          	li	a4,99
    80008136:	02a76963          	bltu	a4,a0,80008168 <sys_read+0x36>
    struct file *f = &ftable.file[fd];
    8000813a:	0516                	slli	a0,a0,0x5
    8000813c:	0045c797          	auipc	a5,0x45c
    80008140:	dcc78793          	addi	a5,a5,-564 # 80463f08 <ftable>
    80008144:	953e                	add	a0,a0,a5
    if (f->ref < 1)
    80008146:	415c                	lw	a5,4(a0)
    80008148:	00f05e63          	blez	a5,80008164 <sys_read+0x32>

// 系统调用：读取文件
int sys_read(int fd, char *p, int n)
{
    8000814c:	1141                	addi	sp,sp,-16
    8000814e:	e406                	sd	ra,8(sp)
    80008150:	e022                	sd	s0,0(sp)
    80008152:	0800                	addi	s0,sp,16
    struct file *f = fd2file(fd);

    if (f == 0)
        return -1;
    return fileread(f, (uint64)p, n);
    80008154:	00000097          	auipc	ra,0x0
    80008158:	d7a080e7          	jalr	-646(ra) # 80007ece <fileread>
}
    8000815c:	60a2                	ld	ra,8(sp)
    8000815e:	6402                	ld	s0,0(sp)
    80008160:	0141                	addi	sp,sp,16
    80008162:	8082                	ret
        return -1;
    80008164:	557d                	li	a0,-1
    80008166:	8082                	ret
    80008168:	557d                	li	a0,-1
}
    8000816a:	8082                	ret

000000008000816c <sys_write>:
    if (fd < 0 || fd >= NFILE)
    8000816c:	06300713          	li	a4,99
    80008170:	02a76963          	bltu	a4,a0,800081a2 <sys_write+0x36>
    struct file *f = &ftable.file[fd];
    80008174:	0516                	slli	a0,a0,0x5
    80008176:	0045c797          	auipc	a5,0x45c
    8000817a:	d9278793          	addi	a5,a5,-622 # 80463f08 <ftable>
    8000817e:	953e                	add	a0,a0,a5
    if (f->ref < 1)
    80008180:	415c                	lw	a5,4(a0)
    80008182:	00f05e63          	blez	a5,8000819e <sys_write+0x32>

// 系统调用：写入文件
int sys_write(int fd, char *p, int n)
{
    80008186:	1141                	addi	sp,sp,-16
    80008188:	e406                	sd	ra,8(sp)
    8000818a:	e022                	sd	s0,0(sp)
    8000818c:	0800                	addi	s0,sp,16
    struct file *f = fd2file(fd);

    if (f == 0)
        return -1;
    return filewrite(f, (uint64)p, n);
    8000818e:	00000097          	auipc	ra,0x0
    80008192:	db8080e7          	jalr	-584(ra) # 80007f46 <filewrite>
}
    80008196:	60a2                	ld	ra,8(sp)
    80008198:	6402                	ld	s0,0(sp)
    8000819a:	0141                	addi	sp,sp,16
    8000819c:	8082                	ret
        return -1;
    8000819e:	557d                	li	a0,-1
    800081a0:	8082                	ret
    800081a2:	557d                	li	a0,-1
}
    800081a4:	8082                	ret

00000000800081a6 <create>:

// 创建文件或目录（参考xv6实现）
struct inode *
create(char *path, short type, short major, short minor)
{
    800081a6:	7139                	addi	sp,sp,-64
    800081a8:	fc06                	sd	ra,56(sp)
    800081aa:	f822                	sd	s0,48(sp)
    800081ac:	f426                	sd	s1,40(sp)
    800081ae:	f04a                	sd	s2,32(sp)
    800081b0:	ec4e                	sd	s3,24(sp)
    800081b2:	e852                	sd	s4,16(sp)
    800081b4:	0080                	addi	s0,sp,64
    800081b6:	89ae                	mv	s3,a1
    struct inode *ip, *dp;
    char name[DIRSIZ];

    if ((dp = nameiparent(path, name)) == 0)
    800081b8:	fc040593          	addi	a1,s0,-64
    800081bc:	fffff097          	auipc	ra,0xfffff
    800081c0:	6da080e7          	jalr	1754(ra) # 80007896 <nameiparent>
    800081c4:	892a                	mv	s2,a0
    800081c6:	14050463          	beqz	a0,8000830e <create+0x168>
    {
        return 0;
    }

    // 确保 name 被正确设置
    if (name[0] == 0)
    800081ca:	fc044783          	lbu	a5,-64(s0)
    800081ce:	cfb9                	beqz	a5,8000822c <create+0x86>
        iput(dp);
        return 0;
    }

    // nameiparent 返回的 dp 是未锁定的，需要锁定
    ilock(dp);
    800081d0:	fffff097          	auipc	ra,0xfffff
    800081d4:	872080e7          	jalr	-1934(ra) # 80006a42 <ilock>

    if ((ip = dirlookup(dp, name, 0)) != 0)
    800081d8:	4601                	li	a2,0
    800081da:	fc040593          	addi	a1,s0,-64
    800081de:	854a                	mv	a0,s2
    800081e0:	fffff097          	auipc	ra,0xfffff
    800081e4:	fd0080e7          	jalr	-48(ra) # 800071b0 <dirlookup>
    800081e8:	84aa                	mv	s1,a0
    800081ea:	cd31                	beqz	a0,80008246 <create+0xa0>
    {
        iunlockput(dp);
    800081ec:	854a                	mv	a0,s2
    800081ee:	fffff097          	auipc	ra,0xfffff
    800081f2:	4fa080e7          	jalr	1274(ra) # 800076e8 <iunlockput>
        ilock(ip);
    800081f6:	8526                	mv	a0,s1
    800081f8:	fffff097          	auipc	ra,0xfffff
    800081fc:	84a080e7          	jalr	-1974(ra) # 80006a42 <ilock>
        if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEV))
    80008200:	0009859b          	sext.w	a1,s3
    80008204:	4789                	li	a5,2
    80008206:	02f59963          	bne	a1,a5,80008238 <create+0x92>
    8000820a:	0444d783          	lhu	a5,68(s1)
    8000820e:	37f9                	addiw	a5,a5,-2
    80008210:	17c2                	slli	a5,a5,0x30
    80008212:	93c1                	srli	a5,a5,0x30
    80008214:	4705                	li	a4,1
    80008216:	02f76163          	bltu	a4,a5,80008238 <create+0x92>
    }

    iunlockput(dp);

    return ip;
}
    8000821a:	8526                	mv	a0,s1
    8000821c:	70e2                	ld	ra,56(sp)
    8000821e:	7442                	ld	s0,48(sp)
    80008220:	74a2                	ld	s1,40(sp)
    80008222:	7902                	ld	s2,32(sp)
    80008224:	69e2                	ld	s3,24(sp)
    80008226:	6a42                	ld	s4,16(sp)
    80008228:	6121                	addi	sp,sp,64
    8000822a:	8082                	ret
        iput(dp);
    8000822c:	fffff097          	auipc	ra,0xfffff
    80008230:	286080e7          	jalr	646(ra) # 800074b2 <iput>
        return 0;
    80008234:	4481                	li	s1,0
    80008236:	b7d5                	j	8000821a <create+0x74>
        iunlockput(ip);
    80008238:	8526                	mv	a0,s1
    8000823a:	fffff097          	auipc	ra,0xfffff
    8000823e:	4ae080e7          	jalr	1198(ra) # 800076e8 <iunlockput>
        return 0;
    80008242:	4481                	li	s1,0
    80008244:	bfd9                	j	8000821a <create+0x74>
    if ((ip = ialloc(dp->dev, type)) == 0)
    80008246:	85ce                	mv	a1,s3
    80008248:	00092503          	lw	a0,0(s2)
    8000824c:	fffff097          	auipc	ra,0xfffff
    80008250:	9f8080e7          	jalr	-1544(ra) # 80006c44 <ialloc>
    80008254:	84aa                	mv	s1,a0
    80008256:	c129                	beqz	a0,80008298 <create+0xf2>
    ilock(ip);
    80008258:	ffffe097          	auipc	ra,0xffffe
    8000825c:	7ea080e7          	jalr	2026(ra) # 80006a42 <ilock>
    ip->nlink = 1;
    80008260:	4a05                	li	s4,1
    80008262:	05449323          	sh	s4,70(s1)
    iupdate(ip);
    80008266:	8526                	mv	a0,s1
    80008268:	fffff097          	auipc	ra,0xfffff
    8000826c:	b30080e7          	jalr	-1232(ra) # 80006d98 <iupdate>
    if (type == T_DIR)
    80008270:	0009859b          	sext.w	a1,s3
    80008274:	03458a63          	beq	a1,s4,800082a8 <create+0x102>
    if (dirlink(dp, name, ip->inum) < 0)
    80008278:	40d0                	lw	a2,4(s1)
    8000827a:	fc040593          	addi	a1,s0,-64
    8000827e:	854a                	mv	a0,s2
    80008280:	fffff097          	auipc	ra,0xfffff
    80008284:	2d2080e7          	jalr	722(ra) # 80007552 <dirlink>
    80008288:	06054b63          	bltz	a0,800082fe <create+0x158>
    iunlockput(dp);
    8000828c:	854a                	mv	a0,s2
    8000828e:	fffff097          	auipc	ra,0xfffff
    80008292:	45a080e7          	jalr	1114(ra) # 800076e8 <iunlockput>
    return ip;
    80008296:	b751                	j	8000821a <create+0x74>
        panic("create: ialloc");
    80008298:	00006517          	auipc	a0,0x6
    8000829c:	5b850513          	addi	a0,a0,1464 # 8000e850 <digits+0x46a0>
    800082a0:	ffffa097          	auipc	ra,0xffffa
    800082a4:	7ec080e7          	jalr	2028(ra) # 80002a8c <panic>
        dp->nlink++;
    800082a8:	04695783          	lhu	a5,70(s2)
    800082ac:	2785                	addiw	a5,a5,1
    800082ae:	04f91323          	sh	a5,70(s2)
        iupdate(dp);
    800082b2:	854a                	mv	a0,s2
    800082b4:	fffff097          	auipc	ra,0xfffff
    800082b8:	ae4080e7          	jalr	-1308(ra) # 80006d98 <iupdate>
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800082bc:	40d0                	lw	a2,4(s1)
    800082be:	00006597          	auipc	a1,0x6
    800082c2:	4ea58593          	addi	a1,a1,1258 # 8000e7a8 <digits+0x45f8>
    800082c6:	8526                	mv	a0,s1
    800082c8:	fffff097          	auipc	ra,0xfffff
    800082cc:	28a080e7          	jalr	650(ra) # 80007552 <dirlink>
    800082d0:	00054f63          	bltz	a0,800082ee <create+0x148>
    800082d4:	00492603          	lw	a2,4(s2)
    800082d8:	00006597          	auipc	a1,0x6
    800082dc:	4d858593          	addi	a1,a1,1240 # 8000e7b0 <digits+0x4600>
    800082e0:	8526                	mv	a0,s1
    800082e2:	fffff097          	auipc	ra,0xfffff
    800082e6:	270080e7          	jalr	624(ra) # 80007552 <dirlink>
    800082ea:	f80557e3          	bgez	a0,80008278 <create+0xd2>
            panic("create dots");
    800082ee:	00006517          	auipc	a0,0x6
    800082f2:	57250513          	addi	a0,a0,1394 # 8000e860 <digits+0x46b0>
    800082f6:	ffffa097          	auipc	ra,0xffffa
    800082fa:	796080e7          	jalr	1942(ra) # 80002a8c <panic>
        panic("create: dirlink");
    800082fe:	00006517          	auipc	a0,0x6
    80008302:	57250513          	addi	a0,a0,1394 # 8000e870 <digits+0x46c0>
    80008306:	ffffa097          	auipc	ra,0xffffa
    8000830a:	786080e7          	jalr	1926(ra) # 80002a8c <panic>
        return 0;
    8000830e:	84aa                	mv	s1,a0
    80008310:	b729                	j	8000821a <create+0x74>

0000000080008312 <sys_open>:
{
    80008312:	7179                	addi	sp,sp,-48
    80008314:	f406                	sd	ra,40(sp)
    80008316:	f022                	sd	s0,32(sp)
    80008318:	ec26                	sd	s1,24(sp)
    8000831a:	e84a                	sd	s2,16(sp)
    8000831c:	e44e                	sd	s3,8(sp)
    8000831e:	1800                	addi	s0,sp,48
    80008320:	84aa                	mv	s1,a0
    80008322:	892e                	mv	s2,a1
    begin_op();
    80008324:	ffffe097          	auipc	ra,0xffffe
    80008328:	2fe080e7          	jalr	766(ra) # 80006622 <begin_op>
    if (omode & O_CREATE)
    8000832c:	20097793          	andi	a5,s2,512
    80008330:	c3cd                	beqz	a5,800083d2 <sys_open+0xc0>
        ip = create(path, T_FILE, 0, 0);
    80008332:	4681                	li	a3,0
    80008334:	4601                	li	a2,0
    80008336:	4589                	li	a1,2
    80008338:	8526                	mv	a0,s1
    8000833a:	00000097          	auipc	ra,0x0
    8000833e:	e6c080e7          	jalr	-404(ra) # 800081a6 <create>
    80008342:	89aa                	mv	s3,a0
        if (ip == 0)
    80008344:	c149                	beqz	a0,800083c6 <sys_open+0xb4>
    if ((f = filealloc()) == 0)
    80008346:	00000097          	auipc	ra,0x0
    8000834a:	a38080e7          	jalr	-1480(ra) # 80007d7e <filealloc>
    8000834e:	84aa                	mv	s1,a0
    80008350:	c561                	beqz	a0,80008418 <sys_open+0x106>
    if (ip->type == T_DEV)
    80008352:	04499703          	lh	a4,68(s3)
    80008356:	478d                	li	a5,3
    80008358:	0cf70b63          	beq	a4,a5,8000842e <sys_open+0x11c>
        f->type = FD_INODE;
    8000835c:	4789                	li	a5,2
    8000835e:	c11c                	sw	a5,0(a0)
        f->off = 0;
    80008360:	00052c23          	sw	zero,24(a0)
    f->ip = ip;
    80008364:	0134b823          	sd	s3,16(s1)
    f->readable = !(omode & O_WRONLY);
    80008368:	00194793          	xori	a5,s2,1
    8000836c:	8b85                	andi	a5,a5,1
    8000836e:	00f48423          	sb	a5,8(s1)
    f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80008372:	00397793          	andi	a5,s2,3
    80008376:	00f037b3          	snez	a5,a5
    8000837a:	00f484a3          	sb	a5,9(s1)
    if ((omode & O_TRUNC) && ip->type == T_FILE)
    8000837e:	40097593          	andi	a1,s2,1024
    80008382:	c591                	beqz	a1,8000838e <sys_open+0x7c>
    80008384:	04499703          	lh	a4,68(s3)
    80008388:	4789                	li	a5,2
    8000838a:	0af70663          	beq	a4,a5,80008436 <sys_open+0x124>
    iunlock(ip);
    8000838e:	854e                	mv	a0,s3
    80008390:	ffffe097          	auipc	ra,0xffffe
    80008394:	7ac080e7          	jalr	1964(ra) # 80006b3c <iunlock>
    end_op();
    80008398:	ffffe097          	auipc	ra,0xffffe
    8000839c:	31a080e7          	jalr	794(ra) # 800066b2 <end_op>
    int fd = (int)(f - ftable.file);
    800083a0:	0045c517          	auipc	a0,0x45c
    800083a4:	b6850513          	addi	a0,a0,-1176 # 80463f08 <ftable>
    800083a8:	40a48533          	sub	a0,s1,a0
    800083ac:	8515                	srai	a0,a0,0x5
    800083ae:	2501                	sext.w	a0,a0
    if (fd < 0 || fd >= NFILE)
    800083b0:	06300793          	li	a5,99
    800083b4:	08a7e763          	bltu	a5,a0,80008442 <sys_open+0x130>
}
    800083b8:	70a2                	ld	ra,40(sp)
    800083ba:	7402                	ld	s0,32(sp)
    800083bc:	64e2                	ld	s1,24(sp)
    800083be:	6942                	ld	s2,16(sp)
    800083c0:	69a2                	ld	s3,8(sp)
    800083c2:	6145                	addi	sp,sp,48
    800083c4:	8082                	ret
            end_op();
    800083c6:	ffffe097          	auipc	ra,0xffffe
    800083ca:	2ec080e7          	jalr	748(ra) # 800066b2 <end_op>
            return -1;
    800083ce:	557d                	li	a0,-1
    800083d0:	b7e5                	j	800083b8 <sys_open+0xa6>
        if ((ip = namei(path)) == 0)
    800083d2:	8526                	mv	a0,s1
    800083d4:	fffff097          	auipc	ra,0xfffff
    800083d8:	4a4080e7          	jalr	1188(ra) # 80007878 <namei>
    800083dc:	89aa                	mv	s3,a0
    800083de:	c51d                	beqz	a0,8000840c <sys_open+0xfa>
        ilock(ip);
    800083e0:	ffffe097          	auipc	ra,0xffffe
    800083e4:	662080e7          	jalr	1634(ra) # 80006a42 <ilock>
        if (ip->type == T_DIR && omode != O_RDONLY)
    800083e8:	04499703          	lh	a4,68(s3)
    800083ec:	4785                	li	a5,1
    800083ee:	f4f71ce3          	bne	a4,a5,80008346 <sys_open+0x34>
    800083f2:	f4090ae3          	beqz	s2,80008346 <sys_open+0x34>
            iunlockput(ip);
    800083f6:	854e                	mv	a0,s3
    800083f8:	fffff097          	auipc	ra,0xfffff
    800083fc:	2f0080e7          	jalr	752(ra) # 800076e8 <iunlockput>
            end_op();
    80008400:	ffffe097          	auipc	ra,0xffffe
    80008404:	2b2080e7          	jalr	690(ra) # 800066b2 <end_op>
            return -1;
    80008408:	557d                	li	a0,-1
    8000840a:	b77d                	j	800083b8 <sys_open+0xa6>
            end_op();
    8000840c:	ffffe097          	auipc	ra,0xffffe
    80008410:	2a6080e7          	jalr	678(ra) # 800066b2 <end_op>
            return -1;
    80008414:	557d                	li	a0,-1
    80008416:	b74d                	j	800083b8 <sys_open+0xa6>
        iunlockput(ip);
    80008418:	854e                	mv	a0,s3
    8000841a:	fffff097          	auipc	ra,0xfffff
    8000841e:	2ce080e7          	jalr	718(ra) # 800076e8 <iunlockput>
        end_op();
    80008422:	ffffe097          	auipc	ra,0xffffe
    80008426:	290080e7          	jalr	656(ra) # 800066b2 <end_op>
        return -1;
    8000842a:	557d                	li	a0,-1
    8000842c:	b771                	j	800083b8 <sys_open+0xa6>
        f->type = FD_DEVICE;
    8000842e:	c11c                	sw	a5,0(a0)
        f->major = 0; // 简化
    80008430:	00051e23          	sh	zero,28(a0)
    80008434:	bf05                	j	80008364 <sys_open+0x52>
        itrunc(ip);
    80008436:	854e                	mv	a0,s3
    80008438:	fffff097          	auipc	ra,0xfffff
    8000843c:	fc4080e7          	jalr	-60(ra) # 800073fc <itrunc>
    80008440:	b7b9                	j	8000838e <sys_open+0x7c>
        panic("sys_open: invalid fd");
    80008442:	00006517          	auipc	a0,0x6
    80008446:	43e50513          	addi	a0,a0,1086 # 8000e880 <digits+0x46d0>
    8000844a:	ffffa097          	auipc	ra,0xffffa
    8000844e:	642080e7          	jalr	1602(ra) # 80002a8c <panic>

0000000080008452 <sys_unlink>:

// 系统调用：删除文件
int sys_unlink(char *path)
{
    80008452:	715d                	addi	sp,sp,-80
    80008454:	e486                	sd	ra,72(sp)
    80008456:	e0a2                	sd	s0,64(sp)
    80008458:	fc26                	sd	s1,56(sp)
    8000845a:	f84a                	sd	s2,48(sp)
    8000845c:	f44e                	sd	s3,40(sp)
    8000845e:	0880                	addi	s0,sp,80
    80008460:	84aa                	mv	s1,a0
    struct inode *ip, *dp;
    char name[DIRSIZ];
    uint off;

    begin_op();
    80008462:	ffffe097          	auipc	ra,0xffffe
    80008466:	1c0080e7          	jalr	448(ra) # 80006622 <begin_op>
    if ((dp = nameiparent(path, name)) == 0)
    8000846a:	fc040593          	addi	a1,s0,-64
    8000846e:	8526                	mv	a0,s1
    80008470:	fffff097          	auipc	ra,0xfffff
    80008474:	426080e7          	jalr	1062(ra) # 80007896 <nameiparent>
    80008478:	cd59                	beqz	a0,80008516 <sys_unlink+0xc4>
    8000847a:	892a                	mv	s2,a0
    {
        end_op();
        return -1;
    }

    ilock(dp);
    8000847c:	ffffe097          	auipc	ra,0xffffe
    80008480:	5c6080e7          	jalr	1478(ra) # 80006a42 <ilock>

    if ((ip = dirlookup(dp, name, &off)) == 0)
    80008484:	fbc40613          	addi	a2,s0,-68
    80008488:	fc040593          	addi	a1,s0,-64
    8000848c:	854a                	mv	a0,s2
    8000848e:	fffff097          	auipc	ra,0xfffff
    80008492:	d22080e7          	jalr	-734(ra) # 800071b0 <dirlookup>
    80008496:	84aa                	mv	s1,a0
    80008498:	c549                	beqz	a0,80008522 <sys_unlink+0xd0>
        iunlockput(dp);
        end_op();
        return -1;
    }

    ilock(ip);
    8000849a:	ffffe097          	auipc	ra,0xffffe
    8000849e:	5a8080e7          	jalr	1448(ra) # 80006a42 <ilock>
    if (ip->nlink < 1)
    800084a2:	04649783          	lh	a5,70(s1)
    800084a6:	08f05963          	blez	a5,80008538 <sys_unlink+0xe6>
        panic("unlink: nlink < 1");
    if (ip->type == T_DIR)
    800084aa:	04449703          	lh	a4,68(s1)
    800084ae:	4785                	li	a5,1
    800084b0:	08f70c63          	beq	a4,a5,80008548 <sys_unlink+0xf6>
        iunlockput(dp);
        end_op();
        return -1;
    }

    if (dirunlink(dp, name) == -1)
    800084b4:	fc040593          	addi	a1,s0,-64
    800084b8:	854a                	mv	a0,s2
    800084ba:	fffff097          	auipc	ra,0xfffff
    800084be:	17e080e7          	jalr	382(ra) # 80007638 <dirunlink>
    800084c2:	89aa                	mv	s3,a0
    800084c4:	57fd                	li	a5,-1
    800084c6:	0af50163          	beq	a0,a5,80008568 <sys_unlink+0x116>
        iunlockput(dp);
        end_op();
        return -1;
    }

    iupdate(dp);
    800084ca:	854a                	mv	a0,s2
    800084cc:	fffff097          	auipc	ra,0xfffff
    800084d0:	8cc080e7          	jalr	-1844(ra) # 80006d98 <iupdate>
    iunlockput(dp);
    800084d4:	854a                	mv	a0,s2
    800084d6:	fffff097          	auipc	ra,0xfffff
    800084da:	212080e7          	jalr	530(ra) # 800076e8 <iunlockput>

    ip->nlink--;
    800084de:	0464d783          	lhu	a5,70(s1)
    800084e2:	37fd                	addiw	a5,a5,-1
    800084e4:	04f49323          	sh	a5,70(s1)
    iupdate(ip);
    800084e8:	8526                	mv	a0,s1
    800084ea:	fffff097          	auipc	ra,0xfffff
    800084ee:	8ae080e7          	jalr	-1874(ra) # 80006d98 <iupdate>
    iunlockput(ip);
    800084f2:	8526                	mv	a0,s1
    800084f4:	fffff097          	auipc	ra,0xfffff
    800084f8:	1f4080e7          	jalr	500(ra) # 800076e8 <iunlockput>

    end_op();
    800084fc:	ffffe097          	auipc	ra,0xffffe
    80008500:	1b6080e7          	jalr	438(ra) # 800066b2 <end_op>
    return 0;
    80008504:	4981                	li	s3,0
}
    80008506:	854e                	mv	a0,s3
    80008508:	60a6                	ld	ra,72(sp)
    8000850a:	6406                	ld	s0,64(sp)
    8000850c:	74e2                	ld	s1,56(sp)
    8000850e:	7942                	ld	s2,48(sp)
    80008510:	79a2                	ld	s3,40(sp)
    80008512:	6161                	addi	sp,sp,80
    80008514:	8082                	ret
        end_op();
    80008516:	ffffe097          	auipc	ra,0xffffe
    8000851a:	19c080e7          	jalr	412(ra) # 800066b2 <end_op>
        return -1;
    8000851e:	59fd                	li	s3,-1
    80008520:	b7dd                	j	80008506 <sys_unlink+0xb4>
        iunlockput(dp);
    80008522:	854a                	mv	a0,s2
    80008524:	fffff097          	auipc	ra,0xfffff
    80008528:	1c4080e7          	jalr	452(ra) # 800076e8 <iunlockput>
        end_op();
    8000852c:	ffffe097          	auipc	ra,0xffffe
    80008530:	186080e7          	jalr	390(ra) # 800066b2 <end_op>
        return -1;
    80008534:	59fd                	li	s3,-1
    80008536:	bfc1                	j	80008506 <sys_unlink+0xb4>
        panic("unlink: nlink < 1");
    80008538:	00006517          	auipc	a0,0x6
    8000853c:	36050513          	addi	a0,a0,864 # 8000e898 <digits+0x46e8>
    80008540:	ffffa097          	auipc	ra,0xffffa
    80008544:	54c080e7          	jalr	1356(ra) # 80002a8c <panic>
        iunlockput(ip);
    80008548:	8526                	mv	a0,s1
    8000854a:	fffff097          	auipc	ra,0xfffff
    8000854e:	19e080e7          	jalr	414(ra) # 800076e8 <iunlockput>
        iunlockput(dp);
    80008552:	854a                	mv	a0,s2
    80008554:	fffff097          	auipc	ra,0xfffff
    80008558:	194080e7          	jalr	404(ra) # 800076e8 <iunlockput>
        end_op();
    8000855c:	ffffe097          	auipc	ra,0xffffe
    80008560:	156080e7          	jalr	342(ra) # 800066b2 <end_op>
        return -1;
    80008564:	59fd                	li	s3,-1
    80008566:	b745                	j	80008506 <sys_unlink+0xb4>
        iunlockput(ip);
    80008568:	8526                	mv	a0,s1
    8000856a:	fffff097          	auipc	ra,0xfffff
    8000856e:	17e080e7          	jalr	382(ra) # 800076e8 <iunlockput>
        iunlockput(dp);
    80008572:	854a                	mv	a0,s2
    80008574:	fffff097          	auipc	ra,0xfffff
    80008578:	174080e7          	jalr	372(ra) # 800076e8 <iunlockput>
        end_op();
    8000857c:	ffffe097          	auipc	ra,0xffffe
    80008580:	136080e7          	jalr	310(ra) # 800066b2 <end_op>
        return -1;
    80008584:	b749                	j	80008506 <sys_unlink+0xb4>

0000000080008586 <sys_mkdir>:

// 系统调用：创建目录
int sys_mkdir(char *path)
{
    80008586:	1101                	addi	sp,sp,-32
    80008588:	ec06                	sd	ra,24(sp)
    8000858a:	e822                	sd	s0,16(sp)
    8000858c:	e426                	sd	s1,8(sp)
    8000858e:	1000                	addi	s0,sp,32
    80008590:	84aa                	mv	s1,a0
    struct inode *ip;

    begin_op();
    80008592:	ffffe097          	auipc	ra,0xffffe
    80008596:	090080e7          	jalr	144(ra) # 80006622 <begin_op>
    if ((ip = create(path, T_DIR, 0, 0)) == 0)
    8000859a:	4681                	li	a3,0
    8000859c:	4601                	li	a2,0
    8000859e:	4585                	li	a1,1
    800085a0:	8526                	mv	a0,s1
    800085a2:	00000097          	auipc	ra,0x0
    800085a6:	c04080e7          	jalr	-1020(ra) # 800081a6 <create>
    800085aa:	cd19                	beqz	a0,800085c8 <sys_mkdir+0x42>
    {
        end_op();
        return -1;
    }
    iunlockput(ip);
    800085ac:	fffff097          	auipc	ra,0xfffff
    800085b0:	13c080e7          	jalr	316(ra) # 800076e8 <iunlockput>
    end_op();
    800085b4:	ffffe097          	auipc	ra,0xffffe
    800085b8:	0fe080e7          	jalr	254(ra) # 800066b2 <end_op>
    return 0;
    800085bc:	4501                	li	a0,0
}
    800085be:	60e2                	ld	ra,24(sp)
    800085c0:	6442                	ld	s0,16(sp)
    800085c2:	64a2                	ld	s1,8(sp)
    800085c4:	6105                	addi	sp,sp,32
    800085c6:	8082                	ret
        end_op();
    800085c8:	ffffe097          	auipc	ra,0xffffe
    800085cc:	0ea080e7          	jalr	234(ra) # 800066b2 <end_op>
        return -1;
    800085d0:	557d                	li	a0,-1
    800085d2:	b7f5                	j	800085be <sys_mkdir+0x38>

00000000800085d4 <snprintf>:
    return *s - *t;
}


// 格式化字符串函数（简化版）
static void snprintf(char *buf, int size, const char *fmt, ...) {
    800085d4:	7175                	addi	sp,sp,-144
    800085d6:	eca2                	sd	s0,88(sp)
    800085d8:	e8a6                	sd	s1,80(sp)
    800085da:	e4ca                	sd	s2,72(sp)
    800085dc:	e0ce                	sd	s3,64(sp)
    800085de:	fc52                	sd	s4,56(sp)
    800085e0:	f856                	sd	s5,48(sp)
    800085e2:	1080                	addi	s0,sp,96
    800085e4:	e414                	sd	a3,8(s0)
    800085e6:	e818                	sd	a4,16(s0)
    800085e8:	ec1c                	sd	a5,24(s0)
    800085ea:	03043023          	sd	a6,32(s0)
    800085ee:	03143423          	sd	a7,40(s0)
    // 简化实现：只支持 %d 和 %s
    va_list args;
    va_start(args, fmt);
    800085f2:	00840793          	addi	a5,s0,8
    800085f6:	fcf43423          	sd	a5,-56(s0)
    char *p = buf;
    const char *f = fmt;
    int i = 0;
    
    while(*f && i < size - 1) {
    800085fa:	00064703          	lbu	a4,0(a2) # 1000 <_entry-0x7ffff000>
    800085fe:	10070563          	beqz	a4,80008708 <snprintf+0x134>
    80008602:	fff5831b          	addiw	t1,a1,-1
    80008606:	10605163          	blez	t1,80008708 <snprintf+0x134>
    int i = 0;
    8000860a:	4781                	li	a5,0
        if(*f == '%' && *(f+1) == 'd') {
    8000860c:	02500e13          	li	t3,37
    80008610:	06400f93          	li	t6,100
                    *p++ = temp[--j];
                    i++;
                }
            }
            f += 2;
        } else if(*f == '%' && *(f+1) == 's') {
    80008614:	07300493          	li	s1,115
    80008618:	889a                	mv	a7,t1
    8000861a:	fa840913          	addi	s2,s0,-88
    8000861e:	fc740393          	addi	t2,s0,-57
    80008622:	4f05                	li	t5,1
    80008624:	412f0f3b          	subw	t5,t5,s2
                    temp[j++] = '0' + (v % 10);
    80008628:	4ea9                	li	t4,10
                while(v > 0 && j < 31) {
    8000862a:	42a5                	li	t0,9
                    *p++ = '-';
    8000862c:	02d00a13          	li	s4,45
                *p++ = '0';
    80008630:	03000993          	li	s3,48
    80008634:	a8ad                	j	800086ae <snprintf+0xda>
                if(v < 0) {
    80008636:	0405c963          	bltz	a1,80008688 <snprintf+0xb4>
                    *p++ = '-';
    8000863a:	86ca                	mv	a3,s2
                    temp[j++] = '0' + (v % 10);
    8000863c:	00df073b          	addw	a4,t5,a3
    80008640:	00070a9b          	sext.w	s5,a4
    80008644:	8756                	mv	a4,s5
    80008646:	03d5e83b          	remw	a6,a1,t4
    8000864a:	0308081b          	addiw	a6,a6,48
    8000864e:	01068023          	sb	a6,0(a3)
                    v /= 10;
    80008652:	882e                	mv	a6,a1
    80008654:	03d5c5bb          	divw	a1,a1,t4
                while(v > 0 && j < 31) {
    80008658:	0102d563          	bge	t0,a6,80008662 <snprintf+0x8e>
    8000865c:	0685                	addi	a3,a3,1
    8000865e:	fc769fe3          	bne	a3,t2,8000863c <snprintf+0x68>
                while(j > 0 && i < size - 1) {
    80008662:	06e05863          	blez	a4,800086d2 <snprintf+0xfe>
    80008666:	974a                	add	a4,a4,s2
    80008668:	01578abb          	addw	s5,a5,s5
    8000866c:	0667d363          	bge	a5,t1,800086d2 <snprintf+0xfe>
                    *p++ = temp[--j];
    80008670:	0505                	addi	a0,a0,1
    80008672:	fff74683          	lbu	a3,-1(a4)
    80008676:	fed50fa3          	sb	a3,-1(a0)
                    i++;
    8000867a:	2785                	addiw	a5,a5,1
                while(j > 0 && i < size - 1) {
    8000867c:	04fa8b63          	beq	s5,a5,800086d2 <snprintf+0xfe>
    80008680:	177d                	addi	a4,a4,-1
    80008682:	fef897e3          	bne	a7,a5,80008670 <snprintf+0x9c>
    80008686:	a0b1                	j	800086d2 <snprintf+0xfe>
                    *p++ = '-';
    80008688:	01450023          	sb	s4,0(a0)
                    i++;
    8000868c:	2785                	addiw	a5,a5,1
                    v = -v;
    8000868e:	40b005bb          	negw	a1,a1
                    *p++ = '-';
    80008692:	0505                	addi	a0,a0,1
    80008694:	b75d                	j	8000863a <snprintf+0x66>
        } else if(*f == '%' && *(f+1) == 's') {
    80008696:	04968063          	beq	a3,s1,800086d6 <snprintf+0x102>
                *p++ = *str++;
                i++;
            }
            f += 2;
        } else {
            *p++ = *f++;
    8000869a:	0605                	addi	a2,a2,1
    8000869c:	00e50023          	sb	a4,0(a0)
            i++;
    800086a0:	2785                	addiw	a5,a5,1
            *p++ = *f++;
    800086a2:	0505                	addi	a0,a0,1
    while(*f && i < size - 1) {
    800086a4:	00064703          	lbu	a4,0(a2)
    800086a8:	c325                	beqz	a4,80008708 <snprintf+0x134>
    800086aa:	0467df63          	bge	a5,t1,80008708 <snprintf+0x134>
        if(*f == '%' && *(f+1) == 'd') {
    800086ae:	ffc716e3          	bne	a4,t3,8000869a <snprintf+0xc6>
    800086b2:	00164683          	lbu	a3,1(a2)
    800086b6:	fff690e3          	bne	a3,t6,80008696 <snprintf+0xc2>
            int val = va_arg(args, int);
    800086ba:	fc843703          	ld	a4,-56(s0)
    800086be:	00870693          	addi	a3,a4,8
    800086c2:	fcd43423          	sd	a3,-56(s0)
    800086c6:	430c                	lw	a1,0(a4)
            if(val == 0) {
    800086c8:	f5bd                	bnez	a1,80008636 <snprintf+0x62>
                *p++ = '0';
    800086ca:	01350023          	sb	s3,0(a0)
                i++;
    800086ce:	2785                	addiw	a5,a5,1
                *p++ = '0';
    800086d0:	0505                	addi	a0,a0,1
            f += 2;
    800086d2:	0609                	addi	a2,a2,2
        if(*f == '%' && *(f+1) == 'd') {
    800086d4:	bfc1                	j	800086a4 <snprintf+0xd0>
            const char *str = va_arg(args, const char*);
    800086d6:	fc843703          	ld	a4,-56(s0)
    800086da:	00870693          	addi	a3,a4,8
    800086de:	fcd43423          	sd	a3,-56(s0)
    800086e2:	6314                	ld	a3,0(a4)
            while(*str && i < size - 1) {
    800086e4:	0006c703          	lbu	a4,0(a3)
    800086e8:	cf11                	beqz	a4,80008704 <snprintf+0x130>
    800086ea:	0067dd63          	bge	a5,t1,80008704 <snprintf+0x130>
                *p++ = *str++;
    800086ee:	0685                	addi	a3,a3,1
    800086f0:	0505                	addi	a0,a0,1
    800086f2:	fee50fa3          	sb	a4,-1(a0)
                i++;
    800086f6:	2785                	addiw	a5,a5,1
            while(*str && i < size - 1) {
    800086f8:	0006c703          	lbu	a4,0(a3)
    800086fc:	c701                	beqz	a4,80008704 <snprintf+0x130>
    800086fe:	ff1798e3          	bne	a5,a7,800086ee <snprintf+0x11a>
                i++;
    80008702:	87c6                	mv	a5,a7
            f += 2;
    80008704:	0609                	addi	a2,a2,2
        } else if(*f == '%' && *(f+1) == 's') {
    80008706:	bf79                	j	800086a4 <snprintf+0xd0>
        }
    }
    *p = '\0';
    80008708:	00050023          	sb	zero,0(a0)
    va_end(args);
}
    8000870c:	6466                	ld	s0,88(sp)
    8000870e:	64c6                	ld	s1,80(sp)
    80008710:	6926                	ld	s2,72(sp)
    80008712:	6986                	ld	s3,64(sp)
    80008714:	7a62                	ld	s4,56(sp)
    80008716:	7ac2                	ld	s5,48(sp)
    80008718:	6149                	addi	sp,sp,144
    8000871a:	8082                	ret

000000008000871c <concurrent_test_worker>:
// ==================== 并发访问测试 ====================

static int concurrent_test_count = 0;
static int worker_pids[4] = {-1, -1, -1, -1};  // 存储每个 worker 的 PID

static void concurrent_test_worker(void) {
    8000871c:	7159                	addi	sp,sp,-112
    8000871e:	f486                	sd	ra,104(sp)
    80008720:	f0a2                	sd	s0,96(sp)
    80008722:	eca6                	sd	s1,88(sp)
    80008724:	e8ca                	sd	s2,80(sp)
    80008726:	e4ce                	sd	s3,72(sp)
    80008728:	e0d2                	sd	s4,64(sp)
    8000872a:	fc56                	sd	s5,56(sp)
    8000872c:	1880                	addi	s0,sp,112
    // 获取当前进程的 PID，用于查找对应的 worker ID
    extern struct proc* myproc(void);
    struct proc *p = myproc();
    8000872e:	ffffb097          	auipc	ra,0xffffb
    80008732:	3cc080e7          	jalr	972(ra) # 80003afa <myproc>
    80008736:	8a2a                	mv	s4,a0
    int worker_id = -1;
    
    // 根据 PID 查找对应的 worker ID
    for(int i = 0; i < 4; i++) {
        if(worker_pids[i] == p->pid) {
    80008738:	4d54                	lw	a3,28(a0)
    8000873a:	00007797          	auipc	a5,0x7
    8000873e:	10678793          	addi	a5,a5,262 # 8000f840 <worker_pids>
    for(int i = 0; i < 4; i++) {
    80008742:	4901                	li	s2,0
    80008744:	4611                	li	a2,4
        if(worker_pids[i] == p->pid) {
    80008746:	4398                	lw	a4,0(a5)
    80008748:	02d70163          	beq	a4,a3,8000876a <concurrent_test_worker+0x4e>
    for(int i = 0; i < 4; i++) {
    8000874c:	2905                	addiw	s2,s2,1
    8000874e:	0791                	addi	a5,a5,4
    80008750:	fec91be3          	bne	s2,a2,80008746 <concurrent_test_worker+0x2a>
        }
    }
    
    // 如果找不到，使用 PID 的相对值（假设主进程 PID 是 1，worker 从 2 开始）
    if(worker_id < 0) {
        worker_id = p->pid - 2;
    80008754:	ffe6879b          	addiw	a5,a3,-2
    80008758:	0007891b          	sext.w	s2,a5
        if(worker_id < 0 || worker_id >= 4) {
    8000875c:	470d                	li	a4,3
    8000875e:	01277863          	bgeu	a4,s2,8000876e <concurrent_test_worker+0x52>
            worker_id = p->pid % 4;  // 如果映射失败，使用 PID 取模
    80008762:	4911                	li	s2,4
    80008764:	0326e93b          	remw	s2,a3,s2
    80008768:	a019                	j	8000876e <concurrent_test_worker+0x52>
    if(worker_id < 0) {
    8000876a:	fe0945e3          	bltz	s2,80008754 <concurrent_test_worker+0x38>
        }
    }
    
    char filename[32];
    snprintf(filename, sizeof(filename), "test_%d", worker_id);
    8000876e:	86ca                	mv	a3,s2
    80008770:	00006617          	auipc	a2,0x6
    80008774:	14060613          	addi	a2,a2,320 # 8000e8b0 <digits+0x4700>
    80008778:	02000593          	li	a1,32
    8000877c:	fa040513          	addi	a0,s0,-96
    80008780:	00000097          	auipc	ra,0x0
    80008784:	e54080e7          	jalr	-428(ra) # 800085d4 <snprintf>
    
    printf("Worker %d (PID %d): Starting concurrent test\n", worker_id, p->pid);
    80008788:	01ca2603          	lw	a2,28(s4) # 801c <_entry-0x7fff7fe4>
    8000878c:	85ca                	mv	a1,s2
    8000878e:	00006517          	auipc	a0,0x6
    80008792:	12a50513          	addi	a0,a0,298 # 8000e8b8 <digits+0x4708>
    80008796:	ffff8097          	auipc	ra,0xffff8
    8000879a:	d6e080e7          	jalr	-658(ra) # 80000504 <printf>
    
    for(int j = 0; j < 100; j++) {
    8000879e:	f8042e23          	sw	zero,-100(s0)
        int fd = sys_open(filename, O_CREATE | O_RDWR);
        if(fd >= 0) {
            sys_write(fd, (char*)&j, sizeof(j));
            sys_close(fd);
            sys_unlink(filename);
            concurrent_test_count++;
    800087a2:	00007a97          	auipc	s5,0x7
    800087a6:	11aa8a93          	addi	s5,s5,282 # 8000f8bc <concurrent_test_count>
    for(int j = 0; j < 100; j++) {
    800087aa:	06300993          	li	s3,99
    800087ae:	a811                	j	800087c2 <concurrent_test_worker+0xa6>
    800087b0:	f9c42783          	lw	a5,-100(s0)
    800087b4:	2785                	addiw	a5,a5,1
    800087b6:	0007871b          	sext.w	a4,a5
    800087ba:	f8f42e23          	sw	a5,-100(s0)
    800087be:	04e9c563          	blt	s3,a4,80008808 <concurrent_test_worker+0xec>
        int fd = sys_open(filename, O_CREATE | O_RDWR);
    800087c2:	20200593          	li	a1,514
    800087c6:	fa040513          	addi	a0,s0,-96
    800087ca:	00000097          	auipc	ra,0x0
    800087ce:	b48080e7          	jalr	-1208(ra) # 80008312 <sys_open>
    800087d2:	84aa                	mv	s1,a0
        if(fd >= 0) {
    800087d4:	fc054ee3          	bltz	a0,800087b0 <concurrent_test_worker+0x94>
            sys_write(fd, (char*)&j, sizeof(j));
    800087d8:	4611                	li	a2,4
    800087da:	f9c40593          	addi	a1,s0,-100
    800087de:	00000097          	auipc	ra,0x0
    800087e2:	98e080e7          	jalr	-1650(ra) # 8000816c <sys_write>
            sys_close(fd);
    800087e6:	8526                	mv	a0,s1
    800087e8:	00000097          	auipc	ra,0x0
    800087ec:	90e080e7          	jalr	-1778(ra) # 800080f6 <sys_close>
            sys_unlink(filename);
    800087f0:	fa040513          	addi	a0,s0,-96
    800087f4:	00000097          	auipc	ra,0x0
    800087f8:	c5e080e7          	jalr	-930(ra) # 80008452 <sys_unlink>
            concurrent_test_count++;
    800087fc:	000aa783          	lw	a5,0(s5)
    80008800:	2785                	addiw	a5,a5,1
    80008802:	00faa023          	sw	a5,0(s5)
    80008806:	b76d                	j	800087b0 <concurrent_test_worker+0x94>
        }
    }
    
    printf("Worker %d (PID %d): Completed %d operations\n", worker_id, p->pid, concurrent_test_count);
    80008808:	00007697          	auipc	a3,0x7
    8000880c:	0b46a683          	lw	a3,180(a3) # 8000f8bc <concurrent_test_count>
    80008810:	01ca2603          	lw	a2,28(s4)
    80008814:	85ca                	mv	a1,s2
    80008816:	00006517          	auipc	a0,0x6
    8000881a:	0d250513          	addi	a0,a0,210 # 8000e8e8 <digits+0x4738>
    8000881e:	ffff8097          	auipc	ra,0xffff8
    80008822:	ce6080e7          	jalr	-794(ra) # 80000504 <printf>
    exit_process(0);
    80008826:	4501                	li	a0,0
    80008828:	ffffc097          	auipc	ra,0xffffc
    8000882c:	bfc080e7          	jalr	-1028(ra) # 80004424 <exit_process>

0000000080008830 <test_filesystem_integrity>:
void test_filesystem_integrity(void) {
    80008830:	7119                	addi	sp,sp,-128
    80008832:	fc86                	sd	ra,120(sp)
    80008834:	f8a2                	sd	s0,112(sp)
    80008836:	f4a6                	sd	s1,104(sp)
    80008838:	0100                	addi	s0,sp,128
    printf("Testing filesystem integrity...\n");
    8000883a:	00006517          	auipc	a0,0x6
    8000883e:	0de50513          	addi	a0,a0,222 # 8000e918 <digits+0x4768>
    80008842:	ffff8097          	auipc	ra,0xffff8
    80008846:	cc2080e7          	jalr	-830(ra) # 80000504 <printf>
    int fd = sys_open("testfile", O_CREATE | O_RDWR);
    8000884a:	20200593          	li	a1,514
    8000884e:	00006517          	auipc	a0,0x6
    80008852:	0f250513          	addi	a0,a0,242 # 8000e940 <digits+0x4790>
    80008856:	00000097          	auipc	ra,0x0
    8000885a:	abc080e7          	jalr	-1348(ra) # 80008312 <sys_open>
    if(fd < 0) {
    8000885e:	0a054d63          	bltz	a0,80008918 <test_filesystem_integrity+0xe8>
    80008862:	84aa                	mv	s1,a0
    printf("✓ Created testfile (fd=%d)\n", fd);
    80008864:	85aa                	mv	a1,a0
    80008866:	00006517          	auipc	a0,0x6
    8000886a:	10a50513          	addi	a0,a0,266 # 8000e970 <digits+0x47c0>
    8000886e:	ffff8097          	auipc	ra,0xffff8
    80008872:	c96080e7          	jalr	-874(ra) # 80000504 <printf>
    char buffer[] = "Hello, filesystem!";
    80008876:	00006717          	auipc	a4,0x6
    8000887a:	2a270713          	addi	a4,a4,674 # 8000eb18 <digits+0x4968>
    8000887e:	631c                	ld	a5,0(a4)
    80008880:	6714                	ld	a3,8(a4)
    80008882:	fcf43423          	sd	a5,-56(s0)
    80008886:	fcd43823          	sd	a3,-48(s0)
    8000888a:	01075683          	lhu	a3,16(a4)
    8000888e:	fcd41c23          	sh	a3,-40(s0)
    80008892:	01274703          	lbu	a4,18(a4)
    80008896:	fce40d23          	sb	a4,-38(s0)
    while(s[n] != '\0') n++;
    8000889a:	0ff7f793          	andi	a5,a5,255
    8000889e:	cfc9                	beqz	a5,80008938 <test_filesystem_integrity+0x108>
    800088a0:	fc840713          	addi	a4,s0,-56
    800088a4:	87ba                	mv	a5,a4
    800088a6:	4685                	li	a3,1
    800088a8:	9e99                	subw	a3,a3,a4
    800088aa:	00f6863b          	addw	a2,a3,a5
    800088ae:	0785                	addi	a5,a5,1
    800088b0:	0007c703          	lbu	a4,0(a5)
    800088b4:	fb7d                	bnez	a4,800088aa <test_filesystem_integrity+0x7a>
    int bytes = sys_write(fd, buffer, strlen(buffer));
    800088b6:	fc840593          	addi	a1,s0,-56
    800088ba:	8526                	mv	a0,s1
    800088bc:	00000097          	auipc	ra,0x0
    800088c0:	8b0080e7          	jalr	-1872(ra) # 8000816c <sys_write>
    800088c4:	862a                	mv	a2,a0
    while(s[n] != '\0') n++;
    800088c6:	fc844783          	lbu	a5,-56(s0)
    800088ca:	cbad                	beqz	a5,8000893c <test_filesystem_integrity+0x10c>
    800088cc:	fc840713          	addi	a4,s0,-56
    800088d0:	87ba                	mv	a5,a4
    800088d2:	4685                	li	a3,1
    800088d4:	9e99                	subw	a3,a3,a4
    800088d6:	00f685bb          	addw	a1,a3,a5
    800088da:	0785                	addi	a5,a5,1
    800088dc:	0007c703          	lbu	a4,0(a5)
    800088e0:	fb7d                	bnez	a4,800088d6 <test_filesystem_integrity+0xa6>
    if(bytes != strlen(buffer)) {
    800088e2:	04b60f63          	beq	a2,a1,80008940 <test_filesystem_integrity+0x110>
        printf("✗ Write failed: expected %d, got %d\n", strlen(buffer), bytes);
    800088e6:	00006517          	auipc	a0,0x6
    800088ea:	0aa50513          	addi	a0,a0,170 # 8000e990 <digits+0x47e0>
    800088ee:	ffff8097          	auipc	ra,0xffff8
    800088f2:	c16080e7          	jalr	-1002(ra) # 80000504 <printf>
        test_failures++;
    800088f6:	00007717          	auipc	a4,0x7
    800088fa:	fca70713          	addi	a4,a4,-54 # 8000f8c0 <test_failures>
    800088fe:	431c                	lw	a5,0(a4)
    80008900:	2785                	addiw	a5,a5,1
    80008902:	c31c                	sw	a5,0(a4)
        sys_close(fd);
    80008904:	8526                	mv	a0,s1
    80008906:	fffff097          	auipc	ra,0xfffff
    8000890a:	7f0080e7          	jalr	2032(ra) # 800080f6 <sys_close>
}
    8000890e:	70e6                	ld	ra,120(sp)
    80008910:	7446                	ld	s0,112(sp)
    80008912:	74a6                	ld	s1,104(sp)
    80008914:	6109                	addi	sp,sp,128
    80008916:	8082                	ret
        printf("✗ Failed to create testfile\n");
    80008918:	00006517          	auipc	a0,0x6
    8000891c:	03850513          	addi	a0,a0,56 # 8000e950 <digits+0x47a0>
    80008920:	ffff8097          	auipc	ra,0xffff8
    80008924:	be4080e7          	jalr	-1052(ra) # 80000504 <printf>
        test_failures++;
    80008928:	00007717          	auipc	a4,0x7
    8000892c:	f9870713          	addi	a4,a4,-104 # 8000f8c0 <test_failures>
    80008930:	431c                	lw	a5,0(a4)
    80008932:	2785                	addiw	a5,a5,1
    80008934:	c31c                	sw	a5,0(a4)
        return;
    80008936:	bfe1                	j	8000890e <test_filesystem_integrity+0xde>
    int n = 0;
    80008938:	4601                	li	a2,0
    8000893a:	bfb5                	j	800088b6 <test_filesystem_integrity+0x86>
    8000893c:	4581                	li	a1,0
    8000893e:	b755                	j	800088e2 <test_filesystem_integrity+0xb2>
    printf("✓ Wrote %d bytes to testfile\n", bytes);
    80008940:	00006517          	auipc	a0,0x6
    80008944:	07850513          	addi	a0,a0,120 # 8000e9b8 <digits+0x4808>
    80008948:	ffff8097          	auipc	ra,0xffff8
    8000894c:	bbc080e7          	jalr	-1092(ra) # 80000504 <printf>
    sys_close(fd);
    80008950:	8526                	mv	a0,s1
    80008952:	fffff097          	auipc	ra,0xfffff
    80008956:	7a4080e7          	jalr	1956(ra) # 800080f6 <sys_close>
    printf("✓ Closed testfile\n");
    8000895a:	00006517          	auipc	a0,0x6
    8000895e:	07e50513          	addi	a0,a0,126 # 8000e9d8 <digits+0x4828>
    80008962:	ffff8097          	auipc	ra,0xffff8
    80008966:	ba2080e7          	jalr	-1118(ra) # 80000504 <printf>
    fd = sys_open("testfile", O_RDONLY);
    8000896a:	4581                	li	a1,0
    8000896c:	00006517          	auipc	a0,0x6
    80008970:	fd450513          	addi	a0,a0,-44 # 8000e940 <digits+0x4790>
    80008974:	00000097          	auipc	ra,0x0
    80008978:	99e080e7          	jalr	-1634(ra) # 80008312 <sys_open>
    8000897c:	84aa                	mv	s1,a0
    if(fd < 0) {
    8000897e:	08054463          	bltz	a0,80008a06 <test_filesystem_integrity+0x1d6>
    printf("✓ Reopened testfile (fd=%d)\n", fd);
    80008982:	85aa                	mv	a1,a0
    80008984:	00006517          	auipc	a0,0x6
    80008988:	08c50513          	addi	a0,a0,140 # 8000ea10 <digits+0x4860>
    8000898c:	ffff8097          	auipc	ra,0xffff8
    80008990:	b78080e7          	jalr	-1160(ra) # 80000504 <printf>
    bytes = sys_read(fd, read_buffer, sizeof(read_buffer) - 1);
    80008994:	03f00613          	li	a2,63
    80008998:	f8840593          	addi	a1,s0,-120
    8000899c:	8526                	mv	a0,s1
    8000899e:	fffff097          	auipc	ra,0xfffff
    800089a2:	794080e7          	jalr	1940(ra) # 80008132 <sys_read>
    800089a6:	85aa                	mv	a1,a0
    if(bytes < 0) {
    800089a8:	06054f63          	bltz	a0,80008a26 <test_filesystem_integrity+0x1f6>
    read_buffer[bytes] = '\0';
    800089ac:	fe040793          	addi	a5,s0,-32
    800089b0:	97aa                	add	a5,a5,a0
    800089b2:	fa078423          	sb	zero,-88(a5)
    printf("✓ Read %d bytes from testfile\n", bytes);
    800089b6:	00006517          	auipc	a0,0x6
    800089ba:	09250513          	addi	a0,a0,146 # 8000ea48 <digits+0x4898>
    800089be:	ffff8097          	auipc	ra,0xffff8
    800089c2:	b46080e7          	jalr	-1210(ra) # 80000504 <printf>
    while(*s && *t && *s == *t) {
    800089c6:	fc844783          	lbu	a5,-56(s0)
    800089ca:	f8840713          	addi	a4,s0,-120
    800089ce:	fc840613          	addi	a2,s0,-56
    800089d2:	cb99                	beqz	a5,800089e8 <test_filesystem_integrity+0x1b8>
    800089d4:	00074683          	lbu	a3,0(a4)
    800089d8:	ca81                	beqz	a3,800089e8 <test_filesystem_integrity+0x1b8>
    800089da:	06f69b63          	bne	a3,a5,80008a50 <test_filesystem_integrity+0x220>
        s++;
    800089de:	0605                	addi	a2,a2,1
        t++;
    800089e0:	0705                	addi	a4,a4,1
    while(*s && *t && *s == *t) {
    800089e2:	00064783          	lbu	a5,0(a2)
    800089e6:	f7fd                	bnez	a5,800089d4 <test_filesystem_integrity+0x1a4>
    if(strcmp(buffer, read_buffer) != 0) {
    800089e8:	00074703          	lbu	a4,0(a4)
    800089ec:	06f71263          	bne	a4,a5,80008a50 <test_filesystem_integrity+0x220>
        printf("✓ Data matches: '%s'\n", read_buffer);
    800089f0:	f8840593          	addi	a1,s0,-120
    800089f4:	00006517          	auipc	a0,0x6
    800089f8:	0ac50513          	addi	a0,a0,172 # 8000eaa0 <digits+0x48f0>
    800089fc:	ffff8097          	auipc	ra,0xffff8
    80008a00:	b08080e7          	jalr	-1272(ra) # 80000504 <printf>
    80008a04:	a88d                	j	80008a76 <test_filesystem_integrity+0x246>
        printf("✗ Failed to reopen testfile\n");
    80008a06:	00006517          	auipc	a0,0x6
    80008a0a:	fea50513          	addi	a0,a0,-22 # 8000e9f0 <digits+0x4840>
    80008a0e:	ffff8097          	auipc	ra,0xffff8
    80008a12:	af6080e7          	jalr	-1290(ra) # 80000504 <printf>
        test_failures++;
    80008a16:	00007717          	auipc	a4,0x7
    80008a1a:	eaa70713          	addi	a4,a4,-342 # 8000f8c0 <test_failures>
    80008a1e:	431c                	lw	a5,0(a4)
    80008a20:	2785                	addiw	a5,a5,1
    80008a22:	c31c                	sw	a5,0(a4)
        return;
    80008a24:	b5ed                	j	8000890e <test_filesystem_integrity+0xde>
        printf("✗ Read failed\n");
    80008a26:	00006517          	auipc	a0,0x6
    80008a2a:	00a50513          	addi	a0,a0,10 # 8000ea30 <digits+0x4880>
    80008a2e:	ffff8097          	auipc	ra,0xffff8
    80008a32:	ad6080e7          	jalr	-1322(ra) # 80000504 <printf>
        test_failures++;
    80008a36:	00007717          	auipc	a4,0x7
    80008a3a:	e8a70713          	addi	a4,a4,-374 # 8000f8c0 <test_failures>
    80008a3e:	431c                	lw	a5,0(a4)
    80008a40:	2785                	addiw	a5,a5,1
    80008a42:	c31c                	sw	a5,0(a4)
        sys_close(fd);
    80008a44:	8526                	mv	a0,s1
    80008a46:	fffff097          	auipc	ra,0xfffff
    80008a4a:	6b0080e7          	jalr	1712(ra) # 800080f6 <sys_close>
        return;
    80008a4e:	b5c1                	j	8000890e <test_filesystem_integrity+0xde>
        printf("✗ Data mismatch: expected '%s', got '%s'\n", buffer, read_buffer);
    80008a50:	f8840613          	addi	a2,s0,-120
    80008a54:	fc840593          	addi	a1,s0,-56
    80008a58:	00006517          	auipc	a0,0x6
    80008a5c:	01850513          	addi	a0,a0,24 # 8000ea70 <digits+0x48c0>
    80008a60:	ffff8097          	auipc	ra,0xffff8
    80008a64:	aa4080e7          	jalr	-1372(ra) # 80000504 <printf>
        test_failures++;
    80008a68:	00007717          	auipc	a4,0x7
    80008a6c:	e5870713          	addi	a4,a4,-424 # 8000f8c0 <test_failures>
    80008a70:	431c                	lw	a5,0(a4)
    80008a72:	2785                	addiw	a5,a5,1
    80008a74:	c31c                	sw	a5,0(a4)
    sys_close(fd);
    80008a76:	8526                	mv	a0,s1
    80008a78:	fffff097          	auipc	ra,0xfffff
    80008a7c:	67e080e7          	jalr	1662(ra) # 800080f6 <sys_close>
    if(sys_unlink("testfile") != 0) {
    80008a80:	00006517          	auipc	a0,0x6
    80008a84:	ec050513          	addi	a0,a0,-320 # 8000e940 <digits+0x4790>
    80008a88:	00000097          	auipc	ra,0x0
    80008a8c:	9ca080e7          	jalr	-1590(ra) # 80008452 <sys_unlink>
    80008a90:	e115                	bnez	a0,80008ab4 <test_filesystem_integrity+0x284>
    printf("✓ Unlinked testfile\n");
    80008a92:	00006517          	auipc	a0,0x6
    80008a96:	04650513          	addi	a0,a0,70 # 8000ead8 <digits+0x4928>
    80008a9a:	ffff8097          	auipc	ra,0xffff8
    80008a9e:	a6a080e7          	jalr	-1430(ra) # 80000504 <printf>
    printf("Filesystem integrity test passed\n");
    80008aa2:	00006517          	auipc	a0,0x6
    80008aa6:	04e50513          	addi	a0,a0,78 # 8000eaf0 <digits+0x4940>
    80008aaa:	ffff8097          	auipc	ra,0xffff8
    80008aae:	a5a080e7          	jalr	-1446(ra) # 80000504 <printf>
    80008ab2:	bdb1                	j	8000890e <test_filesystem_integrity+0xde>
        printf("✗ Failed to unlink testfile\n");
    80008ab4:	00006517          	auipc	a0,0x6
    80008ab8:	00450513          	addi	a0,a0,4 # 8000eab8 <digits+0x4908>
    80008abc:	ffff8097          	auipc	ra,0xffff8
    80008ac0:	a48080e7          	jalr	-1464(ra) # 80000504 <printf>
        test_failures++;
    80008ac4:	00007717          	auipc	a4,0x7
    80008ac8:	dfc70713          	addi	a4,a4,-516 # 8000f8c0 <test_failures>
    80008acc:	431c                	lw	a5,0(a4)
    80008ace:	2785                	addiw	a5,a5,1
    80008ad0:	c31c                	sw	a5,0(a4)
        return;
    80008ad2:	bd35                	j	8000890e <test_filesystem_integrity+0xde>

0000000080008ad4 <test_concurrent_access>:
}

void test_concurrent_access(void) {
    80008ad4:	711d                	addi	sp,sp,-96
    80008ad6:	ec86                	sd	ra,88(sp)
    80008ad8:	e8a2                	sd	s0,80(sp)
    80008ada:	e4a6                	sd	s1,72(sp)
    80008adc:	e0ca                	sd	s2,64(sp)
    80008ade:	fc4e                	sd	s3,56(sp)
    80008ae0:	f852                	sd	s4,48(sp)
    80008ae2:	f456                	sd	s5,40(sp)
    80008ae4:	f05a                	sd	s6,32(sp)
    80008ae6:	ec5e                	sd	s7,24(sp)
    80008ae8:	1080                	addi	s0,sp,96
    printf("Testing concurrent file access...\n");
    80008aea:	00006517          	auipc	a0,0x6
    80008aee:	04650513          	addi	a0,a0,70 # 8000eb30 <digits+0x4980>
    80008af2:	ffff8097          	auipc	ra,0xffff8
    80008af6:	a12080e7          	jalr	-1518(ra) # 80000504 <printf>
    
    concurrent_test_count = 0;
    80008afa:	00007797          	auipc	a5,0x7
    80008afe:	dc07a123          	sw	zero,-574(a5) # 8000f8bc <concurrent_test_count>
    
    // 创建多个进程同时访问文件系统
    for(int i = 0; i < 4; i++) {
    80008b02:	00007917          	auipc	s2,0x7
    80008b06:	d3e90913          	addi	s2,s2,-706 # 8000f840 <worker_pids>
    80008b0a:	4481                	li	s1,0
        int pid = create_process(concurrent_test_worker);
    80008b0c:	00000a17          	auipc	s4,0x0
    80008b10:	c10a0a13          	addi	s4,s4,-1008 # 8000871c <concurrent_test_worker>
            printf("✗ Failed to create worker process %d\n", i);
            test_failures++;
            continue;
        }
        worker_pids[i] = pid;  // 保存 PID 到 worker ID 的映射
        printf("✓ Created worker process %d (PID %d)\n", i, pid);
    80008b14:	00006a97          	auipc	s5,0x6
    80008b18:	06ca8a93          	addi	s5,s5,108 # 8000eb80 <digits+0x49d0>
            printf("✗ Failed to create worker process %d\n", i);
    80008b1c:	00006b97          	auipc	s7,0x6
    80008b20:	03cb8b93          	addi	s7,s7,60 # 8000eb58 <digits+0x49a8>
            test_failures++;
    80008b24:	00007b17          	auipc	s6,0x7
    80008b28:	d9cb0b13          	addi	s6,s6,-612 # 8000f8c0 <test_failures>
    for(int i = 0; i < 4; i++) {
    80008b2c:	4991                	li	s3,4
    80008b2e:	a005                	j	80008b4e <test_concurrent_access+0x7a>
            printf("✗ Failed to create worker process %d\n", i);
    80008b30:	85a6                	mv	a1,s1
    80008b32:	855e                	mv	a0,s7
    80008b34:	ffff8097          	auipc	ra,0xffff8
    80008b38:	9d0080e7          	jalr	-1584(ra) # 80000504 <printf>
            test_failures++;
    80008b3c:	000b2783          	lw	a5,0(s6)
    80008b40:	2785                	addiw	a5,a5,1
    80008b42:	00fb2023          	sw	a5,0(s6)
    for(int i = 0; i < 4; i++) {
    80008b46:	2485                	addiw	s1,s1,1
    80008b48:	0911                	addi	s2,s2,4
    80008b4a:	03348363          	beq	s1,s3,80008b70 <test_concurrent_access+0x9c>
        int pid = create_process(concurrent_test_worker);
    80008b4e:	8552                	mv	a0,s4
    80008b50:	ffffb097          	auipc	ra,0xffffb
    80008b54:	322080e7          	jalr	802(ra) # 80003e72 <create_process>
    80008b58:	862a                	mv	a2,a0
        if(pid < 0) {
    80008b5a:	fc054be3          	bltz	a0,80008b30 <test_concurrent_access+0x5c>
        worker_pids[i] = pid;  // 保存 PID 到 worker ID 的映射
    80008b5e:	00a92023          	sw	a0,0(s2)
        printf("✓ Created worker process %d (PID %d)\n", i, pid);
    80008b62:	85a6                	mv	a1,s1
    80008b64:	8556                	mv	a0,s5
    80008b66:	ffff8097          	auipc	ra,0xffff8
    80008b6a:	99e080e7          	jalr	-1634(ra) # 80000504 <printf>
    80008b6e:	bfe1                	j	80008b46 <test_concurrent_access+0x72>
    80008b70:	4491                	li	s1,4
        int status;
        if(wait_process(&status) < 0) {
            printf("✗ Failed to wait for process\n");
            test_failures++;
        } else {
            printf("✓ Worker process exited with status %d\n", status);
    80008b72:	00006997          	auipc	s3,0x6
    80008b76:	05698993          	addi	s3,s3,86 # 8000ebc8 <digits+0x4a18>
            printf("✗ Failed to wait for process\n");
    80008b7a:	00006a17          	auipc	s4,0x6
    80008b7e:	02ea0a13          	addi	s4,s4,46 # 8000eba8 <digits+0x49f8>
            test_failures++;
    80008b82:	00007917          	auipc	s2,0x7
    80008b86:	d3e90913          	addi	s2,s2,-706 # 8000f8c0 <test_failures>
    80008b8a:	a829                	j	80008ba4 <test_concurrent_access+0xd0>
            printf("✗ Failed to wait for process\n");
    80008b8c:	8552                	mv	a0,s4
    80008b8e:	ffff8097          	auipc	ra,0xffff8
    80008b92:	976080e7          	jalr	-1674(ra) # 80000504 <printf>
            test_failures++;
    80008b96:	00092783          	lw	a5,0(s2)
    80008b9a:	2785                	addiw	a5,a5,1
    80008b9c:	00f92023          	sw	a5,0(s2)
    for(int i = 0; i < 4; i++) {
    80008ba0:	34fd                	addiw	s1,s1,-1
    80008ba2:	c08d                	beqz	s1,80008bc4 <test_concurrent_access+0xf0>
        if(wait_process(&status) < 0) {
    80008ba4:	fac40513          	addi	a0,s0,-84
    80008ba8:	ffffb097          	auipc	ra,0xffffb
    80008bac:	6d6080e7          	jalr	1750(ra) # 8000427e <wait_process>
    80008bb0:	fc054ee3          	bltz	a0,80008b8c <test_concurrent_access+0xb8>
            printf("✓ Worker process exited with status %d\n", status);
    80008bb4:	fac42583          	lw	a1,-84(s0)
    80008bb8:	854e                	mv	a0,s3
    80008bba:	ffff8097          	auipc	ra,0xffff8
    80008bbe:	94a080e7          	jalr	-1718(ra) # 80000504 <printf>
    80008bc2:	bff9                	j	80008ba0 <test_concurrent_access+0xcc>
        }
    }

    printf("Concurrent access test completed (total operations: %d)\n", concurrent_test_count);
    80008bc4:	00007597          	auipc	a1,0x7
    80008bc8:	cf85a583          	lw	a1,-776(a1) # 8000f8bc <concurrent_test_count>
    80008bcc:	00006517          	auipc	a0,0x6
    80008bd0:	02c50513          	addi	a0,a0,44 # 8000ebf8 <digits+0x4a48>
    80008bd4:	ffff8097          	auipc	ra,0xffff8
    80008bd8:	930080e7          	jalr	-1744(ra) # 80000504 <printf>
}
    80008bdc:	60e6                	ld	ra,88(sp)
    80008bde:	6446                	ld	s0,80(sp)
    80008be0:	64a6                	ld	s1,72(sp)
    80008be2:	6906                	ld	s2,64(sp)
    80008be4:	79e2                	ld	s3,56(sp)
    80008be6:	7a42                	ld	s4,48(sp)
    80008be8:	7aa2                	ld	s5,40(sp)
    80008bea:	7b02                	ld	s6,32(sp)
    80008bec:	6be2                	ld	s7,24(sp)
    80008bee:	6125                	addi	sp,sp,96
    80008bf0:	8082                	ret

0000000080008bf2 <test_filesystem_performance>:
}

// ==================== 性能测试 ====================


void test_filesystem_performance(void) {
    80008bf2:	711d                	addi	sp,sp,-96
    80008bf4:	ec86                	sd	ra,88(sp)
    80008bf6:	e8a2                	sd	s0,80(sp)
    80008bf8:	e4a6                	sd	s1,72(sp)
    80008bfa:	e0ca                	sd	s2,64(sp)
    80008bfc:	fc4e                	sd	s3,56(sp)
    80008bfe:	f852                	sd	s4,48(sp)
    80008c00:	f456                	sd	s5,40(sp)
    80008c02:	f05a                	sd	s6,32(sp)
    80008c04:	ec5e                	sd	s7,24(sp)
    80008c06:	1080                	addi	s0,sp,96
    80008c08:	737d                	lui	t1,0xfffff
    80008c0a:	911a                	add	sp,sp,t1
    printf("Testing filesystem performance...\n");
    80008c0c:	00006517          	auipc	a0,0x6
    80008c10:	02c50513          	addi	a0,a0,44 # 8000ec38 <digits+0x4a88>
    80008c14:	ffff8097          	auipc	ra,0xffff8
    80008c18:	8f0080e7          	jalr	-1808(ra) # 80000504 <printf>
    
    // 大量小文件测试（减少数量以避免 inode 耗尽）
    printf("Creating 100 small files...\n");
    80008c1c:	00006517          	auipc	a0,0x6
    80008c20:	04450513          	addi	a0,a0,68 # 8000ec60 <digits+0x4ab0>
    80008c24:	ffff8097          	auipc	ra,0xffff8
    80008c28:	8e0080e7          	jalr	-1824(ra) # 80000504 <printf>
    int small_files_created = 0;
    for(int i = 0; i < 100; i++) {
    80008c2c:	4901                	li	s2,0
    int small_files_created = 0;
    80008c2e:	4a81                	li	s5,0
        char filename[32];
        snprintf(filename, sizeof(filename), "small_%d", i);
    80008c30:	77fd                	lui	a5,0xfffff
    80008c32:	fb040713          	addi	a4,s0,-80
    80008c36:	97ba                	add	a5,a5,a4
    80008c38:	777d                	lui	a4,0xfffff
    80008c3a:	fb870713          	addi	a4,a4,-72 # ffffffffffffefb8 <end+0xffffffff7fb991d8>
    80008c3e:	ff040693          	addi	a3,s0,-16
    80008c42:	9736                	add	a4,a4,a3
    80008c44:	e31c                	sd	a5,0(a4)
    80008c46:	00006a17          	auipc	s4,0x6
    80008c4a:	03aa0a13          	addi	s4,s4,58 # 8000ec80 <digits+0x4ad0>

        int fd = sys_open(filename, O_CREATE | O_RDWR);
        if(fd >= 0) {
            sys_write(fd, "test", 4);
    80008c4e:	00006b17          	auipc	s6,0x6
    80008c52:	042b0b13          	addi	s6,s6,66 # 8000ec90 <digits+0x4ae0>
    for(int i = 0; i < 100; i++) {
    80008c56:	06400993          	li	s3,100
    80008c5a:	a021                	j	80008c62 <test_filesystem_performance+0x70>
    80008c5c:	2905                	addiw	s2,s2,1
    80008c5e:	07390763          	beq	s2,s3,80008ccc <test_filesystem_performance+0xda>
        snprintf(filename, sizeof(filename), "small_%d", i);
    80008c62:	86ca                	mv	a3,s2
    80008c64:	8652                	mv	a2,s4
    80008c66:	02000593          	li	a1,32
    80008c6a:	7bfd                	lui	s7,0xfffff
    80008c6c:	fb8b8793          	addi	a5,s7,-72 # ffffffffffffefb8 <end+0xffffffff7fb991d8>
    80008c70:	ff040713          	addi	a4,s0,-16
    80008c74:	97ba                	add	a5,a5,a4
    80008c76:	6388                	ld	a0,0(a5)
    80008c78:	00000097          	auipc	ra,0x0
    80008c7c:	95c080e7          	jalr	-1700(ra) # 800085d4 <snprintf>
        int fd = sys_open(filename, O_CREATE | O_RDWR);
    80008c80:	20200593          	li	a1,514
    80008c84:	fb8b8793          	addi	a5,s7,-72
    80008c88:	ff040713          	addi	a4,s0,-16
    80008c8c:	97ba                	add	a5,a5,a4
    80008c8e:	6388                	ld	a0,0(a5)
    80008c90:	fffff097          	auipc	ra,0xfffff
    80008c94:	682080e7          	jalr	1666(ra) # 80008312 <sys_open>
    80008c98:	84aa                	mv	s1,a0
        if(fd >= 0) {
    80008c9a:	fc0541e3          	bltz	a0,80008c5c <test_filesystem_performance+0x6a>
            sys_write(fd, "test", 4);
    80008c9e:	4611                	li	a2,4
    80008ca0:	85da                	mv	a1,s6
    80008ca2:	fffff097          	auipc	ra,0xfffff
    80008ca6:	4ca080e7          	jalr	1226(ra) # 8000816c <sys_write>
            sys_close(fd);
    80008caa:	8526                	mv	a0,s1
    80008cac:	fffff097          	auipc	ra,0xfffff
    80008cb0:	44a080e7          	jalr	1098(ra) # 800080f6 <sys_close>
            // 立即删除文件以释放 inode
            sys_unlink(filename);
    80008cb4:	fb8b8793          	addi	a5,s7,-72
    80008cb8:	ff040713          	addi	a4,s0,-16
    80008cbc:	97ba                	add	a5,a5,a4
    80008cbe:	6388                	ld	a0,0(a5)
    80008cc0:	fffff097          	auipc	ra,0xfffff
    80008cc4:	792080e7          	jalr	1938(ra) # 80008452 <sys_unlink>
            small_files_created++;
    80008cc8:	2a85                	addiw	s5,s5,1
    80008cca:	bf49                	j	80008c5c <test_filesystem_performance+0x6a>
        }
    }
    printf("✓ Created and deleted %d small files (100x4B)\n", small_files_created);
    80008ccc:	85d6                	mv	a1,s5
    80008cce:	00006517          	auipc	a0,0x6
    80008cd2:	fca50513          	addi	a0,a0,-54 # 8000ec98 <digits+0x4ae8>
    80008cd6:	ffff8097          	auipc	ra,0xffff8
    80008cda:	82e080e7          	jalr	-2002(ra) # 80000504 <printf>

    // 大文件测试（使用 512KB 以避免块耗尽）
    printf("Creating large file (512KB)...\n");
    80008cde:	00006517          	auipc	a0,0x6
    80008ce2:	ff250513          	addi	a0,a0,-14 # 8000ecd0 <digits+0x4b20>
    80008ce6:	ffff8097          	auipc	ra,0xffff8
    80008cea:	81e080e7          	jalr	-2018(ra) # 80000504 <printf>
    int fd = sys_open("large_file", O_CREATE | O_RDWR);
    80008cee:	20200593          	li	a1,514
    80008cf2:	00006517          	auipc	a0,0x6
    80008cf6:	ffe50513          	addi	a0,a0,-2 # 8000ecf0 <digits+0x4b40>
    80008cfa:	fffff097          	auipc	ra,0xfffff
    80008cfe:	618080e7          	jalr	1560(ra) # 80008312 <sys_open>
    80008d02:	89aa                	mv	s3,a0
    int large_file_blocks = 0;
    80008d04:	4901                	li	s2,0
    if(fd >= 0) {
    80008d06:	06054563          	bltz	a0,80008d70 <test_filesystem_performance+0x17e>
    80008d0a:	777d                	lui	a4,0xfffff
    80008d0c:	fb040793          	addi	a5,s0,-80
    80008d10:	973e                	add	a4,a4,a5
        char large_buffer[4096];
        // 初始化缓冲区
        for(int i = 0; i < 4096; i++) {
    80008d12:	4781                	li	a5,0
    80008d14:	6685                	lui	a3,0x1
            large_buffer[i] = (char)(i % 256);
    80008d16:	00f70023          	sb	a5,0(a4) # fffffffffffff000 <end+0xffffffff7fb99220>
        for(int i = 0; i < 4096; i++) {
    80008d1a:	2785                	addiw	a5,a5,1
    80008d1c:	0705                	addi	a4,a4,1
    80008d1e:	fed79ce3          	bne	a5,a3,80008d16 <test_filesystem_performance+0x124>
    80008d22:	08000493          	li	s1,128
    int large_file_blocks = 0;
    80008d26:	4901                	li	s2,0
        }
        
        for(int i = 0; i < 128; i++) { // 512KB文件 (128 * 4KB = 512KB)
            if(sys_write(fd, large_buffer, sizeof(large_buffer)) > 0) {
    80008d28:	77fd                	lui	a5,0xfffff
    80008d2a:	fb040713          	addi	a4,s0,-80
    80008d2e:	97ba                	add	a5,a5,a4
    80008d30:	777d                	lui	a4,0xfffff
    80008d32:	fb870713          	addi	a4,a4,-72 # ffffffffffffefb8 <end+0xffffffff7fb991d8>
    80008d36:	ff040693          	addi	a3,s0,-16
    80008d3a:	9736                	add	a4,a4,a3
    80008d3c:	e31c                	sd	a5,0(a4)
    80008d3e:	a019                	j	80008d44 <test_filesystem_performance+0x152>
        for(int i = 0; i < 128; i++) { // 512KB文件 (128 * 4KB = 512KB)
    80008d40:	34fd                	addiw	s1,s1,-1
    80008d42:	c095                	beqz	s1,80008d66 <test_filesystem_performance+0x174>
            if(sys_write(fd, large_buffer, sizeof(large_buffer)) > 0) {
    80008d44:	6605                	lui	a2,0x1
    80008d46:	77fd                	lui	a5,0xfffff
    80008d48:	fb878793          	addi	a5,a5,-72 # ffffffffffffefb8 <end+0xffffffff7fb991d8>
    80008d4c:	ff040713          	addi	a4,s0,-16
    80008d50:	97ba                	add	a5,a5,a4
    80008d52:	638c                	ld	a1,0(a5)
    80008d54:	854e                	mv	a0,s3
    80008d56:	fffff097          	auipc	ra,0xfffff
    80008d5a:	416080e7          	jalr	1046(ra) # 8000816c <sys_write>
    80008d5e:	fea051e3          	blez	a0,80008d40 <test_filesystem_performance+0x14e>
                large_file_blocks++;
    80008d62:	2905                	addiw	s2,s2,1
    80008d64:	bff1                	j	80008d40 <test_filesystem_performance+0x14e>
            }
        }
        sys_close(fd);
    80008d66:	854e                	mv	a0,s3
    80008d68:	fffff097          	auipc	ra,0xfffff
    80008d6c:	38e080e7          	jalr	910(ra) # 800080f6 <sys_close>
    }
    printf("✓ Large file created (%d blocks, 512KB)\n", large_file_blocks);
    80008d70:	85ca                	mv	a1,s2
    80008d72:	00006517          	auipc	a0,0x6
    80008d76:	f8e50513          	addi	a0,a0,-114 # 8000ed00 <digits+0x4b50>
    80008d7a:	ffff7097          	auipc	ra,0xffff7
    80008d7e:	78a080e7          	jalr	1930(ra) # 80000504 <printf>

    // 清理测试文件
    printf("Cleaning up test files...\n");
    80008d82:	00006517          	auipc	a0,0x6
    80008d86:	fae50513          	addi	a0,a0,-82 # 8000ed30 <digits+0x4b80>
    80008d8a:	ffff7097          	auipc	ra,0xffff7
    80008d8e:	77a080e7          	jalr	1914(ra) # 80000504 <printf>
    for(int i = 0; i < 100; i++) {
    80008d92:	4481                	li	s1,0
        char filename[32];
        snprintf(filename, sizeof(filename), "small_%d", i);
    80008d94:	77fd                	lui	a5,0xfffff
    80008d96:	fb040713          	addi	a4,s0,-80
    80008d9a:	97ba                	add	a5,a5,a4
    80008d9c:	777d                	lui	a4,0xfffff
    80008d9e:	fb870713          	addi	a4,a4,-72 # ffffffffffffefb8 <end+0xffffffff7fb991d8>
    80008da2:	ff040693          	addi	a3,s0,-16
    80008da6:	9736                	add	a4,a4,a3
    80008da8:	e31c                	sd	a5,0(a4)
    80008daa:	00006997          	auipc	s3,0x6
    80008dae:	ed698993          	addi	s3,s3,-298 # 8000ec80 <digits+0x4ad0>
    for(int i = 0; i < 100; i++) {
    80008db2:	06400913          	li	s2,100
        snprintf(filename, sizeof(filename), "small_%d", i);
    80008db6:	86a6                	mv	a3,s1
    80008db8:	864e                	mv	a2,s3
    80008dba:	02000593          	li	a1,32
    80008dbe:	7a7d                	lui	s4,0xfffff
    80008dc0:	fb8a0793          	addi	a5,s4,-72 # ffffffffffffefb8 <end+0xffffffff7fb991d8>
    80008dc4:	ff040713          	addi	a4,s0,-16
    80008dc8:	97ba                	add	a5,a5,a4
    80008dca:	6388                	ld	a0,0(a5)
    80008dcc:	00000097          	auipc	ra,0x0
    80008dd0:	808080e7          	jalr	-2040(ra) # 800085d4 <snprintf>
        sys_unlink(filename);
    80008dd4:	fb8a0793          	addi	a5,s4,-72
    80008dd8:	ff040713          	addi	a4,s0,-16
    80008ddc:	97ba                	add	a5,a5,a4
    80008dde:	6388                	ld	a0,0(a5)
    80008de0:	fffff097          	auipc	ra,0xfffff
    80008de4:	672080e7          	jalr	1650(ra) # 80008452 <sys_unlink>
    for(int i = 0; i < 100; i++) {
    80008de8:	2485                	addiw	s1,s1,1
    80008dea:	fd2496e3          	bne	s1,s2,80008db6 <test_filesystem_performance+0x1c4>
    }
    sys_unlink("large_file");
    80008dee:	00006517          	auipc	a0,0x6
    80008df2:	f0250513          	addi	a0,a0,-254 # 8000ecf0 <digits+0x4b40>
    80008df6:	fffff097          	auipc	ra,0xfffff
    80008dfa:	65c080e7          	jalr	1628(ra) # 80008452 <sys_unlink>
    
    printf("Performance test completed\n");
    80008dfe:	00006517          	auipc	a0,0x6
    80008e02:	f5250513          	addi	a0,a0,-174 # 8000ed50 <digits+0x4ba0>
    80008e06:	ffff7097          	auipc	ra,0xffff7
    80008e0a:	6fe080e7          	jalr	1790(ra) # 80000504 <printf>
}
    80008e0e:	6305                	lui	t1,0x1
    80008e10:	911a                	add	sp,sp,t1
    80008e12:	60e6                	ld	ra,88(sp)
    80008e14:	6446                	ld	s0,80(sp)
    80008e16:	64a6                	ld	s1,72(sp)
    80008e18:	6906                	ld	s2,64(sp)
    80008e1a:	79e2                	ld	s3,56(sp)
    80008e1c:	7a42                	ld	s4,48(sp)
    80008e1e:	7aa2                	ld	s5,40(sp)
    80008e20:	7b02                	ld	s6,32(sp)
    80008e22:	6be2                	ld	s7,24(sp)
    80008e24:	6125                	addi	sp,sp,96
    80008e26:	8082                	ret

0000000080008e28 <debug_filesystem_state>:

// ==================== 调试功能 ====================

void debug_filesystem_state(void) {
    80008e28:	1101                	addi	sp,sp,-32
    80008e2a:	ec06                	sd	ra,24(sp)
    80008e2c:	e822                	sd	s0,16(sp)
    80008e2e:	e426                	sd	s1,8(sp)
    80008e30:	1000                	addi	s0,sp,32
    printf("=== Filesystem Debug Info ===\n");
    80008e32:	00006517          	auipc	a0,0x6
    80008e36:	f3e50513          	addi	a0,a0,-194 # 8000ed70 <digits+0x4bc0>
    80008e3a:	ffff7097          	auipc	ra,0xffff7
    80008e3e:	6ca080e7          	jalr	1738(ra) # 80000504 <printf>
    
    // 显示超级块信息
    printf("Superblock info:\n");
    80008e42:	00006517          	auipc	a0,0x6
    80008e46:	f4e50513          	addi	a0,a0,-178 # 8000ed90 <digits+0x4be0>
    80008e4a:	ffff7097          	auipc	ra,0xffff7
    80008e4e:	6ba080e7          	jalr	1722(ra) # 80000504 <printf>
    printf("  Magic: 0x%x\n", sb.magic);
    80008e52:	00459497          	auipc	s1,0x459
    80008e56:	2ce48493          	addi	s1,s1,718 # 80462120 <sb>
    80008e5a:	408c                	lw	a1,0(s1)
    80008e5c:	00006517          	auipc	a0,0x6
    80008e60:	f4c50513          	addi	a0,a0,-180 # 8000eda8 <digits+0x4bf8>
    80008e64:	ffff7097          	auipc	ra,0xffff7
    80008e68:	6a0080e7          	jalr	1696(ra) # 80000504 <printf>
    printf("  Size: %d blocks\n", sb.size);
    80008e6c:	40cc                	lw	a1,4(s1)
    80008e6e:	00006517          	auipc	a0,0x6
    80008e72:	f4a50513          	addi	a0,a0,-182 # 8000edb8 <digits+0x4c08>
    80008e76:	ffff7097          	auipc	ra,0xffff7
    80008e7a:	68e080e7          	jalr	1678(ra) # 80000504 <printf>
    printf("  Nblocks: %d\n", sb.nblocks);
    80008e7e:	448c                	lw	a1,8(s1)
    80008e80:	00006517          	auipc	a0,0x6
    80008e84:	f5050513          	addi	a0,a0,-176 # 8000edd0 <digits+0x4c20>
    80008e88:	ffff7097          	auipc	ra,0xffff7
    80008e8c:	67c080e7          	jalr	1660(ra) # 80000504 <printf>
    printf("  Ninodes: %d\n", sb.ninodes);
    80008e90:	44cc                	lw	a1,12(s1)
    80008e92:	00006517          	auipc	a0,0x6
    80008e96:	f4e50513          	addi	a0,a0,-178 # 8000ede0 <digits+0x4c30>
    80008e9a:	ffff7097          	auipc	ra,0xffff7
    80008e9e:	66a080e7          	jalr	1642(ra) # 80000504 <printf>
    printf("  Nlog: %d\n", sb.nlog);
    80008ea2:	488c                	lw	a1,16(s1)
    80008ea4:	00006517          	auipc	a0,0x6
    80008ea8:	f4c50513          	addi	a0,a0,-180 # 8000edf0 <digits+0x4c40>
    80008eac:	ffff7097          	auipc	ra,0xffff7
    80008eb0:	658080e7          	jalr	1624(ra) # 80000504 <printf>
    printf("  Log start: %d\n", sb.logstart);
    80008eb4:	48cc                	lw	a1,20(s1)
    80008eb6:	00006517          	auipc	a0,0x6
    80008eba:	f4a50513          	addi	a0,a0,-182 # 8000ee00 <digits+0x4c50>
    80008ebe:	ffff7097          	auipc	ra,0xffff7
    80008ec2:	646080e7          	jalr	1606(ra) # 80000504 <printf>
    printf("  Inode start: %d\n", sb.inodestart);
    80008ec6:	4c8c                	lw	a1,24(s1)
    80008ec8:	00006517          	auipc	a0,0x6
    80008ecc:	f5050513          	addi	a0,a0,-176 # 8000ee18 <digits+0x4c68>
    80008ed0:	ffff7097          	auipc	ra,0xffff7
    80008ed4:	634080e7          	jalr	1588(ra) # 80000504 <printf>
    printf("  Bitmap start: %d\n", sb.bmapstart);
    80008ed8:	4ccc                	lw	a1,28(s1)
    80008eda:	00006517          	auipc	a0,0x6
    80008ede:	f5650513          	addi	a0,a0,-170 # 8000ee30 <digits+0x4c80>
    80008ee2:	ffff7097          	auipc	ra,0xffff7
    80008ee6:	622080e7          	jalr	1570(ra) # 80000504 <printf>
    
    // 显示块缓存状态（简化）
    printf("\nBlock cache: (simplified info)\n");
    80008eea:	00006517          	auipc	a0,0x6
    80008eee:	f5e50513          	addi	a0,a0,-162 # 8000ee48 <digits+0x4c98>
    80008ef2:	ffff7097          	auipc	ra,0xffff7
    80008ef6:	612080e7          	jalr	1554(ra) # 80000504 <printf>
    printf("  Cache size: %d blocks\n", NBUF);
    80008efa:	06400593          	li	a1,100
    80008efe:	00006517          	auipc	a0,0x6
    80008f02:	f7250513          	addi	a0,a0,-142 # 8000ee70 <digits+0x4cc0>
    80008f06:	ffff7097          	auipc	ra,0xffff7
    80008f0a:	5fe080e7          	jalr	1534(ra) # 80000504 <printf>
    
    // 显示日志状态
    printf("\nLog state:\n");
    80008f0e:	00006517          	auipc	a0,0x6
    80008f12:	f8250513          	addi	a0,a0,-126 # 8000ee90 <digits+0x4ce0>
    80008f16:	ffff7097          	auipc	ra,0xffff7
    80008f1a:	5ee080e7          	jalr	1518(ra) # 80000504 <printf>
    printf("  Start: %d\n", log.start);
    80008f1e:	00459497          	auipc	s1,0x459
    80008f22:	15a48493          	addi	s1,s1,346 # 80462078 <log>
    80008f26:	4c8c                	lw	a1,24(s1)
    80008f28:	00006517          	auipc	a0,0x6
    80008f2c:	f7850513          	addi	a0,a0,-136 # 8000eea0 <digits+0x4cf0>
    80008f30:	ffff7097          	auipc	ra,0xffff7
    80008f34:	5d4080e7          	jalr	1492(ra) # 80000504 <printf>
    printf("  Size: %d\n", log.size);
    80008f38:	4ccc                	lw	a1,28(s1)
    80008f3a:	00006517          	auipc	a0,0x6
    80008f3e:	f7650513          	addi	a0,a0,-138 # 8000eeb0 <digits+0x4d00>
    80008f42:	ffff7097          	auipc	ra,0xffff7
    80008f46:	5c2080e7          	jalr	1474(ra) # 80000504 <printf>
    printf("  Outstanding: %d\n", log.outstanding);
    80008f4a:	508c                	lw	a1,32(s1)
    80008f4c:	00006517          	auipc	a0,0x6
    80008f50:	f7450513          	addi	a0,a0,-140 # 8000eec0 <digits+0x4d10>
    80008f54:	ffff7097          	auipc	ra,0xffff7
    80008f58:	5b0080e7          	jalr	1456(ra) # 80000504 <printf>
    printf("  Committing: %d\n", log.committing);
    80008f5c:	50cc                	lw	a1,36(s1)
    80008f5e:	00006517          	auipc	a0,0x6
    80008f62:	f7a50513          	addi	a0,a0,-134 # 8000eed8 <digits+0x4d28>
    80008f66:	ffff7097          	auipc	ra,0xffff7
    80008f6a:	59e080e7          	jalr	1438(ra) # 80000504 <printf>
    printf("  Log entries: %d\n", log.lh.n);
    80008f6e:	54cc                	lw	a1,44(s1)
    80008f70:	00006517          	auipc	a0,0x6
    80008f74:	f8050513          	addi	a0,a0,-128 # 8000eef0 <digits+0x4d40>
    80008f78:	ffff7097          	auipc	ra,0xffff7
    80008f7c:	58c080e7          	jalr	1420(ra) # 80000504 <printf>
    
    printf("=== End of Debug Info ===\n");
    80008f80:	00006517          	auipc	a0,0x6
    80008f84:	f8850513          	addi	a0,a0,-120 # 8000ef08 <digits+0x4d58>
    80008f88:	ffff7097          	auipc	ra,0xffff7
    80008f8c:	57c080e7          	jalr	1404(ra) # 80000504 <printf>
}
    80008f90:	60e2                	ld	ra,24(sp)
    80008f92:	6442                	ld	s0,16(sp)
    80008f94:	64a2                	ld	s1,8(sp)
    80008f96:	6105                	addi	sp,sp,32
    80008f98:	8082                	ret

0000000080008f9a <test_crash_recovery>:
void test_crash_recovery(void) {
    80008f9a:	7171                	addi	sp,sp,-176
    80008f9c:	f506                	sd	ra,168(sp)
    80008f9e:	f122                	sd	s0,160(sp)
    80008fa0:	ed26                	sd	s1,152(sp)
    80008fa2:	e94a                	sd	s2,144(sp)
    80008fa4:	e54e                	sd	s3,136(sp)
    80008fa6:	e152                	sd	s4,128(sp)
    80008fa8:	fcd6                	sd	s5,120(sp)
    80008faa:	f8da                	sd	s6,112(sp)
    80008fac:	f4de                	sd	s7,104(sp)
    80008fae:	f0e2                	sd	s8,96(sp)
    80008fb0:	1900                	addi	s0,sp,176
    printf("Testing crash recovery...\n");
    80008fb2:	00006517          	auipc	a0,0x6
    80008fb6:	f7650513          	addi	a0,a0,-138 # 8000ef28 <digits+0x4d78>
    80008fba:	ffff7097          	auipc	ra,0xffff7
    80008fbe:	54a080e7          	jalr	1354(ra) # 80000504 <printf>
    printf("Creating test files before simulated crash...\n");
    80008fc2:	00006517          	auipc	a0,0x6
    80008fc6:	f8650513          	addi	a0,a0,-122 # 8000ef48 <digits+0x4d98>
    80008fca:	ffff7097          	auipc	ra,0xffff7
    80008fce:	53a080e7          	jalr	1338(ra) # 80000504 <printf>
    for(int i = 0; i < 10; i++) {
    80008fd2:	4901                	li	s2,0
        snprintf(filename, sizeof(filename), "crash_test_%d", i);
    80008fd4:	00006a97          	auipc	s5,0x6
    80008fd8:	fa4a8a93          	addi	s5,s5,-92 # 8000ef78 <digits+0x4dc8>
            snprintf(data, sizeof(data), "Test data for file %d", i);
    80008fdc:	f7040a13          	addi	s4,s0,-144
    80008fe0:	00006b97          	auipc	s7,0x6
    80008fe4:	fa8b8b93          	addi	s7,s7,-88 # 8000ef88 <digits+0x4dd8>
            printf("✓ Created %s\n", filename);
    80008fe8:	00006b17          	auipc	s6,0x6
    80008fec:	fb8b0b13          	addi	s6,s6,-72 # 8000efa0 <digits+0x4df0>
    int n = 0;
    80008ff0:	4c01                	li	s8,0
    80008ff2:	4985                	li	s3,1
    80008ff4:	414989bb          	subw	s3,s3,s4
    80008ff8:	a805                	j	80009028 <test_crash_recovery+0x8e>
    80008ffa:	8662                	mv	a2,s8
            sys_write(fd, data, strlen(data));
    80008ffc:	85d2                	mv	a1,s4
    80008ffe:	8526                	mv	a0,s1
    80009000:	fffff097          	auipc	ra,0xfffff
    80009004:	16c080e7          	jalr	364(ra) # 8000816c <sys_write>
            sys_close(fd);
    80009008:	8526                	mv	a0,s1
    8000900a:	fffff097          	auipc	ra,0xfffff
    8000900e:	0ec080e7          	jalr	236(ra) # 800080f6 <sys_close>
            printf("✓ Created %s\n", filename);
    80009012:	f5040593          	addi	a1,s0,-176
    80009016:	855a                	mv	a0,s6
    80009018:	ffff7097          	auipc	ra,0xffff7
    8000901c:	4ec080e7          	jalr	1260(ra) # 80000504 <printf>
    for(int i = 0; i < 10; i++) {
    80009020:	2905                	addiw	s2,s2,1
    80009022:	47a9                	li	a5,10
    80009024:	04f90b63          	beq	s2,a5,8000907a <test_crash_recovery+0xe0>
        snprintf(filename, sizeof(filename), "crash_test_%d", i);
    80009028:	86ca                	mv	a3,s2
    8000902a:	8656                	mv	a2,s5
    8000902c:	02000593          	li	a1,32
    80009030:	f5040513          	addi	a0,s0,-176
    80009034:	fffff097          	auipc	ra,0xfffff
    80009038:	5a0080e7          	jalr	1440(ra) # 800085d4 <snprintf>
        int fd = sys_open(filename, O_CREATE | O_RDWR);
    8000903c:	20200593          	li	a1,514
    80009040:	f5040513          	addi	a0,s0,-176
    80009044:	fffff097          	auipc	ra,0xfffff
    80009048:	2ce080e7          	jalr	718(ra) # 80008312 <sys_open>
    8000904c:	84aa                	mv	s1,a0
        if(fd >= 0) {
    8000904e:	fc0549e3          	bltz	a0,80009020 <test_crash_recovery+0x86>
            snprintf(data, sizeof(data), "Test data for file %d", i);
    80009052:	86ca                	mv	a3,s2
    80009054:	865e                	mv	a2,s7
    80009056:	04000593          	li	a1,64
    8000905a:	8552                	mv	a0,s4
    8000905c:	fffff097          	auipc	ra,0xfffff
    80009060:	578080e7          	jalr	1400(ra) # 800085d4 <snprintf>
    while(s[n] != '\0') n++;
    80009064:	f7044783          	lbu	a5,-144(s0)
    80009068:	dbc9                	beqz	a5,80008ffa <test_crash_recovery+0x60>
    8000906a:	87d2                	mv	a5,s4
    8000906c:	00f9863b          	addw	a2,s3,a5
    80009070:	0785                	addi	a5,a5,1
    80009072:	0007c703          	lbu	a4,0(a5) # fffffffffffff000 <end+0xffffffff7fb99220>
    80009076:	fb7d                	bnez	a4,8000906c <test_crash_recovery+0xd2>
    80009078:	b751                	j	80008ffc <test_crash_recovery+0x62>
    printf("Simulating crash...\n");
    8000907a:	00006517          	auipc	a0,0x6
    8000907e:	f3650513          	addi	a0,a0,-202 # 8000efb0 <digits+0x4e00>
    80009082:	ffff7097          	auipc	ra,0xffff7
    80009086:	482080e7          	jalr	1154(ra) # 80000504 <printf>
    recover_from_log();
    8000908a:	ffffd097          	auipc	ra,0xffffd
    8000908e:	4ce080e7          	jalr	1230(ra) # 80006558 <recover_from_log>
    printf("✓ Log recovery completed\n");
    80009092:	00006517          	auipc	a0,0x6
    80009096:	f3650513          	addi	a0,a0,-202 # 8000efc8 <digits+0x4e18>
    8000909a:	ffff7097          	auipc	ra,0xffff7
    8000909e:	46a080e7          	jalr	1130(ra) # 80000504 <printf>
    printf("Checking filesystem state after recovery...\n");
    800090a2:	00006517          	auipc	a0,0x6
    800090a6:	f4650513          	addi	a0,a0,-186 # 8000efe8 <digits+0x4e38>
    800090aa:	ffff7097          	auipc	ra,0xffff7
    800090ae:	45a080e7          	jalr	1114(ra) # 80000504 <printf>
    debug_filesystem_state();
    800090b2:	00000097          	auipc	ra,0x0
    800090b6:	d76080e7          	jalr	-650(ra) # 80008e28 <debug_filesystem_state>
    for(int i = 0; i < 10; i++) {
    800090ba:	4481                	li	s1,0
        snprintf(filename, sizeof(filename), "crash_test_%d", i);
    800090bc:	00006997          	auipc	s3,0x6
    800090c0:	ebc98993          	addi	s3,s3,-324 # 8000ef78 <digits+0x4dc8>
    for(int i = 0; i < 10; i++) {
    800090c4:	4929                	li	s2,10
        snprintf(filename, sizeof(filename), "crash_test_%d", i);
    800090c6:	86a6                	mv	a3,s1
    800090c8:	864e                	mv	a2,s3
    800090ca:	02000593          	li	a1,32
    800090ce:	f7040513          	addi	a0,s0,-144
    800090d2:	fffff097          	auipc	ra,0xfffff
    800090d6:	502080e7          	jalr	1282(ra) # 800085d4 <snprintf>
        sys_unlink(filename);
    800090da:	f7040513          	addi	a0,s0,-144
    800090de:	fffff097          	auipc	ra,0xfffff
    800090e2:	374080e7          	jalr	884(ra) # 80008452 <sys_unlink>
    for(int i = 0; i < 10; i++) {
    800090e6:	2485                	addiw	s1,s1,1
    800090e8:	fd249fe3          	bne	s1,s2,800090c6 <test_crash_recovery+0x12c>
    printf("Crash recovery test completed\n");
    800090ec:	00006517          	auipc	a0,0x6
    800090f0:	f2c50513          	addi	a0,a0,-212 # 8000f018 <digits+0x4e68>
    800090f4:	ffff7097          	auipc	ra,0xffff7
    800090f8:	410080e7          	jalr	1040(ra) # 80000504 <printf>
}
    800090fc:	70aa                	ld	ra,168(sp)
    800090fe:	740a                	ld	s0,160(sp)
    80009100:	64ea                	ld	s1,152(sp)
    80009102:	694a                	ld	s2,144(sp)
    80009104:	69aa                	ld	s3,136(sp)
    80009106:	6a0a                	ld	s4,128(sp)
    80009108:	7ae6                	ld	s5,120(sp)
    8000910a:	7b46                	ld	s6,112(sp)
    8000910c:	7ba6                	ld	s7,104(sp)
    8000910e:	7c06                	ld	s8,96(sp)
    80009110:	614d                	addi	sp,sp,176
    80009112:	8082                	ret

0000000080009114 <debug_inode_usage>:

void debug_inode_usage(void) {
    80009114:	7179                	addi	sp,sp,-48
    80009116:	f406                	sd	ra,40(sp)
    80009118:	f022                	sd	s0,32(sp)
    8000911a:	ec26                	sd	s1,24(sp)
    8000911c:	e84a                	sd	s2,16(sp)
    8000911e:	e44e                	sd	s3,8(sp)
    80009120:	e052                	sd	s4,0(sp)
    80009122:	1800                	addi	s0,sp,48
    printf("=== Inode Usage ===\n");
    80009124:	00006517          	auipc	a0,0x6
    80009128:	f1450513          	addi	a0,a0,-236 # 8000f038 <digits+0x4e88>
    8000912c:	ffff7097          	auipc	ra,0xffff7
    80009130:	3d8080e7          	jalr	984(ra) # 80000504 <printf>
    
    int used_count = 0;
    for(int i = 0; i < NINODE; i++) {
    80009134:	00459497          	auipc	s1,0x459
    80009138:	02448493          	addi	s1,s1,36 # 80462158 <icache+0x18>
    8000913c:	0045b917          	auipc	s2,0x45b
    80009140:	dcc90913          	addi	s2,s2,-564 # 80463f08 <ftable>
    int used_count = 0;
    80009144:	4981                	li	s3,0
        struct inode *ip = &icache.inode[i];
        if(ip->ref > 0) {
            printf("Inode %d: ref=%d, type=%d, size=%d, dev=%d\n",
    80009146:	00006a17          	auipc	s4,0x6
    8000914a:	f0aa0a13          	addi	s4,s4,-246 # 8000f050 <digits+0x4ea0>
    8000914e:	a029                	j	80009158 <debug_inode_usage+0x44>
    for(int i = 0; i < NINODE; i++) {
    80009150:	09848493          	addi	s1,s1,152
    80009154:	03248163          	beq	s1,s2,80009176 <debug_inode_usage+0x62>
        if(ip->ref > 0) {
    80009158:	4490                	lw	a2,8(s1)
    8000915a:	fec05be3          	blez	a2,80009150 <debug_inode_usage+0x3c>
            printf("Inode %d: ref=%d, type=%d, size=%d, dev=%d\n",
    8000915e:	409c                	lw	a5,0(s1)
    80009160:	44f8                	lw	a4,76(s1)
    80009162:	04449683          	lh	a3,68(s1)
    80009166:	40cc                	lw	a1,4(s1)
    80009168:	8552                	mv	a0,s4
    8000916a:	ffff7097          	auipc	ra,0xffff7
    8000916e:	39a080e7          	jalr	922(ra) # 80000504 <printf>
                   ip->inum, ip->ref, ip->type, ip->size, ip->dev);
            used_count++;
    80009172:	2985                	addiw	s3,s3,1
    80009174:	bff1                	j	80009150 <debug_inode_usage+0x3c>
        }
    }
    
    printf("Total inodes in use: %d/%d\n", used_count, NINODE);
    80009176:	03200613          	li	a2,50
    8000917a:	85ce                	mv	a1,s3
    8000917c:	00006517          	auipc	a0,0x6
    80009180:	f0450513          	addi	a0,a0,-252 # 8000f080 <digits+0x4ed0>
    80009184:	ffff7097          	auipc	ra,0xffff7
    80009188:	380080e7          	jalr	896(ra) # 80000504 <printf>
    printf("=== End of Inode Usage ===\n");
    8000918c:	00006517          	auipc	a0,0x6
    80009190:	f1450513          	addi	a0,a0,-236 # 8000f0a0 <digits+0x4ef0>
    80009194:	ffff7097          	auipc	ra,0xffff7
    80009198:	370080e7          	jalr	880(ra) # 80000504 <printf>
}
    8000919c:	70a2                	ld	ra,40(sp)
    8000919e:	7402                	ld	s0,32(sp)
    800091a0:	64e2                	ld	s1,24(sp)
    800091a2:	6942                	ld	s2,16(sp)
    800091a4:	69a2                	ld	s3,8(sp)
    800091a6:	6a02                	ld	s4,0(sp)
    800091a8:	6145                	addi	sp,sp,48
    800091aa:	8082                	ret

00000000800091ac <debug_disk_io>:

// 磁盘I/O统计（需要在实际实现中添加计数器）
static int disk_read_count = 0;
static int disk_write_count = 0;

void debug_disk_io(void) {
    800091ac:	1141                	addi	sp,sp,-16
    800091ae:	e406                	sd	ra,8(sp)
    800091b0:	e022                	sd	s0,0(sp)
    800091b2:	0800                	addi	s0,sp,16
    printf("=== Disk I/O Statistics ===\n");
    800091b4:	00006517          	auipc	a0,0x6
    800091b8:	f0c50513          	addi	a0,a0,-244 # 8000f0c0 <digits+0x4f10>
    800091bc:	ffff7097          	auipc	ra,0xffff7
    800091c0:	348080e7          	jalr	840(ra) # 80000504 <printf>
    printf("Disk reads: %d\n", disk_read_count);
    800091c4:	4581                	li	a1,0
    800091c6:	00006517          	auipc	a0,0x6
    800091ca:	f1a50513          	addi	a0,a0,-230 # 8000f0e0 <digits+0x4f30>
    800091ce:	ffff7097          	auipc	ra,0xffff7
    800091d2:	336080e7          	jalr	822(ra) # 80000504 <printf>
    printf("Disk writes: %d\n", disk_write_count);
    800091d6:	4581                	li	a1,0
    800091d8:	00006517          	auipc	a0,0x6
    800091dc:	f1850513          	addi	a0,a0,-232 # 8000f0f0 <digits+0x4f40>
    800091e0:	ffff7097          	auipc	ra,0xffff7
    800091e4:	324080e7          	jalr	804(ra) # 80000504 <printf>
    printf("=== End of Disk I/O Statistics ===\n");
    800091e8:	00006517          	auipc	a0,0x6
    800091ec:	f2050513          	addi	a0,a0,-224 # 8000f108 <digits+0x4f58>
    800091f0:	ffff7097          	auipc	ra,0xffff7
    800091f4:	314080e7          	jalr	788(ra) # 80000504 <printf>
}
    800091f8:	60a2                	ld	ra,8(sp)
    800091fa:	6402                	ld	s0,0(sp)
    800091fc:	0141                	addi	sp,sp,16
    800091fe:	8082                	ret

0000000080009200 <filesystem_test_runner>:

// ==================== 主测试运行器 ====================

static void filesystem_test_runner(void) {
    80009200:	1101                	addi	sp,sp,-32
    80009202:	ec06                	sd	ra,24(sp)
    80009204:	e822                	sd	s0,16(sp)
    80009206:	e426                	sd	s1,8(sp)
    80009208:	1000                	addi	s0,sp,32
    printf("\n");
    8000920a:	00002517          	auipc	a0,0x2
    8000920e:	5ae50513          	addi	a0,a0,1454 # 8000b7b8 <digits+0x1608>
    80009212:	ffff7097          	auipc	ra,0xffff7
    80009216:	2f2080e7          	jalr	754(ra) # 80000504 <printf>
    printf("========================================\n");
    8000921a:	00004517          	auipc	a0,0x4
    8000921e:	51e50513          	addi	a0,a0,1310 # 8000d738 <digits+0x3588>
    80009222:	ffff7097          	auipc	ra,0xffff7
    80009226:	2e2080e7          	jalr	738(ra) # 80000504 <printf>
    printf("    FILESYSTEM TEST SUITE\n");
    8000922a:	00006517          	auipc	a0,0x6
    8000922e:	f0650513          	addi	a0,a0,-250 # 8000f130 <digits+0x4f80>
    80009232:	ffff7097          	auipc	ra,0xffff7
    80009236:	2d2080e7          	jalr	722(ra) # 80000504 <printf>
    printf("========================================\n");
    8000923a:	00004517          	auipc	a0,0x4
    8000923e:	4fe50513          	addi	a0,a0,1278 # 8000d738 <digits+0x3588>
    80009242:	ffff7097          	auipc	ra,0xffff7
    80009246:	2c2080e7          	jalr	706(ra) # 80000504 <printf>
    
    test_failures = 0;
    8000924a:	00006497          	auipc	s1,0x6
    8000924e:	67648493          	addi	s1,s1,1654 # 8000f8c0 <test_failures>
    80009252:	0004a023          	sw	zero,0(s1)
    
    // 运行所有测试
    test_filesystem_integrity();
    80009256:	fffff097          	auipc	ra,0xfffff
    8000925a:	5da080e7          	jalr	1498(ra) # 80008830 <test_filesystem_integrity>
    printf("\n");
    8000925e:	00002517          	auipc	a0,0x2
    80009262:	55a50513          	addi	a0,a0,1370 # 8000b7b8 <digits+0x1608>
    80009266:	ffff7097          	auipc	ra,0xffff7
    8000926a:	29e080e7          	jalr	670(ra) # 80000504 <printf>
    
    test_concurrent_access();
    8000926e:	00000097          	auipc	ra,0x0
    80009272:	866080e7          	jalr	-1946(ra) # 80008ad4 <test_concurrent_access>
    printf("\n");
    80009276:	00002517          	auipc	a0,0x2
    8000927a:	54250513          	addi	a0,a0,1346 # 8000b7b8 <digits+0x1608>
    8000927e:	ffff7097          	auipc	ra,0xffff7
    80009282:	286080e7          	jalr	646(ra) # 80000504 <printf>
    
    test_crash_recovery();
    80009286:	00000097          	auipc	ra,0x0
    8000928a:	d14080e7          	jalr	-748(ra) # 80008f9a <test_crash_recovery>
    printf("\n");
    8000928e:	00002517          	auipc	a0,0x2
    80009292:	52a50513          	addi	a0,a0,1322 # 8000b7b8 <digits+0x1608>
    80009296:	ffff7097          	auipc	ra,0xffff7
    8000929a:	26e080e7          	jalr	622(ra) # 80000504 <printf>
    
    test_filesystem_performance();
    8000929e:	00000097          	auipc	ra,0x0
    800092a2:	954080e7          	jalr	-1708(ra) # 80008bf2 <test_filesystem_performance>
    printf("\n");
    800092a6:	00002517          	auipc	a0,0x2
    800092aa:	51250513          	addi	a0,a0,1298 # 8000b7b8 <digits+0x1608>
    800092ae:	ffff7097          	auipc	ra,0xffff7
    800092b2:	256080e7          	jalr	598(ra) # 80000504 <printf>
    
    // 调试信息
    debug_filesystem_state();
    800092b6:	00000097          	auipc	ra,0x0
    800092ba:	b72080e7          	jalr	-1166(ra) # 80008e28 <debug_filesystem_state>
    printf("\n");
    800092be:	00002517          	auipc	a0,0x2
    800092c2:	4fa50513          	addi	a0,a0,1274 # 8000b7b8 <digits+0x1608>
    800092c6:	ffff7097          	auipc	ra,0xffff7
    800092ca:	23e080e7          	jalr	574(ra) # 80000504 <printf>
    debug_inode_usage();
    800092ce:	00000097          	auipc	ra,0x0
    800092d2:	e46080e7          	jalr	-442(ra) # 80009114 <debug_inode_usage>
    printf("\n");
    800092d6:	00002517          	auipc	a0,0x2
    800092da:	4e250513          	addi	a0,a0,1250 # 8000b7b8 <digits+0x1608>
    800092de:	ffff7097          	auipc	ra,0xffff7
    800092e2:	226080e7          	jalr	550(ra) # 80000504 <printf>
    debug_disk_io();
    800092e6:	00000097          	auipc	ra,0x0
    800092ea:	ec6080e7          	jalr	-314(ra) # 800091ac <debug_disk_io>
    printf("\n");
    800092ee:	00002517          	auipc	a0,0x2
    800092f2:	4ca50513          	addi	a0,a0,1226 # 8000b7b8 <digits+0x1608>
    800092f6:	ffff7097          	auipc	ra,0xffff7
    800092fa:	20e080e7          	jalr	526(ra) # 80000504 <printf>
    
    // 输出最终结果
    printf("========================================\n");
    800092fe:	00004517          	auipc	a0,0x4
    80009302:	43a50513          	addi	a0,a0,1082 # 8000d738 <digits+0x3588>
    80009306:	ffff7097          	auipc	ra,0xffff7
    8000930a:	1fe080e7          	jalr	510(ra) # 80000504 <printf>
    if (test_failures == 0) {
    8000930e:	408c                	lw	a1,0(s1)
    80009310:	e595                	bnez	a1,8000933c <filesystem_test_runner+0x13c>
        printf("✓ ALL FILESYSTEM TESTS PASSED\n");
    80009312:	00006517          	auipc	a0,0x6
    80009316:	e3e50513          	addi	a0,a0,-450 # 8000f150 <digits+0x4fa0>
    8000931a:	ffff7097          	auipc	ra,0xffff7
    8000931e:	1ea080e7          	jalr	490(ra) # 80000504 <printf>
    } else {
        printf("✗ %d FILESYSTEM TEST(S) FAILED\n", test_failures);
    }
    printf("========================================\n");
    80009322:	00004517          	auipc	a0,0x4
    80009326:	41650513          	addi	a0,a0,1046 # 8000d738 <digits+0x3588>
    8000932a:	ffff7097          	auipc	ra,0xffff7
    8000932e:	1da080e7          	jalr	474(ra) # 80000504 <printf>
    
    exit_process(0);
    80009332:	4501                	li	a0,0
    80009334:	ffffb097          	auipc	ra,0xffffb
    80009338:	0f0080e7          	jalr	240(ra) # 80004424 <exit_process>
        printf("✗ %d FILESYSTEM TEST(S) FAILED\n", test_failures);
    8000933c:	00006517          	auipc	a0,0x6
    80009340:	e3c50513          	addi	a0,a0,-452 # 8000f178 <digits+0x4fc8>
    80009344:	ffff7097          	auipc	ra,0xffff7
    80009348:	1c0080e7          	jalr	448(ra) # 80000504 <printf>
    8000934c:	bfd9                	j	80009322 <filesystem_test_runner+0x122>

000000008000934e <run_filesystem_tests>:
}

void run_filesystem_tests(void) {
    8000934e:	1141                	addi	sp,sp,-16
    80009350:	e406                	sd	ra,8(sp)
    80009352:	e022                	sd	s0,0(sp)
    80009354:	0800                	addi	s0,sp,16
    printf("Starting filesystem tests...\n");
    80009356:	00006517          	auipc	a0,0x6
    8000935a:	e4a50513          	addi	a0,a0,-438 # 8000f1a0 <digits+0x4ff0>
    8000935e:	ffff7097          	auipc	ra,0xffff7
    80009362:	1a6080e7          	jalr	422(ra) # 80000504 <printf>
    
    // 先等待一下确保系统稳定
    ksleep(10);
    80009366:	4529                	li	a0,10
    80009368:	ffffb097          	auipc	ra,0xffffb
    8000936c:	e22080e7          	jalr	-478(ra) # 8000418a <ksleep>
    
    int test_runner_pid = create_process(filesystem_test_runner);
    80009370:	00000517          	auipc	a0,0x0
    80009374:	e9050513          	addi	a0,a0,-368 # 80009200 <filesystem_test_runner>
    80009378:	ffffb097          	auipc	ra,0xffffb
    8000937c:	afa080e7          	jalr	-1286(ra) # 80003e72 <create_process>
    
    if(test_runner_pid < 0) {
    80009380:	00054f63          	bltz	a0,8000939e <run_filesystem_tests+0x50>
    80009384:	85aa                	mv	a1,a0
        printf("ERROR: Failed to create filesystem test runner process\n");
        return;
    }
    
    printf("Filesystem test runner started with PID %d\n", test_runner_pid);
    80009386:	00006517          	auipc	a0,0x6
    8000938a:	e7250513          	addi	a0,a0,-398 # 8000f1f8 <digits+0x5048>
    8000938e:	ffff7097          	auipc	ra,0xffff7
    80009392:	176080e7          	jalr	374(ra) # 80000504 <printf>
}
    80009396:	60a2                	ld	ra,8(sp)
    80009398:	6402                	ld	s0,0(sp)
    8000939a:	0141                	addi	sp,sp,16
    8000939c:	8082                	ret
        printf("ERROR: Failed to create filesystem test runner process\n");
    8000939e:	00006517          	auipc	a0,0x6
    800093a2:	e2250513          	addi	a0,a0,-478 # 8000f1c0 <digits+0x5010>
    800093a6:	ffff7097          	auipc	ra,0xffff7
    800093aa:	15e080e7          	jalr	350(ra) # 80000504 <printf>
        return;
    800093ae:	b7e5                	j	80009396 <run_filesystem_tests+0x48>

00000000800093b0 <free_desc_func>:
}

// 释放描述符（参考xv6实现）
static void
free_desc_func(int i)
{
    800093b0:	1141                	addi	sp,sp,-16
    800093b2:	e406                	sd	ra,8(sp)
    800093b4:	e022                	sd	s0,0(sp)
    800093b6:	0800                	addi	s0,sp,16
    if(i >= NUM)
    800093b8:	479d                	li	a5,7
    800093ba:	04a7c563          	blt	a5,a0,80009404 <free_desc_func+0x54>
        panic("free_desc 1");
    if(free_desc[i])
    800093be:	00006797          	auipc	a5,0x6
    800093c2:	51278793          	addi	a5,a5,1298 # 8000f8d0 <free_desc>
    800093c6:	97aa                	add	a5,a5,a0
    800093c8:	0007c783          	lbu	a5,0(a5)
    800093cc:	e7a1                	bnez	a5,80009414 <free_desc_func+0x64>
        panic("free_desc 2");
    desc[i].addr = 0;
    800093ce:	00451713          	slli	a4,a0,0x4
    800093d2:	00006797          	auipc	a5,0x6
    800093d6:	5167b783          	ld	a5,1302(a5) # 8000f8e8 <desc>
    800093da:	97ba                	add	a5,a5,a4
    800093dc:	0007b023          	sd	zero,0(a5)
    desc[i].len = 0;
    800093e0:	0007a423          	sw	zero,8(a5)
    desc[i].flags = 0;
    800093e4:	00079623          	sh	zero,12(a5)
    desc[i].next = 0;
    800093e8:	00079723          	sh	zero,14(a5)
    free_desc[i] = 1;
    800093ec:	00006797          	auipc	a5,0x6
    800093f0:	4e478793          	addi	a5,a5,1252 # 8000f8d0 <free_desc>
    800093f4:	953e                	add	a0,a0,a5
    800093f6:	4785                	li	a5,1
    800093f8:	00f50023          	sb	a5,0(a0)
}
    800093fc:	60a2                	ld	ra,8(sp)
    800093fe:	6402                	ld	s0,0(sp)
    80009400:	0141                	addi	sp,sp,16
    80009402:	8082                	ret
        panic("free_desc 1");
    80009404:	00006517          	auipc	a0,0x6
    80009408:	e2450513          	addi	a0,a0,-476 # 8000f228 <digits+0x5078>
    8000940c:	ffff9097          	auipc	ra,0xffff9
    80009410:	680080e7          	jalr	1664(ra) # 80002a8c <panic>
        panic("free_desc 2");
    80009414:	00006517          	auipc	a0,0x6
    80009418:	e2450513          	addi	a0,a0,-476 # 8000f238 <digits+0x5088>
    8000941c:	ffff9097          	auipc	ra,0xffff9
    80009420:	670080e7          	jalr	1648(ra) # 80002a8c <panic>

0000000080009424 <free_chain>:

// 释放描述符链（参考xv6实现）
static void
free_chain(int i)
{
    80009424:	7179                	addi	sp,sp,-48
    80009426:	f406                	sd	ra,40(sp)
    80009428:	f022                	sd	s0,32(sp)
    8000942a:	ec26                	sd	s1,24(sp)
    8000942c:	e84a                	sd	s2,16(sp)
    8000942e:	e44e                	sd	s3,8(sp)
    80009430:	1800                	addi	s0,sp,48
    80009432:	892a                	mv	s2,a0
    while(1){
        int flag = desc[i].flags;
    80009434:	00006997          	auipc	s3,0x6
    80009438:	4b498993          	addi	s3,s3,1204 # 8000f8e8 <desc>
    8000943c:	00491713          	slli	a4,s2,0x4
    80009440:	0009b783          	ld	a5,0(s3)
    80009444:	97ba                	add	a5,a5,a4
    80009446:	00c7d483          	lhu	s1,12(a5)
        int nxt = desc[i].next;
    8000944a:	854a                	mv	a0,s2
    8000944c:	00e7d903          	lhu	s2,14(a5)
        free_desc_func(i);
    80009450:	00000097          	auipc	ra,0x0
    80009454:	f60080e7          	jalr	-160(ra) # 800093b0 <free_desc_func>
        if(flag & VRING_DESC_F_NEXT)
    80009458:	8885                	andi	s1,s1,1
    8000945a:	f0ed                	bnez	s1,8000943c <free_chain+0x18>
            i = nxt;
        else
            break;
    }
}
    8000945c:	70a2                	ld	ra,40(sp)
    8000945e:	7402                	ld	s0,32(sp)
    80009460:	64e2                	ld	s1,24(sp)
    80009462:	6942                	ld	s2,16(sp)
    80009464:	69a2                	ld	s3,8(sp)
    80009466:	6145                	addi	sp,sp,48
    80009468:	8082                	ret

000000008000946a <virtio_disk_rw>:
    printf("VirtIO disk initialized successfully\n");
}

static void
virtio_disk_rw(struct buf *b, int write)
{
    8000946a:	7175                	addi	sp,sp,-144
    8000946c:	e506                	sd	ra,136(sp)
    8000946e:	e122                	sd	s0,128(sp)
    80009470:	fca6                	sd	s1,120(sp)
    80009472:	f8ca                	sd	s2,112(sp)
    80009474:	f4ce                	sd	s3,104(sp)
    80009476:	f0d2                	sd	s4,96(sp)
    80009478:	ecd6                	sd	s5,88(sp)
    8000947a:	e8da                	sd	s6,80(sp)
    8000947c:	e4de                	sd	s7,72(sp)
    8000947e:	e0e2                	sd	s8,64(sp)
    80009480:	fc66                	sd	s9,56(sp)
    80009482:	f86a                	sd	s10,48(sp)
    80009484:	f46e                	sd	s11,40(sp)
    80009486:	0900                	addi	s0,sp,144
    80009488:	8caa                	mv	s9,a0
    8000948a:	8d2e                	mv	s10,a1
    uint64 sector = b->blockno * (BSIZE / 512);
    8000948c:	455c                	lw	a5,12(a0)
    8000948e:	0037979b          	slliw	a5,a5,0x3
    80009492:	f6f42e23          	sw	a5,-132(s0)
    80009496:	02079d93          	slli	s11,a5,0x20
    8000949a:	020ddd93          	srli	s11,s11,0x20
    for(int i = 0; i < 3; i++){
    8000949e:	4981                	li	s3,0
    for(int i = 0; i < NUM; i++){
    800094a0:	44a1                	li	s1,8
            free_desc[i] = 0;
    800094a2:	00006b17          	auipc	s6,0x6
    800094a6:	42eb0b13          	addi	s6,s6,1070 # 8000f8d0 <free_desc>
    for(int i = 0; i < 3; i++){
    800094aa:	4a8d                	li	s5,3
    while(1){
        if(alloc3_desc(idx) == 0) {
            break;
        }
        // 检查是否有完成的请求
        if(used->idx != used_idx) {
    800094ac:	00006b97          	auipc	s7,0x6
    800094b0:	42cb8b93          	addi	s7,s7,1068 # 8000f8d8 <used>
    800094b4:	a095                	j	80009518 <virtio_disk_rw+0xae>
            free_desc[i] = 0;
    800094b6:	00fb0733          	add	a4,s6,a5
    800094ba:	00070023          	sb	zero,0(a4)
        idx[i] = alloc_desc();
    800094be:	c19c                	sw	a5,0(a1)
        if(idx[i] < 0){
    800094c0:	0207c563          	bltz	a5,800094ea <virtio_disk_rw+0x80>
    for(int i = 0; i < 3; i++){
    800094c4:	2905                	addiw	s2,s2,1
    800094c6:	0611                	addi	a2,a2,4
    800094c8:	2f590e63          	beq	s2,s5,800097c4 <virtio_disk_rw+0x35a>
        idx[i] = alloc_desc();
    800094cc:	85b2                	mv	a1,a2
    for(int i = 0; i < NUM; i++){
    800094ce:	00006717          	auipc	a4,0x6
    800094d2:	40270713          	addi	a4,a4,1026 # 8000f8d0 <free_desc>
    800094d6:	87ce                	mv	a5,s3
        if(free_desc[i]){
    800094d8:	00074683          	lbu	a3,0(a4)
    800094dc:	fee9                	bnez	a3,800094b6 <virtio_disk_rw+0x4c>
    for(int i = 0; i < NUM; i++){
    800094de:	2785                	addiw	a5,a5,1
    800094e0:	0705                	addi	a4,a4,1
    800094e2:	fe979be3          	bne	a5,s1,800094d8 <virtio_disk_rw+0x6e>
        idx[i] = alloc_desc();
    800094e6:	57fd                	li	a5,-1
    800094e8:	c19c                	sw	a5,0(a1)
            for(int j = 0; j < i; j++)
    800094ea:	01205d63          	blez	s2,80009504 <virtio_disk_rw+0x9a>
    800094ee:	8c4e                	mv	s8,s3
                free_desc_func(idx[j]);
    800094f0:	000a2503          	lw	a0,0(s4)
    800094f4:	00000097          	auipc	ra,0x0
    800094f8:	ebc080e7          	jalr	-324(ra) # 800093b0 <free_desc_func>
            for(int j = 0; j < i; j++)
    800094fc:	2c05                	addiw	s8,s8,1
    800094fe:	0a11                	addi	s4,s4,4
    80009500:	ff8918e3          	bne	s2,s8,800094f0 <virtio_disk_rw+0x86>
        if(used->idx != used_idx) {
    80009504:	000bb783          	ld	a5,0(s7)
    80009508:	00006917          	auipc	s2,0x6
    8000950c:	3c492903          	lw	s2,964(s2) # 8000f8cc <used_idx>
    80009510:	0027d703          	lhu	a4,2(a5)
    80009514:	01271763          	bne	a4,s2,80009522 <virtio_disk_rw+0xb8>
    for(int i = 0; i < 3; i++){
    80009518:	f8040a13          	addi	s4,s0,-128
{
    8000951c:	8652                	mv	a2,s4
    for(int i = 0; i < 3; i++){
    8000951e:	894e                	mv	s2,s3
    80009520:	b775                	j	800094cc <virtio_disk_rw+0x62>
            int id = used->ring[used_idx % NUM].id;
    80009522:	41f9571b          	sraiw	a4,s2,0x1f
    80009526:	01d7569b          	srliw	a3,a4,0x1d
    8000952a:	0126873b          	addw	a4,a3,s2
    8000952e:	8b1d                	andi	a4,a4,7
    80009530:	9f15                	subw	a4,a4,a3
    80009532:	070e                	slli	a4,a4,0x3
    80009534:	97ba                	add	a5,a5,a4
            free_chain(id);
    80009536:	43c8                	lw	a0,4(a5)
    80009538:	00000097          	auipc	ra,0x0
    8000953c:	eec080e7          	jalr	-276(ra) # 80009424 <free_chain>
            used_idx++;
    80009540:	2905                	addiw	s2,s2,1
    80009542:	00006797          	auipc	a5,0x6
    80009546:	3927a523          	sw	s2,906(a5) # 8000f8cc <used_idx>
    8000954a:	b78d                	j	800094ac <virtio_disk_rw+0x42>
        panic("virtio_reg: virtio_base_addr not initialized");
    8000954c:	00006517          	auipc	a0,0x6
    80009550:	db450513          	addi	a0,a0,-588 # 8000f300 <digits+0x5150>
    80009554:	ffff9097          	auipc	ra,0xffff9
    80009558:	538080e7          	jalr	1336(ra) # 80002a8c <panic>
            int id = used->ring[used_idx % NUM].id;
            // 只处理不是当前请求的完成
            if(id != idx[0]) {
                free_chain(id);
            }
            used_idx++;
    8000955c:	2485                	addiw	s1,s1,1
    8000955e:	0004879b          	sext.w	a5,s1
    80009562:	0099a023          	sw	s1,0(s3)
        while(used->idx != used_idx) {
    80009566:	00295683          	lhu	a3,2(s2)
    8000956a:	02d78c63          	beq	a5,a3,800095a2 <virtio_disk_rw+0x138>
            __sync_synchronize();
    8000956e:	0ff0000f          	fence
            int id = used->ring[used_idx % NUM].id;
    80009572:	000a3903          	ld	s2,0(s4)
    80009576:	0009a483          	lw	s1,0(s3)
    8000957a:	41f4d79b          	sraiw	a5,s1,0x1f
    8000957e:	01d7d71b          	srliw	a4,a5,0x1d
    80009582:	009707bb          	addw	a5,a4,s1
    80009586:	8b9d                	andi	a5,a5,7
    80009588:	9f99                	subw	a5,a5,a4
    8000958a:	078e                	slli	a5,a5,0x3
    8000958c:	97ca                	add	a5,a5,s2
    8000958e:	43c8                	lw	a0,4(a5)
            if(id != idx[0]) {
    80009590:	f8042783          	lw	a5,-128(s0)
    80009594:	fca784e3          	beq	a5,a0,8000955c <virtio_disk_rw+0xf2>
                free_chain(id);
    80009598:	00000097          	auipc	ra,0x0
    8000959c:	e8c080e7          	jalr	-372(ra) # 80009424 <free_chain>
    800095a0:	bf75                	j	8000955c <virtio_disk_rw+0xf2>
        }
        
        poll_count++;
    800095a2:	001a879b          	addiw	a5,s5,1
    800095a6:	00078a9b          	sext.w	s5,a5
        if(poll_count % 1000000 == 0) {
    800095aa:	0387e7bb          	remw	a5,a5,s8
    800095ae:	cb8d                	beqz	a5,800095e0 <virtio_disk_rw+0x176>
            printf("virtio_disk_rw: polling... status=0x%x, poll_count=%d, used_idx=%d, used->idx=%d\n",
                   ops[idx[0]].status, poll_count, used_idx, used->idx);
        }
        if(poll_count > 10000000) {
    800095b0:	057a8c63          	beq	s5,s7,80009608 <virtio_disk_rw+0x19e>
    while(ops[idx[0]].status == 0xff) {
    800095b4:	f8042703          	lw	a4,-128(s0)
    800095b8:	00371793          	slli	a5,a4,0x3
    800095bc:	97ba                	add	a5,a5,a4
    800095be:	078e                	slli	a5,a5,0x3
    800095c0:	97da                	add	a5,a5,s6
    800095c2:	0407c703          	lbu	a4,64(a5)
    800095c6:	0ff00793          	li	a5,255
    800095ca:	0cf71663          	bne	a4,a5,80009696 <virtio_disk_rw+0x22c>
        while(used->idx != used_idx) {
    800095ce:	0009a683          	lw	a3,0(s3)
    800095d2:	000a3783          	ld	a5,0(s4)
    800095d6:	0027d783          	lhu	a5,2(a5)
    800095da:	f8d79ae3          	bne	a5,a3,8000956e <virtio_disk_rw+0x104>
    800095de:	b7d1                	j	800095a2 <virtio_disk_rw+0x138>
                   ops[idx[0]].status, poll_count, used_idx, used->idx);
    800095e0:	f8042703          	lw	a4,-128(s0)
    800095e4:	00371793          	slli	a5,a4,0x3
    800095e8:	97ba                	add	a5,a5,a4
    800095ea:	078e                	slli	a5,a5,0x3
    800095ec:	97da                	add	a5,a5,s6
            printf("virtio_disk_rw: polling... status=0x%x, poll_count=%d, used_idx=%d, used->idx=%d\n",
    800095ee:	8736                	mv	a4,a3
    800095f0:	8656                	mv	a2,s5
    800095f2:	0407c583          	lbu	a1,64(a5)
    800095f6:	00006517          	auipc	a0,0x6
    800095fa:	d6250513          	addi	a0,a0,-670 # 8000f358 <digits+0x51a8>
    800095fe:	ffff7097          	auipc	ra,0xffff7
    80009602:	f06080e7          	jalr	-250(ra) # 80000504 <printf>
    80009606:	b76d                	j	800095b0 <virtio_disk_rw+0x146>
            printf("virtio_disk_rw: timeout waiting for completion\n");
    80009608:	00006517          	auipc	a0,0x6
    8000960c:	da850513          	addi	a0,a0,-600 # 8000f3b0 <digits+0x5200>
    80009610:	ffff7097          	auipc	ra,0xffff7
    80009614:	ef4080e7          	jalr	-268(ra) # 80000504 <printf>
            printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
    80009618:	f8042583          	lw	a1,-128(s0)
                   idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
    8000961c:	00006717          	auipc	a4,0x6
    80009620:	2cc73703          	ld	a4,716(a4) # 8000f8e8 <desc>
            printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
    80009624:	f8442683          	lw	a3,-124(s0)
    80009628:	f8842783          	lw	a5,-120(s0)
                   idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
    8000962c:	00479813          	slli	a6,a5,0x4
    80009630:	983a                	add	a6,a6,a4
    80009632:	00469513          	slli	a0,a3,0x4
    80009636:	953a                	add	a0,a0,a4
    80009638:	00459613          	slli	a2,a1,0x4
    8000963c:	963a                	add	a2,a2,a4
            printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
    8000963e:	00082803          	lw	a6,0(a6)
    80009642:	4118                	lw	a4,0(a0)
    80009644:	4210                	lw	a2,0(a2)
    80009646:	00006517          	auipc	a0,0x6
    8000964a:	c2a50513          	addi	a0,a0,-982 # 8000f270 <digits+0x50c0>
    8000964e:	ffff7097          	auipc	ra,0xffff7
    80009652:	eb6080e7          	jalr	-330(ra) # 80000504 <printf>
            printf("virtio_disk_rw: avail->idx=%d, used->idx=%d, used_idx=%d\n",
    80009656:	00006697          	auipc	a3,0x6
    8000965a:	2766a683          	lw	a3,630(a3) # 8000f8cc <used_idx>
    8000965e:	00006797          	auipc	a5,0x6
    80009662:	27a7b783          	ld	a5,634(a5) # 8000f8d8 <used>
    80009666:	0027d603          	lhu	a2,2(a5)
    8000966a:	00006797          	auipc	a5,0x6
    8000966e:	2767b783          	ld	a5,630(a5) # 8000f8e0 <avail>
    80009672:	0027d583          	lhu	a1,2(a5)
    80009676:	00006517          	auipc	a0,0x6
    8000967a:	d6a50513          	addi	a0,a0,-662 # 8000f3e0 <digits+0x5230>
    8000967e:	ffff7097          	auipc	ra,0xffff7
    80009682:	e86080e7          	jalr	-378(ra) # 80000504 <printf>
                   avail->idx, used->idx, used_idx);
            panic("virtio_disk_rw completion timeout");
    80009686:	00006517          	auipc	a0,0x6
    8000968a:	d9a50513          	addi	a0,a0,-614 # 8000f420 <digits+0x5270>
    8000968e:	ffff9097          	auipc	ra,0xffff9
    80009692:	3fe080e7          	jalr	1022(ra) # 80002a8c <panic>
        }
    }
    
    // 处理当前请求的完成
    while(used->idx != used_idx) {
    80009696:	00006717          	auipc	a4,0x6
    8000969a:	23672703          	lw	a4,566(a4) # 8000f8cc <used_idx>
    8000969e:	00006797          	auipc	a5,0x6
    800096a2:	23a7b783          	ld	a5,570(a5) # 8000f8d8 <used>
    800096a6:	0027d783          	lhu	a5,2(a5)
    800096aa:	06f70263          	beq	a4,a5,8000970e <virtio_disk_rw+0x2a4>
        __sync_synchronize();
        int id = used->ring[used_idx % NUM].id;
    800096ae:	00006a17          	auipc	s4,0x6
    800096b2:	22aa0a13          	addi	s4,s4,554 # 8000f8d8 <used>
    800096b6:	00006997          	auipc	s3,0x6
    800096ba:	21698993          	addi	s3,s3,534 # 8000f8cc <used_idx>
        __sync_synchronize();
    800096be:	0ff0000f          	fence
        int id = used->ring[used_idx % NUM].id;
    800096c2:	000a3903          	ld	s2,0(s4)
    800096c6:	0009a483          	lw	s1,0(s3)
    800096ca:	41f4d79b          	sraiw	a5,s1,0x1f
    800096ce:	01d7d71b          	srliw	a4,a5,0x1d
    800096d2:	009707bb          	addw	a5,a4,s1
    800096d6:	8b9d                	andi	a5,a5,7
    800096d8:	9f99                	subw	a5,a5,a4
    800096da:	078e                	slli	a5,a5,0x3
    800096dc:	97ca                	add	a5,a5,s2
    800096de:	43c8                	lw	a0,4(a5)
        if(id == idx[0]) {
    800096e0:	f8042783          	lw	a5,-128(s0)
    800096e4:	02a78063          	beq	a5,a0,80009704 <virtio_disk_rw+0x29a>
            used_idx++;
            break;
        }
        free_chain(id);
    800096e8:	00000097          	auipc	ra,0x0
    800096ec:	d3c080e7          	jalr	-708(ra) # 80009424 <free_chain>
        used_idx++;
    800096f0:	2485                	addiw	s1,s1,1
    800096f2:	0004879b          	sext.w	a5,s1
    800096f6:	0099a023          	sw	s1,0(s3)
    while(used->idx != used_idx) {
    800096fa:	00295703          	lhu	a4,2(s2)
    800096fe:	fcf710e3          	bne	a4,a5,800096be <virtio_disk_rw+0x254>
    80009702:	a031                	j	8000970e <virtio_disk_rw+0x2a4>
            used_idx++;
    80009704:	2485                	addiw	s1,s1,1
    80009706:	00006797          	auipc	a5,0x6
    8000970a:	1c97a323          	sw	s1,454(a5) # 8000f8cc <used_idx>
    }

    if(ops[idx[0]].status != 0) {
    8000970e:	f8042483          	lw	s1,-128(s0)
    80009712:	00349793          	slli	a5,s1,0x3
    80009716:	97a6                	add	a5,a5,s1
    80009718:	078e                	slli	a5,a5,0x3
    8000971a:	0045b717          	auipc	a4,0x45b
    8000971e:	48670713          	addi	a4,a4,1158 # 80464ba0 <ops>
    80009722:	97ba                	add	a5,a5,a4
    80009724:	0407c583          	lbu	a1,64(a5)
    80009728:	e58d                	bnez	a1,80009752 <virtio_disk_rw+0x2e8>
               idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
        printf("virtio_disk_rw: sector=%d, write=%d\n", (int)sector, write);
        panic("virtio_disk_rw");
    }

    free_chain(idx[0]);
    8000972a:	8526                	mv	a0,s1
    8000972c:	00000097          	auipc	ra,0x0
    80009730:	cf8080e7          	jalr	-776(ra) # 80009424 <free_chain>
}
    80009734:	60aa                	ld	ra,136(sp)
    80009736:	640a                	ld	s0,128(sp)
    80009738:	74e6                	ld	s1,120(sp)
    8000973a:	7946                	ld	s2,112(sp)
    8000973c:	79a6                	ld	s3,104(sp)
    8000973e:	7a06                	ld	s4,96(sp)
    80009740:	6ae6                	ld	s5,88(sp)
    80009742:	6b46                	ld	s6,80(sp)
    80009744:	6ba6                	ld	s7,72(sp)
    80009746:	6c06                	ld	s8,64(sp)
    80009748:	7ce2                	ld	s9,56(sp)
    8000974a:	7d42                	ld	s10,48(sp)
    8000974c:	7da2                	ld	s11,40(sp)
    8000974e:	6149                	addi	sp,sp,144
    80009750:	8082                	ret
        printf("virtio_disk_rw: device returned error status=0x%x\n", ops[idx[0]].status);
    80009752:	00006517          	auipc	a0,0x6
    80009756:	cf650513          	addi	a0,a0,-778 # 8000f448 <digits+0x5298>
    8000975a:	ffff7097          	auipc	ra,0xffff7
    8000975e:	daa080e7          	jalr	-598(ra) # 80000504 <printf>
               idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
    80009762:	00006717          	auipc	a4,0x6
    80009766:	18673703          	ld	a4,390(a4) # 8000f8e8 <desc>
        printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
    8000976a:	f8442683          	lw	a3,-124(s0)
    8000976e:	f8842783          	lw	a5,-120(s0)
               idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
    80009772:	00479513          	slli	a0,a5,0x4
    80009776:	953a                	add	a0,a0,a4
    80009778:	00469593          	slli	a1,a3,0x4
    8000977c:	95ba                	add	a1,a1,a4
    8000977e:	00449613          	slli	a2,s1,0x4
    80009782:	963a                	add	a2,a2,a4
        printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
    80009784:	00052803          	lw	a6,0(a0)
    80009788:	4198                	lw	a4,0(a1)
    8000978a:	4210                	lw	a2,0(a2)
    8000978c:	85a6                	mv	a1,s1
    8000978e:	00006517          	auipc	a0,0x6
    80009792:	ae250513          	addi	a0,a0,-1310 # 8000f270 <digits+0x50c0>
    80009796:	ffff7097          	auipc	ra,0xffff7
    8000979a:	d6e080e7          	jalr	-658(ra) # 80000504 <printf>
        printf("virtio_disk_rw: sector=%d, write=%d\n", (int)sector, write);
    8000979e:	866a                	mv	a2,s10
    800097a0:	f7c42583          	lw	a1,-132(s0)
    800097a4:	00006517          	auipc	a0,0x6
    800097a8:	cdc50513          	addi	a0,a0,-804 # 8000f480 <digits+0x52d0>
    800097ac:	ffff7097          	auipc	ra,0xffff7
    800097b0:	d58080e7          	jalr	-680(ra) # 80000504 <printf>
        panic("virtio_disk_rw");
    800097b4:	00006517          	auipc	a0,0x6
    800097b8:	cf450513          	addi	a0,a0,-780 # 8000f4a8 <digits+0x52f8>
    800097bc:	ffff9097          	auipc	ra,0xffff9
    800097c0:	2d0080e7          	jalr	720(ra) # 80002a8c <panic>
    struct virtio_blk_req *buf0 = &ops[idx[0]];
    800097c4:	f8042483          	lw	s1,-128(s0)
    800097c8:	00349713          	slli	a4,s1,0x3
    800097cc:	9726                	add	a4,a4,s1
    800097ce:	070e                	slli	a4,a4,0x3
    if(write)
    800097d0:	0045b697          	auipc	a3,0x45b
    800097d4:	3d068693          	addi	a3,a3,976 # 80464ba0 <ops>
    800097d8:	96ba                	add	a3,a3,a4
    800097da:	01a037b3          	snez	a5,s10
    800097de:	c29c                	sw	a5,0(a3)
    buf0->reserved = 0;
    800097e0:	0006a223          	sw	zero,4(a3)
    buf0->sector = sector;
    800097e4:	01b6b423          	sd	s11,8(a3)
    desc[idx[0]].addr = (uint64) buf0;
    800097e8:	00006797          	auipc	a5,0x6
    800097ec:	1007b783          	ld	a5,256(a5) # 8000f8e8 <desc>
    800097f0:	00449a13          	slli	s4,s1,0x4
    800097f4:	01478633          	add	a2,a5,s4
    800097f8:	e214                	sd	a3,0(a2)
    desc[idx[0]].len = sizeof(struct virtio_blk_req) - 1; // 不包括status字段
    800097fa:	04700693          	li	a3,71
    800097fe:	c614                	sw	a3,8(a2)
    desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80009800:	4685                	li	a3,1
    80009802:	00d61623          	sh	a3,12(a2) # 100c <_entry-0x7fffeff4>
    desc[idx[0]].next = idx[1];
    80009806:	f8442903          	lw	s2,-124(s0)
    8000980a:	01261723          	sh	s2,14(a2)
    desc[idx[1]].addr = (uint64) b->data;
    8000980e:	00491993          	slli	s3,s2,0x4
    80009812:	01378633          	add	a2,a5,s3
    80009816:	040c8c93          	addi	s9,s9,64
    8000981a:	01963023          	sd	s9,0(a2)
    desc[idx[1]].len = BSIZE;
    8000981e:	6685                	lui	a3,0x1
    80009820:	c614                	sw	a3,8(a2)
        desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80009822:	001d3693          	seqz	a3,s10
    80009826:	0686                	slli	a3,a3,0x1
    desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80009828:	0016e693          	ori	a3,a3,1
    8000982c:	00d61623          	sh	a3,12(a2)
    desc[idx[1]].next = idx[2];
    80009830:	f8842a83          	lw	s5,-120(s0)
    80009834:	01561723          	sh	s5,14(a2)
    ops[idx[0]].status = 0xff; // device writes 0 on success
    80009838:	0045b617          	auipc	a2,0x45b
    8000983c:	36860613          	addi	a2,a2,872 # 80464ba0 <ops>
    80009840:	00e606b3          	add	a3,a2,a4
    80009844:	55fd                	li	a1,-1
    80009846:	04b68023          	sb	a1,64(a3) # 1040 <_entry-0x7fffefc0>
    desc[idx[2]].addr = (uint64) &ops[idx[0]].status;
    8000984a:	004a9b13          	slli	s6,s5,0x4
    8000984e:	97da                	add	a5,a5,s6
    80009850:	04070713          	addi	a4,a4,64
    80009854:	963a                	add	a2,a2,a4
    80009856:	e390                	sd	a2,0(a5)
    desc[idx[2]].len = 1;
    80009858:	4705                	li	a4,1
    8000985a:	c798                	sw	a4,8(a5)
    desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000985c:	4709                	li	a4,2
    8000985e:	00e79623          	sh	a4,12(a5)
    desc[idx[2]].next = 0;
    80009862:	00079723          	sh	zero,14(a5)
    printf("virtio_disk_rw: desc chain: %d->%d->%d\n", idx[0], idx[1], idx[2]);
    80009866:	86d6                	mv	a3,s5
    80009868:	864a                	mv	a2,s2
    8000986a:	85a6                	mv	a1,s1
    8000986c:	00006517          	auipc	a0,0x6
    80009870:	9dc50513          	addi	a0,a0,-1572 # 8000f248 <digits+0x5098>
    80009874:	ffff7097          	auipc	ra,0xffff7
    80009878:	c90080e7          	jalr	-880(ra) # 80000504 <printf>
           idx[0], (uint32)desc[idx[0]].addr, idx[1], (uint32)desc[idx[1]].addr, idx[2], (uint32)desc[idx[2]].addr);
    8000987c:	00006797          	auipc	a5,0x6
    80009880:	06c7b783          	ld	a5,108(a5) # 8000f8e8 <desc>
    80009884:	9b3e                	add	s6,s6,a5
    80009886:	99be                	add	s3,s3,a5
    80009888:	9a3e                	add	s4,s4,a5
    printf("virtio_disk_rw: desc[%d].addr=0x%x, desc[%d].addr=0x%x, desc[%d].addr=0x%x\n",
    8000988a:	000b2803          	lw	a6,0(s6)
    8000988e:	87d6                	mv	a5,s5
    80009890:	0009a703          	lw	a4,0(s3)
    80009894:	86ca                	mv	a3,s2
    80009896:	000a2603          	lw	a2,0(s4)
    8000989a:	85a6                	mv	a1,s1
    8000989c:	00006517          	auipc	a0,0x6
    800098a0:	9d450513          	addi	a0,a0,-1580 # 8000f270 <digits+0x50c0>
    800098a4:	ffff7097          	auipc	ra,0xffff7
    800098a8:	c60080e7          	jalr	-928(ra) # 80000504 <printf>
    avail->ring[avail->idx % NUM] = idx[0];
    800098ac:	00006697          	auipc	a3,0x6
    800098b0:	03468693          	addi	a3,a3,52 # 8000f8e0 <avail>
    800098b4:	6298                	ld	a4,0(a3)
    800098b6:	00275783          	lhu	a5,2(a4)
    800098ba:	8b9d                	andi	a5,a5,7
    800098bc:	0786                	slli	a5,a5,0x1
    800098be:	97ba                	add	a5,a5,a4
    800098c0:	00979223          	sh	s1,4(a5)
    __sync_synchronize();
    800098c4:	0ff0000f          	fence
    avail->idx += 1; // not % NUM ...
    800098c8:	6298                	ld	a4,0(a3)
    800098ca:	00275783          	lhu	a5,2(a4)
    800098ce:	2785                	addiw	a5,a5,1
    800098d0:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    800098d4:	0ff0000f          	fence
           (avail->idx - 1) % NUM, idx[0], avail->idx);
    800098d8:	629c                	ld	a5,0(a3)
    800098da:	0027d683          	lhu	a3,2(a5)
    800098de:	fff6879b          	addiw	a5,a3,-1
    printf("virtio_disk_rw: added to avail ring[%d]=%d, avail->idx=%d\n", 
    800098e2:	41f7d59b          	sraiw	a1,a5,0x1f
    800098e6:	01d5d59b          	srliw	a1,a1,0x1d
    800098ea:	9fad                	addw	a5,a5,a1
    800098ec:	8b9d                	andi	a5,a5,7
    800098ee:	2681                	sext.w	a3,a3
    800098f0:	f8042603          	lw	a2,-128(s0)
    800098f4:	40b785bb          	subw	a1,a5,a1
    800098f8:	00006517          	auipc	a0,0x6
    800098fc:	9c850513          	addi	a0,a0,-1592 # 8000f2c0 <digits+0x5110>
    80009900:	ffff7097          	auipc	ra,0xffff7
    80009904:	c04080e7          	jalr	-1020(ra) # 80000504 <printf>
    if(virtio_base_addr == 0)
    80009908:	00006797          	auipc	a5,0x6
    8000990c:	fe87b783          	ld	a5,-24(a5) # 8000f8f0 <virtio_base_addr>
    80009910:	c2078ee3          	beqz	a5,8000954c <virtio_disk_rw+0xe2>
    *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80009914:	0407a823          	sw	zero,80(a5)
    printf("virtio_disk_rw: notified device\n");
    80009918:	00006517          	auipc	a0,0x6
    8000991c:	a1850513          	addi	a0,a0,-1512 # 8000f330 <digits+0x5180>
    80009920:	ffff7097          	auipc	ra,0xffff7
    80009924:	be4080e7          	jalr	-1052(ra) # 80000504 <printf>
    int poll_count = 0;
    80009928:	4a81                	li	s5,0
    while(ops[idx[0]].status == 0xff) {
    8000992a:	0045bb17          	auipc	s6,0x45b
    8000992e:	276b0b13          	addi	s6,s6,630 # 80464ba0 <ops>
        while(used->idx != used_idx) {
    80009932:	00006997          	auipc	s3,0x6
    80009936:	f9a98993          	addi	s3,s3,-102 # 8000f8cc <used_idx>
    8000993a:	00006a17          	auipc	s4,0x6
    8000993e:	f9ea0a13          	addi	s4,s4,-98 # 8000f8d8 <used>
        if(poll_count % 1000000 == 0) {
    80009942:	000f4c37          	lui	s8,0xf4
    80009946:	240c0c1b          	addiw	s8,s8,576
        if(poll_count > 10000000) {
    8000994a:	00989bb7          	lui	s7,0x989
    8000994e:	681b8b93          	addi	s7,s7,1665 # 989681 <_entry-0x7f67697f>
    while(ops[idx[0]].status == 0xff) {
    80009952:	b18d                	j	800095b4 <virtio_disk_rw+0x14a>

0000000080009954 <virtio_disk_init_wrapper>:

void
virtio_disk_init_wrapper(void)
{
    80009954:	7179                	addi	sp,sp,-48
    80009956:	f406                	sd	ra,40(sp)
    80009958:	f022                	sd	s0,32(sp)
    8000995a:	ec26                	sd	s1,24(sp)
    8000995c:	e84a                	sd	s2,16(sp)
    8000995e:	e44e                	sd	s3,8(sp)
    80009960:	e052                	sd	s4,0(sp)
    80009962:	1800                	addi	s0,sp,48
    for(uint64 addr = VIRTIO_BASE; addr < VIRTIO_BASE + 10 * VIRTIO_SIZE; addr += VIRTIO_SIZE) {
    80009964:	100014b7          	lui	s1,0x10001
        if(*magic == VIRTIO_MAGIC && *version == VIRTIO_VERSION && *device_id == 2) {
    80009968:	74727737          	lui	a4,0x74727
    8000996c:	97670713          	addi	a4,a4,-1674 # 74726976 <_entry-0xb8d968a>
    80009970:	4609                	li	a2,2
    for(uint64 addr = VIRTIO_BASE; addr < VIRTIO_BASE + 10 * VIRTIO_SIZE; addr += VIRTIO_SIZE) {
    80009972:	100026b7          	lui	a3,0x10002
    80009976:	40068693          	addi	a3,a3,1024 # 10002400 <_entry-0x6fffdc00>
    8000997a:	a029                	j	80009984 <virtio_disk_init_wrapper+0x30>
    8000997c:	20048493          	addi	s1,s1,512 # 10001200 <_entry-0x6fffee00>
    80009980:	1cd48863          	beq	s1,a3,80009b50 <virtio_disk_init_wrapper+0x1fc>
        if(*magic == VIRTIO_MAGIC && *version == VIRTIO_VERSION && *device_id == 2) {
    80009984:	409c                	lw	a5,0(s1)
    80009986:	2781                	sext.w	a5,a5
    80009988:	fee79ae3          	bne	a5,a4,8000997c <virtio_disk_init_wrapper+0x28>
    8000998c:	40dc                	lw	a5,4(s1)
    8000998e:	2781                	sext.w	a5,a5
    80009990:	fec796e3          	bne	a5,a2,8000997c <virtio_disk_init_wrapper+0x28>
    80009994:	449c                	lw	a5,8(s1)
    80009996:	2781                	sext.w	a5,a5
    80009998:	fec792e3          	bne	a5,a2,8000997c <virtio_disk_init_wrapper+0x28>
            printf("Found VirtIO block device at 0x%x\n", (uint32)found_addr);
    8000999c:	0004859b          	sext.w	a1,s1
    800099a0:	00006517          	auipc	a0,0x6
    800099a4:	b1850513          	addi	a0,a0,-1256 # 8000f4b8 <digits+0x5308>
    800099a8:	ffff7097          	auipc	ra,0xffff7
    800099ac:	b5c080e7          	jalr	-1188(ra) # 80000504 <printf>
    if(found_addr == 0) {
    800099b0:	1a048063          	beqz	s1,80009b50 <virtio_disk_init_wrapper+0x1fc>
    virtio_base_addr = found_addr;
    800099b4:	00006917          	auipc	s2,0x6
    800099b8:	f3c90913          	addi	s2,s2,-196 # 8000f8f0 <virtio_base_addr>
    800099bc:	00993023          	sd	s1,0(s2)
    virtio_disk_available = 1;
    800099c0:	4785                	li	a5,1
    800099c2:	00006717          	auipc	a4,0x6
    800099c6:	f0f72323          	sw	a5,-250(a4) # 8000f8c8 <virtio_disk_available>
    printf("VirtIO disk found, initializing...\n");
    800099ca:	00006517          	auipc	a0,0x6
    800099ce:	b9650513          	addi	a0,a0,-1130 # 8000f560 <digits+0x53b0>
    800099d2:	ffff7097          	auipc	ra,0xffff7
    800099d6:	b32080e7          	jalr	-1230(ra) # 80000504 <printf>
    if(virtio_base_addr == 0)
    800099da:	00093783          	ld	a5,0(s2)
    800099de:	1c078a63          	beqz	a5,80009bb2 <virtio_disk_init_wrapper+0x25e>
    *R(VIRTIO_MMIO_STATUS) = 0;
    800099e2:	0607a823          	sw	zero,112(a5)
    *R(VIRTIO_MMIO_STATUS) = status;
    800099e6:	4705                	li	a4,1
    800099e8:	dbb8                	sw	a4,112(a5)
    *R(VIRTIO_MMIO_STATUS) = status;
    800099ea:	470d                	li	a4,3
    800099ec:	dbb8                	sw	a4,112(a5)
    features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800099ee:	4b98                	lw	a4,16(a5)
    *R(VIRTIO_MMIO_DRIVER_FEATURES) = features & 0x1;  // 只接受基本特性
    800099f0:	8b05                	andi	a4,a4,1
    800099f2:	d398                	sw	a4,32(a5)
    *R(VIRTIO_MMIO_STATUS) = status;
    800099f4:	472d                	li	a4,11
    800099f6:	dbb8                	sw	a4,112(a5)
    status = *R(VIRTIO_MMIO_STATUS);
    800099f8:	5bb8                	lw	a4,112(a5)
    800099fa:	0007049b          	sext.w	s1,a4
    if(!(status & VIRTIO_STATUS_FEATURES_OK)) {
    800099fe:	8b21                	andi	a4,a4,8
    80009a00:	1c070163          	beqz	a4,80009bc2 <virtio_disk_init_wrapper+0x26e>
    *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80009a04:	0207a823          	sw	zero,48(a5)
    uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80009a08:	5bcc                	lw	a1,52(a5)
    80009a0a:	2581                	sext.w	a1,a1
    if(max == 0) {
    80009a0c:	1c058863          	beqz	a1,80009bdc <virtio_disk_init_wrapper+0x288>
    if(max < NUM) {
    80009a10:	479d                	li	a5,7
    80009a12:	1eb7f263          	bgeu	a5,a1,80009bf6 <virtio_disk_init_wrapper+0x2a2>
    desc = (struct virtq_desc*)alloc_page();
    80009a16:	ffff7097          	auipc	ra,0xffff7
    80009a1a:	5c2080e7          	jalr	1474(ra) # 80000fd8 <alloc_page>
    80009a1e:	00006917          	auipc	s2,0x6
    80009a22:	eca90913          	addi	s2,s2,-310 # 8000f8e8 <desc>
    80009a26:	00a93023          	sd	a0,0(s2)
    avail = (struct virtq_avail*)alloc_page();
    80009a2a:	ffff7097          	auipc	ra,0xffff7
    80009a2e:	5ae080e7          	jalr	1454(ra) # 80000fd8 <alloc_page>
    80009a32:	00006797          	auipc	a5,0x6
    80009a36:	eaa7b723          	sd	a0,-338(a5) # 8000f8e0 <avail>
    used = (struct virtq_used*)alloc_page();
    80009a3a:	ffff7097          	auipc	ra,0xffff7
    80009a3e:	59e080e7          	jalr	1438(ra) # 80000fd8 <alloc_page>
    80009a42:	86aa                	mv	a3,a0
    80009a44:	00006797          	auipc	a5,0x6
    80009a48:	e8a7ba23          	sd	a0,-364(a5) # 8000f8d8 <used>
    if(!desc || !avail || !used) {
    80009a4c:	00093583          	ld	a1,0(s2)
    80009a50:	1c058863          	beqz	a1,80009c20 <virtio_disk_init_wrapper+0x2cc>
    80009a54:	00006617          	auipc	a2,0x6
    80009a58:	e8c63603          	ld	a2,-372(a2) # 8000f8e0 <avail>
    80009a5c:	1c060263          	beqz	a2,80009c20 <virtio_disk_init_wrapper+0x2cc>
    80009a60:	1c050063          	beqz	a0,80009c20 <virtio_disk_init_wrapper+0x2cc>
    80009a64:	6705                	lui	a4,0x1
    80009a66:	972e                	add	a4,a4,a1
    80009a68:	87ae                	mv	a5,a1
        cdst[i] = c;
    80009a6a:	00078023          	sb	zero,0(a5)
    for(int i = 0; i < n; i++){
    80009a6e:	0785                	addi	a5,a5,1
    80009a70:	fef71de3          	bne	a4,a5,80009a6a <virtio_disk_init_wrapper+0x116>
    80009a74:	6705                	lui	a4,0x1
    80009a76:	9732                	add	a4,a4,a2
    80009a78:	87b2                	mv	a5,a2
        cdst[i] = c;
    80009a7a:	00078023          	sb	zero,0(a5)
    for(int i = 0; i < n; i++){
    80009a7e:	0785                	addi	a5,a5,1
    80009a80:	fef71de3          	bne	a4,a5,80009a7a <virtio_disk_init_wrapper+0x126>
    80009a84:	6705                	lui	a4,0x1
    80009a86:	9736                	add	a4,a4,a3
    80009a88:	87b6                	mv	a5,a3
        cdst[i] = c;
    80009a8a:	00078023          	sb	zero,0(a5)
    for(int i = 0; i < n; i++){
    80009a8e:	0785                	addi	a5,a5,1
    80009a90:	fef71de3          	bne	a4,a5,80009a8a <virtio_disk_init_wrapper+0x136>
        free_desc[i] = 1;
    80009a94:	00006797          	auipc	a5,0x6
    80009a98:	e3c78793          	addi	a5,a5,-452 # 8000f8d0 <free_desc>
    80009a9c:	4705                	li	a4,1
    80009a9e:	00e78023          	sb	a4,0(a5)
    80009aa2:	00e780a3          	sb	a4,1(a5)
    80009aa6:	00e78123          	sb	a4,2(a5)
    80009aaa:	00e781a3          	sb	a4,3(a5)
    80009aae:	00e78223          	sb	a4,4(a5)
    80009ab2:	00e782a3          	sb	a4,5(a5)
    80009ab6:	00e78323          	sb	a4,6(a5)
    80009aba:	00e783a3          	sb	a4,7(a5)
    if(virtio_base_addr == 0)
    80009abe:	00006797          	auipc	a5,0x6
    80009ac2:	e327b783          	ld	a5,-462(a5) # 8000f8f0 <virtio_base_addr>
    80009ac6:	16078a63          	beqz	a5,80009c3a <virtio_disk_init_wrapper+0x2e6>
    *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80009aca:	4721                	li	a4,8
    80009acc:	df98                	sw	a4,56(a5)
    *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)desc;
    80009ace:	0005871b          	sext.w	a4,a1
    80009ad2:	08e7a023          	sw	a4,128(a5)
    *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)desc >> 32;
    80009ad6:	4205d713          	srai	a4,a1,0x20
    80009ada:	08e7a223          	sw	a4,132(a5)
    *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)avail;
    80009ade:	0006071b          	sext.w	a4,a2
    80009ae2:	08e7a823          	sw	a4,144(a5)
    *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)avail >> 32;
    80009ae6:	42065713          	srai	a4,a2,0x20
    80009aea:	08e7aa23          	sw	a4,148(a5)
    *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)used;
    80009aee:	0006871b          	sext.w	a4,a3
    80009af2:	0ae7a023          	sw	a4,160(a5)
    *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)used >> 32;
    80009af6:	4206d713          	srai	a4,a3,0x20
    80009afa:	0ae7a223          	sw	a4,164(a5)
    printf("VirtIO: queue addresses - desc=%p, avail=%p, used=%p\n", 
    80009afe:	00006517          	auipc	a0,0x6
    80009b02:	b2a50513          	addi	a0,a0,-1238 # 8000f628 <digits+0x5478>
    80009b06:	ffff7097          	auipc	ra,0xffff7
    80009b0a:	9fe080e7          	jalr	-1538(ra) # 80000504 <printf>
    if(virtio_base_addr == 0)
    80009b0e:	00006797          	auipc	a5,0x6
    80009b12:	de27b783          	ld	a5,-542(a5) # 8000f8f0 <virtio_base_addr>
    80009b16:	12078a63          	beqz	a5,80009c4a <virtio_disk_init_wrapper+0x2f6>
    *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80009b1a:	4705                	li	a4,1
    80009b1c:	c3f8                	sw	a4,68(a5)
    uint32 queue_ready = *R(VIRTIO_MMIO_QUEUE_READY);
    80009b1e:	43ec                	lw	a1,68(a5)
    80009b20:	2581                	sext.w	a1,a1
    if(queue_ready != 1) {
    80009b22:	12e58c63          	beq	a1,a4,80009c5a <virtio_disk_init_wrapper+0x306>
        printf("VirtIO: ERROR - queue ready flag not set correctly (got %d)\n", queue_ready);
    80009b26:	00006517          	auipc	a0,0x6
    80009b2a:	b3a50513          	addi	a0,a0,-1222 # 8000f660 <digits+0x54b0>
    80009b2e:	ffff7097          	auipc	ra,0xffff7
    80009b32:	9d6080e7          	jalr	-1578(ra) # 80000504 <printf>
        printf("VirtIO: This indicates the device did not accept the queue configuration\n");
    80009b36:	00006517          	auipc	a0,0x6
    80009b3a:	b6a50513          	addi	a0,a0,-1174 # 8000f6a0 <digits+0x54f0>
    80009b3e:	ffff7097          	auipc	ra,0xffff7
    80009b42:	9c6080e7          	jalr	-1594(ra) # 80000504 <printf>
        virtio_disk_available = 0;
    80009b46:	00006797          	auipc	a5,0x6
    80009b4a:	d807a123          	sw	zero,-638(a5) # 8000f8c8 <virtio_disk_available>
        return;
    80009b4e:	a0c9                	j	80009c10 <virtio_disk_init_wrapper+0x2bc>
        printf("VirtIO block device not found. Scanned addresses:\n");
    80009b50:	00006517          	auipc	a0,0x6
    80009b54:	99050513          	addi	a0,a0,-1648 # 8000f4e0 <digits+0x5330>
    80009b58:	ffff7097          	auipc	ra,0xffff7
    80009b5c:	9ac080e7          	jalr	-1620(ra) # 80000504 <printf>
        for(uint64 addr = VIRTIO_BASE; addr < VIRTIO_BASE + 10 * VIRTIO_SIZE; addr += VIRTIO_SIZE) {
    80009b60:	100014b7          	lui	s1,0x10001
            if(*magic == VIRTIO_MAGIC) {
    80009b64:	747279b7          	lui	s3,0x74727
    80009b68:	97698993          	addi	s3,s3,-1674 # 74726976 <_entry-0xb8d968a>
                printf("  0x%x: Device ID = %d\n", (uint32)addr, *device_id);
    80009b6c:	00006a17          	auipc	s4,0x6
    80009b70:	9aca0a13          	addi	s4,s4,-1620 # 8000f518 <digits+0x5368>
        for(uint64 addr = VIRTIO_BASE; addr < VIRTIO_BASE + 10 * VIRTIO_SIZE; addr += VIRTIO_SIZE) {
    80009b74:	10002937          	lui	s2,0x10002
    80009b78:	40090913          	addi	s2,s2,1024 # 10002400 <_entry-0x6fffdc00>
    80009b7c:	a029                	j	80009b86 <virtio_disk_init_wrapper+0x232>
    80009b7e:	20048493          	addi	s1,s1,512 # 10001200 <_entry-0x6fffee00>
    80009b82:	03248063          	beq	s1,s2,80009ba2 <virtio_disk_init_wrapper+0x24e>
            if(*magic == VIRTIO_MAGIC) {
    80009b86:	409c                	lw	a5,0(s1)
    80009b88:	2781                	sext.w	a5,a5
    80009b8a:	ff379ae3          	bne	a5,s3,80009b7e <virtio_disk_init_wrapper+0x22a>
                printf("  0x%x: Device ID = %d\n", (uint32)addr, *device_id);
    80009b8e:	4490                	lw	a2,8(s1)
    80009b90:	2601                	sext.w	a2,a2
    80009b92:	0004859b          	sext.w	a1,s1
    80009b96:	8552                	mv	a0,s4
    80009b98:	ffff7097          	auipc	ra,0xffff7
    80009b9c:	96c080e7          	jalr	-1684(ra) # 80000504 <printf>
    80009ba0:	bff9                	j	80009b7e <virtio_disk_init_wrapper+0x22a>
        panic("VirtIO block device required but not found");
    80009ba2:	00006517          	auipc	a0,0x6
    80009ba6:	98e50513          	addi	a0,a0,-1650 # 8000f530 <digits+0x5380>
    80009baa:	ffff9097          	auipc	ra,0xffff9
    80009bae:	ee2080e7          	jalr	-286(ra) # 80002a8c <panic>
        panic("virtio_reg: virtio_base_addr not initialized");
    80009bb2:	00005517          	auipc	a0,0x5
    80009bb6:	74e50513          	addi	a0,a0,1870 # 8000f300 <digits+0x5150>
    80009bba:	ffff9097          	auipc	ra,0xffff9
    80009bbe:	ed2080e7          	jalr	-302(ra) # 80002a8c <panic>
        printf("VirtIO: features not accepted\n");
    80009bc2:	00006517          	auipc	a0,0x6
    80009bc6:	9c650513          	addi	a0,a0,-1594 # 8000f588 <digits+0x53d8>
    80009bca:	ffff7097          	auipc	ra,0xffff7
    80009bce:	93a080e7          	jalr	-1734(ra) # 80000504 <printf>
        virtio_disk_available = 0;
    80009bd2:	00006797          	auipc	a5,0x6
    80009bd6:	ce07ab23          	sw	zero,-778(a5) # 8000f8c8 <virtio_disk_available>
        return;
    80009bda:	a81d                	j	80009c10 <virtio_disk_init_wrapper+0x2bc>
        printf("VirtIO: cannot find virtio disk queue\n");
    80009bdc:	00006517          	auipc	a0,0x6
    80009be0:	9cc50513          	addi	a0,a0,-1588 # 8000f5a8 <digits+0x53f8>
    80009be4:	ffff7097          	auipc	ra,0xffff7
    80009be8:	920080e7          	jalr	-1760(ra) # 80000504 <printf>
        virtio_disk_available = 0;
    80009bec:	00006797          	auipc	a5,0x6
    80009bf0:	cc07ae23          	sw	zero,-804(a5) # 8000f8c8 <virtio_disk_available>
        return;
    80009bf4:	a831                	j	80009c10 <virtio_disk_init_wrapper+0x2bc>
        printf("VirtIO: queue too small (%d < %d)\n", max, NUM);
    80009bf6:	4621                	li	a2,8
    80009bf8:	00006517          	auipc	a0,0x6
    80009bfc:	9d850513          	addi	a0,a0,-1576 # 8000f5d0 <digits+0x5420>
    80009c00:	ffff7097          	auipc	ra,0xffff7
    80009c04:	904080e7          	jalr	-1788(ra) # 80000504 <printf>
        virtio_disk_available = 0;
    80009c08:	00006797          	auipc	a5,0x6
    80009c0c:	cc07a023          	sw	zero,-832(a5) # 8000f8c8 <virtio_disk_available>
    virtio_disk_init();
}
    80009c10:	70a2                	ld	ra,40(sp)
    80009c12:	7402                	ld	s0,32(sp)
    80009c14:	64e2                	ld	s1,24(sp)
    80009c16:	6942                	ld	s2,16(sp)
    80009c18:	69a2                	ld	s3,8(sp)
    80009c1a:	6a02                	ld	s4,0(sp)
    80009c1c:	6145                	addi	sp,sp,48
    80009c1e:	8082                	ret
        printf("VirtIO: failed to allocate virtqueue memory\n");
    80009c20:	00006517          	auipc	a0,0x6
    80009c24:	9d850513          	addi	a0,a0,-1576 # 8000f5f8 <digits+0x5448>
    80009c28:	ffff7097          	auipc	ra,0xffff7
    80009c2c:	8dc080e7          	jalr	-1828(ra) # 80000504 <printf>
        virtio_disk_available = 0;
    80009c30:	00006797          	auipc	a5,0x6
    80009c34:	c807ac23          	sw	zero,-872(a5) # 8000f8c8 <virtio_disk_available>
        return;
    80009c38:	bfe1                	j	80009c10 <virtio_disk_init_wrapper+0x2bc>
        panic("virtio_reg: virtio_base_addr not initialized");
    80009c3a:	00005517          	auipc	a0,0x5
    80009c3e:	6c650513          	addi	a0,a0,1734 # 8000f300 <digits+0x5150>
    80009c42:	ffff9097          	auipc	ra,0xffff9
    80009c46:	e4a080e7          	jalr	-438(ra) # 80002a8c <panic>
    80009c4a:	00005517          	auipc	a0,0x5
    80009c4e:	6b650513          	addi	a0,a0,1718 # 8000f300 <digits+0x5150>
    80009c52:	ffff9097          	auipc	ra,0xffff9
    80009c56:	e3a080e7          	jalr	-454(ra) # 80002a8c <panic>
    printf("VirtIO: queue ready flag set (verified=%d)\n", queue_ready);
    80009c5a:	4585                	li	a1,1
    80009c5c:	00006517          	auipc	a0,0x6
    80009c60:	a9450513          	addi	a0,a0,-1388 # 8000f6f0 <digits+0x5540>
    80009c64:	ffff7097          	auipc	ra,0xffff7
    80009c68:	8a0080e7          	jalr	-1888(ra) # 80000504 <printf>
    status |= VIRTIO_STATUS_DRIVER_OK;
    80009c6c:	0044e493          	ori	s1,s1,4
    if(virtio_base_addr == 0)
    80009c70:	00006797          	auipc	a5,0x6
    80009c74:	c807b783          	ld	a5,-896(a5) # 8000f8f0 <virtio_base_addr>
    80009c78:	cf9d                	beqz	a5,80009cb6 <virtio_disk_init_wrapper+0x362>
    *R(VIRTIO_MMIO_STATUS) = status;
    80009c7a:	dba4                	sw	s1,112(a5)
    __sync_synchronize();
    80009c7c:	0ff0000f          	fence
    if(virtio_base_addr == 0)
    80009c80:	00006797          	auipc	a5,0x6
    80009c84:	c707b783          	ld	a5,-912(a5) # 8000f8f0 <virtio_base_addr>
    80009c88:	cf9d                	beqz	a5,80009cc6 <virtio_disk_init_wrapper+0x372>
    status = *R(VIRTIO_MMIO_STATUS);
    80009c8a:	5ba4                	lw	s1,112(a5)
    80009c8c:	2481                	sext.w	s1,s1
    printf("VirtIO: final device status=0x%x\n", status);
    80009c8e:	85a6                	mv	a1,s1
    80009c90:	00006517          	auipc	a0,0x6
    80009c94:	a9050513          	addi	a0,a0,-1392 # 8000f720 <digits+0x5570>
    80009c98:	ffff7097          	auipc	ra,0xffff7
    80009c9c:	86c080e7          	jalr	-1940(ra) # 80000504 <printf>
    if(!(status & VIRTIO_STATUS_DRIVER_OK)) {
    80009ca0:	8891                	andi	s1,s1,4
    80009ca2:	c895                	beqz	s1,80009cd6 <virtio_disk_init_wrapper+0x382>
    printf("VirtIO disk initialized successfully\n");
    80009ca4:	00006517          	auipc	a0,0x6
    80009ca8:	adc50513          	addi	a0,a0,-1316 # 8000f780 <digits+0x55d0>
    80009cac:	ffff7097          	auipc	ra,0xffff7
    80009cb0:	858080e7          	jalr	-1960(ra) # 80000504 <printf>
}
    80009cb4:	bfb1                	j	80009c10 <virtio_disk_init_wrapper+0x2bc>
        panic("virtio_reg: virtio_base_addr not initialized");
    80009cb6:	00005517          	auipc	a0,0x5
    80009cba:	64a50513          	addi	a0,a0,1610 # 8000f300 <digits+0x5150>
    80009cbe:	ffff9097          	auipc	ra,0xffff9
    80009cc2:	dce080e7          	jalr	-562(ra) # 80002a8c <panic>
    80009cc6:	00005517          	auipc	a0,0x5
    80009cca:	63a50513          	addi	a0,a0,1594 # 8000f300 <digits+0x5150>
    80009cce:	ffff9097          	auipc	ra,0xffff9
    80009cd2:	dbe080e7          	jalr	-578(ra) # 80002a8c <panic>
        printf("VirtIO: ERROR - DRIVER_OK not set in final status\n");
    80009cd6:	00006517          	auipc	a0,0x6
    80009cda:	a7250513          	addi	a0,a0,-1422 # 8000f748 <digits+0x5598>
    80009cde:	ffff7097          	auipc	ra,0xffff7
    80009ce2:	826080e7          	jalr	-2010(ra) # 80000504 <printf>
        virtio_disk_available = 0;
    80009ce6:	00006797          	auipc	a5,0x6
    80009cea:	be07a123          	sw	zero,-1054(a5) # 8000f8c8 <virtio_disk_available>
        return;
    80009cee:	b70d                	j	80009c10 <virtio_disk_init_wrapper+0x2bc>

0000000080009cf0 <virtio_disk_read>:

void
virtio_disk_read(struct buf *b)
{
    80009cf0:	1141                	addi	sp,sp,-16
    80009cf2:	e406                	sd	ra,8(sp)
    80009cf4:	e022                	sd	s0,0(sp)
    80009cf6:	0800                	addi	s0,sp,16
    if(!virtio_disk_available) {
    80009cf8:	00006797          	auipc	a5,0x6
    80009cfc:	bd07a783          	lw	a5,-1072(a5) # 8000f8c8 <virtio_disk_available>
    80009d00:	cb91                	beqz	a5,80009d14 <virtio_disk_read+0x24>
        panic("virtio_disk_read: VirtIO disk not available");
    }
    virtio_disk_rw(b, 0);
    80009d02:	4581                	li	a1,0
    80009d04:	fffff097          	auipc	ra,0xfffff
    80009d08:	766080e7          	jalr	1894(ra) # 8000946a <virtio_disk_rw>
}
    80009d0c:	60a2                	ld	ra,8(sp)
    80009d0e:	6402                	ld	s0,0(sp)
    80009d10:	0141                	addi	sp,sp,16
    80009d12:	8082                	ret
        panic("virtio_disk_read: VirtIO disk not available");
    80009d14:	00006517          	auipc	a0,0x6
    80009d18:	a9450513          	addi	a0,a0,-1388 # 8000f7a8 <digits+0x55f8>
    80009d1c:	ffff9097          	auipc	ra,0xffff9
    80009d20:	d70080e7          	jalr	-656(ra) # 80002a8c <panic>

0000000080009d24 <virtio_disk_write>:

void
virtio_disk_write(struct buf *b)
{
    80009d24:	1141                	addi	sp,sp,-16
    80009d26:	e406                	sd	ra,8(sp)
    80009d28:	e022                	sd	s0,0(sp)
    80009d2a:	0800                	addi	s0,sp,16
    if(!virtio_disk_available) {
    80009d2c:	00006797          	auipc	a5,0x6
    80009d30:	b9c7a783          	lw	a5,-1124(a5) # 8000f8c8 <virtio_disk_available>
    80009d34:	cb91                	beqz	a5,80009d48 <virtio_disk_write+0x24>
        panic("virtio_disk_write: VirtIO disk not available");
    }
    virtio_disk_rw(b, 1);
    80009d36:	4585                	li	a1,1
    80009d38:	fffff097          	auipc	ra,0xfffff
    80009d3c:	732080e7          	jalr	1842(ra) # 8000946a <virtio_disk_rw>
}
    80009d40:	60a2                	ld	ra,8(sp)
    80009d42:	6402                	ld	s0,0(sp)
    80009d44:	0141                	addi	sp,sp,16
    80009d46:	8082                	ret
        panic("virtio_disk_write: VirtIO disk not available");
    80009d48:	00006517          	auipc	a0,0x6
    80009d4c:	a9050513          	addi	a0,a0,-1392 # 8000f7d8 <digits+0x5628>
    80009d50:	ffff9097          	auipc	ra,0xffff9
    80009d54:	d3c080e7          	jalr	-708(ra) # 80002a8c <panic>

0000000080009d58 <poweroff>:
#include "power.h"

static volatile unsigned int *const VIRT_TEST = (unsigned int *)0x100000;

void poweroff(void)
{
    80009d58:	1141                	addi	sp,sp,-16
    80009d5a:	e422                	sd	s0,8(sp)
    80009d5c:	0800                	addi	s0,sp,16
    // QEMU virt: 写入 0x5555 到 virt-test 设备触发退出
    *VIRT_TEST = 0x5555;
    80009d5e:	00100737          	lui	a4,0x100
    80009d62:	6795                	lui	a5,0x5
    80009d64:	55578793          	addi	a5,a5,1365 # 5555 <_entry-0x7fffaaab>
    80009d68:	c31c                	sw	a5,0(a4)
}
    80009d6a:	6422                	ld	s0,8(sp)
    80009d6c:	0141                	addi	sp,sp,16
    80009d6e:	8082                	ret
	...
