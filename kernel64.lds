OUTPUT_ARCH( "riscv" )

ENTRY( reset_vector )

SECTIONS
{
    . = 0x2000;
    .htif :
    {
        *(.htif)
    }

    . = 0x40000000;
    _ftext = .;

    .text :
    {
        *(.text.init)
    }

    .text :
    {
        *(.text)
        *(.text.*)
    }

    .rodata :
    {
        *(.rdata)
        *(.rodata)
        *(.rodata.*)
    }

    . = ALIGN(0x1000);
    _etext = .;
    _fdata = .;

    .data :
    {
        *(.data)
        *(.data.*)
        *(.srodata*)
    }

    . = ALIGN(16);
    _edata = .;
    _fbss = .;

    _bss_start = .;
    .bss :
    {
        *(.bss)
        *(.bss.*)
        *(.sbss*)
    }

    . = ALIGN(0x1000);
    _end = .;
}
