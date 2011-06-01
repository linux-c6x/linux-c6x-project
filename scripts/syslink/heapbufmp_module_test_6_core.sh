#!/bin/sh
insmod ./heapbufmpapp.ko NUMPROCS=5 PROCID=01234
rmmod  ./heapbufmpapp.ko
