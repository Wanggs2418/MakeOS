// elf header中的数据类型
// elf32_half：2字节 无符号中等大小整数
// elf32_word：4字节 无符号大整数
// elf32_addr：4字节 无符号程序运行地址
// elf32_off：4字节 无符号文件偏移量
#include "elf.h"

// elf header结构
// 52字节
struct Elf32_Ehdr {
    unsigned char e_ident[16];  //16字节数组
    Elf32_Half e_type;  //2字节，指定文件类型，2-可执行
    Elf32_Half e_machine;   //2字节，文件运行平台
    Elf32_Word e_version;
    Elf32_Addr e_entry;
    Elf32_Off e_phoff;  // program header table程序头表在文件内的字节偏移量
    Elf32_Off e_shoff;  // section header table节头表在文件内的字节偏移量
    Elf32_Word e_flags;
    Elf32_Half e_ehsize;    // elf header的字节大小-0x34
    Elf32_Half e_phentsize; // 程序头表中每个条目(entry)的字节大小（描述段信息的数据结构大小）-0x20
    Elf32_Half e_phnum; // 程序头表中的条目数量,即段的数量
    Elf32_Half e_shentsize; // 节头表中每个条目的字节大小（描述节信息的数据结构大小）
    Elf32_Half e_shnum; // 节头表中的条目数量，即节的数量
    Elf32_Half e_shstrndx;
};

// program segment header
// 描述位于磁盘上程序的一个段
// 共32字节
typedef struct {
    Elf32_Word p_type;  // 4字节，段类型
    Elf32_Off p_offset; // 段在文件内的偏移
    Elf32_Addr p_vaddr; // 段在内存中的起始虚拟地址
    Elf32_Addr p_paddr;
    Elf32_Word p_filesz; // 段在文件中的大小
    Elf32_Word p_memsz; // 段在内存中的大小
    Elf32_Word p_flags;
    Elf32_Word p_align;
} Elf32_Phdr;

