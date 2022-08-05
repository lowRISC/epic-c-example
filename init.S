    .bss
    .align 12
    .skip (1 << 12)
stack_top:

.section .text.init,"ax",@progbits
.global _start

_start:
    la t0, trap_handler
    csrw mtvec, t0

    la sp, stack_top
    li gp, 0
    call main
    j shutdown

trap_handler:
    li a0, 1
    j shutdown
    j trap_handler
