## Install Docker Package

Docker binaries are incorporated into RHEL/CentOS 7 extras repositories. The installation process is pretty simple. Install Docker package by issuing the following command with root privileges:

```
# yum -y install docker
```

After Docker package has been installed, start the daemon, check its status and enable it system wide using the below commands:

```
# systemctl enable docker
# systemctl start docker
# systemctl status docker
```

## Download CentOS Image

Download the CentOS 7 prepackaged image through the link provided during the presentation

## Download VMware Workstation or VMware Player

You can download either VMware Workstation (requires license) or VMware Player (free).

VMware Workstation can be used without a license keys for 30 days if you just want to explore. You require VMware Workstation if you require to build your own VM from the ISO.

You can download [VMware Player](https://my.vmware.com/en/web/vmware/free#desktop_end_user_computing/vmware_workstation_player/12_0) to start the CentOS VM - if you downloaded it from the link given during the presentation.

### Set up subnet address for vmnet8

If using VMware Workstation, click `Edit` > `Virtual Network Editor ...`

Select `VMnet8` and click `Change Settings`.

Select VMnet8 again and change the Subnet IP to 192.168.142.0 and mask 255.255.255.0 so that you can communicate with Db2 and DSM from outside the VM since we are going to use this subnet address in the VM and also the IP addresses in the same subnet for containers.

However, vmware player does not provide this option. You have to use the command line way of setting the VMnet8 addresses.

Open a command line window in an elevated shell (`Windows` > `Run` > `cmd`) and press `ctrl-shift Enter` to open an elevated shell.

Switch to the directory where you have vmplayer.exe. It should also have `vnetlib.exe` which you need to set VMnet8 subnet and mask.

Run these commands:

```
echo before: %vmdir%
if exist "\Program Files (x86)\VMware\VMware Workstation" set vmdir="\Program Files (x86)\VMware\VMware Workstation"
if exist "\Program Files (x86)\VMware\Workstation" set vmdir="\Program Files (x86)\VMware\Workstation"
echo after: %vmdir%

echo Stopping VMware networking services...
start /wait vnetlib.exe -- stop dhcp
start /wait vnetlib.exe -- stop nat

echo Backing up VMware networking files...
cd \ProgramData\VMware
copy vmnetdhcp.conf vmnetdhcp.conf.pre
copy vmnetnat.conf vmnetnat.conf.pre

cd %vmdir%
echo Changing VMware settings...
start /wait vnetlib.exe -- set vnet vmnet8 mask 255.255.255.0
start /wait vnetlib.exe -- set vnet vmnet8 addr 192.168.142.0
start /wait vnetlib.exe -- add dhcp vmnet8
start /wait vnetlib.exe -- add nat vmnet8
start /wait vnetlib.exe -- update dhcp vmnet8
start /wait vnetlib.exe -- update nat vmnet8
start /wait vnetlib.exe -- update adapter vmnet8

echo Starting VMware networking services...
start /wait vnetlib.exe -- start dhcp
start /wait vnetlib.exe -- start nat

echo Done
```

After VMnet8 subnet is changed to  

Start `vmplayer.exe` and click to `Open a Virtual Machine`.

Locate `dsm.vmx` and open it.

Click `Play`.

Resize the VMware window as per your choice.

## Change VM memory

The allocated memory to VM is 6 GB. You can change this to suitable size as per your laptop available memory by editing the VM settings.

## How to use?

If there is a shell running, press `CTRL-C` to get the command prompt.

Double click `GNOME Terminal`.

Root password is `password` the logged in user is `db2psc` and the password is `password`.

To become root, type `su -` and type the password as `password`.

Change directory to /mnt/disk/git

```
# cd /mnt/disk/git
```

You should see db2 and dsm directories

```
[root@node01 git]# ls -l
total 8
drwxr-xr-x 4 root root 4096 May 20 23:49 db2
drwxr-xr-x 4 root root 4096 May 20 17:21 dsm
```

## Build db2 container

The contents of the db2 folder is cloned using:

```
# git clone https://github.com/vikramkhatri/db2.git
```

If you are building your own VM and after cloning the above db2 repository, you will need to get the db2 software as per the READMM.md file.

In the VM, everything is included and use this as a practice so that you learn how Db2 and DSM containers are built.

```
# cd db2
# ./builddocker.sh
```

You need internet connectivity so that the docker build command downloads official CentOS 7 image and then it will update the packages and install new packages as per Dockerfile. We save this image as custom image and then we use this custom image to work on rests of the Db2 build process.

The build process may take 10-30 minutes depending upon the internet speed. After build process is done, run `docker images`

```
[root@node01 db2]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
ibm/db2             v11.1.3.3           448ca89a46ce        14 seconds ago       2.05GB
centos              custom              bfe39ba88c31        About a minute ago   1.1GB
centos              7                   e934aafc2206        6 weeks ago          199MB
```

## Run db2 container

We will run `rundb2c.sh` to run the Db2 container.

```
[root@node01 db2]# cat rundb2c.sh
#!/bin/bash

echo =================================================
echo Run db2 container
echo =================================================

docker run -d -it \
 --privileged=true \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v /db2c:/db2mount \
 --name=db2c \
 --tmpfs /run/systemd/system \
 --cap-add SYS_ADMIN \
 --env-file=./bin/config/db2c.env \
 -p 50000-50001:50000-50001 \
 -p 50022:22 \
 -h db2c \
 ibm/db2:v11.1.3.3

```

Run the command `rundb2c.sh`

```
[root@node01 db2]# ./rundb2c.sh
=================================================
Run db2 container
=================================================
a37ffccf15cfb57ae04dd38ddb39f3bd78cc92448564dfe29bc4004771703a68
```

Put a tail of the log to see the progress

```
[root@node01 db2]# docker logs -f db2c
systemd 219 running in system mode. (+PAM +AUDIT +SELINUX +IMA -APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 -SECCOMP +BLKID +ELFUTILS +KMOD +IDN)
Detected virtualization docker.
Detected architecture x86-64.

Welcome to CentOS Linux 7 (Core)!

Set hostname to <db2c>.
Cannot add dependency job for unit systemd-tmpfiles-clean.timer, ignoring: Unit is masked.
[  OK  ] Reached target Local File Systems.
[  OK  ] Reached target Paths.
[  OK  ] Reached target Timers.
[  OK  ] Created slice Root Slice.
[  OK  ] Created slice System Slice.
[  OK  ] Reached target Slices.
[  OK  ] Listening on Journal Socket.
         Starting Create Static Device Nodes in /dev...
[  OK  ] Reached target Swap.
[  OK  ] Listening on Delayed Shutdown Socket.
         Starting Create Volatile Files and Directories...
         Starting Journal Service...

```

The build process inside the Db2 container starts to create the instance and create database.

The commands are in bin directory and those are run through the systemd daemon that we created.

```
[root@node01 bin]# tree
.
├── config
│   ├── db2c.env
│   ├── db2d.env
│   ├── db2set.txt
│   ├── dbcfg.txt
│   ├── dbmcfg.txt
│   └── setenvvars
├── image
│   └── db2.tar.gz
├── license
│   ├── db2de.lic
│   └── sam41.lic
└── setup
    ├── createDatabase
    ├── createDatabaseDDL
    ├── creategsk8
    ├── createInstance
    ├── createUsersAndDir
    ├── init
    ├── initsystemd
    └── startInstance

4 directories, 17 files
```

This is all done through bash scripting and you can add / modify to this as per your requirements.

If add something in the scripts, which needs to be shared with the Db2 community, please fork the github repo and put a pull request so that I can assimilate those changes.

Share the knowledge and this is how we learn from each other.

After the build process is over, you should see message `Ending work ...` at the end. Then, press CTRL-C to break the tail -f command from the docker container.

```
===================================================
Apply registry variables
===================================================
File /db2mount/config/db2set.txt not found.
===================================================
Apply DBM CFG
===================================================
File /db2mount/config/dbmcfg.txt not found.
===================================================
Stopping and Starting the instance
===================================================
05/21/2018 07:08:04     0   0   SQL1032N  No start database manager command was issued.
SQL1032N  No start database manager command was issued.  SQLSTATE=57019
05/21/2018 07:08:09     0   0   SQL1063N  DB2START processing was successful.
SQL1063N  DB2START processing was successful.
========================================================
Create Database : CREATE DATABASE PSDB ON /db2mount/db2data/dbpath DBPATH ON /db2mount/db2data/data USING CODESET UTF-8 TERRITORY US COLLATE USING SYSTEM PAGESIZE 32768
========================================================
CREATE DATABASE PSDB ON /db2mount/db2data/dbpath DBPATH ON /db2mount/db2data/data USING CODESET UTF-8 TERRITORY US COLLATE USING SYSTEM PAGESIZE 32768
DB20000I  The CREATE DATABASE command completed successfully.

========================================================
Apply DB CFG
========================================================
File /db2mount/config/dbcfg.txt not found.
===================================================
Starting the instance
===================================================
05/21/2018 07:09:13     0   0   SQL1026N  The database manager is already active.
SQL1026N  The database manager is already active.
Ending work ...
^C

```

## Test Db2 container

```
# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                                                         NAMES
a37ffccf15cf        ibm/db2:v11.1.3.3   "/usr/sbin/init"    7 minutes ago       Up 7 minutes        0.0.0.0:50000-50001->50000-50001/tcp, 0.0.0.0:50022->22/tcp   db2c
```

## Get root shell to the containers

Run `docker exec -it db2c bash` to get the root shell to the container.

```
[root@node01 db2]# docker exec -it db2c bash
[root@db2c ~]# ls -l
total 4
-rw------- 1 root root 3270 Apr  2 14:39 anaconda-ks.cfg
drwxr-xr-x 6 root root   61 May 21 07:03 bin
[root@db2c ~]# pwd
/root
```

## Login as db2psc

Login as `db2psc` and check database directory

```
[root@db2c ~]# su - db2psc
Last login: Mon May 21 07:09:13 EDT 2018
[db2psc@db2c ~]$ db2 list db directory

 System Database Directory

 Number of entries in the directory = 1

Database 1 entry:

 Database alias                       = PSDB
 Database name                        = PSDB
 Local database directory             = /db2mount/db2data/data
 Database release level               = 14.00
 Comment                              =
 Directory entry type                 = Indirect
 Catalog database partition number    = 0
 Alternate server hostname            =
 Alternate server port number         =
```

Note that the Local Database Directory is in `/db2mount`, which is mounted as `db2c` on the host.

Press `ctrl-d` twice to get out frm the Db2 container and run `ls -l /db2c`

```
# ls -l /db2c
total 0
drwxr-xr-x 2 db2psc db2psc  6 May 21 07:05 activelogs
drwxr-xr-x 2 db2psc db2psc  6 May 21 07:05 archivelogs
drwxr-xr-x 2 db2psc db2psc  6 May 21 07:05 backup
drwxr-xr-x 2 db2psc db2psc 28 May 21 07:08 config
drwxr-xr-x 4 db2psc db2psc 32 May 21 07:05 db2data
drwxr-xr-x 2 db2psc db2psc  6 May 21 07:05 db2dump
drwxr-xr-x 4 db2psc db2psc 35 May 21 07:05 home
drwxr-xr-x 2 db2psc db2psc 36 May 21 07:05 log
```

The directory `/db2c` on the host is persistent. Please remember that Docker containers are ephemeral and once a docker container is removed, its contents are gone.

## Build dsm container

The Data Server Manager container github repo is at : https://github.com/vikramkhatri/dsm

Note: If you are using your own VM, you can clone the repo

```
# git clone https://github.com/vikramkhatri/dsm
```

Then, you have to follow the README.md of the repo to download Data Server Manager software from IBM Developerworks.

If you are using downloaded VM, you do not have to clone and download the software as this is already done in the `/mnt/disk/git/dsm` folder.

Change directory to `dsm`

```
# cd ../dsm
```

Run `builddocker.sh`

```
[root@node01 dsm]# ./builddocker.sh
Sending build context to Docker daemon    527MB
Step 1/9 : FROM centos:7
 ---> e934aafc2206
Step 2/9 : ARG CONT_IMG_VER="latest"
 ---> Using cache
 ---> 47849d985c5b
Step 3/9 : MAINTAINER vikram@zinox.com
 ---> Using cache
 ---> a8053f6aa6c0
Step 4/9 : WORKDIR /opt
 ---> 96c7211f55e9
Removing intermediate container 80fc9ed24b77
Step 5/9 : ADD software/2.1.5-IM-Data-Server-Manager-linux-x86_64-IF201803061555.tgz /opt
 ---> e4d32006f2a0
Step 6/9 : ADD software/ibm-datasrvrmgr-enterprise-license-activation-kit-linux-x86_64.tgz /opt/ibm-datasrvrmgr/
 ---> c67fd5eb4e9a
Step 7/9 : ADD start_dsm.sh /opt/
 ---> 483c5a92009a
Step 8/9 : RUN yum -y update &&  yum -y install curl tar wget which && yum clean all && chmod +x /opt/start_dsm.sh
 ---> Running in c5ffec57e8c9

```

Wait for the build process to complete . It may take 5-10 minutes depeneding upon your internet speed.

## Run dsm container

Run `rundsm.sh` to start the dsm container.

```
[root@node01 dsm]# ./rundsm.sh
48da741cb84b916d8598ad26fee5af585a1584384989123e9411a969f5b08a9e

```

## Open log on dsm

```
[root@node01 dsm]# docker logs -f dsm

STATUS_PORT=11082
HOSTNAME=dsmhost
WEB_PWD=wtiv2_c4ab127272f676cbe3a28b5afdbf8625
TERM=xterm
HTTP_PORT=11080
REP_USER=dsm
REP_PWD=password
REP_PORT=50000
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/opt
REP_HOST=localhost
SHLVL=1
HOME=/root
WEB_USER=admin
REP_DBNAME=DSMDB
HTTPS_PORT=11081
_=/usr/bin/env

         product.license.accepted=y
         port=11080
         https.port=11081
         status.port=11082
         admin.user=admin
         admin.password=wtiv2_c4ab127272f676cbe3a28b5afdbf8625
         repositoryDB.dataServerType=DB2LUW
         repositoryDB.host=localhost
         repositoryDB.port=50000
         repositoryDB.databaseName=DSMDB
         repositoryDB.user=dsm
         repositoryDB.password=wtiv2_c4ab127272f676cbe3a28b5afdbf8625

Install Data Server Manager in the container

Moving new product files in place... [Completed]

```

When you start the container for the first time, it will install dsm and this is all done through the scripting `start_dsm.sh` which runs inside the container when it is started.

```
[root@node01 dsm]# cat start_dsm.sh
#!/bin/bash

set +x

DSMHOME=/opt/ibm-datasrvrmgr
FLAG="/var/log/firstboot.log"

if  [ ! -f $FLAG ] ; then
   WEB_PWD=$($DSMHOME/dsutil/bin/crypt.sh ${WEB_PWD:=password})

   echo ####################################################
   env
   echo ####################################################

   if [[ -z $REP_HOST || -z $REP_PORT || -z $REP_DBNAME || -z $REP_USER || -z $REP_PWD ]] ; then
     tee $DSMHOME/setup.conf <<-EOF
        product.license.accepted=y
        port=${HTTP_PORT:=11080}
        https.port=${HTTPS_PORT:=11081}
        status.port=${STATUS_PORT:=11082}
        admin.user=${WEB_USER:=admin}
        admin.password=${WEB_PWD}
EOF
   else
      REP_PWD=$($DSMHOME/dsutil/bin/crypt.sh ${REP_PWD:=password})
      tee $DSMHOME/setup.conf <<-EOF
         product.license.accepted=y
         port=${HTTP_PORT:=11080}
         https.port=${HTTPS_PORT:=11081}
         status.port=${STATUS_PORT:=11082}
         admin.user=${WEB_USER:=admin}
         admin.password=${WEB_PWD}
         repositoryDB.dataServerType=DB2LUW
         repositoryDB.host=${REP_HOST:=localhost}
         repositoryDB.port=${REP_PORT:=50000}
         repositoryDB.databaseName=${REP_DBNAME:=DSMDB}
         repositoryDB.user=${REP_USER:=dsm}
         repositoryDB.password=${REP_PWD}
EOF
   fi

   sed -i "s/^[ \t]*//" $DSMHOME/setup.conf

   echo ####################################################
   echo Install Data Server Manager in the container
   echo ####################################################
   cd $DSMHOME
   ./setup.sh -silent
   echo ####################################################
   echo Add cookie.secureOnly=false for http access
   echo ####################################################
   if ! grep -qs cookie.secureOnly $DSMHOME/Config/dswebserver.properties ; then
      echo "cookie.secureOnly=false" >> $DSMHOME/Config/dswebserver.properties
   fi
   touch $FLAG
else
   echo ####################################################
   echo Starting Data Server Manager
   echo ####################################################
   cd $DSMHOME/bin
   ./start.sh
fi

echo "--done--"

## Run forever so that container does not stop
tail -f /dev/null
```

After you see the message `--done--`, press `ctrl-c` to break the tail.

```
The server is started.

******************************************************************************

Summary
	* Web console HTTP URL
 		http://dsmhost:11080/console   (login: admin)

	* Web console HTTPS URL
 		https://dsmhost:11081/console   (login: admin)


Add cookie.secureOnly=false for http access

--done--
^C
```

## Test dsm container

```
[root@node01 dsm]# docker ps
CONTAINER ID        IMAGE               COMMAND               CREATED             STATUS              PORTS                                                         NAMES
48da741cb84b        ibm/dsm:v2.1.5      "/opt/start_dsm.sh"   4 minutes ago       Up 4 minutes        0.0.0.0:11080-11081->11080-11081/tcp                          dsm
a37ffccf15cf        ibm/db2:v11.1.3.3   "/usr/sbin/init"      27 minutes ago      Up 27 minutes       0.0.0.0:50000-50001->50000-50001/tcp, 0.0.0.0:50022->22/tcp   db2c

```

You should see dsm container up and running.

## Login to dsm container

```
[root@node01 dsm]# docker exec -it dsm bash

```

## Check dsm status

```
[root@dsmhost opt]# ibm-datasrvrmgr/bin/status.sh
Server dsweb is running with process ID 507.

```

Press `ctrl-d` to logout from the dsm container.

Now, you can open the web console from your host or Windows machine.

Open URL: http://192.168.142.101:11080/

The user id and password is admin/password.
