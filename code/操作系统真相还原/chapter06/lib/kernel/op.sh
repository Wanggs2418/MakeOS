cd chapter06/lib/kernel/str
# 汇编语言编译器
nasm -f elf -o print.o print.s
# C语言编译
gcc -I kernel/str/ -m32 -c -o main.o main.c
ls -lb main.o
# 链接,main.o在前，print.o中的put_char函数，调用在前，实现在后
ld -Ttext 0xc0001500 -e main -m elf_i386 -o kernel.bin main.o print.o
# 写入虚拟硬盘
ls -lb kernel.bin
dd if=kernel.bin of=~/hd60M.img bs=512 count=200 seek=9 conv=notrunc