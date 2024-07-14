; mbr只有512B，无法为内核准备好环境，需在loader.s中完成初始化环境及加载任务
; master boot record
; 预处理命令,在编译前将boot.inc文件啊包含进来
%include "boot.inc"

; 注意等号两边不能使用空格，否则warning
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
; (CL, CH) = 窗口左上角位置(x,y),(0,0)
; (DL, DH) = 窗口右下角位置(x,y),(24,79)
; 无返回值
; 一次容纳80个字符，共25行，从(0,0)开始
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

    ; eax, bx, cx 传递参数到函数 rd_disk_m_16 中
    mov eax, LOADER_START_SECTOR    ; 起始扇区地址
    mov bx, LOADER_BASE_ADDR        ; 写入的内存地址
    mov cx, 4                       ; 读入的扇区数,loader.bin大小超过512B
    call rd_disk_m_16   ; 读取扇区程序

    jmp LOADER_BASE_ADDR

; -------------------------------------------
; 功能：读取硬盘 n 个扇区
; -------------------------------------------
rd_disk_m_16:
        mov esi, eax
        mov di, cx
    ; 1.设置读取的扇区数
        mov dx, 0x1f2       ; 端口地址加载到dx寄存器
        mov al, cl          ; 数据加载到al寄存器
        out dx, al          ; al寄存器的数据发送到指定的端口处
        mov eax, esi        ; 恢复
    ; 2.将 LBA28 地址存入 0x1f3~0x1f6, LBA low, LBA mid, LBA high, data 低4位
        ; 7~0 写入端口 0x1f3-LBA low
        mov dx, 0x1f3
        out dx, al

        ; 15~8 写入端口 0x1f4-LBA mid
        mov cl, 8
        shr eax, cl         ; 向右移动cl指定的位数8位
        mov dx, 0x1f4       ; 右移后，原来低8位的舍去
        out dx, al

        ; 23-16 写入端口 0x1f5-LBA mid
        shr eax, cl
        mov dx, 0x1f5
        out dx, al

        ; 借助device reg
        shr eax, cl
        and al, 0x0f    ; 24~27位与操作,00001111
        or al, 0xe0     ; 或操作,8bit,11100000,7-4位为1110
        mov dx, 0x1f6
        out dx, al
    ; 3.向端口写入读命令 0x20
        mov dx, 0x1f7
        mov al, 0x20
        out dx, al
    ; 4.检测硬盘状态
    .not_ready:
        nop
        in al, dx
        and al, 0x88    ; 10001000，第3bit=1-数据准备好，7bit=1硬盘忙
        cmp al, 0x08    ; 比较操作数，数据是否准备好,即第3bit=1
        jnz .not_ready  ; 更改条件标志位，让 jnz 进行跳转
    ; 5.从0x1f0读取数据
    ; di-读取的扇区数,一个扇区512B，每次读入1个字，即2B,共需di*512/2次
        mov ax, di
        mov dx, 256
        mul dx          ; ax×dx -> |ax| 结果未超过16位
        mov cx, ax
        mov dx, 0x1f0   ; 切换到对应reg
    ; 借助mbr加载loader,实模式下16位偏移，因此loader.bin < 64KB
    .go_on_read:
        in ax, dx
        mov [bx], ax
        add bx, 2
        loop .go_on_read
        ret

    times 510-($-$$) db 0
    db 0x55, 0xaa