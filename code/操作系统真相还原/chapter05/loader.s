; -------------------------------
; 功能：实模式下的内核加载器loader
; -------------------------------

%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

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
    add edx 0x100000    ;ax+1MB
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
    mov [total_mem_bytes], edx   `

; 出错则挂起
.error_hlt:
    hlt

; -------------------------------
; 进入保护模式
; 打开 A20 -> 加载 GDT -> 将 CR0 的 PE 位置设置位 1
; -------------------------------

; -------------------------------
; 打开 A20
in al, 0x92
or al, 0000_0010b
out 0x92, al

; -------------------------------
; 加载 GDT
; lgdt 48 位内存数据
lgdt [gdt_ptr]

; -------------------------------
; CR0 的 PE 位置 1
mov eax, cr0
or eax, 0x0000_0001
mov cr0, eax

; 刷新流水线
jmp dword SELECTOR_CODE:p_mode_start

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


; --------------------------------------------------
; 开启分页机制
; 创建目录及页表 -> CR3 存储页目录基址 -> CR0 中PG设置1
; --------------------------------------------------
; 清理4KB空间
setup_page:
    mov ecx, 0x1000
    mov esi, 0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS + esi], 0
    inc esi
    loop .clear_page_dir

; 创建页目录项PDE,1MB(0x100000)以上位置
.create_pde:
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x1000 ;第1个页表位置-0x101000
    mov ebx, eax    ;ebx为基址
    ; 第1个页表的地址,用户特权|可写|存在物理内存
    or eax, PG_US_U | PG_RW_W | PG_P
    mov [PAGE_DIR_TABLE_POS + 0x0], eax
    ; 0-3GB为用户虚拟空间，对应0-0xc00页表目录
    ; (0xc00/4×4K/4×4K=0x300×0x400×0x1000), 0xc00/4 = 768页目录项
    sub eax, 0x1000
    mov [PAGE_DIR_TABLE_POS + 0x1000], eax  ; 指向页目录表本身的地址

; 创建页表项PTE
; 程序用到的总物理内存为1MB，实际需要的页表项为1MB/4B=256个
mov ecx, 256
mov esi, 0
mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx+esi*4], edx    ; ebx=0x101000
    add edx, 0x1000
    inc esi
    loop .create_pte

; 创建其他表PDE
mov eax, PAGE_DIR_TABLE_POS
add eax, 0x2000 ; 第2个页表位置
or eax, PG_US_U | PG_RW_W | PG_P
mov ebx, PAGE_DIR_TABLE_POS
mov ecx, 254    ; 剩余页表目录项
mov esi, 769
.create_kernel_pde:
    mov [ebx+esi*4], eax
    inc esi
    add eax, 0x1000
    loop .create_kernel_pde
    ret