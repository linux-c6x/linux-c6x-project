-c
-heap 		0x8000
-stack 		0x8000
-l 		rts6400_elf.lib
MEMORY
{
	VECS: o = 0E0000000h l = 00400h /* reset & interrupt vectors */
	PMEM: o = 0E0000400h l = 0FC00h /* intended for initialization */
	BMEM: o = 0E0010000h l = 40000h /* .bss, .sysmem, .stack, .cinit */
}
SECTIONS
{
	vectors 	> VECS
	
	.text 		> PMEM
	
	.data 		> BMEM
	.stack 	> BMEM
	.bss 		> BMEM
	.sysmem 	> BMEM
	.cinit 	> BMEM
	.const 	> BMEM
	.cio 		> BMEM
	.far 		> BMEM
}