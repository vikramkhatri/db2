# Db2 Docker Container

## Download Db2 from IBM Fix Central

Go to [Fix Central](https://www-945.ibm.com/support/fixcentral/)

Go To **Select Product** Tab. Choose **Information Management**. **DB2 for Linux, UNIX and Windows**, **Installed version 11.1.*** (or latest) and **Linux 64-bit,x86_64** platform. Go and download the latest fix pack.

## Prune components - Build db2.tar.gz
Untar the file in some folder. Run the following command.

Replace the name of the tar file with the one you downloaded.

```
# tar xvfz v11.1.3fp3_linuxx64_server_t.tar.gz
# cd server_t/db2/linuxamd64/utilities/db2iprune/
```

You can edit db2server_t.prn to uncomment the components that you not want.

For Db2 with minumum install, I created the following db2prune.txt file

```
# sed -e '/^\*.*/d' -e '/^$/d' db2server_t.prn
PRUNE_PROD               = CONNECT_SERVER                      ** DB2 Connect Server
PRUNE_PROD               = RUNTIME_CLIENT                      ** IBM Data Server Runtime Client
PRUNE_COMP               = ACS                                 ** Integrated Flash Copy Support
PRUNE_COMP               = DB2_DATA_SOURCE_SUPPORT             ** DB2 data source support
PRUNE_COMP               = DB2_UPDATE_SERVICE                  ** DB2 Update Service
PRUNE_COMP               = FED_DATA_SOURCE_SUPPORT             ** Federated Data Access Support
PRUNE_COMP               = FIRST_STEPS                         ** First Steps
PRUNE_COMP               = GPFS                                ** General Parallel File System (GPFS)
PRUNE_COMP               = GUARDIUM_INST_MNGR_CLIENT           ** Guardium Installation Manager Client
PRUNE_COMP               = IINR_APPLICATIONS_WRAPPER           ** Application data sources
PRUNE_COMP               = IINR_STRUCTURED_FILES_WRAPPER       ** Structured file data sources
PRUNE_COMP               = INFORMIX_DATA_SOURCE_SUPPORT        ** Informix data source support
PRUNE_COMP               = INSTANCE_SETUP_SUPPORT              ** DB2 Instance Setup wizard
PRUNE_COMP               = LDAP_EXPLOITATION                   ** DB2 LDAP support
PRUNE_COMP               = ORACLE_DATA_SOURCE_SUPPORT          ** Oracle data source support
PRUNE_COMP               = PURESCALE                           ** IBM DB2 pureScale Feature
PRUNE_COMP               = SPATIAL_EXTENDER_CLIENT_SUPPORT     ** Spatial Extender client
PRUNE_COMP               = SPATIAL_EXTENDER_SERVER_SUPPORT     ** Spatial Extender server support
PRUNE_COMP               = SQL_SERVER_DATA_SOURCE_SUPPORT      ** SQL Server data source support
PRUNE_COMP               = SYBASE_DATA_SOURCE_SUPPORT          ** Sybase data source support
PRUNE_COMP               = TERADATA_DATA_SOURCE_SUPPORT        ** Teradata data source support
PRUNE_COMP               = TEXT_SEARCH                         ** DB2 Text Search
PRUNE_COMP               = TSAMP                               ** Tivoli SA MP
PRUNE_TSAMP              = YES
PRUNE_LANG               = ALL             ** Remove all except English
```

Run the db2prune command to build new directory containing components that we do not need.

```
# ./db2iprune -r ./db2prune.txt -o /tmp/server_t
```

The minimum install will be created on /tmp/server_t directory. Create the tarball.

```
# cd /tmp
# tar cvfz db2.tar.gz server_t/
```

This tarball we can use it for regular db2 install without having components that we do not need.

## Create Docker Container

### Move db2.tar.gz directory

Let's create first a directory db2docker and move server_t from /tmp here

```
# mkdir db2docker
# cd db2docker
# mkdir -p bin/image bin/setup bin/scripts bin/backup
# mv /tmp/db2.tar.gz bin/image
```

### Create Dockerfile

The Dockerfile (Credit: Aruna for the big help) is created and please take a look at it.

Take away points are:

- We are using --privileged option when creating the Container through docker run command. This is not ideal and in future, my personal choice is to run docker container without privilege. This is not so important right now and we will tackle this later in favor of more pressing needs.

- We will use systemd `/usr/sbin/init` as the entrypoint. We could have used our own script as an entry point. We created a systemd unit to run that script based upon systemd infrastructure. This is also not my favorite but we will tackle this later.

- We run the script `bin/setup/initsystemd` to create a systemd unit **db2local** so that this service will run on startup and `/usr/sbin/init` will launch this service. Thanks Aruna on this.

```
#!/bin/bash -e

# Preparation for systemd init
cd /lib/systemd/system/sysinit.target.wants/; ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1;
rm -f /lib/systemd/system/multi-user.target.wants/*;
rm -f /etc/systemd/system/*.wants/*;
rm -f /lib/systemd/system/local-fs.target.wants/*;
rm -f /lib/systemd/system/sockets.target.wants/*udev*;
rm -f /lib/systemd/system/sockets.target.wants/*initctl*;
rm -f /lib/systemd/system/basic.target.wants/*;
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install SystemD unit files for dashDB local service and Enable
cat <<'EOF' > /etc/systemd/system/db2local.service
[Unit]
Description=The entrypoint script for initializing the service
Wants=network-online.target
After=multi-user.target
After=network-online.target
After=npingSrv.service

[Service]
Type=idle
# PassEnvironment directive is only supported from SystemD v228
# PassEnvironment=NODESFILE
EnvironmentFile=/root/bin/config/db2c.env
ExecStart=/root/bin/setup/init
ExecStartPost=/bin/sh -c "rm -f /var/run/nologin"
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF

chmod 664 /etc/systemd/system/db2local.service
systemctl enable db2local.service

# Configure following setting in journald:
# * persistent logging
# * forward to Console and enable console TTY device
# * set the max journal size to 100MB
mkdir -p /var/log/journal
sed -i -e 's/\(.*\)Storage=\(.*\)/Storage=persistent/' /etc/systemd/journald.conf
sed -i -e 's/\(.*\)SystemMaxUse=\(.*\)/SystemMaxUse=1G/' /etc/systemd/journald.conf
sed -i -e 's/\(.*\)SplitMode=\(.*\)/SplitMode=none/' /etc/systemd/journald.conf

# Set systemd /tmp cleanup to two days
sed -i 's/10d/2d/g' /usr/lib/tmpfiles.d/tmp.conf
# Disable tmpfile cleanup service for now. We'll re-enable after deployment.
systemctl mask systemd-tmpfiles-clean.timer

# Modify sendmail.service unit if /var/run is not sym-linked to /run
[[ -L /var/run ]] || sed -i 's|^PIDFile\(.*\)|PIDFile=/var/run/sendmail.pid|' /usr/lib/systemd/system/sendmail.service

```  

- I copy prune version of db2 tar ball named as `db2.tar.gz` folder in `/root/bin/image`. Now, this is debatable that should we run `db2_install` while building the container or just copy the tar ball in the container. I am a big proponent of the reduced size of shipped container. If the tar ball size of less than by few hundreds MB compared to the installed software, I then would like to copy the tarball and on the first invocation of the container, install the software, create the instance and create the database.

- I am using the `--env-file` option to pass parameters. The sample env file is kept in` /root/bin/config/db2c.env`. The sample file is:

```
TIMEZONE=America/New_York
INST_UID=1001
FENC_UID=1002
INST_GID=1001
FENC_GID=1002
INST_USER=db2psc
FENC_USER=db2fenc
INST_PWD=password
FENC_PWD=password
INST_GROUP=db2iadm
FENC_GROUP=db2fenc
INST_PORT=50000
SSL_PORT=50001
DB_NAME=PSDB
ENCRYPT_DB=NO
DB_CODESET=UTF-8
DB_TERRITORY=US
DB_COLLATION_SEQUENCE=SYSTEM
DB_PAGESIZE=32768
DB2SET_FILE=$DB2_MOUNT/config/db2set.txt
DBMCFG_FILE=$DB2_MOUNT/config/dbmcfg.txt
DBCFG_FILE=$DB2_MOUNT/config/dbcfg.txt
```

-  **Mount points**. This is my best practice and I have helped hundreds of customers to implement this. The best practice is : Create a local directory and this can be called anything. I am saying this /db2mount. Underneath, the directory structure is:

```
[root@db2chost setup]# ls -l /db2mount
total 0
drwxr-xr-x 2 db2psc db2iadm  6 Mar  5 23:42 activelogs
drwxr-xr-x 2 db2psc db2iadm  6 Mar  5 23:42 archivelogs
drwxr-xr-x 2 db2psc db2iadm  6 Mar  5 23:42 backup
drwxr-xr-x 2 db2psc db2iadm 28 Mar  5 23:45 config
drwxr-xr-x 4 db2psc db2iadm 32 Mar  5 23:42 db2data
drwxr-xr-x 2 db2psc db2iadm  6 Mar  5 23:42 db2dump
drwxr-xr-x 4 db2psc db2iadm 35 Mar  5 23:42 home
drwxr-xr-x 2 db2psc db2iadm 36 Mar  5 23:43 log
```

The active logs will be in **activelogs**, archive logs will be in **archivelogs**, db2 backup will be **backup**, db2 database will be in **db2data**, db2 diag logs will be in **db2dump**, the db2 instance home directory will be **home** and other logs files will be in **log**.

Now, at the host level, if this is a single instance db2, everything can be in a directory will be mounted through -v to container `/db2mount` directory. This directory can not be on SAN, or NFS or any other shared file system. Please remember - you can nest GPFS volumes but if you use a local directory, you can keep on adding as many GPFS volumes as necessary.

Then, inside this directory, all other directory can be either GPFS mounts, GlusterFS volumnes, VMware vSAN volumes, iSCSI volumes, or NFS volumes.

This strategy gives the flexibility and choice at the host level to choose best options. At the host level, we just need to mount these directories optionally.

I have helped 100s of customers to build this best practice for SAN management.

So when I run my Db2 container, the only mount point that I need to use is the local directory to the container.

I am not a big fan for the mounting several directories inside the container. This limits us the choices. What if customer wants to expand this. Through local directory, they can keep on adding mount points. This is a limitation in Sailfish, where I had to add a volume to the list and reinitialize the database. This was a big no from customer but there was no option.

- The init for the db2 system is in **/root/bin/setup/init**. Please see the source and it will first check - if container is started for the first time, then:
  * Run **createUsersAndDir** and it will create users as per **db2c.env**, create all necessary directories under `/db2mount` if they are not there already.
  * Run **createInstance** and it will unzip `db.tar.gz` in /tmp, run `db2_install` to install the software on /opt/ibm/db2 and then run **db2icrt** command to create the instance.
  * Run **createDatabaseDDL** command to build Db2 database creation command. I give option to specify parameters through db2c.env file or allow customer to choose their own `CREATE DATABASE` command. Please remember that customers know Db2 better than us. We can not impose artificial restrictions. If customer defines their own `CREATE DATABASE`, they can use environment variable `CREATE_DB_DDL` and put that in `db2c.env` file. The script will use this variable and create database as per customer choice. We still need them to pass the name of the database name through `DB_NAME` parameter.
  * Run **createDatabase** command to create the database. This command will take input from customer defined `DBM CFG`, `DB CFG` and `db2set` variables from files kept in `/db2mount/config` directory. The syntax of these files are simple. The `dbmcfg.txt` will have entry extacly as a customer will type when using` UPDATE DBM CFG` after using statement. Same will be the case for `dbcfg.txt`  and `db2set.txt`. I am not using any brain cells to parse the output and let customers choose what they want to use. db2set assignment can be tricky and writing a python program to parse and build db2set command is not worth the trouble. Just trust what customer is providing. The worst - it will fail and that is customer problem.

- If container is already initialized, it will just see if software is installed, instance and database is created and then it will exit.

## Run Docker container

We are going to use 2 methods to run the docker containers.

### Use Host network

This is simple and straightforward method where containers share the host network. It means that if I am running multiple db2 containers, each must have a different port number assigned to the db2 instance (Same case when you create multiple Db2 instances on the same host).

If we run SSH inside the db2 container, it can use same port 22 inside the container but that port must be mapped to a port on the host.

Example of running Db2 container with host network.

```
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

Note that SSH port 22 inside the container is mapped to port 50022 on the host and db2 instance port 50000 is mapped to port 50000 on the host.

If SSH connection needs to be made from outside to the db2 container, you would running

```
$ ssh -p 50022 -l db2psc <hostIPAddress>
```

### Use Seperate IP address on the same host subnet

We can use separate IP address on the same subnet and assign that to the container.

For this, we need to create a docker network [Reference is here](http://blog.oddbit.com/2018/03/12/using-docker-macvlan-networks/)

```
#!/bin/bash

echo =================================================
echo Create macvlan network
echo =================================================

docker network create -d macvlan -o parent=eth0 \
  --subnet 192.168.142.0/24 \
  --gateway 192.168.142.2 \
  --ip-range 192.168.142.192/27 \
  --aux-address 'host=192.168.142.223' \
  mynet

ip link add mynet-shim link eth0 type macvlan  mode bridge
ip addr add 192.168.142.223/32 dev mynet-shim
ip link set mynet-shim up
ip route add 192.168.142.192/27 dev mynet-shim
```

Explanation: macvlan Docker driver is used for create a docker network.

In above example, the VM is running with a subnet of 192.168.142.0 with gateway assigned to 192.168.142.2 (VMware vnet8 network)

We are defining a IP Address range 192.168.142.192/27, which is a range of 32 IP addresses from 192.168.142.192 to 102.168.142.223.

As per the [reference quoted](http://blog.oddbit.com/2018/03/12/using-docker-macvlan-networks/):-

> With a container attached to a macvlan network, you will find that while it can contact other systems on your local network without a problem, the container will not be able to connect to your host (and your host will not be able to connect to your container). This is a limitation of macvlan interfaces: without special support from a network switch, your host is unable to send packets to its own macvlan interfaces.

> Fortunately, there is a workaround for this problem: you can create another macvlan interface on your host, and use that to communicate with containers on the macvlan network.

In the Docker network command, we reserve an address from our network range for use by the host interface by using the --aux-address option set to 192.168.142.223.  

In order to route packets from host to the container, the following steps are followed:

```
ip link add mynet-shim link eth0 type macvlan  mode bridge
ip addr add 192.168.142.223/32 dev mynet-shim
ip link set mynet-shim up
ip route add 192.168.142.192/27 dev mynet-shim
```
The modified command to start the container.

```
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
 --net mynet \
 --ip 192.168.142.193 \
 -h db2c \
 ibm/db2:v11.1.3.3
```

Note that we are using --net set to mynet and IP address for the container is set to 192.168.142.193

Now this container is like a VM with its own IP address and we do not have to worry about port mapping for SSH and Db2 running inside containers.

This gives a great flexibility to run multiple Db2 containers on same host (or different hosts) but using its own IP addresses.

Additional Commands:

After container is started:-

```
# docker ps --> Shows running containers
# docker ps -a --> Shows all containers including stopped ones
# docker network ls --> List docker networks
# docker stop db2c --> Stops the container
# docker rm db2c --> Removes the container
# docker images --> Lists all docker images
# docker rmi <imageid> --> Removed the docker image from /var/lib/docker folder
```

## Future Works:

- This will become our basis for creating of pureScale container and we will need to do the following.
  *  Wait for all containers to get started
  *  Add password less ssh when all containers are started.
  *  Run db2_icrt to create instance and add a CF
  *  Run db2iupdt to add member, CFs etc.
  *  Create database
