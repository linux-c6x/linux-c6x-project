#!/bin/sh
insmod ./listmpapp.ko NUMPROCS=3 PROCID=123
rmmod  ./listmpapp.ko
