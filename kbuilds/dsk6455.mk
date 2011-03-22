# these are mandatory
DEFCONFIG = ti_dsk6455_defconfig
LOCALVERSION = -dsk6455$(ENDIAN_SUFFIX)-$(DATE)

# these are optional
CONFIGPATCH =
ifeq ($(ENDIAN),little)
CMDLINE = emac_addr=00:0e:1e:64:55:01 console=hvc ip=dhcp root=/dev/nfs nfsroot=/es/nfsroots/ti6455-le-1 rw
else
CMDLINE = emac_addr=00:0e:1e:64:55:01 console=hvc ip=dhcp root=/dev/nfs nfsroot=/es/nfsroots/ti6455-be-1 rw
endif
PRODVERSION = -1
