# makefile fragment to create a specific bootblob
# is sourced into bootblob and should not be used otherwise

CPU=C66
: ${MEM:="mem=256M"}
: ${CONSOLE:="console=ttyS0,115200"}
: ${JFFS2_OPTIONS:="--eraseblock=16KiB --pagesize=512"}
: ${JFFS2_DEV:="/dev/mtdblock3"}
: ${MEMORY_START:=0x80000000}

