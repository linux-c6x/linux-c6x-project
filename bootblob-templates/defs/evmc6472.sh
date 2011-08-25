# makefile fragment to create a specific bootblob
# is sourced into bootblob and should not be used otherwise

EVM=evmc6472
source ${STD_TEMPLATE_DIR}/defs/evmc64xxlc.sh
: ${MEMORY_START:=0xE0000000}

