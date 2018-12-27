FROM centos:7
MAINTAINER Erik M Jacobs <erikmjacobs@gmail.com>
ENV hass_ver=0.84.6
VOLUME /opt/homeassistant

# centos7 doesn't have python36 
# epel doesn't package pip36
RUN groupadd -g 1005 hass \
    && useradd -u 10101 -g 1005 -G dialout hass
RUN yum -y install epel-release \
    && yum -y install python36 gcc python36-devel make glib2-devel gcc-c++ which \
    libstdc++-devel systemd-devel git libyaml autoconf mariadb-devel \
    && curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py \
    && /usr/bin/python36 /tmp/get-pip.py

# python zwave graph
COPY home-assistant-z-wave-graph /tmp/home-assistant-z-wave-graph
RUN ln -s /usr/bin/python3.6 /usr/bin/python3 && \
  mv /tmp/home-assistant-z-wave-graph/bin /home/hass && \
  chown -R hass:hass /home/hass

# Install hass component dependencies
COPY requirements_all.txt requirements_all.txt
RUN export LC_ALL="en_US.UTF-8" && pip3 install --no-cache-dir -r requirements_all.txt

# Install hass
RUN export LC_ALL="en_US.UTF-8" && pip3 install --no-cache-dir mysqlclient psycopg2 uvloop cchardet cython \
    homeassistant==$hass_ver networkx 

# cleanup annoying deps and reinstall git
RUN yum -y remove gcc cpp glibc-devel glibc-headers kernel-headers make \
  mpfr python36-devel dwz groff-base perl* python-rpm-macros python-srpm-macros \
  redhat-rpm-config zip glib2-devel pcre-devel gcc-c++ libstdc++-devel systemd-devel \
  m4 autoconf mariadb-devel keyutils-libs-devel krb5-devel libcom_err-devel libselinux-devel \
  libsepol-devel libverto-devel openssl-devel zlib-devel \
  && yum -y install git \
  && yum -y update \
  && yum clean all \
  && rm -rf /var/cache/yum

USER 10101
CMD hass -c /opt/homeassistant