#!/bin/sh
insmod ./sharedregionapp.ko SHAREDMEM=0x87E00000 NUMPROCS=2 PROCID=01
rmmod ./sharedregionapp.ko
