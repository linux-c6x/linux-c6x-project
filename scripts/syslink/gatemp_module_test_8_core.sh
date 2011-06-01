#!/bin/sh
insmod ./gatempapp.ko NUMPROCS=7 PROCID=1234567
rmmod  ./gatempapp.ko
