PAGE_DIR_TABLE_POS equ 0x100000 ; 页目录地址
; 创建PDE（页目录）和页表(PTE)
.setup_page:
    mov ecx, 0x1000
    mov esi, 0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS+esi], 0 
    inc esi
    loop .clear_page_dir

; 创建页目录项
.create_pde:
    mov eax, PAGE_DIR_TABLE_POS
    ; PDE内容
    add eax, 0x1000
    mov ebx, eax
    or eax, PG_US_U | PG_RW_W | PG_P
    ; 第1个
    mov [PAGE_DIR_TABLE_POS+0x0], eax
    ; 第768个
    mov [PAGE_DIR_TABLE_POS+0xc00], eax
    ; 第1024个
    sub eax, 0x1000
    mov [PAGE_DIR_TABLE_POS+0x1000], eax
    ; 第769-1024
    mov eax, PAGE_DIR_TABLE_POS
    add eax, 0x2000
    or eax, PG_US_U | PG_RW_W | PG_P
    mov ebx, PAGE_DIR_TABLE_POS
    mov ecx, 254
    mov esi, 769
    .create_kernel_pde:
        mov [ebx+esi*4], eax
        add eax, 0x1000
        inc esi
        loop .create_kernel_pde
        ret

; 创建页表,第1个
mov ecx, 256
mov esi, 0
; 真实物理地址
mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx+esi*4], edx
    add edx, 0x1000
    inc esi
    loop .create_pte