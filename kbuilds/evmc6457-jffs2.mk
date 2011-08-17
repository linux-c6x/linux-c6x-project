# these are mandatory
LOCALVERSION = -evmc6457$(ENDIAN_SUFFIX)$(BUILD_NAME)-jffs2
DEFCONFIG = ti_evmc6457_defconfig

# these are optional
CONFIGPATCH =

ifeq ($(ENDIAN),little)
CMDLINE = console=cio ip=dhcp root=/dev/mtdblock3 rw rootfstype=jffs2
else
CMDLINE = console=cio ip=dhcp root=/dev/mtdblock3 rw rootfstype=jffs2
endif

# tack this on to name of kernel when copying vmlinux to product directory
PRODVERSION = 
