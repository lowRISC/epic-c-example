    .bss
    .align 12
    .skip (1 << 12)
stack_top:

    .section .text.init,"ax",@progbits
trap_vector:
    #li a0, 125
    #j shutdown
    mret

.global reset_vector
.global start

reset_vector:
    la sp, stack_top
    li gp, 0
    call start
    j shutdown
