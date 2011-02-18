# these are mandatory
DEFCONFIG = ti_evmc6474_lite_defconfig
LOCALVERSION = -evmc6474_lite$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=evmc6474-lite$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=cio ip=dhcp rw
PRODVERSION = -1-initramfs
