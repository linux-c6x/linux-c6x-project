# these are mandatory
DEFCONFIG = ti_evmc6670_defconfig
LOCALVERSION = -evmc6670$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=evmc6670$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=ttyS0,115200 ip=dhcp rw
PRODVERSION = -1-initramfs
