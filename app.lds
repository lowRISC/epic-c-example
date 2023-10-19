OUTPUT_ARCH( "riscv" )

ENTRY( _start )

PROG_LENGTH = 0x00040000; /* 448 KB */
RAM_LENGTH  = 0x00010000; /* 64 KB */
STACK_SIZE  = 0x00001000;

MEMORY {
    FLASH (RX) : ORIGIN = 0x80000000, LENGTH = PROG_LENGTH
    SRAM (RWX) : ORIGIN = 0x00000000, LENGTH = RAM_LENGTH
}

SECTIONS
{
    /* Discard allocatable sections we don't need */
    /DISCARD/ :
    {
        *(.dynsym)
        *(.gnu.hash)
        *(.hash)
        *(.dynstr)
        *(.dynamic)
    }

    .crt0_header :
    {
        /**
         * Populate the header expected by `crt0`:
         *
         *  struct hdr {
         *    size_t data_load_start;
         *    size_t data_start;
         *    size_t data_size;
         *    size_t bss_start;
         *    size_t bss_size;
         *    size_t rela_dyn_start;
         *    size_t rela_dyn_size;
         *  };
         */
        /* Address of data in flash */
        LONG(LOADADDR(.data));
        /* Address of data section */
        LONG(ADDR(.data));
        /* Size of data section */
        LONG(SIZEOF(.data));
        /* Address of BSS section */
        LONG(ADDR(.bss));
        /* Size of BSS section */
        LONG(SIZEOF(.bss));
        /* Address of .rela.dyn section */
        LONG(LOADADDR(.rela.dyn));
        /* Size of .rela.dyn section */
        LONG(SIZEOF(.rela.dyn));
    } > FLASH =0xFF

    .rela.dyn :
    {
        __rela_dyn_start = .;
        *(.rela.dyn)
        __rela_dyn_end = .;
    } > FLASH

    .text ALIGN(4):
    {
        _ftext = .;
        *(.text.init)
        *(.text)
        *(.text.*)
        *(.gnu.linkonce.t.*)
    } > FLASH

    .rodata ALIGN(8):
    {
        *(.rdata)
        *(.rodata)
        *(.rodata.*)
        *(.gnu.linkonce.r.*)
    } > FLASH

    _etext = .;

    .data ALIGN(8):
    {
        *(.data)
        *(.data.*)
        *(.sdata*)
        *(.srodata*)
        *(.gnu.linkonce.d.*)
        *(.comment)
        . = ALIGN(4);
    } > SRAM AT > FLASH

    _edata = .;

    /* bss: Uninitialized writeable data section */
    .bss ALIGN(8):
    {
        *(.bss)
        *(.bss.*)
        *(.sbss*)
        *(.gnu.linkonce.b.*)
        *(COMMON)
        . = ALIGN(4);
    } > SRAM

    .endflash :
    {
    } > FLASH

    _end = .;
}
