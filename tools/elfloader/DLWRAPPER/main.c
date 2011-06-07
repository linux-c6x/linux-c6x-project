#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include "dload_api.h"

/* dload <core #> <elf file name> */
int main(int argc, char **argv)
{
	FILE *fp;
	int  ret=0;
	int  core;
	unsigned int  prog_handle, entry_address, vector_address;

	if (argc < 3) {
		printf("Usage: %s <core #> <ELF File>\n", argv[0]);
		return -1;
	}
	    
	fp = fopen(argv[2], "rb"); 

    if (!fp) {
        printf("Failed to open file %s\n", argv[2]);
        return -1;
    }

    core = atoi(argv[1]);
    if (DLIF_reset_core(core))
    {
       printf("Failed to reset core '%d'\n", core);
       ret = -1;
       goto error;
    }

    /* Initialize the dynamic loader */
    DLOAD_initialize();

	/* load the image */
	prog_handle = DLOAD_load(core, fp, 0, NULL);
    if (!prog_handle) {
        printf("Failed to load file %s on core %d\n", argv[2], core);
        ret = -1;
        goto error;
    }

    if (DLOAD_get_entry_point(prog_handle, (void **)&entry_address) != TRUE) {
        printf("ERROR: Could not retrieve program entry point\n");
        ret = -1;
        goto error;
    }

    printf("Program entry address: 0x%x\n", entry_address);

    if (entry_address & 0x3ff) {
        printf("Program entry address not 10bit aligned trying to use reset vector table\n");
        if (DLOAD_get_reset_vector_section(prog_handle, (void **)&vector_address) != TRUE) {
            printf("ERROR: Could not retrieve reset vector address\n");
            ret = -1;
            goto error;
        }
        else {
            printf("Reset vector address: 0x%x\n", vector_address);
            entry_address = vector_address;
        }
    }

    if (DLOAD_unload(prog_handle) != TRUE) {
       printf("Failed to cleanup loader\n"); 
       ret =-1;
       goto error;
    }

    if (DLIF_run_core(core, entry_address))
    {
       printf("Failed to load on core '%d'\n", core);
       ret =-1;
       goto error;
    }
    printf("Started Program execution on core: %d\n", core);

error:
    fclose(fp);
    return ret;
}

