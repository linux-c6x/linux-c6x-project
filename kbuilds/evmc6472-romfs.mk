# these are mandatory
DEFCONFIG = ti_evmc6472_defconfig
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=evmc6472$(ENDIAN_SUFFIX)
CONFIGPATCH =
CMDLINE = console=hvc ip=dhcp root=/dev/mtdblock0 ro
PRODVERSION = -1-romfs

