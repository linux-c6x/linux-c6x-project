#!/bin/sh
insmod ./gatempapp.ko NUMPROCS=3 PROCID=123
rmmod  ./gatempapp.ko
