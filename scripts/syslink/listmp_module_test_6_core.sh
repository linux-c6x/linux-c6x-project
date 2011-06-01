#!/bin/sh
insmod ./listmpapp.ko NUMPROCS=5 PROCID=01234
rmmod  ./listmpapp.ko
