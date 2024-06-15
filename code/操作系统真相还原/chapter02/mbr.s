; main boot record
; 起始编译地址：0x7c00
; 注意vstart=0x7c00不能有空格
SECTION MBR vstart=0x7c00
; 通用寄存器ax中转cs中的值，初始化其他寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    ; sp栈指针初始化，0x7c00以下可以当作栈使用

; -------------------------------------------
; INT 0x10 功能号：0x06 功能描述：上卷窗口，清屏
; 输入：
; AH 功能号 = 0x06
; AL = 上卷的行数,0表示全部行
; BH = 上卷行属性
; (CL, CH) = 窗口左上角位置(x,y)
; (DL, DH) = 窗口右下角位置(x,y)
; 无返回值
    mov ax, 0x600
    mov bx, 0x700
    mov cx, 0           ; (0,0)
    mov dx, 0x184f      ; (80,25)
    ; VGA文本模式中，一行只能容纳80个字符，共25行，下标从0开始，0x18=14,0x4f=79
    int 0x10            ; 中断int 0x10 清屏

; 获取光标位置,在光标处打印
    mov ah, 3           ; 中断程序的3号子功能
    mov bh, 0           ; 待获取贯标的页号
    int 0x10
; 输出中 ch=光标开始行,cl=结束行，dh=光标所在行号，dl=光标所在列号

; 打印字符串，10h中断的13号子功能
    mov ax, message
    mov bp, ax          ; es:bp,字符串首地址
    mov cx, 5           ; 字符串长度，不包括结束符0的字符个数
    mov ax, 0x1301      ; ah=13子功能，al=01写入字符的方式，光标跟随移动
    mov bx, 0x2         ; bh=0要显示的页号，bl=02h黑底绿字
    int 0x10
    jmp $               ; 程序悬停,jmp近跳转
    message db "1 MBR"  ; 定义打印的字符串
    times 510-($-$$) db 0   ;当前地址-section起始地址，用0填满510B中的剩余空间
    db 0x55, 0xaa       ; 最后两个字节标记位