; 打印函数实现
; --------------------
; 流程
; 1.备份寄存器现场
; 2.获取光标坐标值，即下一个可打印字符的位置
; 3.获取待打印的字符
; 4.判断字符是否为控制字符，若为回车，换行，退格这三种控制符，则进入相应的处理流程。否则，认为是可见字符
; 5.判断是否需要滚屏
; 6.更新光标坐标值，指向下一个打印字符位置
; 7.回复寄存器现场，退出
; --------------------
; 视频段选择子
TI_GDT equ 0
RPL0 equ 0
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0

[bits 32]
section .text
; --------------------
; 函数名：put_char,将栈中的 1 个字符写入光标处
; --------------------
global put_char
put_char:
    pushad              ; 备份32位寄存器环境，push all double
    mov ax, SELECTOR_VIDEO
    mov gs, ax          ; 用通用寄存器将立即数输入段寄存器
    ; 2.获取光标位置
    mov dx, 0x03d4      ; Address Register端口地址
    mov al, 0x0e        ; 光标寄存器高8位
    out dx, al          ; 将数据输出到端口
    mov dx, 0x03d5
    in al, dx           ; 获取光标位置的高8位
    mov ah, al
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    in al, dx           ; 获取光标位置的低8位

    mov bx, ax          ; 将光标位置保存到bx
    ; 3.获取待打印的字符
    mov ecx, [esp+36]   ; 一个寄存器4字节，压入8个寄存器，主调函数返回地址4字节
    cmp cl, 0xd         ; CR-0x0d, LF-0x0a
    jz .is_carriage_return  ; 回车,jmp if zero
    cmp cl, 0xa
    jz .is_line_feed        ; 换行
    cmp cl, 0x8
    jz .is_backspace        ; 退格
    jmp .put_other

; 对控制字符的行为安排
; 回车+换行：回到行首+到下一行
; 退格：删除前一个字符
.is_backspace:
    dec bx              ; 光标位置左移1位
    shl bx, 1           ; 左移×2
    mov byte [gs:bx], 0x20  ; 待删除的字符补为空格ASCII码-0x20
    inc bx
    mov byte [gs:bx], 0x07  ; 属性0x07(黑屏白字)写入高字节
    shr bx, 1               ; 右移/2，忽略余数
    jmp .set_cursor

.put_other:
    shl bx, 1
    mov [gs:bx], cl
    inc bx
    mov byte [gs:bx], 0x07
    shr bx, 1
    inc bx
    cmp bx, 2000
    jl .set_cursor          ; 设置新的光标值

.is_line_feed:
.is_carriage_return:
    xor dx, dx              ; 被除数高16位，清0
    mov ax, bx              ; 被除数低16位
    mov si, 80              ; 一行80个字符，160字节
    div si
    sub bx, dx              ; 光标值-余数，即为80的整数倍,对应当前行首坐标

.is_carriage_return_end:
    add bx, 80              ; 光标更新到下一行后是否超过屏幕，需要换行
    cmp bx, 2000
.is_line_feed_end:
    jl .set_cursor

.roll_screen:
    cld
    mov ecx, 960            ; 2000-80=1920字符，1920×2=3840字节，3840/4=960次
    mov esi, 0xc00b80a0     ; 源地址：第1行行首,0xa0=160
    mov edi, 0xc00b8000     ; 目的地址：第0行行首
    rep movsd

    mov ebx, 3840           ; 最后一行行首
    mov ecx, 80
.cls:
    mov word [gs:ebx], 0x0720   ; 黑底白字空格
    add ebx, 2
    loop .cls

mov ebx, 1920           ; 说着最后一行
; 更新光标位置
.set_cursor:
    ; 设置高8位
    mov dx, 0x03d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x03d5
    mov al, bh
    out dx, al          ; 写入指令操作
    ; 设置低8位
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    mov al, bl
    out dx, al

.put_char_done:
    popad               ; 恢复寄存器环境
    ret