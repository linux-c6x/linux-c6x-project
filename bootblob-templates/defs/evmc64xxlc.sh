# makefile fragment to create a specific bootblob
# is sourced into bootblob and should not be used otherwise

# defs common to all low-cost c64x platforms: evmc6472 evmc6457 evmc6474-lite
CPU=C64P
: ${MEM:=""}
: ${CONSOLE:="console=ttySI0,115200"}
: ${JFFS2_OPTIONS:="--eraseblock=128KiB --pagesize=2048"}
: ${JFFS2_DEV:="/dev/mtdblock3"}

