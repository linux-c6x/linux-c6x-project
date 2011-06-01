#!/bin/sh
insmod ./gatempapp.ko NUMPROCS=2 PROCID=01
rmmod  ./gatempapp.ko
