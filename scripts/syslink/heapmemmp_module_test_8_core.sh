#!/bin/sh
insmod ./heapmemmpapp.ko NUMPROCS=7 PROCID=1234567
rmmod  ./heapmemmpapp.ko
