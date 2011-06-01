#!/bin/sh
insmod ./messageqapp.ko NUMPROCS=3 PROCID=123
rmmod  ./messageqapp.ko
