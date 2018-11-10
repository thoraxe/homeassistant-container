FROM centos:7
MAINTAINER Erik M Jacobs <erikmjacobs@gmail.com>
ENV hass_ver=0.81.2
VOLUME /config

# centos7 doesn't have python36 
# epel doesn't package pip36
RUN groupadd -g 1005 hass \
    && useradd -u 1001 -g 1005 -G dialout hass
RUN yum -y install epel-release \
    && yum -y install python36 gcc python36-devel make glib2-devel gcc-c++ which \
    libstdc++-devel systemd-devel git libyaml autoconf mariadb-devel \
    && curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py \
    && /usr/bin/python36 /tmp/get-pip.py

# weird python stuff for depsolving and building openzwave
RUN python36 -m pip install cython wheel six \
    && python36 -m pip install 'PyDispatcher>=2.0.5' 
#    && python36 -m pip install python-openzwave==0.4.10

# Install hass component dependencies
COPY requirements_all.txt requirements_all.txt
# Uninstall enum34 because some dependencies install it but breaks Python 3.4+.
# See PR #8103 for more info.
RUN export LC_ALL="en_US.UTF-8" && pip3 install --no-cache-dir -r requirements_all.txt \
    && pip3 install --no-cache-dir mysqlclient psycopg2 uvloop cchardet cython \
    homeassistant==$hass_ver

# https://www.reddit.com/r/homeautomation/comments/8x65qo/howto_homeseer_hswd200_showing_correctly/
COPY open-zwave/config /usr/local/lib/python3.6/site-packages/python_openzwave/ozw_config/

# cleanup annoying deps and reinstall git
RUN yum -y remove gcc cpp glibc-devel glibc-headers kernel-headers make \
  mpfr python36-devel dwz groff-base perl* python-rpm-macros python-srpm-macros \
  redhat-rpm-config zip glib2-devel pcre-devel gcc-c++ libstdc++-devel systemd-devel \
  m4 autoconf mariadb-devel keyutils-libs-devel krb5-devel libcom_err-devel libselinux-devel \
  libsepol-devel libverto-devel openssl-devel zlib-devel \
  && yum -y install git && yum -y update

USER 1001:1005
CMD hass