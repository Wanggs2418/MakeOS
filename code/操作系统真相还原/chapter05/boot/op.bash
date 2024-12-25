# -----------------------
# 1.mbr（0扇区）
# -----------------------
# clear
cd chapter05
# 包含文件路径,指定库目录
nasm -I include/ -o mbr.bin mbr.s

# 512B大小,MBR写入0扇区
ls -lb mbr.bin
dd if=mbr.bin of=../hd60M.img bs=512 count=1 conv=notrunc

# -----------------------
# 2.loader(2，3，4扇区)
# -----------------------
# clear
# 包含文件路径,指定库目录
nasm -I include/ -o loader.bin loader.s

# 512B大小,loader写入2扇区
ls -lb loader.bin
dd if=loader.bin of=~/hd60M.img bs=512 count=3 seek=2 conv=notrunc

# -----------------------
# 3.kernel加载（9扇区）
# -----------------------
# seek=9跨越前9个扇区
# 文件体积小于 count*bs,则按照实际大小写入，100KB-count=200
dd if=kernel.bin of=../hd60M.img bs=512 count=200 seek=9 conv=notrunc



# -----------------------
# bochs调试
# -----------------------
# 返回上一级目录
cd 
bochs
c
# ctrl+c 中断
# 查看段描述符表
info gdt
creg