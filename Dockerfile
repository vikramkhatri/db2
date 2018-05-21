FROM centos:7
ARG CONT_IMG_VER="latest"
MAINTAINER vikram@zinox.com
USER root
RUN rm -fr /var/cache/yum && yum clean all && yum -y update && \
    yum -y install dos2unix adcli authconfig bc bind bind-chroot blas-devel \
           cairo compat-libstdc++* compat-libstdc++-33 crontabs cups curl dapl dapl-devel dmidecode ed ethtool expect file  \
           gcc-c++ gcc-gfortran gdbm-devel install tar ksh lapack-devel libX11-devel libXmu \
           libXt libaio libaio.i686 libcom_err.i686 libcurl-devel libicu libicu-devel libdb-devel libibverbs-devel \
           libjpeg-devel libpcap-devel libpng-devel libstdc++ libstdc++-devel libstdc++.i686 libtool-ltdl libtool-ltdl-devel \
           libxml2-devel lsof mdadm nc ncurses-libs.i686 ncurses-devel net-tools nmap nscd nss-pam-ldapd numactl numactl.i686 \
           pam pam.i686 pango pangocairo pcre-devel perl-Env psmisc \
           python-setuptools readline-devel realmd rsyslog sendmail sendmail-cf sendmail-devel sg3_utils \
           strace sudo systemtap tcl-devel texinfo-tex texlive-dvips texlive-latex tk-devel unixODBC unixODBC-devel \
           selinux-policy-targeted unzip vim wget which xdg-utils xz-devel zlib zlib-devel \
           openssh openssh-server && \
    yum -y groupinstall "Development tools"
