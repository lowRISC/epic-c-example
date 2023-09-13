#include <stddef.h>

// The following addresses should match those in the linker script

#define SRAM_MEM_START  0x00000000
#define SRAM_MEM_END    0x00010000

#define FLASH_MEM_START 0x80000000
#define FLASH_MEM_END   0x80040000

inline int is_flash(size_t paddr) {
    return paddr >= FLASH_MEM_START && paddr <= FLASH_MEM_END;
}
