# these are mandatory
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)-$(DATE)
DEFCONFIG = ti_evmc6472_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=ttySI0,115200 ip=dhcp root=/dev/nfs nfsroot=/es/nfsroots/ti6472-le-1 rw
else
CMDLINE = console=ttySI0,115200 ip=dhcp root=/dev/nfs nfsroot=/es/nfsroots/ti6472-be-1 rw
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
