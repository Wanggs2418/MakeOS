; -------------------------------
; 功能：实模式下的内核加载器loader
; -------------------------------

%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
; jmp loader_start

; -------------------------------
; GDT及其内部描述符
; -------------------------------
; dd-双字变量，4字节数据,下面为高地址
GDT_BASE: dd 0x00000000
          dd 0x00000000
; 代码段描述符
CODE_DESC: dd 0x0000FFFF
           dd DESC_CODE_HIGH4
; 数据段和栈段描述符
DATA_STACK_DESC: dd 0x0000FFFF
                 dd DESC_DATA_HIGH4
; 描述符特权等级-DPL=0, 显存段描述符
VIDEO_DESC: dd 0x80000007
            dd DESC_VIDEO_HIGH4
GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1

; 预留60个描述符空位，dq-4字，8字节数据 define quad-word-64位
times 60 dq 0
; 选择子
SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

; -------------------------------
; total_mem_bytes 保存内存容量, 4字节
; 当前loader.bin文件头为 0x200, 而loader.bin的加载地址在 0x900
; total_mem_bytes 在内存中的地址为：0xb00
; -------------------------------
total_mem_bytes dd 0    ; 4字节

; ---------------------------------------
; GDT指针，前16位GDT界限，后32位GDT起始地址 
; ---------------------------------------
; 前 16 位界限值告诉CPU置显示的段描述符个数-即(界限值+1)/8字节
; 段描述符大小为8字节，即64位
; dw-16位，dd-32位，共6字节
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE

; ADRS结构体数量, db为1字节，每个ADRS为20字节
; 数据缓冲区，用于存放ARDS结构
ards_buf times 244 db 0     ;244字节,为凑得256字节所取
ards_nr dw 0    ;2字节
; 4+6+244+2 = 256 字节

; -------------------------------
; 获取内存布局
; BIOS 中断 int 0x15
; 功能号-0xe820, eax
; 功能号-0xe801, ax
; 功能号-0x88, ax
; edx=0x534d4150, ('SMAP'对应的ASCII)
; -------------------------------
loader_start:
    xor ebx, ebx    ; 异或操作，相当于清零
    mov edx, 0x534d4150
    mov di, ards_buf

; -------------------------------
; 功能号-0xe820
; 循环获取每个ARDS内存范围描述结构
.e820_mem_get_loop:
    mov eax, 0x0000e820 ; 功能号
    mov ecx, 20
    int 0x15
    ; cf=1,发生错误，则使用e801子功能
    jc .e820_failed_so_try_e801
    ; di增加20字节，指向缓冲区中新的ARDS结构
    add di, cx
    ; 数值+1，ards_nr,dw类型，记录ARDS数量
    inc word [ards_nr]  
    cmp ebx, 0
    jnz .e820_mem_get_loop
    ; 遍历每一个ARDS,循环次数为 ARDS 的数量
    mov cx, [ards_nr]
    mov ebx, ards_buf
    xor edx, edx
.find_max_mem_area:
    mov eax, [ebx]      ; baseAddrlow
    add eax, [ebx+8]    ; lengthLow
    add ebx, 20         ; 指向缓冲区中的下一个ARDS结构
    cmp edx, eax
    ; 冒泡排序，找出最大内存容量
    jge .next_ards      ; 大于等于跳转
    mov edx, eax
.next_ards:
    loop .find_max_mem_area
    jmp .mem_get_ok

; -------------------------------
; 功能号-0xe801
; ax=cx,单位KB. bx=dx,单位64KB
; ax=cx中低16MB，bx=dx中16MB-4GB
.e820_failed_so_try_e801:
    mov ax, 0xe801
    int 0x15
    jc .e801_failed_so_try88
    ; 1.计算低15MB内存
    mov cx, 0x400   ;KB
    mul cx          ;cx为乘数
    shl edx, 16     ;左移16位
    and eax, 0x0000FFFF
    or edx, eax     ;提取edx的16位内容
    add edx, 0x100000    ;ax+1MB
    mov esi, edx    ; 15MB存入esi备份
    ; 2.16MB以上,单位64KB
    xor eax, eax
    mov ax, bx
    mov ecx, 0x10000    ;64KB
    ; 32位乘法,被乘数eax,积64位,edx-高32,eax-低32
    mul ecx
    add esi, eax
    mov edx, esi
    jmp .mem_get_ok

; -------------------------------
; 功能号-0x88
; 获取64MB以内的内存容量
.e801_failed_so_try88:
    mov ah, 0x88
    int 0x15
    jc .error_hlt
    and eax, 0x0000FFFF
    ; 16位乘法,被乘数ax,积32位.dx-高16位,ax-低16位
    mov cx, 0x400
    mul cx
    shl edx, 16     ;dx内容左移到高16位
    or edx, eax     ;eax取低16位
    add edx, 0x100000   ;+1MB

