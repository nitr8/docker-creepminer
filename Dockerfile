FROM ubuntu:16.04
MAINTAINER Wayne Humphrey <wayne@humphrey.za.net>
LABEL version="1.2"

# Set some env variables as we mostly work in non interactive mode
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
ENV RELEASE development

# Update system and install Supervisord, OpenSSH server, and tools needed for creepMiner
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"
RUN apt-get update && apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confold" \
  apt-utils supervisor \
  openssh-server \
  build-essential \
  python-pip \
  python-setuptools \
  python-dev \
  libssl-dev \
  openssl \
  cmake \
  git \
  sudo

RUN cd /tmp/ \
  && pip install --upgrade pip \
  && pip install conan \
  && git clone -b ${RELEASE} https://github.com/Creepsky/creepMiner \
  && cd creepMiner \
  && conan install . -s compiler.libcxx=libstdc++11 --build=missing \
  && cmake CMakeLists.txt -DNO_GPU=ON \
  && make -j$(nproc) \
  && cp -r /tmp/creepMiner/resources/public /usr/local/sbin/ \
  && cp -r /tmp/creepMiner/bin/creepMiner /usr/local/sbin/

# Add init and supervisord config
ADD helper/init /sbin/init
ADD helper/supervisord.conf /etc/supervisor/supervisord.conf
ADD helper/mining.conf /usr/local/sbin/mining.conf
RUN chmod 755 /sbin/init

# Set root password to toor
RUN echo 'root:toor' | chpasswd

VOLUME ["/config"]

EXPOSE 8124 9001 22

# Use baseimage-docker's init system.
CMD ["/sbin/init"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*