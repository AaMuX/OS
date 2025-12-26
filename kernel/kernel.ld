/* Linker script for minimal bare-metal RISC-V kernel */
ENTRY(_start)


PROVIDE(_stack_top = 0x80020000);

SECTIONS
{

  . = 0x80000000;

  _text = .;
  .text : {
    *(.text*)
  }
  _etext = .;

  _rodata = .;
  .rodata : {
    *(.rodata*)
  }
  _erodata = .;

  _data = .;
  .data : {
    *(.data*)
  }
  _edata = .;


  .bss (NOLOAD) : {
    __bss_start = .;
    *(.bss*)
    *(COMMON)
    __bss_end = .;
  }
  
  _end = .;  

}
