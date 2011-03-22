# these are mandatory
LOCALVERSION = -evmc6474_lite$(ENDIAN_SUFFIX)-$(DATE)
DEFCONFIG = ti_evmc6474_lite_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=hvc ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x rw
#CMDLINE = console=hvc ip=dhcp root=/dev/nfs nfsroot=10.218.100.248:/opt/min-root-c6474-le rw
else
CMDLINE = console=hvc ip=dhcp root=/dev/nfs nfsroot=158.218.100.25:/opt/min-root-c6x-be rw
#CMDLINE = console=hvc ip=dhcp root=/dev/nfs nfsroot=10.218.100.248:/opt/min-root-c6474-be rw
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
