# -f指定编译输出的文件格式
nasm -f elf -o syscall_write.o syscall_write.S
ld -m elf_i386 -o syscall_write.bin syscall_write.o