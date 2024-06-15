# MakeOS

> [Code Index](https://github.com/yyu/osfs00) | [Linux 发行版](https://www.linuxmi.com/)

### 说明

OrangeS一个操作系统的实现 (于渊) ：WSL Ubuntu-22.04+bochs2.7

操作系统真象还原 (郑纲) ：WSL Ubuntu-20.04+bochs2.6.2



## 0. Tools

### 0.1 GNU/Linux 下的开发环境

用编辑器写代码，Make 调用编译工具生成内核并写入磁盘映像，虚拟机 Bochs 运行所写的 OS。

- 编辑器 vim | emacs；
- 用到 gnu/gcc 中的 C 语言编译器 ；
- 汇编代码编译器 nasm；
- 自动化编译和连接 gnu/make；
- 运行编写的 OS 的虚拟机 bochs；

```bash
sudo apt-get update

# 一组在大多数情况下编译和构建软件所必需的基础工具
# 包含 gcc,Make,gdb,dpkg-dev等
sudo apt-get install build-essential
```

**GCC**

> [GNU Compiler Collection](https://gcc.gnu.org/)

编译器组件，支持多种编程语言，包括 C、C++、Objective-C、Fortran、Ada 和 Go 等。这里主要用到其中的 C 编译器，GCC 要求汇编代码为 AT&T 格式，对于习惯 IBMPC 汇编的读者不友好。



### 0.2 Windows 下开发环境

- 在 Windows 下编写代码；
- 在虚拟机 QEMU 中安装 Linux ，并用 Make 调用 GCC，NASM 等生成内核并写入磁盘映像；
- 在 Windows 下的 Bochs 运行编写的操作系统；



### 0.3 NASM

> [nasm](https://nasm.us/)

在 `WSL` 中借助 `apt` 自动安装

- 对于 Linux 一般安装在 `usr/bin` 目录文件下，其中 `/usr/bin` 前期已经添加到环境变量中；
- 安装到 `/usr/bin/local` 同样性质，不过必要时需手动添加环境变量；

```bash
sudo apt-get update
sudo apt-get install nasm

# 删除软件包，单保留用户数据和配置文件，便于再次安装时恢复以前的设置状态
sudo apt-get remove nasm
# purge 命令在删除包的同时也删除了包的配置文件
sudo apt-get purge nasm
sudo apt-get autoremove             # 删除系统不再使用的孤立软件

# 前置命令，清除过时的软件包，这样可以更精确地释放空间，同时保留当前需要的软件包缓存，以便未来的安装和更新
sudo apt-get autoclean	
sudo apt-get clean                       # 清理所有软件缓存

# 强制删除对应的文件，一般不推荐
sudo rm /usr/bin/nasm
```



### 0.4 Bochs

> [Bochs](https://bochs.sourceforge.io/) |  [安装指南](https://www.cnblogs.com/kendoziyu/p/install-bochs-and-qemu-on-ubuntu-20-04.html)

#### 1 源码编译安装(v2.7)

> 对应 WSL 中 Ubuntu-22.04

从源码安装的版本会在其配置和编译过程中根据所在平台的特性去优化，这是其他软件包所不能比拟的。对于 Bochs 默认安装可能缺少调试功能，因此采用从源码安装。

- 安装到 `/usr` 目录中，编译后的文件分布在 `usr/bin` 和 `usr/share` 中；
- 也可以安装到 `/opt/bochs2.6.2` 目录中，方便对第三方软件管理，但需创建链接到 `/usr/bin` 和 `/usr/share` 中；

**安装到 `/usr` 目录中**

- 主要需求是下载文件，特别是需要递归下载或恢复中断的下载，`wget` 可能是更好的选择；
- 需要与Web服务交互，发送各种类型的HTTP请求，或者需要更灵活的网络操作，`curl ` 可能是更好的选择；

```bash
# 编译安装到 /usr中
wget https://sourceforge.net/projects/bochs/files/bochs/2.7/bochs-2.7.tar.gz
tar -zxvf bochs-2.7.tar.gz

# 安装依赖库,先更新
sudo apt-get update
# gcc,gdb,make等一般Linux自带GUN组件
# 否则安装基础组件 build-essential
#sudo apt-get install build-essential

sudo apt-get install -y libx11-dev libc6-dev build-essential xorg-dev libreadline-dev libgtk2.0-dev

cd bochs-2.7

sudo ./configure \
--prefix=/usr/ \
--enable-x86-debugger \
--enable-debugger \
--enable-iodebug \
--with-x \
--with-x11

sudo make
sudo make install
```

#### 2 Bochs 配置文件(2.7)

> **注意查看参考文件的内容 `bochsrc-sample.txt`，所有参数设置都可以发现；**

```bash
# 针对2.7版本创建虚拟软盘
bximage -fd=1.44M -q f1_44M.img
```

**配置文件位置与编辑**

`vim` 编辑时，`:set number` 设文件行号；

```bash
# 参考文件路径
cd /usr/share/doc/bochs
sudo cp  bochsrc-sample.txt ~/

# 配置文件路径
cd	# 返回 home directory
sudo -s
vim .bochsrc

# 仅输入bochs则默认在当前目录寻找以下配置文件
.bochsrc
bochsrc
bochsrc.txt
bochsrc.bxrc # 针对Windows系统

# 或使用自定文件
bochs -f demo.disk
```

**配置文件内容**

```bash
#########################################################
# Configuration file for Bochs
#########################################################
# 1.Bochs 模拟器使用的内存：32MB
megs: 32

# 2.ROM images 名称
romimage: file=/usr/share/bochs/BIOS-bochs-latest
vgaromimage: file=/usr/share/bochs/VGABIOS-lgpl-latest

# 3.设置Bochs所使用的磁盘
# 命名规则，floppya,floppyb...
floppya: image="f1_44M.img", status=inserted

# 4.选择启动盘符
#boot: disk    # 从硬盘启动
boot: floppy # 默认从软盘启动

# 5.设置日志文件输出
log: bochs.out

# 6.开启或关闭某些功能
mouse: enabled=0
keyboard: keymap=/usr/share/bochs/keymaps/x11-pc-us.map
####################Config End###########################
```

#### 3 源码编译安装(v2.6.2)

> 对应 WSL 中 Ubuntu-20.04

**安装到 `/usr` 目录中**

```bash
# 编译安装到 /usr中
wget https://sourceforge.net/projects/bochs/files/bochs/2.6.2/bochs-2.6.2.tar.gz
tar -zxvf bochs-2.6.2.tar.gz

# 安装依赖库
sudo apt-get install -y libx11-dev libc6-dev build-essential xorg-dev libgtk2.0-dev libreadline-dev

cd bochs-2.6.2

sudo ./configure \
--prefix=/usr/ \
--enable-x86-debugger \
--enable-debugger \
--enable-disasm \
--enable-iodebug \
--with-x \
--with-x11
```

**安装到 `/opt` 目录中**

```bash
# 编译安装到/opt中 需要创建链接
sudo ln -s /opt/bochs2.6.2/bin/bochs /usr/bin/bochs
sudo ln -s /opt/bochs2.6.2/bin/bximage /usr/bin/bximage

# 配置文件
cd /opt/bochs2.6.2/share/doc/bochs
sudo -s
vim bochsrc.disk

sudo rm -i /usr/bin/bochs 
```

#### 4  Bochs 配置文件(v2.6.2)

**创建虚拟硬盘**

```bash
# 创建虚拟硬盘2.6.2(注意版本匹配问题)
bximage -hd -mode="flat" -size=60 -q hd60M.img
```

**配置文件位置与编辑- `/usr` 目录下**

```bash
# 参考文件路径
cd /usr/share/doc/bochs
sudo cp  bochsrc-sample.txt ~/

# 配置文件路径
cd	# 返回 home directory
sudo -s
vim .bochsrc

# 仅输入bochs则默认在当前目录寻找以下配置文件
.bochsrc
bochsrc
bochsrc.txt
bochsrc.bxrc # 针对Windows系统

# 或使用自定文件
bochs -f demo.disk
```

**配置文件位置与编辑- `/opt` 目录下**

**`Bochs` 配置文件：参照 `/opt/bochs2.6.2/share/doc/bochs/bochsrc-sample.txt` 设置 `bochsrc.disk`**；

将其放到 `bochs` 的安装目录下：`sudo cp /opt/bochs2.6.2/share/doc/bochs/bochsrc.disk /opt/bochs2.6.2/bin/`；

**配置文件内容**

确保创建好对应的虚拟硬盘：`hd60M.img`，即 `bximage -hd -mode="flat" -size=60 -q hd60M.img  `；

```bash
#########################################################
# Configuration file for Bochs
#########################################################
# 1.Bochs 模拟器使用的内存：32MB
megs: 32

# 2.ROM images 名称
romimage: file=/usr/share/bochs/BIOS-bochs-latest
vgaromimage: file=/usr/share/bochs/VGABIOS-lgpl-latest

# 3.设置Bochs所使用的磁盘
# 命名规则，floppya,floppyb...
# floppya: 1_44 = a.img, status=inserted

# 4.选择启动盘符
# boot: floppy # 默认从软盘启动
boot: disk    # 从硬盘启动

# 5.设置日志文件输出
log: bochs.out

# 6.开启或关闭某些功能
mouse: enabled=0
keyboard: keymap=/usr/share/bochs/keymaps/x11-pc-us.map

# 硬盘设置,hd60M.img为虚拟硬盘名称
ata0: enabled=1, ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14
ata0-master: type=disk, path="hd60M.img", mode=flat, cylinders=121, heads=16, spt=63

# 增加bochs对gdb的支持，通过gdb可远程连接到机器的1234端口调试
# gdbstub: enabled=1, port=1234, text_base=0, data_base=0, bss_base=0

####################Config End###########################
```

#### 5 Bochs Debug

> [The Bochs internal debugger](https://bochs.sourceforge.io/cgi-bin/topper.pl?name=New+Bochs+Documentation&url=https://bochs.sourceforge.io/doc/docbook/user/index.html)

```bash
############针对 bochs2.7############

# List of CPU integer registers and their contents
r|reg|regs|registers         
# List of all CPU registers and their contents,展示CPU寄存器内容,
info cpu
```



### 0.5 QEMU

> [A generic and open source machine emulator and virtualizer](https://www.qemu.org/ )

- 在 Linux 下开发，Bochs 一般够用，在 Windows 下开发，需要快一点的虚拟机运行 Linux；
- Bochs 完全模拟硬件及一些外围设备，使用 QEMU 可以模拟较多的硬件平台；
- 不需要调试时，也可以在 Linux 中使用 QEMU；
- 当然 Bochs 的调试功能也是可以自由选择 打开 | 关闭；



### 0.6 Other Commands

```bash
# 0.让更改立即生效
source ~/.bashrc

# 1.创建链接
sudo ln -s /opt/bochs2.6.2/bin/bochs /usr/bin/bochs
sudo ln -s /opt/bochs2.6.2/bin/bximage /usr/bin/bximage
sudo ln -s /opt/bochs2.7/bin /usr/bin/bochs_bin # 文件夹生成链接

# 2.添加系统变量
export PATH=/usr/local/bochs2.7/bin:$PATH # 添加到最前面
export PATH=$PATH:/usr/local/bochs2.7/bin # 添加到最后面

# 3.查找与删除
whereis bochs
sudo rm -rf bochs 

# 4.移动和复制
sudo mv bochs-2.7 /opt/bochs-2.7
sudo cp bochs-2.7 /opt/bochs-2.7
```



### 0.7 errors

> [isuue](https://github.com/microsoft/WSL/issues/6389)

1.在 **WSL2 中 Ubuntu22.0.4** 安装 Bochs 遇到如下问题：

```txt
Message: ROM: couldn't open ROM image file '/usr/share/bochs/BIOS-bochs-latest'
```

解决方法：

```bash
sudo apt-get install -y bochsbios
sudo apt-get install -y vgabios
```

2.问题：

```bash
undefined reference to 'pthread_create'
undefined reference to 'pthread_join'
```

解决方法，用 vim 编译 `Makefile`，添加如下命令：

```bash
sudo vim Makefile

# 95行LIBS行尾添加
-lpthread
```

3.`X windows gui was selected, but X windows libraries were not found.`

解决方法：bochs2.3.5 版本不支持，使用高版本 bochs2.7 解决

```bash
wget https://sourceforge.net/projects/bochs/files/bochs/2.7/bochs-2.7.tar.gz
```



## 1. 创建 MBR

### 1.1 概述

#### 术语

-  BIOS（基本输入输出系统）；
-  **MBR**（主引导记录，Master 或 Main Boot Record），整个**硬盘最开始扇区以 0x55 和 0xaa 结束**，MBR 所在的扇区称为 MBR 引导扇区，有且只有一个；
-  EBR（拓展引导记录），与 MBR 结构相同，数量取决于拓展分区；
-  CHS 方式扇区编址起始为1，LBA 扇区编址起始位 0；
-  **OBR**（操作系统引导扇区，OS Boot Record），也称内核加载器，数量与主分区数和扩展分区数有关。位于**各分区最开始的扇区，以 0x55 和 0xaa 结束**；
-  DBR（DOS 操作系统引导记录，DOS Boot Record），后来演变为 OBR；

#### 内存布局

- 内存条需要占用地址总线的地址空间，外设同样需要占用地址总线，因此需要将一些地址总线的地址空间预留出来；
- 即使内存条和地址总线大小一样，因为外设也占用地址空间的缘故，因此内存条利用不完全；

#### BIOS 

BISO 在实模式下运行，而实模式只能访问 1MB 空间。

cpu 采用分段方式访问内存，即段地址+偏移地址。开机的时候，CPU 的 cs:ip 初始化为 **0xF000:0xFFF0**，此时处于实模式，cs 左移 4 位，等效地址为 **0xFFFF0**，此地址中存储一个跳转指令，用于跳转到 BISO 真正的起始地址位置，然后运行 BISO 开机自检，初始化硬件。

BIOS 程序的最后一步是检查软盘的 0 面 0 磁道 1 扇区，最后跳转到 0x7c00 地址处。

#### 过程

1. 接电后，运行，BIOS 位于主板上的一个小程序，空间受限且代码量少；
2. **MBR 在固定位置**，整个磁盘最开始的扇区等待，即 0 盘 0 道 1 扇区；
3. 安装了操作系统的**活动分区**在 MBR 分区变项中**标记为 0x80**，MBR 跳转到活动分区的操作系统内核加载器，**内核加载器在**活动分区的**固定位置**；





### 1.2 MBR

> 0x7c00 中的 MBR

#### 1 原理

BIOS 检查软盘的 0 面 0 磁道 1 扇区，发现以 0xaa，0x55 结尾则表示其为引导扇区 MBR，该扇区包含 512B 的执行程序。之后 BIOS 将这 512B 装载到内存 **0x7c00**，然后跳转到该位置。

注：从 sector[0] 开始，8B，sector[510]\==0x55，sector[511]==0xaa，bochs 采用小端存储，即高位高字节，低位低字节

#### 2 编译写入软盘

引导扇区代码 `mbr.asm`

**$** 给编译器给当前行安排地址，**$\$** 编译器给的 section 起始地址。section 由编译器 nasm 给开发人员逻辑上规划代码用，最终对应的纹理地址解释权由 nasm 决定。

```asm
	org	07c00h			; where the code will be running
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	call	DispStr			; let's display a string
	jmp	$			; 跳转到自身，导致无限循环
DispStr:
	mov	ax, BootMessage
	mov	bp, ax			; ES:BP = string address
	mov	cx, 16			; CX = string length
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 000ch		; RED/BLACK
	mov	dl, 0
	int	10h
	ret
BootMessage:		db	"Hello, OS world!"
times 	510-($-$$)	db	0	; fill zeros to make it exactly 512 bytes
dw 	0xaa55				; boot record signature
```

编译引导扇区代码，写入前面创建号的软盘中 `f1_44M.img`

```bash
# 编译，得到512B
nasm boot.asm -o boot.bin
# notrunc确保软盘文件不被截断
dd if=boot.bin of=../f1_44M.img bs=512 count=1 conv=notrunc
```

#### 3 调试过程

> [The Bochs internal debugger unit8](https://bochs.sourceforge.io/cgi-bin/topper.pl?name=New+Bochs+Documentation&url=https://bochs.sourceforge.io/doc/docbook/user/index.html)

```bash
# 查看命令帮助
h trace-reg

# 设置断点
b 0x7c00
# 继续执行，直到断点处
c
# 查看cpu
info cpu
# 查看内存,64B，x-16进制，b-单个字节查看
x /64xb 0x7c00
# 两个字节查看 h, 共128B
x /64xh 0x7c00

# 追踪reg,让bochs每一步都显示主寄存器的值
trace-reg on
```



## 2. 保护模式













