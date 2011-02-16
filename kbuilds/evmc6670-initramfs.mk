# these are mandatory
DEFCONFIG = ti_evmc6670_defconfig
LOCALVERSION = -evmc6670$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=evmc6670$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=cio rw
PRODVERSION = -1-initramfs
