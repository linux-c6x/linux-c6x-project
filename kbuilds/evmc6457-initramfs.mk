# these are mandatory
DEFCONFIG = ti_evmc6457_defconfig
LOCALVERSION = -evmc6457$(ENDIAN_SUFFIX)$(BUILD_NAME)

# these are optional
KOBJNAME=evmc6457$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=ttySI0,115200 ip=dhcp rw
PRODVERSION = -initramfs
