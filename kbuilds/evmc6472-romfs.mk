# these are mandatory
DEFCONFIG = ti_evmc6472_defconfig
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)$(BUILD_SUFFIX)

# these are optional
KOBJNAME=evmc6472$(ENDIAN_SUFFIX)
CONFIGPATCH =
CMDLINE = console=cio ip=dhcp root=/dev/mtdblock0 ro
PRODVERSION = -romfs

