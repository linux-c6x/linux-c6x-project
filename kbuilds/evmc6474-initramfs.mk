# these are mandatory
DEFCONFIG = ti_evmc6474_defconfig
LOCALVERSION = -evmc6474$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=evmc6474$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=cio ip=dhcp rw
PRODVERSION = -1-initramfs