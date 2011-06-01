#!/bin/sh
insmod ./heapbufmpapp.ko NUMPROCS=7 PROCID=1234567
rmmod  ./heapbufmpapp.ko
