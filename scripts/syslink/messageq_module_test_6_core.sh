#!/bin/sh
insmod ./messageqapp.ko NUMPROCS=5 PROCID=01234
rmmod  ./messageqapp.ko
