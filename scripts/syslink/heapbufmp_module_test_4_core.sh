#!/bin/sh
insmod ./heapbufmpapp.ko NUMPROCS=3 PROCID=123
rmmod  ./heapbufmpapp.ko
