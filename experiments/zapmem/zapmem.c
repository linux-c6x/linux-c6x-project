/*
** zapmem.c: fill memory section used for intramfs
** [Because fill memory from CCS 3 is too slow]
*/

#include <stdio.h>

void main()
{	
    unsigned long start = 0xE1000000;
    unsigned long len   = 0x01000000;
    unsigned char fill  = 0;
    
    printf("zapmem: start %8.8lX  for %8.8lX  fill %2.2X\n", start, len, fill);
    memset(start, fill, len);
    printf("done\n");
}

