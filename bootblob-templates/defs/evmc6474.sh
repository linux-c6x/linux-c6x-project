# makefile fragment to create a specific bootblob
# is sourced into bootblob and should not be used otherwise

EVM=evmc6474	# dual 6474 EVM, NOT the LC version
CPU=C64P
: ${MEM:=""}
: ${CONSOLE:="console=cio"}
: ${JFFS2_OPTIONS:="--no-supported-flash-on-this-platform"}
: ${MEMORY_START:=0x80000000}

