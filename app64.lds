OUTPUT_ARCH( "riscv" )

ENTRY( main )

PROG_LENGTH = 0x00040000; /* 448 KB */
RAM_LENGTH  = 0x00010000; /* 64 KB */
STACK_SIZE  = 0x00001000;

MEMORY {
    FLASH (rx) : ORIGIN = 0x80000000, LENGTH = PROG_LENGTH
    SRAM (RWX) : ORIGIN = 0x00000000, LENGTH = RAM_LENGTH
}

SECTIONS
{
    .crt0_header :
    {
        /**
         * Populate the header expected by `crt0`:
         *
         *  struct hdr {
         *    uint64_t got_sym_start;
         *    uint64_t got_start;
         *    uint64_t got_size;
         *    uint64_t data_sym_start;
         *    uint64_t data_start;
         *    uint64_t data_size;
         *    uint64_t bss_start;
         *    uint64_t bss_size;
         *    uint64_t reldata_start;
         *    uint64_t stack_size;
         *  };
         */
        /* Offset of GOT symbols in flash from the start of the application
         * binary. */
        QUAD(LOADADDR(.got) - ORIGIN(FLASH));
        /* Offset of where the GOT section will be placed in memory from the
         * beginning of the app's assigned memory. */
        QUAD(_got - ORIGIN(SRAM));
        /* Size of GOT section. */
        QUAD(SIZEOF(.got));
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
        /* First address offset after program flash, where elf2tab places
         * .rel.data section */
        QUAD(LOADADDR(.endflash) - ORIGIN(FLASH));
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

    .stack :
    {
        /* elf2tab requires that the `_SRAM_ORIGIN` symbol be present to
		 * mark the first address in the SRAM memory. Since ELF files do
		 * not really need to specify this address as they only care about
		 * loading into flash, we need to manually mark this address for
		 * elf2tab. elf2tab will use it to add a fixed address header in the
		 * TBF header if needed.
		 */
	    _sram_origin = .;

        /* Be conservative about our alignment for the stack. Different
         * architectures require different values (8 for ARM, 16 for RISC-V),
         * so we choose the largest value. In practice, this likely will not
         * matter since the start of SRAM is unlikely to be at a very peculiar
         * address.
         */
        . = ALIGN(16);
        _stack = .;
        . = _stack + STACK_SIZE;
        . = ALIGN(16);
    } > SRAM

    .got :
    {
        . = ALIGN(4);
        _got = .;
        *(.got*)
        *(.got.plt*)
        . = ALIGN(128);
    } > SRAM AT > FLASH

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
