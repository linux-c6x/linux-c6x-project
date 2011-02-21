# these are mandatory
LOCALVERSION = -evmc6474_lite$(ENDIAN_SUFFIX)-$(DATE)-jffs2
DEFCONFIG = ti_evmc6474_lite_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/mtdblock3 rw rootfstype=jffs2
else
CMDLINE = console=cio ip=dhcp root=/dev/mtdblock3 rw rootfstype=jffs2
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = -1
