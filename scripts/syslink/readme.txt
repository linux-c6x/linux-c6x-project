======== SysLink sample application readme.txt ==========

In all of the sample applications, SysLink/IPC sample runs on Core0 and 
BIOS/IPC sample applications run on remaining cores.

c66x platforms
==============

In order to simplify the syslink sample application execution by the user
wrapper scripts are provided per evm. The files are defined per core.

For C6678 - Number of cores = 8
For C6670 - Number of cores = 6

The scripts uses /usr/bin/mcoreloader for loading and running images on the
slave cores.

For example to run notify user land application on C6678, the script invoked is
./notify_app_test_8_core.sh

To run notify kernel module sample, user has to run 2 samples

1. Telnet to board using target IP address. Start IPC by running
procmgr_load_<application>_<num_cores>_core.sh, where application can be
one of the several sample applications supported. num_cores=4 for C6670
and 8 for C6678.

For example for Notify application on C6678, execute

./procmgr_load_notifyapp_8_core.sh

Do not press enter.

2) Run kernel module sample by executing notify_module_test_8_core.sh

 
c64x platforms
==============

For c64x platforms, there are no loader to load and run BIOS/IPC sample
applications on the slave cores . So different scripts are used for running
sample applications.

syslinktest-dss.js is a dss script that is used for loading and running BIOS
sample applications on the slave cores. syslinktest-dss.js is run on the
windows host machine. syslink-app-c64x.sh is the script for running user land
sample applications. syslink-module-c64x.sh is the script for testing kernel
module samples. These scripts are run on the target along with the
syslinktest-dss.js.

Please read the documentation at the header of the above scripts for details
on how to run them.

