// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stddef.h>
#include <stdint.h>
#include "elf.h"
#include "util.h"

typedef struct {
    uint8_t  e_ident[16];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint32_t e_entry;
    uint32_t e_phoff;
    uint32_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_ph_num;
    uint16_t e_shentsize;
    uint16_t e_sh_num;
    uint16_t e_shstrndx;
} Elf32_Ehdr;

typedef struct {
    uint8_t  e_ident[16];
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_ph_num;
    uint16_t e_shentsize;
    uint16_t e_sh_num;
    uint16_t e_shstrndx;
} Elf64_Ehdr;

typedef struct {
    uint32_t sh_name;
    uint32_t sh_type;
    uint32_t sh_flags;
    uint32_t sh_addr;
    uint32_t sh_offset;
    uint32_t sh_size;
    uint32_t sh_link;
    uint32_t sh_info;
    uint32_t sh_addralign;
    uint32_t sh_entsize;
} Elf32_Shdr;

typedef struct {
    uint32_t sh_name;
    uint32_t sh_type;
    uint64_t sh_flags;
    uint64_t sh_addr;
    uint64_t sh_offset;
    uint64_t sh_size;
    uint32_t sh_link;
    uint32_t sh_info;
    uint64_t sh_addralign;
    uint64_t sh_entsize;
} Elf64_Shdr;

typedef struct
{
    uint32_t p_type;
    uint32_t p_offset;
    uint32_t p_vaddr;
    uint32_t p_paddr;
    uint32_t p_filesz;
    uint32_t p_memsz;
    uint32_t p_flags;
    uint32_t p_align;
} Elf32_Phdr;

typedef struct {
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
} Elf64_Phdr;

typedef struct {
    uint32_t r_offset;
    uint32_t r_info;
    int32_t  r_addend;
} Elf32_Rela;

typedef struct {
    uint64_t r_offset;
    uint64_t r_info;
    int64_t  r_addend;
} Elf64_Rela;

#if __riscv_xlen == 64
#   define Elf_Ehdr Elf64_Ehdr
#   define Elf_Shdr Elf64_Shdr
#   define Elf_Phdr Elf64_Phdr
#   define Elf_Rela Elf64_Rela
#else
#   define Elf_Ehdr Elf32_Ehdr
#   define Elf_Shdr Elf32_Shdr
#   define Elf_Phdr Elf32_Phdr
#   define Elf_Rela Elf32_Rela
#endif

#define PT_LOAD 1
#define SHT_RELA 4

static int check_elf(const void *data) {
    // Check alignment
    if ((size_t)data & 3)
        return 0;

    // Check magic number
    const Elf_Ehdr *eh = data;
    if (!(eh->e_ident[0] == '\177' && eh->e_ident[1] == 'E' &&
            eh->e_ident[2] == 'L' && eh->e_ident[3] == 'F')) {
        return 0;
    }

    return 1;
}

size_t program_flash_with_elf(const void *data, size_t flash_offset) {
    if (!check_elf(data))
        return 0;

    const Elf_Ehdr *eh = data;

    int ph_num = eh->e_ph_num;
    const Elf_Phdr *ph = data + eh->e_phoff;

    for(int i = 0; i < ph_num-1; i++) {
        if(ph[i].p_type != PT_LOAD || ph[i].p_memsz == 0)
            continue;
        if((ph[i].p_paddr & SENTINEL) == 0)
            continue;

        // Load data into simulated Flash segment
        size_t paddr = ph[i].p_paddr;
        if(paddr & SENTINEL) {
            paddr += flash_offset;
            memcpy((void*)paddr, data + ph[i].p_offset, ph[i].p_filesz);
        }
    }

    return eh->e_entry + flash_offset;
}

static const char *get_str(const void *data, uint32_t str_idx) {
    const Elf_Ehdr *eh = data;
    const Elf_Shdr *sh = data + eh->e_shoff;
    return data + sh[eh->e_shstrndx].sh_offset + str_idx;
}

rela_section_info rela_section(const void *data, int skip_sections) {
    if (!check_elf(data))
        return (rela_section_info){0, 0};

    const Elf_Ehdr *eh = data;
    const Elf_Shdr* sh = data + eh->e_shoff;

    for(int i = skip_sections; i < eh->e_sh_num-1; i++) {
        if(sh[i].sh_type == SHT_RELA) {
            const Elf_Rela *rela = data + sh[i].sh_offset;

            // We don't apply relocations in Flash (e.g. .rela.text)
            if(rela->r_offset & SENTINEL)
                continue;

            return (rela_section_info){sh[i].sh_size, sh[i].sh_offset};
        }
    }

    return (rela_section_info){0, 0};
}
