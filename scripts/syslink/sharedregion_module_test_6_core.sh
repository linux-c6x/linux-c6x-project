#!/bin/sh
insmod ./sharedregionapp.ko SHAREDMEM=0xE7E00000 NUMPROCS=5 PROCID=01234
rmmod ./sharedregionapp.ko
