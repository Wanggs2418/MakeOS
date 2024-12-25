; 输入参数≤5，用寄存器传递参数
; 系统调用的2种方式
section .data
; 第1种系统调用方式
str_c_lib: db "c library says:hello, world!!!", 0xa; 0xa-LF对应的ASCII码
str_c_lib_len equ $-str_c_lib
; 第2种系统调用方式
str_syscall: db "syscall says:hello, world!!!", 0xa
str_syscall_len equ $-str_syscall

section .text
global _start
_start:
    ; 方式1，模拟 C 语言中系统调用库函数
    push str_c_lib_len  ; 压入参数
    push str_c_lib
    push 1
    call simu_write
    add esp, 12         ; 回收栈空间
    ; 方式2，跨过库函数，直接进行系统调用
    mov eax, 4          ; 对应系统函数write子功能号
    mov ebx, 1
    mov ecx, str_syscall
    mov edx, str_syscall_len
    int 0x80

    ; 第1号子功能，退出程序-exit
    mov eax, 1
    int 0x80

; 模拟C语言中系统调用函数write
simu_write:
    push ebp
    mov ebp, esp
    mov eax, 4
    mov ebx, [ebp+8]      ;第1个参数
    mov ecx, [ebp+12]     ;第2个参数
    mov edx, [ebp+16]     ;第3个参数
    int 0x80
    pop ebp
    ret 