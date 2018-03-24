FROM ubuntu:16.04
MAINTAINER Wayne Humphrey <wayne@humphrey.za.net>
LABEL version="1.1"

# Set some env variables as we mostly work in non interactive mode
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile 

# Update system and install Supervisord, OpenSSH server, POCO and tools needed for creepMiner
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
  sudo \
  wget \
  apt-utils \
  screen


RUN mkdir -p /opt \
  && pip install --upgrade pip \
  && pip install conan \
  && cd /opt \
  && git clone -b development https://github.com/Creepsky/creepMiner \
  && cd creepMiner \
  && conan install . -s compiler.libcxx=libstdc++11 --build=missing \
  && cmake CMakeLists.txt -DNO_GPU=ON \
  && make -j$(nproc)

# Add image init and supervisord config
ADD helper/init /sbin/init
ADD helper/supervisord.conf /etc/supervisor/supervisord.conf
RUN chmod 755 /sbin/init
ADD helper/mining.conf /opt/creepMiner/bin/mining.conf

# Set root password to toor
RUN echo 'root:toor' | chpasswd

# Enable passwordless sudo for users under the "sudo" group
#RUN sed 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' -i /etc/sudoers

EXPOSE 22 8124

# Use baseimage-docker's init system.
CMD ["/sbin/init"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*