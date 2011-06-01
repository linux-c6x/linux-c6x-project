#!/bin/sh
insmod ./sharedregionapp.ko SHAREDMEM=0x8FE00000 NUMPROCS=3 PROCID=123
rmmod ./sharedregionapp.ko
