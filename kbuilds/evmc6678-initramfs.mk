# these are mandatory
DEFCONFIG = ti_evmc6678_defconfig
LOCALVERSION = -evmc6678$(ENDIAN_SUFFIX)$(BUILD_NAME)

# these are optional
KOBJNAME=evmc6678$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=ttyS0,115200 ip=dhcp rw
PRODVERSION = -initramfs
