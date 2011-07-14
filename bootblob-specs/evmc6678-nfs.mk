# makefile fragment to create a specific bootblob

EVM=evmc6678
INITRAMFS=
ROOT=root=/dev/nfs nfsroot=/sysroots/$(EVM)$(ENDIAN_SUFFIX)/,v3,tcp rw

include $(PRJ)/bootblob-specs/defs/evmc667x.mk
