#!/bin/sh
insmod ./sharedregionapp.ko SHAREDMEM=0x9FE00000 NUMPROCS=7 PROCID=1234567
rmmod ./sharedregionapp.ko
