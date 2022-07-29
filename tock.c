// This file is based on `libtock/crt0.c` from the libtock-c repository
// <https://github.com/tock/libtock-c> and is therefore licensed under Apache
// License, Version 2.0 <http://www.apache.org/licenses/LICENSE-2.0> or the MIT
// license <http://opensource.org/licenses/MIT>, at your option.

#include "tock.h"
#include "util.h"

struct hdr {
  // Offset of data symbols in flash from the start of the application binary.
  size_t data_sym_start;
  // Offset of where the data section needs to be placed in memory from the
  // start of the application's memory region.
  size_t data_start;
  // Size of data section.
  size_t data_size;
  // Offset of where the BSS section needs to be placed in memory from the start
  // of the application's memory region.
  size_t bss_start;
  // Size of BSS section.
  size_t bss_size;
  // First address offset after program flash, where elf2tab places the
  // .rel.data section
  size_t reldata_start;
  // The size of the stack requested by this application.
  size_t stack_size;
};

void load_from_flash(size_t app_start, size_t mem_start,
                     struct reldata *rel_data) {
  struct hdr* myhdr = (struct hdr*)app_start;

  // Load the data section from flash into RAM. We use the offsets from our
  // crt0 header so we know where this starts and where it should go.
  void* data_start     = (void*)(myhdr->data_start + mem_start);
  void* data_sym_start = (void*)(myhdr->data_sym_start + app_start);
  memcpy(data_start, data_sym_start, myhdr->data_size);

  // Zero BSS segment. Again, we know where this should be in the process RAM
  // based on the crt0 header.
  char* bss_start = (char*)(myhdr->bss_start + mem_start);
  memset(bss_start, 0, myhdr->bss_size);

#if 0
  // The original code assumes that the relocation data is in Flash.
  struct reldata* rd = (struct reldata*)(myhdr->reldata_start + (uint32_t)app_start);
#else
  // In this demo it's in the ELF file but not in a loadable section, and thus
  // it won't be in the simulated Flash ROM. Therefore, we load it from the ELF
  // data in the kernel's memory (passed as an additional argument).
  struct reldata* rd = rel_data;
#endif
  for (size_t i = 0; i < (rd->len / (int)sizeof(size_t)); i += 3) {
    // The entries are offsets from the beginning of the app's memory region.
    // First, we get a pointer to the location of the address we need to fix.
    size_t* target = (size_t*)(rd->data[i] + mem_start);
    size_t addend = rd->data[i+2];
    if ((*target & SENTINEL) == 0) {
      // Again, we use our sentinel. If the address at that location has a MSB
      // of 0, then we know this is an address in RAM. We need to fix the
      // address by including the offset where the app actual ended up in
      // memory. This is a simple addition since the app was compiled with a
      // memory address of zero.
      *target += mem_start;
    } else {
      // When the MSB is 1, the address is in flash. We clear our sentinel, and
      // then make the address an offset from the start of where the app is
      // located in flash.
      *target = (*target ^ SENTINEL) + app_start;
    }
  }
}
