#!/bin/sh
insmod ./heapmemmpapp.ko NUMPROCS=3 PROCID=123
rmmod  ./heapmemmpapp.ko
