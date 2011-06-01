#!/bin/sh
insmod ./gatempapp.ko NUMPROCS=5 PROCID=01234
rmmod  ./gatempapp.ko
