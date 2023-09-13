OUTPUT_ARCH( "riscv" )

ENTRY( main )

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
         *    uint64_t data_sym_start;
         *    uint64_t data_start;
         *    uint64_t data_size;
         *    uint64_t bss_start;
         *    uint64_t bss_size;
         *    uint64_t reldata_start;
         *    uint64_t stack_size;
         *  };
         */
        /* Offset of data symbols in flash from the start of the application
         * binary. */
        QUAD(LOADADDR(.data) - ORIGIN(FLASH));
        /* Offset of where the data section will be placed in memory from the
         * beginning of the app's assigned memory. */
        QUAD(_fdata - ORIGIN(SRAM));
        /* Size of data section. */
        QUAD(SIZEOF(.data));
        /* Offset of where the BSS section will be placed in memory from the
         * beginning of the app's assigned memory. */
        QUAD(_fbss - ORIGIN(SRAM));
        /* Size of BSS section */
        QUAD(SIZEOF(.bss));
        /* Address offset of .rela.dyn section */
        QUAD(LOADADDR(.rela.dyn) - ORIGIN(FLASH));
        /* Size of .rela.dyn section */
        QUAD(SIZEOF(.rela.dyn));
        /* The size of the stack requested by this application */
        QUAD(STACK_SIZE);
        QUAD(128);
    } > FLASH =0xFF

    .text :
    {
        . = ALIGN(0x10);
        _ftext = .;
        *(.text.init)
        *(.text)
        *(.text.*)
        *(.gnu.linkonce.t.*)
    } > FLASH

    .rodata :
    {
        . = ALIGN(0x10);
        *(.rdata)
        *(.rodata)
        *(.rodata.*)
        *(.gnu.linkonce.r.*)
    } > FLASH

    . = ALIGN(0x1000);
    _etext = .;

    . = ALIGN(2048);
    .data ALIGN(2048):
    {
        _fdata = .;
        *(.data)
        *(.data.*)
        *(.sdata*)
        *(.srodata*)
        *(.gnu.linkonce.d.*)
        *(.comment)
    } > SRAM AT > FLASH

    . = ALIGN(16);
    _edata = .;

    /* Start of uninitialized data segment */
    _fbss = .;

    /* sbss: Uninitialized writeable small data section */

    /* bss: Uninitialized writeable data section */
    _bss_start = .;
    .bss :
    {
        *(.bss)
        *(.bss.*)
        *(.sbss*)
        *(.gnu.linkonce.b.*)
        *(COMMON)
    } > SRAM

    .endflash :
    {
    } > FLASH

    . = ALIGN(0x1000);
    _end = .;
}
