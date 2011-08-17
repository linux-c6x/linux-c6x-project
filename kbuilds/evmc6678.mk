# these are mandatory
DEFCONFIG = ti_evmc6678_defconfig
LOCALVERSION = -evmc6678$(ENDIAN_SUFFIX)$(BUILD_NAME)

# these are optional
CONFIGPATCH =
ifeq ($(ENDIAN),little)
CMDLINE = console=ttyS0,115200 ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-le-netcp,v3,tcp rw
else
CMDLINE = console=cio rw
endif
PRODVERSION =
