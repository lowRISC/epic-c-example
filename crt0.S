#if __riscv_xlen == 32
    .equ xsize, 4
#define LOAD lw
#define STORE sw
#elif __riscv_xlen == 64
    .equ xsize, 8
#define LOAD ld
#define STORE sd
#else
#    error Unsupported configuration
#endif

    .equ hdr_data_load_start_offset, 0
    .equ hrd_data_start_offset, hdr_data_load_start_offset + xsize
    .equ hdr_data_size_offset, hrd_data_start_offset + xsize
    .equ hrd_bss_start_offset, hdr_data_size_offset + xsize
    .equ hdr_bss_size_offset, hrd_bss_start_offset + xsize
    .equ hdr_rela_dyn_start_offset, hdr_bss_size_offset + xsize
    .equ hdr_rela_dyn_size_offset, hdr_rela_dyn_start_offset + xsize
    .equ rela_entry_size, 3 * xsize
    .equ flash_mem_start, 0x80000000

    .text
    .globl    _start
_start:
    addi sp, sp, -(4*xsize)
    STORE ra, 3*xsize(sp)
    STORE s0, 2*xsize(sp)
    STORE s1, 1*xsize(sp)
    STORE s2, 0*xsize(sp)

    mv s0, a0
    mv s1, a1
    mv s2, a2

    LOAD a0, hrd_data_start_offset(s0)      // a0 <- hdr->data_start
    add a0, a0, a2                          // a0 <- hdr->data_start + mem_offset
    LOAD a1, hdr_data_load_start_offset(s0) // a1 <- hdr->data_load_start
    add a1, a1, s1                          // a1 <- hdr->data_load_start + flash_offset
    LOAD a2, hdr_data_size_offset(s0)       // a2 <- hdr->data_size
    call memcpy                             // memcpy(data_start + mem_offset, data_load_start + flash_offset, hdr->data_size);

    LOAD a0, hrd_bss_start_offset(s0)       // a0 <- hdr->bss_start
    add a0, a0, s2                          // a0 <- hdr->bss_start + mem_offset
    li a1, 0                                // a1 <- 0
    LOAD a2, hdr_bss_size_offset(s0)        // a2 <- hdr->bss_size
    call memset                             // memset(bss_start + mem_offset, 0, hdr->bss_size);

    li t0, 0                                // t0 <- i = 0
    LOAD t1, hdr_rela_dyn_size_offset(s0)   // t1 <- hdr->rela_dyn_size
    LOAD t2, hdr_rela_dyn_start_offset(s0)  // t2 <- hdr->rela_dyn_start
    add t2, t2, s1                          // t2 <- hdr->rela_dyn_start + flash_offset
    li t3, flash_mem_start
1:
    add t4, t2, t0                          // t4 <- rel_data_entry = hdr->rela_dyn_start + flash_offset + i
    LOAD t5, 0*xsize(t4)                    // t5 <- rel_data_entry->r_offset
    add t5, t5, s2                          // t5 <- rel_data_entry->r_offset + mem_offset
    LOAD t6, 2*xsize(t4)                    // t6 <- rel_data_entry->r_addend
    bgeu t6, t3, 2f
    add t6, t6, s2                          // t6 <- rel_data_entry->r_addend + mem_offset
    j 3f
2:
    add t6, t6, s1                          // t6 <- rel_data_entry->r_addend + flash_offset
3:
    STORE t6, 0(t5)
    addi t0, t0, rela_entry_size
    bltu t0, t1, 1b

    mv a2, s2
    mv a1, s1
    mv a0, s0

    call main

    LOAD ra, 3*xsize(sp)
    LOAD s0, 2*xsize(sp)
    LOAD s1, 1*xsize(sp)
    LOAD s2, 0*xsize(sp)
    addi sp, sp, 4*xsize

    ret
