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
# 2.mbr_loader
# -----------------------
# clear
cd chapter03
# 包含文件路径,指定库目录
nasm -I include/ -o mbr.bin mbr_loader.s

# 512B大小,MBR写入0扇区
ls -lb mbr.bin
dd if=mbr.bin of=../hd60M.img bs=512 count=1 conv=notrunc

# -----------------------
# 3.mbr_loader
# -----------------------
# clear
# 包含文件路径,指定库目录
nasm -I include/ -o loader.bin loader_real.s

# 512B大小,loader写入2扇区,98B-98字节
ls -lb loader.bin
dd if=loader.bin of=../hd60M.img bs=512 count=1 seek=2 conv=notrunc