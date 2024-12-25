; 直接与显示器交互
SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

; 清屏
; -------------------------------------------
; INT 0x10 功能号：0x06 功能描述：上卷窗口，清屏
; 输入：
; AH 功能号 = 0x06
; AL = 上卷的行数,0表示全部行
; BH = 上卷行属性
; (CL, CH) = 窗口左上角位置(x,y)
; (DL, DH) = 窗口右下角位置(x,y)
; 无返回值
; -------------------------------------------
    mov ax, 0600h
    mov bx, 0700h
    mov cx, 0
    mov dx, 184fh
    int 10h

; 直接向显存输入， 1 MBR
; 输出背景色为绿色，前景色为红色
    mov byte [gs:0x00], '1'
    mov byte [gs:0x01], 0xA4
    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0xA4
    mov byte [gs:0x04], 'M'
    mov byte [gs:0x05], 0xA4
    mov byte [gs:0x06], 'B'
    mov byte [gs:0x07], 0xA4
    mov byte [gs:0x08], 'R'
    mov byte [gs:0x09], 0xA4

    jmp $

    times 510-($-$$) db 0
    db 0x55, 0xaa