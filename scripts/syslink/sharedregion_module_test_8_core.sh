#!/bin/sh
insmod ./sharedregionapp.ko SHAREDMEM=0x8FE00000 NUMPROCS=7 PROCID=1234567
rmmod ./sharedregionapp.ko
