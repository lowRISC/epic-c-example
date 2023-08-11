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
  // Address offset of .rela.dyn section
  size_t rela_dyn_start;
  // Size of .rela.dyn section
  size_t rela_dyn_size;
  // The size of the stack requested by this application.
  size_t stack_size;
};

void load_from_flash(size_t app_start, size_t mem_start) {
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

  size_t *data = (size_t*)(myhdr->rela_dyn_start + (uint32_t)app_start);

  for (size_t i = 0; i < (myhdr->rela_dyn_size / (int)sizeof(size_t)); i += 3) {
    // The entries are offsets from the beginning of the app's memory region.
    // First, we get a pointer to the location of the address we need to fix.
    size_t* target = (size_t*)(data[i] + mem_start);
    size_t addend = data[i+2];
    if ((addend & SENTINEL) == 0) {
      // Again, we use our sentinel. If the address at that location has a MSB
      // of 0, then we know this is an address in RAM. We need to fix the
      // address by including the offset where the app actual ended up in
      // memory. This is a simple addition since the app was compiled with a
      // memory address of zero.
      *target = addend + mem_start;
    } else {
      // When the MSB is 1, the address is in flash. We clear our sentinel, and
      // then make the address an offset from the start of where the app is
      // located in flash.
      *target = (addend ^ SENTINEL) + app_start;
    }
  }
}
