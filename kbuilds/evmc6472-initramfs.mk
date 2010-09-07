# these are mandatory
DEFCONFIG = ti_evmc6472_defconfig
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=evmc6472$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(PRJ)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = console=cio ip=dhcp rw
PRODVERSION = -1-initramfs