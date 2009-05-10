-c
-heap 		0x8000
-stack 		0x8000
-l 		rts6400.lib
MEMORY
{
	VECS: o = 80000000h l = 00400h /* reset & interrupt vectors */
	PMEM: o = 80000400h l = 0FC00h /* intended for initialization */
	BMEM: o = 80010000h l = 40000h /* .bss, .sysmem, .stack, .cinit */
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