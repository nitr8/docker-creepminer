FROM ubuntu:16.04
MAINTAINER Wayne Humphrey <wayne@humphrey.za.net>
LABEL version="1.3"

# Set some env variables as we mostly work in non interactive mode
RUN echo "export VISIBLE=now" >> /etc/profile

# Update system and install Supervisord, OpenSSH server, and tools needed for creepMiner
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"
RUN apt-get update && apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confold" \
  apt-utils supervisor sudo \
  net-tools openssh-server \
  build-essential cmake git \
  python-pip python-setuptools python-dev \
  openssl libssl-dev


RUN cd /tmp/ \
  && pip install --upgrade pip \
  && pip2.7 install conan \
  && git clone -b development https://github.com/Creepsky/creepMiner \
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

# Expose port 8124 for creepMiner UI and 9001 for supervisord
EXPOSE 8124 9001

# Use baseimage-docker's init system.
CMD ["/sbin/init"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*