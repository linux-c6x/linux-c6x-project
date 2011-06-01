#!/bin/sh
insmod ./notifyapp.ko NUMPROCS=7 PROCID=1234567
rmmod  ./notifyapp.ko
