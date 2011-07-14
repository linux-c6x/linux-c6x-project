# makefile fragment to create a specific bootblob

MEM     ?= mem=256M
IP      ?= ip=dhcp
CONSOLE ?= console=ttyS0,115200
ROOT    ?= rw

MEMORY_START=0x80000000


ifneq ($(INITRAMFS),)

BOOTBLOB_DEPENDS = 
BOOTBLOB_CMD=./bootblob make-image \
    --abs-base=$(MEMORY_START) --round=0x100000 \
    $(BOOTBLOB_FILE)-$(ARCHef).bin \
    vmlinux-2.6.34-$(EVM)$(ENDIAN_SUFFIX)-$(DATE)-1.bin \
    $(INITRAMFS)-$(ARCHef).cpio.gz \
    "$(CONSOLE) initrd=0x%fsimage-start-abs-x%,0x%fsimage-size-x% $(ROOT) $(MEM) $(IP) rw"

else

BOOTBLOB_DEPENDS = 
BOOTBLOB_CMD=cp vmlinux-2.6.34-$(EVM)$(ENDIAN_SUFFIX)-$(DATE)-1.bin $(BOOTBLOB_FILE)-$(ARCHe).bin; \
    ./bootblob set-cmdline $(BOOTBLOB_FILE)-$(ARCHe).bin \
    "$(CONSOLE) $(ROOT) $(MEM) $(IP)"

endif

