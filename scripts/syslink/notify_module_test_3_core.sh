#!/bin/sh
insmod ./notifyapp.ko NUMPROCS=2 PROCID=01
rmmod  ./notifyapp.ko
