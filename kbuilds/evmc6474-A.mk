# these are mandatory
LOCALVERSION = -evmc6474$(ENDIAN_SUFFIX)-$(DATE)-A
DEFCONFIG = ti_evmc6474_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=hvc ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-nov mem=32M rw
else
CMDLINE = console=hvc ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be-nov mem=32M rw
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
