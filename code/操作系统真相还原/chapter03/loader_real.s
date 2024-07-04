; 实模式下的内核加载器loader
%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR

; 输出内容
; 背景色-绿色，前景色-红色，跳动的字符串 "2 loader"
    mov byte [gs:0x00], '2'
    mov byte [gs:0x01], 0xA4
    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0xA4
    mov byte [gs:0x04], 'L'
    mov byte [gs:0x05], 0xA4
    mov byte [gs:0x06], 'O'
    mov byte [gs:0x07], 0xA4
    mov byte [gs:0x08], 'A'
    mov byte [gs:0x09], 0xA4
    mov byte [gs:0x0a], 'D'
    mov byte [gs:0x0b], 0xA4
    mov byte [gs:0x0c], 'E'
    mov byte [gs:0x0d], 0xA4
    mov byte [gs:0x0e], 'R'
    mov byte [gs:0x0f], 0xA4

    jmp $