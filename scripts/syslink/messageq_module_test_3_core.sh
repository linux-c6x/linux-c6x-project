#!/bin/sh
insmod ./messageqapp.ko NUMPROCS=2 PROCID=01
rmmod  ./messageqapp.ko
