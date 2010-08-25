MEMORY
{
	LinuxProcess:	org = 0x80000000 len = 0x80000000
}

SECTIONS
{
    .text : PALIGN(32) {
        _stext = .;
	*(.text)
        _etext = .;
    } > LinuxProcess

    GROUP (NEARDP) : ALIGN(4096)
    {
       .neardata   /* ELF only */
       .rodata     /* ELF only */
        _bss_start = .;
       .bss        /* COFF & ELF */
        _bss_end = .;
	.data : PALIGN(8) {
	      _sdata = .;
	      *(.cinit)
	      *(.cio)
	      *(.data)
	      *(.switch)
	      *(.sysmem)
	      *(.fardata)
	      *(.ppdata)
	      _edata = .;
	      _farbss_start = .;
	      *(.far)
	      _farbss_end = .;
    } > LinuxProcess

  }
}
