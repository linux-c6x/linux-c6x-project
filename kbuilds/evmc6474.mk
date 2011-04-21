# these are mandatory
LOCALVERSION = -evmc6474$(ENDIAN_SUFFIX)-$(DATE)
DEFCONFIG = ti_evmc6474_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x,v3,tcp rw
else
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be,v3,tcp rw
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
