// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "util.h"
#include "htif.h"

void *memset(void *s, int c, size_t n) {
    for(size_t i = 0; i < n; ++i) {
        ((char*)s)[i] = 0;
    }
    return s;
}

void *memcpy(void *dest, const void *src, size_t n) {
    for(size_t i = 0; i < n; ++i) {
        ((char*)dest)[i] = ((char*)src)[i];
    }
    return dest;
}

static unsigned strlen(const char* str) {
    long i = 0;
    while(str[i] != 0)
        ++i;
    return i;
}

void print(char *s) {
    syscall(SYS_write, 0, (uintptr_t)s, (uintptr_t)strlen(s), 0, 0, 0, 0);
}
