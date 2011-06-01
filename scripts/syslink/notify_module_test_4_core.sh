#!/bin/sh
insmod ./notifyapp.ko NUMPROCS=3 PROCID=123
rmmod  ./notifyapp.ko
