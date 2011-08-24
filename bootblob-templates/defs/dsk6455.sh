# makefile fragment to create a specific bootblob
# is sourced into bootblob and should not be used otherwise

EVM=dsk6455
CPU=C64P
: ${MEM:=""}
: ${CONSOLE:="console=cio"}
: ${JFFS2_OPTIONS:="--no-supported-flash-on-this-platform"}
: ${MEMORY_START:=0xe0000000}

