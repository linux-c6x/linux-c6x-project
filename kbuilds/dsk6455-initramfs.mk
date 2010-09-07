# these are mandatory
DEFCONFIG = ti_dsk6455_defconfig
LOCALVERSION = -dsk6455$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
KOBJNAME=dsk6455$(ENDIAN_SUFFIX)
CONFIGPATCH =
CONFIGSCRIPT = initramfs.sh
CONFIGARGS = $(BLD)/rootfs/$(ROOTFS)-$(ARCHe) NONE

CMDLINE = emac_addr=00:0e:1e:64:55:01 console=cio ip=dhcp rw
PRODVERSION = -1-initramfs
