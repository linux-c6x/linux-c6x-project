# these are mandatory
DEFCONFIG = ti_evmc6670_defconfig
LOCALVERSION = -evmc6670$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
CONFIGPATCH =
ifeq ($(ENDIAN),little)
CMDLINE = console=cio
else
CMDLINE = console=cio
endif
PRODVERSION = -1
