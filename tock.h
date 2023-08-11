// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stddef.h>
#include <stdint.h>

#define SENTINEL 0x80000000

void load_from_flash(size_t app_start, size_t mem_start);
