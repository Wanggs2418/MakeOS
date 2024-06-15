cd chapter02
nasm -o mbr.bin mbr.s
# 查看文件大小
ls -lb mbr.bin
# dd-磁盘操作
# if-in file,of-out file bs-blcok size(B),count-1拷贝的块数, notrunc不打断文件
cd chapter02
dd if=mbr.bin of=../hd60M.img bs=512 count=1 conv=notrunc