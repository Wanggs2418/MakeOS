# 查看帮助
gcc --help|grep '\-S'
# 仅编译
gcc -c -o main.o main.c
# file命令检查main.o文件状态
file main.o
# nm查看符号信息
nm main.o
# 链接指定生成可执行文件的起始虚拟地址
# -Ttext ADDRESS Set address of .text section，指定虚拟起始地址
# -e ADDRESS, --entry ADDRESS Set start address，指定程序的起始地址
# main函数为入口地址
ld main.o -Ttext 0xc0001500 -e main -o main.bin

# 直接生成可执行文件
gcc -o main_temp.bin main.c

# 汇编
cat -n main.c
gcc -S -o main.S main.c
gcc -m32 -S -o main32.S main.c
cat -n main.S

# 对于二者符号个数, -l 表示行数
nm main.bin | wc -l
nm main_temp.bin | wc -l

# 运行脚本文件
cd chapter05/kernel
sh ../tool/xxd.sh main.bin 0 300

readelf -e main.bin