#!/bin/sh
insmod ./messageqapp.ko NUMPROCS=7 PROCID=1234567
rmmod  ./messageqapp.ko
