# these are mandatory
DEFCONFIG = ti_evmtci6616_defconfig
LOCALVERSION = -evmtci6616$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
CONFIGPATCH =
ifeq ($(ENDIAN),little)
CMDLINE = console=cio
else
CMDLINE = console=cio
endif
PRODVERSION = -1
