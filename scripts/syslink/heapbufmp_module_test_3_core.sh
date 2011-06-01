#!/bin/sh
insmod ./heapbufmpapp.ko NUMPROCS=2 PROCID=01
rmmod  ./heapbufmpapp.ko
