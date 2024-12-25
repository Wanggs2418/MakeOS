; 打印字符串
[bits 32]
section .text
; ----------------------------
; put_str打印以0结尾的字符串
; ----------------------------
global put_str
put_str:
    push ebx
    push ecx
    xor ecx, ecx
    mov ebx, [esp+12]       ; 待打印的字符串地址
.goon:
    mov cl, [ebx]
    cmp cl, 0
    jz .str_over            ; 处理到字符串末尾，则跳到结束处返回
    push ecx                ; 参数是字符串的地址
    call put_str
    add esp, 4              ; 回收参数所占的地址空间
    inc ebx
    jmp .goon
.str_over:
    pop ecx
    pop ebx
    ret