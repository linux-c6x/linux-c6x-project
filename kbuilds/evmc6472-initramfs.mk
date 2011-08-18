# these are mandatory
DEFCONFIG = ti_evmc6472_defconfig
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)$(BUILD_SUFFIX)

# these are optional
KOBJNAME=evmc6472$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=cio ip=dhcp rw
PRODVERSION = -initramfs
