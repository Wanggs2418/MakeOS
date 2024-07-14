# -----------------------
# 1.mbr_GPU
# -----------------------
# clear
cd chapter03
nasm -o mbr.bin mbr_GPU.s
# 512B大小
ls -lb mbr.bin
dd if=mbr.bin of=../hd60M.img bs=512 count=1 conv=notrunc

# -----------------------
# 2.mbr
# -----------------------
# clear
cd chapter03
# 包含文件路径,指定库目录
nasm -I include/ -o mbr.bin mbr.s

# 512B大小,MBR写入0扇区
ls -lb mbr.bin
dd if=mbr.bin of=../hd60M.img bs=512 count=1 conv=notrunc

# -----------------------
# 3.loader
# -----------------------
# clear
# 包含文件路径,指定库目录
nasm -I include/ -o loader.bin loader.s

# 512B大小,loader写入2扇区
ls -lb loader.bin
dd if=loader.bin of=../hd60M.img bs=512 count=2 seek=2 conv=notrunc

# -----------------------
# 3.bochs调试
# -----------------------
# 返回上一级目录
cd 
bochs
c
# ctrl+c 中断
# 查看段描述符表
info gdt
creg