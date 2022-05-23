// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stddef.h>
#include <stdint.h>

#define SENTINEL 0x80000000

typedef struct {
  size_t size;
  size_t offset;
} rela_section_info;

size_t program_flash_with_elf(const void *data, size_t flash_offset);
rela_section_info rela_section(const void *data, int skip_sections);
