#!/bin/sh
insmod ./heapmemmpapp.ko NUMPROCS=2 PROCID=01
rmmod  ./heapmemmpapp.ko
