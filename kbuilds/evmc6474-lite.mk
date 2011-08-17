# these are mandatory
LOCALVERSION = -evmc6474_lite$(ENDIAN_SUFFIX)$(BUILD_NAME)
DEFCONFIG = ti_evmc6474_lite_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x rw
else
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be rw
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION =
