# these are mandatory
LOCALVERSION = -evmc6474$(ENDIAN_SUFFIX)-$(DATE)-1B
DEFCONFIG = ti_evmc6474_defconfig

# these are optional
CONFIGPATCH = ti_evmc6474_1B_defconfig.patch

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x mem=64M emac_shared ro
else
CMDLINE = console=cio ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be mem=64M emac_shared ro
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