; 内存单位变换为byte单位后存入
.mem_get_ok:
    mov [total_mem_bytes], edx

; -------------------------------
; 进入保护模式
; 打开 A20 -> 加载 GDT -> 将 CR0 的 PE 位置设置位 1
; -------------------------------
; 打开 A20
    in al, 0x92
    or al, 0000_0010b
    out 0x92, al

; -------------------------------
; 加载 GDT
; lgdt 48 位内存数据,GDTR存储GDT地址
; 从gdt_ptr指向的地址读取GDT的界限和基址
    lgdt [gdt_ptr]

; -------------------------------
; CR0 的 PE 位置 1
    mov eax, cr0
    or eax, 0x0000_0001
    mov cr0, eax

; 刷新流水线
    jmp dword SELECTOR_CODE:p_mode_start

; 出错则挂起
.error_hlt:
    hlt


; 保护模式
; 往显存第 80 个字符位置写入字符 P,默认文本显示模式80(0-79)*25,每个字符2字节
; 低字节显示字符，高字节显示属性，默认位黑底白字
; 选择子初始化各段寄存器
[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    
    mov byte [gs:160], 'p'

    jmp $

; 开启分页之前，将kernel.bin程序拷贝到内存（不运行）
mov eax, KERNEL_START_SECTOR    ; 扇区号
mov ebx, KERNEL_BIN_BASE_ADDR   ; 目标地址
mov ecx, 200    ; 读入的扇区数
; eax,ebx,ecx是rd_disk_m_32函数的参数
; 同 mbr 中rd_disk_m_16一样，只是寄存器发生了变化
call rd_disk_m_32


; --------------------------------------------------
; 开启分页机制
; 创建目录及页表 -> CR3 存储页目录基址 -> CR0 中PG设置1
; --------------------------------------------------
; 1.创建页目录表和页表，以及内存位图初始化
call setup_page
; 描述符表及偏移量写入gdt_ptr地址,前2字节->偏移量,后4字节->GDT基址
sgdt [gdt_ptr]
; 更改显存地址用3GB以上的空间，由系统控制
; 1GB: 0x0000_0000-0x3fff_ffff | 1GB: 0x4000_0000-0x7fff_ffff
; 1GB: 0x8000_0000-0xbfff_ffff | 1GB: 0xc000_0000-0xffff_ffff
mov ebx, [gdt_ptr+2]
; 1个GD为8字节，其中显存对应的video描述符在第3个GD,dword指定操作位数为32位
; 段描述符的高4位对应基址的24-31,通过or操作实现地址增加至3GB以上
or dword [ebx+0x18+4], 0xc000_0000
; 将GDT地址移入内核
add dword [gdt_ptr+2], 0xc000_0000
add esp, 0xc000_0000

; --------------------------------------------------
; 2.CR3存储页目录基址
mov eax, PAGE_DIR_TABLE_POS
mov cr3, eax

; --------------------------------------------------
; 3.CR0的第31位,PG=1
mov eax, cr0
or eax, 0x8000_0000
mov cr0, eax

; --------------------------------------------------
; 开启分页后,重新加载GDT地址
lgdt [gdt_ptr]
; 输出
mov byte [gs:160], 'V'
jmp $

; --------------------------------------------------
; setup_page函数:创建页目录及页表
; 清理4KB空间,0x1000-4096
setup_page:
    mov ecx, 0x1000
    mov esi, 0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS + esi], 0
    inc esi
    loop .clear_page_dir

; 创建页目录项PDE,共0-1023个表目录项
; 页目录表基址在1MB(0x100000)以上
.create_pde:
    ; 1.第1个PDE和第768个PDE
    mov eax, PAGE_DIR_TABLE_POS ; 0x100000
    add eax, 0x1000 ;第1个页表位置-0x101000
    mov ebx, eax    ;ebx为首个页表的基址
    ; 第1个页表的地址,用户特权|可写|存在物理内存
    or eax, PG_US_U | PG_RW_W | PG_P
    mov [PAGE_DIR_TABLE_POS + 0x0], eax ; 存储首个页表的地址，形成PDE
    mov [PAGE_DIR_TABLE_POS + 0xc00], eax ; 第768个页目录项，存储首个页表的地址，形成PDE
    ; 第0项和第768项同时指向第一个页表，对应低端4MB物理内存
    ; 其中第768项对应虚拟地址为：0xc000_0000~0xc030_0000(4MB空间)
    
    ; 2.第1023个PDE指向自身
    ; 共1024个页目录项，其中0-3GB为用户虚拟空间，对应0-0xc00页表目录
    ; (0xc00/4×4K/4×4K=0x300×0x400×0x1000), 0xc00/4 = 768个页目录项
    sub eax, 0x1000
    ; 注意是4092,不是4096
    mov [PAGE_DIR_TABLE_POS + 4092], eax  ; 指向页目录表本身的地址

