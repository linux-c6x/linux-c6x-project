#!/bin/sh
insmod ./listmpapp.ko NUMPROCS=2 PROCID=01
rmmod  ./listmpapp.ko
