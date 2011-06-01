#!/bin/sh
insmod ./heapmemmpapp.ko NUMPROCS=5 PROCID=01234
rmmod  ./heapmemmpapp.ko
