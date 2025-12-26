#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "interrupt.h"

// UART寄存器定义
#define Reg(reg) ((volatile unsigned char *)(UART0 + reg))

#define RHR 0 // 接收保持寄存器
#define THR 0 // 发送保持寄存器
#define IER 1 // 中断使能寄存器
#define IIR 2 // 中断标识寄存器
#define FCR 2 // FIFO控制寄存器
#define LCR 3 // 线控制寄存器
#define LSR 5 // 线状态寄存器

#define LSR_RX_READY (1 << 0) // 接收就绪
#define LSR_TX_IDLE (1 << 5)  // 发送空闲

#define IIR_NO_INT 0x01   // 无中断
#define IIR_RX_INT 0x04   // 接收中断
#define IIR_TX_INT 0x02   // 发送中断
#define IIR_LINE_INT 0x06 // 线路状态中断

#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

// 输入缓冲区（环形缓冲区）
#define UART_RX_BUF_SIZE 256
static volatile char uart_rx_buf[UART_RX_BUF_SIZE];
static volatile uint32 uart_rx_head = 0; // 写入位置
static volatile uint32 uart_rx_tail = 0; // 读取位置

// PLIC配置函数
static void plic_init(void)
{
    // 设置UART中断优先级（必须大于0）
    volatile uint32 *plic_priority = (volatile uint32 *)PLIC_PRIORITY(UART_IRQ);
    *plic_priority = 1;

    // 启用UART中断（hart 0）
    volatile uint32 *plic_enable = (volatile uint32 *)PLIC_ENABLE(0, UART_IRQ);
    *plic_enable |= (1 << (UART_IRQ % 32));
}

// UART中断处理函数（处理UART设备的接收中断）
static void uart_handle_interrupt(void)
{
    // 读取中断标识寄存器
    uint8 iir = ReadReg(IIR);

    // 检查中断类型
    if ((iir & IIR_NO_INT) == 0)
    { // 有中断
        if ((iir & 0x0F) == IIR_RX_INT)
        {
            // 接收中断：读取所有可用字符
            while (ReadReg(LSR) & LSR_RX_READY)
            {
                char c = ReadReg(RHR);

                // 将字符放入缓冲区（环形缓冲区）
                uint32 next_head = (uart_rx_head + 1) % UART_RX_BUF_SIZE;
                if (next_head != uart_rx_tail)
                { // 缓冲区未满
                    uart_rx_buf[uart_rx_head] = c;
                    uart_rx_head = next_head;
                }
                else
                {
                    // 缓冲区满，丢弃字符
                    // printf("UART RX buffer full!\n");
                }
            }
        }
        // 可以处理其他中断类型（发送中断、线路状态中断）
    }
}

// 外部中断处理函数（处理所有外部中断，包括UART）
void uart_interrupt_handler(void)
{
    // 从PLIC claim中断（获取中断ID）
    volatile uint32 *plic_claim = (volatile uint32 *)PLIC_CLAIM(0);
    uint32 irq_id = *plic_claim;

    // 处理UART中断
    if (irq_id == UART_IRQ)
    {
        uart_handle_interrupt();
    }
    else if (irq_id != 0)
    {
        // 其他外部中断（暂未实现）
        // printf("Unknown external interrupt: %d\n", irq_id);
    }

    // 完成中断处理（向PLIC发送完成信号）
    if (irq_id != 0)
    {
        *plic_claim = irq_id;
    }
}

void uartinit(void)
{
    // 初始化PLIC
    plic_init();

    // 禁用UART设备中断（先配置好再启用）
    WriteReg(IER, 0x00);

    // 设置波特率
    WriteReg(LCR, 0x80); // 解锁波特率设置
    WriteReg(0, 0x03);   // 38.4K baud
    WriteReg(1, 0x00);
    WriteReg(LCR, 0x03); // 8位数据，无校验

    // 启用FIFO
    WriteReg(FCR, 0x07);

    // 启用UART接收中断（IER bit 0 = 接收中断使能）
    WriteReg(IER, 0x01); // 只启用接收中断

    // 注册外部中断处理函数
    register_interrupt(IRQ_M_EXT, uart_interrupt_handler);

    // 启用机器模式外部中断
    enable_interrupt(IRQ_M_EXT);
}

void uartputc(int c)
{
    // 等待发送器空闲
    while ((ReadReg(LSR) & LSR_TX_IDLE) == 0)
        ;
    WriteReg(THR, c);
}

// 从缓冲区读取字符（非阻塞）
int uartgetc(void)
{
    // 先检查硬件是否有数据（轮询方式，作为备用）
    if (ReadReg(LSR) & LSR_RX_READY)
    {
        return ReadReg(RHR);
    }

    // 从缓冲区读取
    if (uart_rx_head != uart_rx_tail)
    {
        char c = uart_rx_buf[uart_rx_tail];
        uart_rx_tail = (uart_rx_tail + 1) % UART_RX_BUF_SIZE;
        return (unsigned char)c;
    }

    return -1; // 无数据
}

// 检查是否有字符可读
int uart_has_char(void)
{
    return (uart_rx_head != uart_rx_tail) || (ReadReg(LSR) & LSR_RX_READY);
}

// 获取缓冲区中待读取的字符数
int uart_rx_available(void)
{
    if (uart_rx_head >= uart_rx_tail)
    {
        return uart_rx_head - uart_rx_tail;
    }
    else
    {
        return UART_RX_BUF_SIZE - (uart_rx_tail - uart_rx_head);
    }
}

// 新增：输出字符串函数
void uart_puts(const char *s)
{
    while (*s)
    {
        uartputc(*s++);
    }
}

// 新增：强制刷新输出缓冲区
void uart_flush(void)
{
    // 等待所有数据发送完成
    while ((ReadReg(LSR) & LSR_TX_IDLE) == 0)
        ;
}

// 读取一行输入（阻塞直到收到换行符或缓冲区满）
// 注意：这个函数会阻塞等待输入，适合在中断驱动的系统中使用
int uart_readline(char *buf, int maxlen)
{
    int i = 0;
    while (i < maxlen - 1)
    {
        int c = uartgetc();
        if (c >= 0 && c != '\0')
        {
            // 回显字符
            uartputc(c);
            uart_flush();

            if (c == '\n' || c == '\r')
            {
                buf[i] = '\0';
                return i;
            }
            else if (c == '\b' || c == 127)
            { // 退格
                if (i > 0)
                {
                    i--;
                    uartputc('\b');
                    uartputc(' ');
                    uartputc('\b');
                    uart_flush();
                }
            }
            else if (c >= 32 && c < 127)
            { // 可打印字符
                buf[i++] = c;
            }
        }
        // 简单延时，避免CPU占用过高
        for (volatile int j = 0; j < 1000; j++)
            ;
    }
    buf[i] = '\0';
    return i;
}