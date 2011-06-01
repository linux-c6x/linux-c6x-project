#!/bin/sh
insmod ./notifyapp.ko NUMPROCS=5 PROCID=01234
rmmod  ./notifyapp.ko
