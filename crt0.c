// This file is loosely based on `libtock/crt0.c` from the libtock-c repository
// <https://github.com/tock/libtock-c> and is therefore licensed under Apache
// License, Version 2.0 <http://www.apache.org/licenses/LICENSE-2.0> or the MIT
// license <http://opensource.org/licenses/MIT>, at your option.

#include "addrs.h"
#include "util.h"

struct hdr {
    size_t data_load_start;
    size_t data_start;
    size_t data_size;
    size_t bss_start;
    size_t bss_size;
    size_t rela_dyn_start;
    size_t rela_dyn_length;
};

typedef struct {
    size_t r_offset;
    size_t r_info;
    ptrdiff_t r_addend;
} Elf_Rela;

void _start(size_t app_start, size_t flash_offset, size_t mem_offset) {
    struct hdr* hdr = (struct hdr*)(app_start);

    // Load statically initialized data into memory.
    void* data_start      = (void*)(hdr->data_start + mem_offset);
    void* data_load_start = (void*)(hdr->data_load_start + flash_offset);
    memcpy(data_start, data_load_start, hdr->data_size);

    // Zero BSS segment.
    void* bss_start = (void*)(hdr->bss_start + mem_offset);
    memset(bss_start, 0, hdr->bss_size);

    // Apply relocations (to fix statically initialized pointers).
    Elf_Rela *rel_data = (Elf_Rela*)(hdr->rela_dyn_start + flash_offset);
    for (size_t i = 0; i < (hdr->rela_dyn_length); i++) {
        // The entries are offsets from the beginning of the app's memory region.
        // First, we get a pointer to the location of the address we need to fix.
        size_t* target = (size_t*)(rel_data[i].r_offset + mem_offset);
        size_t addend = rel_data[i].r_addend;
        if (is_flash(addend)) {
            // Relocate pointers to flash memory by adding the flash offset
            *target = addend + flash_offset;
        } else {
            // Relocate pointers to sram memory by adding the sram offset
            *target = addend + mem_offset;
        }
    }

    int main(void);
    main();
}
