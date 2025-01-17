# these are mandatory
LOCALVERSION = -evmc6457$(ENDIAN_SUFFIX)$(BUILD_SUFFIX)
DEFCONFIG = ti_evmc6457_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-oct,v3,tcp rw
else
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be-oct,v3,tcp rw
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION =
