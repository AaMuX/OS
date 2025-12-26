# 编译器设置
CC = riscv64-unknown-elf-gcc
LD = riscv64-unknown-elf-ld
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

# 编译选项
CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb
CFLAGS += -MD
CFLAGS += -mcmodel=medany
CFLAGS += -ffreestanding -fno-common -nostdlib -mno-relax
CFLAGS += -Ikernel
CFLAGS += -march=rv64gc

# 链接选项
LDFLAGS = -z max-page-size=4096

# 目标文件列表
OBJS = \
    entry.o \
    main.o \
    uart.o \
    printf.o \
    console.o \
    pmm.o \
    vm.o \
    panic.o \
    trapentry.o \
    trap.o \
    sbi.o \
    timer.o \
    spinlock.o \
    sleeplock.o \
    swtch.o \
    proc.o \
    proc_test.o \
    bio.o \
    log.o \
    fs.o \
    fsinit.o \
    file.o \
    fs_test.o \
    virtio_disk.o \
    power.o

# 磁盘镜像文件大小（MB）
FSIMG_SIZE = 1

# 默认目标
all: os.elf

# 各个源文件的编译规则
entry.o: kernel/entry.S
	$(CC) $(CFLAGS) -c -o $@ $<

trapentry.o: kernel/trapentry.S
	$(CC) $(CFLAGS) -c -o $@ $<

swtch.o: kernel/swtch.S
	$(CC) $(CFLAGS) -c -o $@ $<

main.o: kernel/main.c
	$(CC) $(CFLAGS) -c -o $@ $<

uart.o: kernel/uart.c
	$(CC) $(CFLAGS) -c -o $@ $<

printf.o: kernel/printf.c
	$(CC) $(CFLAGS) -c -o $@ $<

console.o: kernel/console.c
	$(CC) $(CFLAGS) -c -o $@ $<

pmm.o: kernel/pmm.c
	$(CC) $(CFLAGS) -c -o $@ $<

vm.o: kernel/vm.c
	$(CC) $(CFLAGS) -c -o $@ $<

panic.o: kernel/panic.c
	$(CC) $(CFLAGS) -c -o $@ $<

trap.o: kernel/trap.c
	$(CC) $(CFLAGS) -c -o $@ $<

sbi.o: kernel/sbi.c
	$(CC) $(CFLAGS) -c -o $@ $<

timer.o: kernel/timer.c
	$(CC) $(CFLAGS) -c -o $@ $<

spinlock.o: kernel/spinlock.c
	$(CC) $(CFLAGS) -c -o $@ $<

sleeplock.o: kernel/sleeplock.c
	$(CC) $(CFLAGS) -c -o $@ $<

proc.o: kernel/proc.c
	$(CC) $(CFLAGS) -c -o $@ $<

proc_test.o: kernel/proc_test.c
	$(CC) $(CFLAGS) -c -o $@ $<

bio.o: kernel/bio.c
	$(CC) $(CFLAGS) -c -o $@ $<

log.o: kernel/log.c
	$(CC) $(CFLAGS) -c -o $@ $<

fs.o: kernel/fs.c
	$(CC) $(CFLAGS) -c -o $@ $<

fsinit.o: kernel/fsinit.c
	$(CC) $(CFLAGS) -c -o $@ $<

file.o: kernel/file.c
	$(CC) $(CFLAGS) -c -o $@ $<

fs_test.o: kernel/fs_test.c
	$(CC) $(CFLAGS) -c -o $@ $<

virtio_disk.o: kernel/virtio_disk.c
	$(CC) $(CFLAGS) -c -o $@ $<

power.o: kernel/power.c
	$(CC) $(CFLAGS) -c -o $@ $<

# 内核ELF文件
os.elf: $(OBJS) kernel/kernel.ld
	$(LD) $(LDFLAGS) -T kernel/kernel.ld -o $@ $(OBJS)
	$(OBJDUMP) -S os.elf > os.asm
	$(OBJDUMP) -t os.elf | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > os.sym
	@echo "Kernel built: os.elf"

# 创建磁盘镜像文件
fs.img: os.elf
	@echo "Creating disk image..."
	dd if=/dev/zero of=fs.img bs=1M count=$(FSIMG_SIZE) 2>/dev/null || \
	dd if=/dev/zero of=fs.img bs=1024 count=$$((1024 * $(FSIMG_SIZE))) 2>/dev/null
	@echo "Disk image created: fs.img"

# 运行QEMU
run: os.elf
	qemu-system-riscv64 -machine virt -nographic -bios none -kernel os.elf

# 清理
clean:
	rm -f $(OBJS) os.elf os.asm os.sym fs.img
	@echo "Cleaned build files"

.PHONY: all run clean