; 第1个页表
; 创建页表项256个PTE,对应1MB物理内存,256×4KB=1MB
mov ecx, 256
mov esi, 0
mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx+esi*4], edx    ; ebx=0x101000
    add edx, 0x1000         ; 页表项对应的物理地址增加 4KB
    inc esi
    loop .create_pte

; 254个表目录项PDE,对应高1GB
; 剩余页目录项 769-1022个PDE
mov eax, PAGE_DIR_TABLE_POS
add eax, 0x2000             ; 第769PDE -> 第2个页表位置
or eax, PG_US_U | PG_RW_W | PG_P
mov ebx, PAGE_DIR_TABLE_POS
mov ecx, 254                ; 剩余页表目录项,循环254次
mov esi, 769                ; 从第769个PDE开始创建
.create_kernel_pde:
    mov [ebx+esi*4], eax    ; 769以上PDE地址
    inc esi
    add eax, 0x1000
    loop .create_kernel_pde
    ret
; 函数setup_page结束

; 开启分页后，用gdt新地址重新加载
lgdt [gdt_ptr]
; 一直处于32位以下，原则上不需要强制刷新
; 刷新流水线
jmp SELECTOR_CODE:enter_kernel
enter_kernel:
    call kernel_init
    mov esp, 0xc009f000     ;进入内核前将栈底指针指向0xc009f000
    jmp KERNEL_ENTRY_POINT

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
mem_cpy:
    cld                 ; 保证esi,edi递增，增加大小为复制的字节数
    push ebp            ; 备份edp的值
    mov ebp, esp        ; esp栈顶指针，有数入栈时，esp地址变小
    push ecx            ; 备份ecx的值
    mov edi, [ebp+8]    ; 目的地址
    mov esi, [ebp+12]   ; 源地址
    mov ecx, [ebp+16]   ; 段大小
    rep movsb

    pop ecx             ; 复原ecx的值
    pop ebp             ; 复原ebp的值
    ret

;-------------------------------------------------------------------------------
			   ;功能:读取硬盘n个扇区
rd_disk_m_32:	   
;-------------------------------------------------------------------------------
							 ; eax=LBA扇区号
							 ; ebx=将数据写入的内存地址
							 ; ecx=读入的扇区数
      mov esi,eax	   ; 备份eax
      mov di,cx		   ; 备份扇区数到di
;读写硬盘:
;第1步：设置要读取的扇区数
      mov dx,0x1f2
      mov al,cl
      out dx,al            ;读取的扇区数

      mov eax,esi	   ;恢复ax

;第2步：将LBA地址存入0x1f3 ~ 0x1f6

      ;LBA地址7~0位写入端口0x1f3
      mov dx,0x1f3                       
      out dx,al                          

      ;LBA地址15~8位写入端口0x1f4
      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      ;LBA地址23~16位写入端口0x1f5
      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f	   ;lba第24~27位
      or al,0xe0	   ; 设置7～4位为1110,表示lba模式
      mov dx,0x1f6
      out dx,al

;第3步：向0x1f7端口写入读命令，0x20 
      mov dx,0x1f7
      mov al,0x20                        
      out dx,al

;;;;;;; 至此,硬盘控制器便从指定的lba地址(eax)处,读出连续的cx个扇区,下面检查硬盘状态,不忙就能把这cx个扇区的数据读出来

;第4步：检测硬盘状态
  .not_ready:		   ;测试0x1f7端口(status寄存器)的的BSY位
      ;同一端口,写时表示写入命令字,读时表示读入硬盘状态
      nop
      in al,dx
      and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输,第7位为1表示硬盘忙
      cmp al,0x08
      jnz .not_ready	   ;若未准备好,继续等。

;第5步：从0x1f0端口读数据
      mov ax, di	   ;以下从硬盘端口读数据用insw指令更快捷,不过尽可能多的演示命令使用,
			   ;在此先用这种方法,在后面内容会用到insw和outsw等

      mov dx, 256	   ;di为要读取的扇区数,一个扇区有512字节,每次读入一个字,共需di*512/2次,所以di*256
      mul dx
      mov cx, ax	   
      mov dx, 0x1f0
  .go_on_read:
      in ax,dx		
      mov [ebx], ax
      add ebx, 2
      loop .go_on_read
      ret
