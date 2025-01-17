# these are mandatory
LOCALVERSION = -evmc6472$(ENDIAN_SUFFIX)$(BUILD_SUFFIX)-D
DEFCONFIG = ti_evmc6472_defconfig

# these are optional
CONFIGPATCH = patches/ti_evmc6472_D_defconfig.patch

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-nov mem=32M emac_shared ro
else
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be-nov mem=32M emac_shared ro
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = 
