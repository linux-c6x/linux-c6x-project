# these are mandatory
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)-$(DATE)-B
DEFCONFIG = ti_evmc6472_defconfig

# these are optional
CONFIGPATCH = ti_evmc6472_B_defconfig.patch

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=/es/nfsroots/ti6472-le-1 mem=128M emac_shared ro
else
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=/es/nfsroots/ti6472-be-1 mem=128M emac_shared ro
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
