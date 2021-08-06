// This file is based on `libtock/crt0.c` from the libtock-c repository
// <https://github.com/tock/libtock-c> and is therefore licensed under Apache
// License, Version 2.0 <http://www.apache.org/licenses/LICENSE-2.0> or the MIT
// license <http://opensource.org/licenses/MIT>, at your option.

#include <stdint.h>

// The structure of the relative data section. This structure comes from the
// compiler.
struct reldata {
  // Number of relative addresses.
  uint32_t len;
  // Array of offsets of the address to be updated relative to the start of the
  // application's memory region. Each address at these offsets needs to be
  // adjusted to be a fixed address relative to the start of the app's actual
  // flash or RAM start address.
  const uint32_t *data;
};

void load_from_flash(uint32_t app_start, uint32_t mem_start,
                     struct reldata *rel_data);
