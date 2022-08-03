#include "elf.h"
#include "htif.h"
#include "util.h"
#include "tock.h"

// Include the ELF contents of relocatable apps for us to load.
// All of these apps need to be compiled with -fepic.

// Example app: CoreMark.
__attribute__ ((aligned(8))) const
#include "cm.h"

int start() {
    // Arbitrary SRAM and Flash app addresses.
    // You can change these to relocate the loadable app. Just be sure you
    // don't collide with the kernel (0x80000000-~0x80010000) and that the
    // address range has been made available in spike. The first two pages
    // (0 - 0x2000) are reserved by spike and the third page contains the
    // host-target interface symbols defined in the kernel (0x2000, 0x2008).
    size_t sram_addr = 0x12340000;
    size_t flash_addr = 0x81234000;

    const void* elf_data = cm; // App to load.

    // Simulate programming "Flash" with an app's ELF file contents.
    size_t entry = program_flash_with_elf(elf_data, flash_addr - SENTINEL);
    if (entry == 0) {
        print("Failed to load app\n");
        return 1;
    }

    // Get relocation data from the ELF file. We could call rela_section
    // multiple times to get the various relocation sections but here we
    // assume that only one relocation section is needed (.rela.data).
    rela_section_info rela_info = rela_section(elf_data, 0);
    if (rela_info.offset == 0) {
        print("Failed to find relocation section\n");
        return 1;
    }

    // Put the relocation data in the format expected by the libtock-c crt0.
    struct reldata rel_data = {rela_info.size, elf_data + rela_info.offset};

    // Use loader adapted from libtock-c crt0 to load the app from the simulated
    // Flash and relocate it.
    load_from_flash(flash_addr, sram_addr, &rel_data);

    // Set the GP register (the PIC base) to the app's SRAM base address.
    // This is needed every time control is transfered to a different
    // relocatable app.
    asm volatile("mv gp, %0" :: "r"(sram_addr));

    // Transfer control to the app we loaded.
    ((int(*)())entry)();

    return 0;
}
