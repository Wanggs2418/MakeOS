; -------------------------------
; 功能：实模式下的内核加载器loader
; -------------------------------

%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

; GDT及其内部描述符
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
SELECTOR_VIDEO equ (0x0003+<<3) + TI_GDT + RPL0

; GDT指针，前16位GDT界限，后32位GDT起始地址
; dw-16位，dd-32位
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE
loadermsg db '2 loader in real.'

; -------------------------------
; 1.打印字符串，int 0x10, 功能号-0x13
; -------------------------------
; 输入：
;       ah -- 子功能号，0x13
;       al -- 显示输出方式，1只显示字符，显示属性在 bl 中
;       bh -- 页码，0x00
;       bl -- 属性，0x1f蓝底粉字
;       cx -- 字符串长度
;       (dh,dl) -- (行，列)
;       es:bp -- 字符串地址
; -------------------------------
; 输出：
;       无
loader_start:
    mov sp, LOADER_BASE_ADDR
    mov bp, loadermsg
    mov cx, 17
    mov ax, 0x1301
    mov bx, 0x001f
    mov dx, 0x1800
    int 0x10

; -------------------------------
; 2.进入保护模式
; -------------------------------
; 打开 A20 -> 加载 GDT -> 将 CR0 的 PE 位置设置位 1

; 打开 A20
; -------------------------------
in al, 0x92
or al, 0000_0010b
out 0x92, al

; 加载 GDT
; -------------------------------
; lgdt 48 位内存数据
lgdt [gdt_ptr]

; CR0 的 PE 位置 1
; -------------------------------
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