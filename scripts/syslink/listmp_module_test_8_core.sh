#!/bin/sh
insmod ./listmpapp.ko NUMPROCS=7 PROCID=1234567
rmmod  ./listmpapp.ko
