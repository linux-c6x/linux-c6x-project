# these are mandatory
DEFCONFIG = ti_evmc6678_defconfig
LOCALVERSION = -evmc6678$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
CONFIGPATCH =
ifeq ($(ENDIAN),little)
CMDLINE = console=ttyS0,115200 rw
else
CMDLINE = console=cio rw
endif
PRODVERSION = -1
