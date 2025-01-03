# MakeOS

> [Code Index](https://github.com/yyu/osfs00) | [Linux 发行版](https://www.linuxmi.com/) | [VsCode icon meanings](https://code.visualstudio.com/docs/editor/intellisense#_types-of-completions)

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

#### 伪指令

- `dw`：define word，单字数据 |2 字节（16 位）；
- `dd`：define double word，双字数据 |4 字节（32 位）；
- `dq`：define quad word，4字数据 | 8 字节（64位）；



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

# x后接线性地址
# xp后接物理地址，在实模式中用物理地址
# 默认以4字节为单位来显示
help xp

# 退出
q
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



### 0.8 实模式和寻址方式

实模式体现在：程序中用到的地址都是真实的物理地址，即段基址：段内偏移产生的逻辑地址就是物理地址，程序员可以看见完全真实的内存。

8086 是 Intel 第一个 x86 系列的 CPU，即使用 x86 架构。在8086 CPU 中，首次引入段的逻辑形式，以段基址：段内偏移地址的策略访问内存，8086 地址总线 20 位宽，内部寄存器是 16 位，地址总线从 0 开始，即 A0~A19。

**寻址方式**

- 寄存器寻址，操作数在寄存器中；

- 立即数寻址，操作数在指令中给出；

- 内存寻址，内存访问-段基址+偏移地址；

  - 直接寻址，直接给出内存的地址 `mov ax, [0x1234]`，然后再访问内存中的数据

  - 基址寻址，实模式下以 bx, bp 为基址寄存器，ds:bx, ss:bp，保护模式无限制

  - 变址寻址，与基址寻址类似，只是 bx, bp 换成 si, di, 两个寄存器默认的段寄存器位 ds

    `mov [di], ax` 将 ax 中的值存入 ds:di 指向的内存

  - 基址变址寻址，基址寄存器 bx, bp 加上变址寄存器 si, di，`mov [bx+di], ax`



### 0.9 寄存器

不同的 CPU 有不同的寄存器个数，其中 8086CPU 有 14 个寄存器：

**ax, bx, cx, dx, sp, bp, si, di** | **ds, ss, cs, es** | **ip flag(psw)**

#### 通用寄存器

无论是实模式还是保护模式，通用寄存器有 8 个，即**ax, bx, cx, dx, sp, bp, si, di**

<img src="os_img/03.png" style="zoom:80%;" />

通用寄存器具有多种用途，但针对不同名称的通用寄存器具有一些约定的用法；

![](os_img/04.png)

**段寄存器**

**sreg: ds, ss, cs, es**，16 位 CPU 中，只有一个附加段寄存器 ES，而 FS 和 GS 附加段寄存器是在 32 位 CPU 中增加的。

<img src="os_img/05.png" style="zoom:80%;" />

**标志寄存器：flag**，其中存储的信息称为程序状态字(PSW)。

为了兼容性，16 位寄存器可分为 8 位寄存器，如 AL 和 AH 是**可独立使用的寄存器**；

<img src="os_img/02.png" style="zoom: 50%;" />

- 每个寄存器都是 16 位，其中 **ax, bx, cx, dx 为通用寄存器**，存储一般性数据；
- **si, di** 是与 BX 功能相近的寄存器，但是不能够分成 8 位寄存器，**bx 指明一个内存单元 [bx]**，更灵活的寻址方式 **[bx+si+idata] | [bx+di+idata]**；
- 只有 **bx, si, di, bp** 4个寄存器可以用在 [...] 中进行**内存单元寻址**，可以**单个形式出现，或**组合形式出现：**bx+si, bx+di, bp+si, bp+di**，其余组合形式则不存在；
- 只要**在 [...] 使用 bp**，且指令中没有显示给出段地址，则**使用 ss 中的段地址**；

- 存放访问内存的段地址，**cs, ds, ss, es 为段寄存器**，cs-code 代码段地址，ds-data 数据段地址，ss-stack 栈顶段地址；
- **CPU 将 cs:ip 指向的内容当作指令执行(cs×16+ip)**，ip 为指令寄存器，cs 为代码段寄存器；
- ip, cs 没有 mov 指令，需通过转移指令赋值，如 **jmp 3:01b6 类似于 mov cs, 3 | mov ip, 01b6；**
- **ss:sp 指向栈顶元素**，ss 存储段地址，sp 存放偏移地址；

#### section 和 vstart

`section` 是伪指令，不会产生地址和机器指令，地址 = 上一个地址+上一个地址的内容长度。

`section` 对程序中的地址没有任何影响，仅在逻辑上供开发人员梳理程序使用。

`vstart 0x7c00` 和 `org 0x7c00` 的功能相同，即**指定一个虚拟的起始地址**。将之后的指令从该地址开始编译。使用 `vstart` 时一般预先知道程序被加载到某地址处，也**只是告诉编译器后面数据的的起始地址**，数据本身在文件中的地址，即文件偏移量。



### 0.10 显示输出

CPU 和 外设间通过 IO 接口进行协调转换。如声卡是驱动音响设备的 IO 接口，显卡是驱动显示器，可分为集成显卡和独立显卡。IO 接口是连接 CPU 外设的逻辑控制部件，分为软件和硬件两个部分：

- 硬件部分，协调 CPU 和外设之间的不匹配问题，如速度，数据格式，信号电平转换；
- 软件部分，控制接口电路工作的驱动程序以及内部数据传输需要的数据；

为区分 CPU 中的寄存器，io 接口中的寄存器称为端口，`in` 从端口读取数据，`out` 往端口写数据。

#### 显卡

显卡是 PCI 设备，安装在主板 PCI 插槽上，PCI 总线是共享并行架构，要保证数据发送后必须同时到达目的地。

PCI Express, PCIe 总线，串行设备，传输频率快，PCI-Peripheral Component Interconnect, 外设部件互连标准

#### 默认文本模式

默认的模式未：`80*25`，一行 80 个字符，共25 行，即一屏打印 2000 个字符。

<img src="os_img/06.png" style="zoom:80%;" />



### 0.11 硬盘操作方法

#### 硬盘

硬盘扇区在物理的定位：**CHS，Cylinder Head Sector**，扇区-磁头-扇区，对磁头来说直观，但是对人不直观；

**LBA，Logical Block Address**，逻辑上定位扇区地址。从 0 开始编号，不考虑扇区所在的物理结构，其中每个扇区是 512 bit：

- LBA28，28bit 描述一个扇区地址，$2^{28}×2^9(512)=128$GB；
- LBA48，48bit 描述一个扇区地址，$2^{48}×2^9(512)=128$PB；
- LBA 的寄存器，LBA low, LBA mid, LBA high 都是 8bit，总位数 24bit，为了存储 28bit 扇区地址，还需借助 `device` 寄存器的低 4bit；

```assembly
   ; 将寄存器 al 中的内容发送到 dx 寄存器指定的端口(即寄存器)
   	mov dx, 0x1f2       ; 端口地址加载到dx寄存器
    mov al, cl          ; 数据加载到al寄存器
    out dx, al          ; al寄存器的数据发送到指定的端口处
    mov eax, esi        ; 恢复
```

#### 硬盘控制器

硬盘控制器属于 IO 接口，此处的端口指的是硬盘控制器上的寄存器。

主板提供两个 IDE 插槽—IDE0 和 IDE1，其中 IDE0 为 Primary 通道，IDE1 为 Secondary 通道。

- 兼容以前的 PATA, Parallel ATA 并行接口，PATA 接口线缆也称为 IDE 线，一个 IDE 线上挂两块硬盘，一个是 主盘 Master，另一个是从盘 Slave。两个 IDE 支持 4 块硬盘；
- 主流为 SATA, Serial ATA 串行接口，插槽为 L 形；

**端口**
**注意寄存器的位数从 0 开始数**

- `sector count` ：8bit reg，为 0，表示要操作 256 个扇区，指定待读取或待写入的扇区数，硬盘每完成一个扇区，就将此寄存器的值减1；

- `device`：8bit reg，低 4bit 存储 LBA 地址的 24~27 位，第 4bit 指定 master 还是 slave，第 6bit 设置是否启用 LBA 方式；
- `status`：8bit reg，**读硬盘时的名称**，表示硬盘状态信息，是否出错 | 数据是否准备好 | 硬盘是否正在忙。`command`：和 `status` 为同一个，**写硬盘时的名称**，存储让硬盘执行的命令；

<img src="os_img/07.png" style="zoom:60%;" />

**硬盘操作步骤**

1. 选择通道，向通道的 `sector count` 寄存器写入待操作的扇区数；
2. 向该通道的 3 个 LBA 寄存器写入扇区起始地址的低 24 位；
3. 向 `device` 寄存器写入 LBA 地址的 24~27 位，并置第 6 位为 1，使其为 LBA 模式；
4. 向 `command` 寄存器写入操作的命令；
5. 读取 `status` 寄存器，判断硬盘工作是否完成；

**操作扇区数 > 写入待寻找的 LBA 地址 > 写入操作命令 > 执行操作**



### 0.12 汇编语法

```assembly
# 将内存单元的内容送入ax
mov ax, [bx]
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

cpu 采用分段方式访问内存，即段地址+偏移地址。

#### 过程

1. 接电后，运行，开机的时候，CPU 的 cs:ip 初始化为 **0xF000:0xFFF0**，此时处于实模式，cs 左移 4 位，等效地址为 **0xFFFF0**，此地址中存储一个跳转指令，用于跳转到 BISO 真正的起始地址位置，然后运行 BISO 开机自检，初始化硬件；
2. BIOS 程序的最后一步是检查软盘的 0 面 0 磁道 1 扇区，最后跳转到 0x7c00 地址处。**MBR 在固定位置**，整个磁盘最开始的扇区等待，即 0 盘 0 道 1 扇区；
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
# OrangeOS bochs2.7
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
# 直接执行，不间断
bochs
c

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
# 指令让代码走向下一步
n

# 查看命令帮助
h trace-reg
# 追踪reg,让bochs每一步都显示主寄存器的值
trace-reg on
```

<img src="os_img/01.png" style="zoom:70%;" />

## 2. 保护模式

```shell
 nasm pmtest1.asm -o pmtest1.bin
 dd if=pmtest1.bin of=a.img bs=512 count=1 conv=notrunc
```

引导扇区的空间只有 512 字节，当程序过大时，通过 dd 将 `.bin` 文件的方法就会失效，因此选择 DOS 将程序编译成 COM 文件，然后让 DOS 执行它。

### 2.1 概述

在保护模式下，物理地址不能被直接访问，虚拟地址需要被转化为物理地址后才能再去访问。而地址转换由处理器和操作系统共同协作完成的：

- 处理器在硬件上提供地址转换部件；
- 操作系统提供转换工程所需的页表；

#### 实模式 VS 保护模式

32 位 CPU 具有两种运行模式，其中 16 位的运行模式为实模式，32 位的运行模式为保护模式。**实模式是在 32 位 CPU 时才提出的，与存粹的 16 位 CPU，如8086无关**。32 位 CPU 在 16 位的实模式下运行，仍然具备 32 位操作数的处理能力。

保护模式对内存段的描述更加安全，其中内存段的信息专门用**全局描述符表**进行存储：

- 表中的每个表项称为段描述符，大小64B，**描述内存段的起始地址，大小，权限等信息**；
- 全局描述符表很大，存放在内存中，访问效率不高，由 GDRT 寄存器指向；
- 段寄存器保存的位选择子(selector)，用来**索引全局描述符表中的段描述符**，selector 类似于下标；
- 段描述符的数据分散在不同位置，需要 CPU 将数据进行整合，形成完整数据；

由于 CPU 访问内存的内容效率过低，因此将前期 CPU 整合好的段描述符缓存在寄存器中，即**段描述符缓冲寄存器(Descriptor Cache Registers)**，以后访问相同段时，直接读取寄存器中的内容即可。

**寻址方式**

实模式下的 reg 有固定的用途，保护模式的寻址方式灵活，基址寄存器是所有 32 位的通用寄存器，变址寄存器是除 esp 外的 32 位寄存器。

**CPU 变动**

对于 IA32（Intel Architecture 32-bit）体系架构的 CPU，其内存访问方式还是分段策略。

**80286**：鸡肋产品，首款具有保护模式的 CPU 但 16 位，寄存器 16 位，地址总线 20 位，可访问空间 16MB；

**80386**：1985 年推出，地址总线 32 位，寄存器 32 位，开始平坦模式时代；

**寄存器拓展**

16 位 8086 CPU 中的基址偏移是不得已而为之，而新的 32 位 CPU 则需要对 reg 进行拓展，使其能够访问 4GB 内存空间。

- 除了**段寄存器（仍保留 16 位）**外，其余寄存器均从 16 位拓展到 32 位；
- 拓展(extend)后的寄存器，统一在名字前加 e；

<img src="os_img/08.png" style="zoom:80%;" />

**指令拓展**

`mul` 无符号数相乘指令（有符号乘法指令 `imul`）：

- 乘数为 8 位，`al` 为另一乘数，结果 16 位，存入 `ax`；
- 乘数为 16 位，`ax` 为另一乘数，结果 32 位，存入 `eax`；
- 乘数为 32 位，`eax` 为另一乘数，结果 64 位，高 32 位存入 `edx`，低 32 位存入 `eax`；

`div` 无符号除法指令：

- 除数为 8 位，被除数 16 位(`ax`)，商在 `al`，余数 `ah`；
- 除数为 16 位，被除数 32 位(高 16 位在 `dx`，其余在 `ax`)，商在 `ax`，余数 `dx`；
- 除数为 32 位，被除数 64 位(高 32 位在 `edx`，其余在 `eax`)，商在 `eax`，余数 `edx`；

#### 指定编译模式

兼容性使得 CPU 同时支持 16 位和 32 位的指令，但对于需要指定编译器编译的机器码位数，这就需要借助编译器的伪指令 `bits` 解决，`bits` 指令的范围是当前 `bits` 到下一个 `bits`，默认为 `[bits 16]`。

- `[bits 16]`：编译为 16 位的机器码；
- `[bits 32]`：编译为 32 位的机器码；
- 使用 `bits` 指令，需要清楚代码在那种模式下运行，从而向编译器指定编译对应位数的机器码；
- 对在 `bits` 作用范围内模式不匹配的指令，**编译器自动在操作数机器码**前添加 `0x66` 模式反转前缀，寻址方式反转前缀 `0x67`；
- 编译器通过在机器码前添加反转前缀，临时将当前运行模式下的操作数和寻址方式转换为另一种模式下的操作数和寻址方式；



### 2.2 描述符

#### 段描述符

**段式内存管理（线性地址） > 分页式内存管理**

为了访问内存的安全性，同事保证内存的访问方式仍然位：段基址+偏移。使用段描述符（8字节）来定义一个内存段，如数据段，栈段等。段描述符存放在内存中，共同组成全局描述符表（GDT），段描述符相当于数组中的一个元素。

<img src="os_img/01.jpg" style="zoom:67%;" />

#### GD全局描述符

> Global Descriptor，GD

保护模式下的内存段登记表，仍然是 IA32 结构处理器的段基址：段内偏移地址。其后描述的描述符大小都为**连续的 8字节**，即 64 位。

<img src="os_img/09.png" style="zoom:80%;" />

- 保护模式下地址总线宽度 32 位，**段基址也是 32 位**；
- 段界限表示段边界的拓展最值，数据段向上拓展，地址越来越高；栈段向下拓展，地址越来越低。段界限是一个偏移量，表示段的边界、大小、范围等；
- **段界限共 20 位**，单位是 `B`(G=0，粒度为 1B) 或 `KB`(G=1，粒度为 4KB)，表示偏移了多少 `B` 或多少 `KB`；
- 由于历史问题，考虑到兼容性，段界限和段基址是分开存放的；
- `S` 字段为 0，表示系统段，为 1 表示数据段（硬件需要的数据为—系统段，软件需要的数据—数据段）；
- `type` 字段指定描述符的类型。4 位，该段是否访问过-A，一致性代码段-C，一般限制代码段是否可读-R，是否可执行-X，是否可写-W，拓展方向-E。**其中 A=1 由 CPU 完成，A=0 由 OS 完成，通过统计段被置 1 的次数来统计访问的频率，从而将使用频率最低的段换到内存。**
- `DPL`，Descriptor Privilege Level，描述符特权等级。2 位，保护模式提供的内存安全访问解决方案，共 0，1，2，3 级特权，数字越小，特权等级越大；
- `P`，Present，该段是否存在于内存中；
- `AVL`，availale，操作系统可随意用此位；
- `L`，保留位，是否设置为 64 位代码段；
- `D/B` (代码段或栈段) 字段，指示段内偏移地址及操作数的大小；
- `G` 段，Granularity，粒度，指定段界限的单位大小；

#### GDTR全局描述符表寄存器

> Global Descriptor Table Register，GDTR

一个段描述符定义一个内存段，段描述符放在全局描述符表，并通过选择子提供的下标在 GDT 中索引 GD。

**专用寄存器 GDT Register(48 位) 用来存储 GDT 的地址**，`lgdt` 指令访问 GDTR：

- 寄存器 GDTR 的**前 16 位为 GDT 的界限值**，单位 B；
- **后 32 位是 GDT 的起始地址**，每个 GD(全局描述符) 大小为 8 字节；

实模式下，段寄存器存放的是段基址，而保护模式中，段描述符已经存储了段基址，此时段寄存器存放 selector 选择子，类似于索引值，可在段描述符表中索引段描述符。

#### Selector 选择子

段寄存器 16 位，存储选择子。

- 0-1 位，存储 `RPL`，Request Privilege Level，共 0，1，2，3 四种特权等级；
- 2 位，`Ti`，Table Indictor，选择子是在 GDT(全局) 还是 LDT(局部) 索引段描述符；
- 3-15 位，共 13 位，段描述符的索引值；
- 选择子未初始化时为 0，则指向 GDT 的第 0 各段描述符，为避免出现这种情况 GDT 的第 0 段描述符不可用；

<img src="os_img/10.png" style="zoom:80%;" />

**A20 地址总线**

实模式下，对于超过 1MB 的部分采用地址回绕(warp-around)，而打开 A20，第 21 条地址总线可避免 warp-around。

```assembly
# 打开 A20Gate,将端口 0x92 的第 1 位设置为 1
in al, 0x92
or al, 0b00000010
out 0x92, al
```

**CR0**

设置 CR0 寄存器的第 0 位，即 PE(Protection Enable) 位，控制保护模式的开启 | 关闭。

```assembly
mov eax, cr0
or eax, 0x00000001
mov cr0, eax
```

<img src="os_img/11.png" style="zoom:80%;" />



### 2.3 保护模式

- `mbr.s` 更改，由于 `loader.bin` 文件超过一个扇区大小-512B，因此 `mbr.s` 中扩大加载的扇区数量；
- 在 `loader.s` 中进入保护模式，`loader.bin` 文件超过 512B，此处将 `loader.bin` 写入第 2 个扇区，其中第 0 个扇区为 `mbr`，第 1 个扇区未使用；

```bash
# 包含文件路径,指定库目录，loader.bin大小618bytes(字节)
nasm -I include/ -o loader.bin loader.s

# 512B大小,loader写入2扇区,拷贝的块数=2，块大小=512字节
ls -lb loader.bin
# man dd 磁盘操作命令
dd if=loader.bin of=../hd60M.img bs=512 count=2 seek=2 conv=notrunc
```

注意，选择的显存地址为: `0xB8000-0xBFFFF`，共 32KB，默认模式为每行 80 字符，共 25 行，即一屏可打印 80×25 = 2000 个字符，每个字符 2 字节，高位是属性信息，低位为文字信息。

#### 选择子检查

32 位保护模式下，段寄存器用以保存选择子(16 位)。引用一个段，就是将寄存器加载选择子

**选择子的段索引值是越界检验**

- 根据选择子的值验证段描述符是否超越界限，类似于数组的下标索引不过界；
- **GDT 基址 + 选择子的索引值×8 + 7 ≤ GDT 基址 + GDT 界限值；**
- 注意不要再段寄存器设置值为 0 的选择子，因为 GDT 的第 0 个描述符为空描述符，不可用；

**段类型检查-段描述 `type` 字段**

- 确保寄存器的用途和段类型匹配；
- `CS` 寄存器：有且只有可执行属性的段（代码段）；
- `SS` 寄存器：可写属性的段（数据段）；
- `DS, ES, FS, GS` 段寄存器：可读属性的段；

**段是否存在于内存-段描述 `P` 字段**

- `P` =1，存在于内存，可以将选择子载入段寄存器，访问过后 CPU 将段描述符的 `A` =1；
- 段描述符缓冲寄存器也会更新为选择子对应的段描述符内容；
- `P` =0，处理器抛出异常，随后转去异常处理程序。

#### 内存段的保护

段描述符中记录一块内存的性质，CPU 根据段描述符中的内容可以检查内存操作的合法性，从而保护内存。

**代码段和数据段保护**

对于 IA-32(Intel Architecture)访问内存就用分段策略。32 位保护模式下，段基址存放在 CS 寄存器中，偏移地址存放在 EIP 寄存器中。检查指令能够完整地放在代码段/数据段内。

段寄存器存储选择子，用于索引段描述符，进而确定段基址。CPU 自动从段描述符中取出段基址，加上段内偏移地址，就形成-段基址：段内偏移地址的形式。

**栈段的保护**

段描述符 `type` 中的 `e` 位用来表示段的拓展方向，但仅描述段的性质，数据段也可以用作栈：

- `e` = 1，向下拓展，也可引用不断向上增加的内存地址；
- `e` = 0，向上拓展，也可引用不断向下的内存地址；



### 2.4 处理器微架构

#### 流水线

对于单核 CPU 来说，一次只能执行一个指令。CPU 可以一边执行指令，一边取指令，一边译码，及三级流水线。

CPU 所执行的指令数量越多，效率就越高，对应的流水线级数就越多。一种提高效率的方法是将 CPU 的每一步操作细分为粒度更细的操作。

#### 乱序执行

CPU 运行指令时按照一定的策略打乱顺序执行。x86 最初的指令集为 CISC（Complex Instruction Set Computer），即复杂指令集，其中的指令往往由多个微操作合成。

RISC（Reduced Instruction Set Computer）精简指令集，保留常用的微操作级别的指令。

随着后续发展，×86 内部已采用 RISC 内核。因此在译码过程中，首先按照指令格式分析机器码下，其后将 CISC 指令分解为多个 RISC 指令，即多个微操作，提高指令间的独立性，非常适合乱序执行。

乱序执行允许后面的操作放到前面来做，利于装载到流水线上提高效率。

#### 缓存

用一些存取速度较快的储存设备作为数据缓冲区，避免频繁访问速度较慢的低速储存设备。CPU 对应的三级缓存都是 SRAM，即静态随机访问存储器，而寄存器和 SRAM 访问速度是同一级别的。

根据局部性原理：**程序 90% 的时间都运行在程序中 10% 的代码上**，根据**时间性和空间性**，CPU 将当前用到的指令和当前位置附近的数据都加载到缓存中。

#### 分支预测

当 CPU 遇到一个分支指令时，把分支的那边放到流水线上。而分支结构是流水线面临的关键问题，否则流水线的级数越多，需要清空的指令就越多。**CPU 流水线设计到对未来指令的准备，一次提前预测未来分支的跳转位置对提高效率十分重要**。

**预测算法**：预测主要针对有条件跳转指令，最简单的方法就是 2 位预测法。而 Intel 的分支预测部件使用分支目标缓冲器（branch Target Buffer, BTB）。

- 遇到分支指令，先到 BTB 中查找，根据先前的统计信息将响应的预测分支送到流水线上；
- 在真正执行时，根据实际分支流向，更新 BTB 中的跳转信息；
- BTB 中没有记录，则使用 Static Predictor 的固定策略；

#### 远指令跳转清空流水线

使用 `jmp` 远转移的原因：

- 段描述缓冲寄存器未更新，进入保护模式后，需要将实模式下的值换掉；
- `jmp` 指令具有清空流水线的功能；



## 3. 内核初步

### 3.1 获取物理内存

**实模式下调用 BIOS 中断 0x15**

中断 `0x15` 的 3 个子功能，其中子功能号存放在 `eax/ax` :

- `eax=0xe820`，遍历主机上全部内存，返回的信息量多，但操作复杂；
- `ax=0xe801`，检测低 15MB 和 16MB~4GB 内存。低于 15MB 内存的以 1KB 为单位记录，16MB~4GB 的以 64KB 为单位记录；
- `ax=0x88`，最多检测 64MB 内存，如果实际容量超过也按照 4GB 返回；

**`eax=0xe820` 子功能**

按照内存的属性划分系统内存，分别返回对应类型的内存信息，**BIOS 是一段函数程序，需要提供的参数运行**。

ARDS(Address Range Descriptor Structure)地址范围描述符，用于储存中断返回的各类型内存的信息：

- 结构大小 20 字节，每 4 个字节代表一个属性名称；
- 用 64 位描述内存起始地址，`type` 说明内存的用途-被 OS 使用 | 保留起来不用；

![](os_img/12.png)

每次执行中断 `int 0x15` 后，寄存器 `eax,ebx,ecx` 都会更新：

- `eax` 的值由子功能号变为字符串 SMAP 的 ASCII 码；
- `ebx` 为新的后续值，`ecx` 为实际写入缓冲区中的字节数；
- 每得到一个 ARDS 结构，就将 `di` 增加 20 字节，指向缓冲区下一个 ARDS 的存放位置，而后将 `ards_nr` 加 1，用于记录 ARDS 的个数，方便后续对 ARDS 结构的遍历；

**memory hole**

内存空洞，历史遗留问题。当时 80286 拥有 24 位地址线，寻址空间为 16MB，而一些 ISA 设备要用 15MB 以上的内存作为缓冲区，即保留 1MB 的内存作为缓冲区。其中 ISA总线（Industry Standard Architecture，工业标准结构总线）为 20 世纪 80 年代计算机总线标准，已淘汰。



### 3.2 分页机制

> 内存管理：有限内存的高效利用问题

32 位保护模式下，未开启分页功能时，IA32 架构使用“段基址+段内偏移”确定线性的物理地址，**程序中引用的线性地址是连续的，故对应的物理地址也必须是连续的。**

为了充分利用物理内存，需要将线性地址映射到任意的物理地址上，解除线性地址到物理地址的一一对应关系。而这就产生了分页管理内存的机制。

分页机制建立在分段机制之上，分页机制下的进程先经过**逻辑分段**，在进程自己的 4GB 虚拟空间中分配内存段空间，而后将段在逻辑上拆分为已页为单位的小内存块，并建立和物理内存页的映射关系。

#### 一级页表

分页的原理：将连续的线性地址与任意的物理地址相关联。对于 IA32 架构，分页机制建立在分段机制上。使用分页机制后，段部件输出的为线性地址，即虚拟地址，而虚拟地址对应的物理地址需要在页表中查找。

<img src="os_img/13.png" style="zoom:67%;" />

1. 首先在自己 4GB 虚拟地址空间中寻找可用空间分配内存段，将不同的段（如数段段，代码段等）在逻辑上拆分为大小相等的内存块；
2. 将虚拟地址映射到物理地址，并将映射关系存储在页表中（Page Table），每一行对应页表项（Page Table Entry，PTE）;

内存块大小为 1B 时，4GB 空间划分为 4G 个内存块，即 4G 个页表项。而每个页表存储 32 位地址，需要 4B 内存，故在内存块大小为 1B 时，页表要占用 4G×4B=16GB 内存。

由于 32 位地址表示 **4GB 空间**，因此将 32 地址划分为-内存块大小×内存块数量。官方设定的内存块大小 $2^{12}=4$KB，对应的内存块数量 $2^{20}=1$M 个。

- 页是地址空间的计量单位，只要是 4KB 地址空间都称为一页；
- 先找到对应的物理页，$2^{20}$ 可表示全部物理页。在物理页内偏移，$2^{12}$ 可全部表示；
- **一个页表数组，$2^{20}$ 个页表项，每个页表项 4B 大小；**

<img src="os_img/14.png" style="zoom:60%;" />

**地址转换过程**

1. 在开启分页机制前，页表物理地址被存储在 `CR3` 中，即对应页表的基址；
2. 线性地址的高 20 位索引页表项，每个页表项 4B。**页表项物理地址** = 20 位索引值×4 + `CR3` 中页表基址；
3. 从页表项中获取到**物理页地址**，线性地址的低 12 位则对应**页内偏移地址**；

实际中，CPU 集成了专门的硬件模块进行转换，称为**页部件**，给出一个线性地址，自动在页表中检索物理地址。

<img src="os_img/15.png" style="zoom:67%;" />

#### 二级页表

无论几级页表，标准页的尺寸都是 4KB，**1 个页目录项对应 4MB 物理内存，1 个页表项对应 4KB 物理内存**。

- 一级页表中，一张页表对应 1M 个表项，共 1 个页表。1 个页表大小为 4MB；
- 二级页表中，一张页表对应 1K 个表项，共 1K 个页表。1 个页表大小为 4KB
  - 使用 PDE(Page Directory Entry) 存储页表的物理地址，4KB 大小；
  - 页目录项大小同页表项一样，即描述物理地址对应的 4 字节;
  - **1 个页目录项对应 1 个页表，1 个页表中有 1024 个页表项，对应 1K×4KB=4MB 物理内存**

<img src="os_img/17.png" style="zoom:50%;" /><img src="os_img/16.png" style="zoom:50%;" />

#### 虚拟地址到物理地址的转换

这种转换的工作借助硬件自动转换，**32 位虚拟地址的各位说明（一个表项对应 4B）**：

1. 高 10 位在页目录表中定位页目录项—PDE，1 个页目录表对应 $2^{10} = 1024$ 个 PDE；
2. 中间 10 位在页表中定位页表项—PTE，1 个页表对应 $2^{10} = 1024$ 个 PTE；
3. 后 12 位对应标准页的页内偏移地址，标准页为 4KB 大小；

**获得页目录项 PDE**：页目录表的基址 + 高 10 位页目录表的中的偏移  >> PDE；

**获得页表项 PTE**：页表的物理基址(20位即可表示出32位的物理地址) + 中 10 位页表的中的偏移偏移  >> PTE；

- **由 PTE 得到实际物理地址 + 后 12 位的偏移地址；**

- **虚拟地址提供偏移量，CR3寄存器，PDE 和 PTE 分别提供基址；**
- **CR3 提供页目录项基址，PDE 提供页表基址，PTE 提供物理内存块基址；**

<img src="os_img/18.png" style="zoom:70%;" />

#### 页表项和CR

**标准页的大小为 4KB，物理地址为 4K 的倍数，所以低 12 位为 0。只需 20 位即可表示 32 位物理地址**，其余 12 位用于设置属性。

<img src="os_img/19.png" style="zoom:70%;" />

- `P` 存在位，1 表示页存在于物理内存；
- `RW` 读写，1 表示可读写；
- `US` 普通用于/超级用户，1 为 User 级别，0 为 Supervisor 级别（特权 0，1，2 可访问）；
- `PWT`(Page-level Write-Through) 页级通写位，一般为 0 不采用通写位；
- `PCD`(Page-level Cache Disable)，页级高速缓存禁止位，0 表示启用高速缓存；
- `A`(Accessed) 访问位，由 CPU 设置，为 1 表示 CPU 已经访问过；
- `D` 脏页位，1 表示 CPU 对改页执行写操作；
- `PAT`(Page Attribute Table) 页表属性位，一般为 0；
- `G` 全局位，1 表示将虚拟地址转换结果在高速缓存 TLB(translation lookaside buffer) 中保存；
- `AVL` OS 可以位；

**CR-控制寄存器**

CR3 用于储存页表物理地址，称为**页目录基址寄存器**（Page Directory Base Register,PDBR），控制寄存器可以和通用寄存器传递数据。

![](os_img/20.png)

最后一步，启用分页机制的时，需将 `CR0` 的 PG=1，PE =1 为开启保护模式。在进入分页之前，段部件 输出的线性地址是物理地址，开启分页后则将线性地址当作虚拟地址。

**页表共享**

为实现页表共享，将所有用户进程的 3GB-4GB 虚拟地址所对应的空间都指向统一片物理地址，即 0-3GB 为用户进程，3GB-4GB 为操作系统。

**Bochs 模拟页表的物理地址设定**

<img src="os_img/21.png" style="zoom:70%;" />

**`loader.s` 文件内容内存设定说明**

<img src="os_img/23.png" style="zoom:50%;" />

#### 虚拟地址访问页表

页表是动态的数据结构，根据内存的需求动态增减。

**虚拟地址的高 10 位 | 虚拟地址的中间 10 位 | 虚拟地址的低 12 位**

从 CR3 寄存器中获得页目录表的物理地址 >>>

虚拟地址的高 10 位× 4 作为偏移量找到对应的 PDE，从 PDE 读出页表的物理地址 >>>

虚拟地址的中间 10 位× 4 作为页表中的偏移量寻址 PTE，从 PTE 中读出页框的物理地址 >>>

虚拟地址的低 12 位作为该物理页框的偏移量 >>> 完成虚拟地址到物理地址的映射

**开两把锁拿到页框的基址 + 虚拟低 12 位（页大小 4KB，4GB 内存，索引个数位 1M<二级索引实现 1M>）**

#### 快表TLB

> Translation Lookaside Buffer

处理器准备一个高速缓存，专门存放虚拟地址页框与物理地址页框的映射关系。

TLB 的条目是虚拟地址高 20 位到物理地址高 20 位的映射。TLB 是页表的缓存，需要时时刷新，但是随时更新的话则又需要查询映射关系，因此最终 TLB 由开发人员手动维护。



### 3.3 加载内核(C语言)

不同语言在不同的层级，各层级有不同的思维方式。相比于 C 语言，汇编语言在更低的层级上，主要用于完成宏观需求的具体步骤。

C 语言程序生成过程：先将源程序变成汇编代码，再由汇编代码生成二进制的目标文件，最后将目标文件链接成二进制可执行文件。

```cmd
# -c 仅编译，汇编，不链接
gcc -c -o main.o main.c
# file命令检查main.o文件状态
file main.o
# 链接指定生成可执行文件的起始虚拟地址
# -Ttext ADDRESS Set address of .text section，指定虚拟起始地址
# -e ADDRESS, --entry ADDRESS Set start address，指定程序的起始地址
# main函数为入口地址
ld main.o -Ttext 0xc0001500 -e main -o main.bin

# 直接生成可执行文件
gcc -o main_temp.bin main.c

# 对于二者符号个数, -l 表示行数
nm main.bin | wc -l
nm main_temp.bin | wc -l
```

目标文件 `main.o` 是重定位文件(relocatable)，符号（变量名，函数名）的地址未确定，一律在链接阶段重定位。

#### 程序头设置

应用程序位于外存中，使用时才需调入内存。在程序中，程序头（文件头）用来描述程序的布局信息，即元数据。

<img src="os_img/24.png" style="zoom:80%;" />

将程序读入到内存后，从程序头中读入程序入口地址，而后跳转到入口地址执行程序。

#### ELF 文件

> Executable and Linkable Format，可执行链接格式

<img src="os_img/25.png" style="zoom:67%;" />

- 待重定位文件（relocatable file），源文件仅编译，未进行链接；
- 共享目标文件（shared object file），动态链接库；
- 可执行文件（executable file），编译链接后可直接执行的文件；

#### ELF 头和程序头

**ELF 头**

`e_ident[5]` ：指定编码格式

- `1`-小端字节序，LSB（最低有效字节），最低字节存放在最低字节处
- `2`-大端字节序，MSB（最高有效字节）

**程序头表条目的数据结构**

`struct Elf32_Phdr` 描述磁盘程序中的一个段；

段描述符描述物理内存中的内存段；

<img src="os_img/26.png" style="zoom:80%;" />

```c
// elf header中的数据类型
// elf32_half：2字节 无符号中等大小整数
// elf32_word：4字节 无符号大整数
// elf32_addr：4字节 无符号程序运行地址
// elf32_off：4字节 无符号文件偏移量
#include "elf.h"

// elf header结构
// 52字节
struct Elf32_Ehdr {
    // 16字节大小的数组
    unsigned char e_ident[16];
    // 2字节，指定文件类型2-可执行
    Elf32_Half e_type;
    // 2字节，文件运行的平台
    Elf32_Half e_machine;
    Elf32_Word e_version;
    Elf32_Addr e_entry;
    // program header table程序头表在文件内的字节偏移量
    Elf32_Off e_phoff;
    // section header table节头表在文件内的字节偏移量
    Elf32_Off e_shoff;
    Elf32_Word e_flags;
    // elf header的字节大小
    Elf32_Half e_ehsize;
    // 程序头表中每个条目(entry)的字节大小（描述段信息的数据结构大小）
    Elf32_Half e_phentsize;
    // 程序头表中的条目数量,即段的数量
    Elf32_Half e_phnum;
    // 节头表中每个条目的字节大小（描述节信息的数据结构大小）
    Elf32_Half e_shentsize;
    // 节头表中的条目数量，即节的数量
    Elf32_Half e_shnum;
    Elf32_Half e_shstrndx;
};

// program segment header
// 描述位于磁盘上程序的一个段
// 共32字节
typedef struct {
    // 4字节，段类型
    Elf32_Word p_type;
    // 段在文件内的偏移
    Elf32_Off p_offset;
    // 段在内存中的起始虚拟地址
    Elf32_Addr p_vaddr;
    Elf32_Addr p_paddr;
    // 段在文件中的大小
    Elf32_Word p_filesz;
    // 段在内存中的大小
    Elf32_Word p_memsz;
    Elf32_Word p_flags;
    Elf32_Word p_align;
} Elf32_Phdr;
```

#### 自定义映射的内存地址

内核文件 90% 由 C 语言编写，通过 `loader` 将内核从硬盘中加载到内存中。

**MBR 跳转 > Loader > 加载内核kernel**

MBR.bin：加载的起始地址 0x7C00 ，硬盘第 0 扇区，512字节；

Loader.bin：加载的起始地址 0x900 ，硬盘第 2 扇区，根据其大小占用 2，3，4扇区

kernel.bin：第 9 扇区开始，自定义**加载的起始地址为  0x70000**，0x900+2000(预估 Loader.bin 大小) = 0x10d0。最终选择 **0x1500 作为内核映像**的入口地址，对应虚拟地址 **0xc0001500**（3GB-4GB）。

<img src="os_img/27.png" style="zoom:67%;" />

#### 内核映射到内存

**Loader 将 kernel 加载到缓冲区**

1. 将硬盘中的内核拷贝到内存（不运行）；

   内核加载到内存后，loader 通过分析其 `elf` 结构将内核展开到新的位置。内核在内存中有两份，一份是 `elf` 格式的原文件 `kernel.bin`，另一份是 loader 解析 `kernel.bin` （`elf` 格式）后在内存中生成的内核映像，即将程序中各种段 `segment` 复制到内存中，**此时的映像文件才是真正的内核**。

   内核文件 `kernel.bin` 放在高地址区，内核映像放置在低地址区，后续映像可以覆盖内核原文件。

2. 初始化内核；

   将 `kernel.bin` 中的段复制到内核文件中。拷贝起始地址  0x70000，**内核代码段入口地址 0x1500，对应虚拟地址为 0xc000_1500，起始地址为 0xc000_1000，0xc000_1000~0xc000_1500 为文件头，非代码。**
   
   内核起始物理地址 `0x1500`，大小预估为 70KB，设定的栈底地址为 `0x9f000`，此时 `0x9f000~0x1500` 约有 630KB 空间。

<img src="os_img/29.png" style="zoom:80%;" />

```assembly
; --------------------------------------------------
; 将kernel.bin中的segment复制到编译的地址
; KERNEL_BIN_BASE_ADDR equ 0x70000拷贝的地址
; 获取program header内存拷贝地址，数量，大小
kernel_init:
    xor eax, eax    ;异或操作，相同为0，不同为1
    xor ebx, ebx    ;program header地址
    xor ecx, ecx    ;program header数量
    xor edx, edx    ;program header大小
    mov ebx, [KERNEL_BIN_BASE_ADDR + 28]    ; 偏移28字节，e_phoff对应program header偏移的偏移量(0x34-52字节)
    add ebx, KERNEL_BIN_BASE_ADDR
    mov ecx, [KERNEL_BIN_BASE_ADDR + 44]    ; 偏移44字节，e_phnum对应program header数量（2字节)
    mov dx, [KERNEL_BIN_BASE_ADDR + 42]     ; elf偏移42字节,e_phentsize对应program header大小(0x20-32字节)

; 遍历各个段
; ebx:program header在文件内的起始地址
; 进栈顺序：段大小，源地址，目的地址，栈顶填充，栈顶在低位
; 栈从上往下发展，栈底用不上
.each_segemnt:
    cmp byte [ebx + 0], PT_NULL ; 偏移0字节，段类型，p_type
    je .PTNULL                  ; 相等,program header未使用
    push dword [ebx + 16]       ; 偏移16字节，段在文件中大小，p_filesz
    mov eax, [ebx + 4]          ; 偏移4字节，段在文件内的偏移量，p_offset
    add eax, KERNEL_BIN_BASE_ADDR
    push eax                    ; 源地址
    push dword [ebx + 8]        ;目的地址，p_addr，段在内存中的起始虚拟地址
    call mem_cpy                ; 完成段的映像
    add esp, 12                 ; 清理压入的3个参数:大小，源地址，目的地址

.PTNULL:
    add ebx, edx                ;edx为pd大小，指向下一个program header
    loop .each_segemnt
    ret

; 将拷贝到内存中的内核展开为映像文件
; 输入：栈中参数(dst, src, size)
; 输入：无
.mem_cpy:
    cld
    push ebp            ; ebp的值入栈备份
    mov ebp, esp        ; esp栈顶指针，有数入栈时，esp地址变小
    push ecx
    mov edi, [ebp+8]    ; 目的地址
    mov esi, [ebp+12]   ; 源地址
    mov ecx, [ebp+16]   ; 段大小
    rep movsb

    pop ecx
    pop ebp
    ret
```

1.  ELF Header 中：获取程序头表地址（拷贝后的内存地址 = 基址 + 偏移量），一个程序头代表一个段；
2.  ELF Header 中：获取程序头的数量，即段的数量；
3. 根据 program header 的内存拷贝地址和 program header 数量，结合 Program Header 的信息，遍历每个段；

**栈是向下拓展的，通过 push 指令压栈，栈指针 esp 的值越来越小。**

栈从上往下发展，栈底（高地址）一般用不上

<img src="os_img/28.png" style="zoom:67%;" />

#### 数据块复制指令

**复制数据：movs[bwd] 指令族，重复执行指令 rep，方向指令 cld,std**

`move string-movs`，本质上复制字节数据，将 `DS:ESI` 地址处的 1 字节搬到 `ES:EDI` 地址。

- `movsb`：复制 1 字节
- ` movsw`：复制 2 字节
- `movsd`：复制 4 字节

`rep` 按照 `ecx` 中的次数重复执行指令。

`cld,std` 控制重复执行复制命令时，`esi,edi` 地址的递增（`cld`），递减（`std`）

- `cld`：clean direction，`eflags` 寄存器中方向标志位 `DF=0` ，`esi,edi` 自动加上搬用的字节大小；
- `std`：set direction，`eflags` 寄存器中方向标志位 `DF=1` ，**高地址向低地址方向发展**，`esi,edi` 自动减去搬用的字节大小；

CPU 自动根据`DF` 设置的标志位进行自增/自减。

- 其中 `movsb,movsw,movsd` 同时包含 `esi,edi` 的自增/减；
- `insb,insw,insd` 从端口读入数据到内存的目的地址，只包含 `edi` 的自增/减；
- `outsb,outsw,outsd` 从内存的源数据写入到端口的目的地址，只包含 `esi` 的自增/减；
- `lodsb,lodsw,lodsd` 将内存中的源数据加载到寄存器 `al,ax,eax` ，只包含 `esi`；
- `stosb,stosw,stosd` 将寄存器 `al,ax,eax` 的内容写入到内存中目的地址，只包含 `edi`；



### 3.4 特权级

保护模式下的特权等级。CPU 将程序分为 4 级：0 级，1 级，2 级，3 级。0 级特权最大，即 OS 内核所在的特权级，用户程序一般为 3 级特权。

#### TSS

> Task State Segment,任务状态段

TSS 是一种数据结构，用于存储任务环境，是处理器在硬件上原生支持多任务的一种实现方式。

一个任务被分为用户部分和内核部分，处理器在不同特权级下，使用不同特权级的栈。TSS 代表一个任务，存在记录的有 3 个栈，**TSS 是处理器硬件原生的系统级数据结构。**

特权级转移分为两类：

- 低特权级转向高特权级：中断门、调用门等手段实现。TSS 中记录高特权级的栈地址；
- 高特权级返回低特权级：调用返回指令，唯一能让处理器降低特权级的情况。当处理器由低向高特权级转移时，则自动把当时的低特权级的栈地址压入高特权级所在的栈中；

处理器从 TSS 中找到更高特权级的栈地址。类似于 GDT，GDT 需加载到寄存器 GDTR 中才能被处理器找到，而 TSS 则由 TR（Task Register）寄存器加载。

#### CPL 和 DPL

指令访问其他资源的能力等级称为请求特权级，指令存放在代码段中，故用代码寄存器 CS 中选择子的 RPL 位表示。当前特权级 CPL(Current Privilege Level)表示处理器正在执行的代码的特权级别，**当前特权级 CPL 保存在 CS 选择子中的 RPL 部分**。

受访者的特权级标签 DPL(Descriptor Privilege Level，描述符特权级)，是段描述符所代表的内存区域的“门槛”权限。在不涉及 RPL 的前提下：

- 受访者为**数据段**，**访问者权限 ≥ DPL** 表示的最低权限才可以继续访问；
- 受访者为**代码段**，**访问者权限 = DPL** 表示的最低权限才能继续访问，即只能平级访问，代码段就是 CPU 执行的指令；

处理器唯一一种从高特权级降到低特权级的情况：从中断处理程序返回到用户态，而中断处理都是在 0 特权级下进行。

**一致性代码段**

在段描述符中，如果该段为非系统段，`type` 字段中的 C 位=1 表示该段为一致性代码段，也称为依从代码段，用于**实现从低特权级代码向高特权级代码转移**。

如果自己是转移后的目标段，自己的 DPL 的特权级 ≥ 转移前的 CPL，一致性代码段的 DPL 是权限的上限，任何此权限下的特权级都可以转到此代码段上执行。代码段存在一致和非一致性，但是数据段总是非一致性的，**即数据段不允许特权级更低的代码段访问**。

#### 调用门

处理器通过门结构**实现低特权级到高特权级的转移**。段描述符对应一片内存区域，门描述符对应一段函数。

- 任务门描述符：放在 GDT，LDT，IDT；
- 调用门描述符：GDT，LDT；
- 中断门和陷阱门仅位于 IDT 中；

任务门和调用门通段描述符一样，使用选择子访问，可以用 `call` 和 `jmp` 指令直接调用。陷阱门和中断门只存在于 IDT 中，只能通过中断信号触发使用。任务门用任务 TSS 的描述符选择子来描述一个任务，而其余三个门描述符都是用选择子及偏移地址来描述函数的。

<img src="os_img/30.png" style="zoom:67%;" />

1. 调用门：`call` 和 `jmp` 指令之后，以其选择子为参数，以调用函数例程的形式实现从低特权向高特权转移。`call` 实现向高特权转移，`jmp` 只实现平级转移；
2. 中断门：`int` 指令主动中断实现低特权向高特权的转移；
3. 陷阱门：`int3` 指令主动中断，一般在编译器调试时用；
4. 任务门：以任务状态段 TSS 为单位，实现任务切换，借助中断或指令发起；

**RPL**，请求特权级，当前特权级是对处理器而言，处理器从一个特权级代码段转移到另一个特权级代码段上运行，代码段的特权级 DPL 是未来处理器的 CPL。**简单来说就是用户程序在系统调用时，需处理器进入内核态执行内核服务。**

<img src="os_img/31.png" style="zoom:67%;" />

GDTR 中 GDT 基地址 + GDT 中的偏移量**找到调用门描述符**，该描述符中记录内核例程地址。在向内核例程传递参数过程中，设计处理器在硬件上实现参数的自动复制，即 3 特权级栈中参数自动复制到 0 特权级中。

**32 位模式下 `call` 指令调用调用门**

![](os_img/32.png)

在段寄存器中填充 0，便是利用选择子为 0 引发异常的原理。

#### RPL

> Request Privilege Level，RPL，请求特权级

RPL 代表真正资源需求者的 CPL，在请求特权级为 DPL 级别的资源时，检查 CPL 和 RPL 的特权。

用户程序的 CPL 由 OS 赋予，记录在段寄存器 CS 中的低 2 位。RPL 引入的目的就是避免低特权级的程序访问高特权级的资源。特权级检查是让 CPU 检查**数值上 CPL ≤ DPL && RPL ≤ DPL**。

#### IO 特权级

特权指令只能在 0 特权级下执行，如 `hlt,lgdt,lidt` 等。IO 读写特权由标志寄存器 `eflags` 中的 IOPL 位和 TSS 中的 IO 位图决定。IO 指令只有在当前特权级大于等于 IOPL 时执行，称为 IO 敏感指令 (IO Sensitive Instruction)。具体 IO 相关指令有 `in,out,cli,sti` 等。

IOPL（I/O Privilege Level），即 IO 特权级，是打开**所有 IO 端口**的开关，每个任务（内核进程或用户程序）都有自己的 `eflags` 寄存器，每个任务都有自己的 IOPL，数值上 CPL ≤ IOPL 时才允许执行全部的 IO 指令。

当数值上 CPL ＞ IOPL 时，通过 IO 位图设置部分端口的访问权限。Intel 处理器支持 65536 个端口，允许通过 I/O 位图开启特定端口，**位图中的每一个 bit 代表相应的端口，相应的 bit 位为 0 表示端口可以访问**。I/O 位图位于 TSS 中，可有可无，有的话则位于 TSS 顶端。

<img src="os_img/33.png" style="zoom:67%;" />

## 4. 完善内核

### 4.1 函数调用约定

> calling conventions

调用约定是解决汇编语言问题提出的，对于高级语言则不存在。

- 参数的传递方式；
- 参数的传递顺序；
- 调用者保存寄存器环境/被调着保存寄存器环境；

**cdecl 调用约定**

 C declaration，C 声明。C 语言遵循 `cdecl` 调用约定，函数参数从右到左入栈，参数在栈中传递，最后由调用者清理栈空间。`cdecl` 调用约定的最大亮点是允许函数中参数的数量不固定。

**stdcall 调用约定**

参数从右向左入栈，与 `cdecl` 一致，最后由被调用者清理栈空间。



### 4.2 汇编和 C 混合编程

- 单独的汇编代码文件 + 单独的 C 语言文件编译为目标文件后，一起链接成可执行程序；
- 在 C 语言中嵌入汇编代码，直接编译生成可执行程序—内联汇编；

**系统调用**

即用户程序调用操作系统功能，Linux 中系统调用只有一个入口，即 `0x80` 号中断，具体的子功能在寄存器 `eax` 中单独指定，具体定义在 `/usr/include/asm/unistd.h` 文件中。C 语言编译器 `gcc`，汇编语言编译器 `nasm`。

**混合编程**

- 在**汇编代码中**导出符号供外部引用的关键字 `global`，引用外部文件的符号用的关键字 `extern`；
- 在 C 语言中将符号定义为全局即可被外部引用，引用外部符号时用 `extern` 声明；



### 4.3 实现打印函数

寄存器分组：Address Register 和 Data Register。端口实际上就是 IO 接口上的寄存器。

- Address Register：数组索引；

- Data Register：寄存器数组中索引对应的寄存器；

如访问 CRT Register 寄存器组的寄存器，CRT 中索引为 `0eh` 的光标高 8 位寄存器 Cursor Location  High Register，索引为 `0fh` 的光标低 8 位寄存器 Cursor Location  Low Register。

- 先往端口地址为 `0x3d4` 的 Address Register 中写入寄存器的索引值 `0x0e`；
- 再从端口地址为 `0x3D5` 的 Data Register 寄存器中读写数据；

#### 显存说明

文本模式下：80×25=2000 个字符，每个字符占 2 个字节，低字节是字符的 ASCII 码，高字节是前景色和背景色属性。总的来说，4000 字节的现存中，起始地址为偶数的都可以写入字符。

光标是字符的一维线性坐标，默认为 25 行，每行 80 个字符，共 2000 个字符。故该坐标值的范围是 0~1999。0 行的字符坐标为：0~24，光标乘以 2 是字符的显存地址。**光标的位置存在光标寄存器中，光标不会跟随字符自动更新**。

#### 滚屏设置

显存大小 32 KB，每屏有 4000B，32KB/4000B = 8 屏字符。显卡提供 2 个寄存器来设置屏幕显示字符的起始位置，指定起始位置后，屏幕自动向后显示 2000 个字符。

- 索引为 `0xc` ：Start Address High Register（8位寄存器）；
- 索引为 `0xd` ：Start Address Low Register（8位寄存器）；

另一种设置滚屏的方法：

- 将 1~24 行内容搬到 0~23 行，即把第 0 行的数据覆盖；
- 将第 24 行用空格覆盖，将光标移动到 24 行行首；

#### 特权级

- CPL：当前特权级，程序运行时所处的特权等级，对应 CS 段寄存器中选择子的 RPL；
- RPL：请求特权级，选择子中的 RPL 字段；
- DPL：段描述符所代表内存区域的特权级；

32 位保护模式下，段寄存器储存的都是选择子，当段寄存器选择子指向的段描述的 DPL 权限高于 `iretd` 命令返回后的 CPL，**CPU 则将该段寄存器赋值为 0**。

用户进程特权级由 CS 寄存器中的选择子 RPL 字段决定，即将成为进程在 CPU 上运行时的 CPL。















































