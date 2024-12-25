; loader 和 kernel
LOADER_BASE_ADDR equ 0x900
LOADER_START_SECTOR equ 0x2
; 页目录基址
PAGE_DIR_TABLE_POS equ 0x100000

; -----------------------------------
; GDT属性，以下针对8B段描述符的高32位
; -----------------------------------
; 第23位：描述符G位4K粒度
DESC_G_4K equ 1000_0000_0000_0000_0000_0000b
; 第22位：代码段D位设置为1，表示32位
DESC_D_32 equ 100_0000_0000_0000_0000_0000b
; 第21位：L位，不设置64位代码段
DESC_L equ 00_0000_0000_0000_0000_0000b
; 第20位：AVL位
DESC_AVL equ 0_0000_0000_0000_0000_0000b 
; 第16-19位，段界限
DESC_LIMIT_CODE2 equ 1111_0000_0000_0000_0000b
DESC_LIMIT_DATA2 equ DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2 equ 0000_0000_0000_0000_0000b
; 第15位：P位
DESC_P equ 1000_0000_0000_0000b
; 第13-14位：DPL特权等级
DESC_DPL_0 equ 000_0000_0000_0000b
DESC_DPL_1 equ 010_0000_0000_0000b
DESC_DPL_2 equ 100_0000_0000_0000b
DESC_DPL_3 equ 110_0000_0000_0000b
; 第12位：S位,非系统段
DESC_S_CODE equ 1_0000_0000_0000b
DESC_S_DATA equ DESC_S_CODE
DESC_S_sys equ 0_0000_0000_0000b
; 第8-11位：描述符类型
; xcra-1000,可执行，非一致性，不可读，未访问
DESC_TYPE_CODE equ 1000_0000_0000b
; xewa-0010,不可执行，向上拓展，可写，未访问
DESC_TYPE_DATA equ 0010_0000_0000b
; ---------------------------------
; 高4字节，即高32位描述
; CODE
DESC_CODE_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 +\
DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
; DATA
DESC_DATA_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 +\
DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
; VIDEO,注意显存的起始地址为 0xB8000, 0x0B8000-24位地址表示
DESC_VIDEO_HIGH4 equ (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 +\
DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0B

; --------------------------
; 选择子属性,16位
; --------------------------
; 请求特权等级
RPL0 equ 00b
RPL1 equ 01b
RPL2 equ 10b
RPL3 equ 11b
; 在GDT | LDT 中索引
TI_GDT equ 000b
TI_LDT equ 100b

; --------------------------
; 页表相关属性
; --------------------------
PG_P equ 1b
PG_RW_R equ 00b
PG_RW_W equ 10b
PG_US_S equ 000b
PG_US_U equ 100b

; --------------------------
; 加载内核属性
; --------------------------
KERNEL_START_SECTOR equ 0x9
; kernel.bin文件拷贝到内存的起始地址
KERNEL_BIN_BASE_ADDR equ 0x70000
PT_NULL equ 0
KERNEL_ENTRY_POINT equ 0xc0001500