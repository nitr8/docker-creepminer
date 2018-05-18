FROM ubuntu:16.04
MAINTAINER Wayne Humphrey <wayne@humphrey.za.net>
LABEL version="1.4"

# Set some env variables as we mostly work in non interactive mode
RUN echo "export VISIBLE=now" >> /etc/profile

# Update system and install Supervisord, OpenSSH server, and tools needed for creepMiner
RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"
RUN apt-get update && apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confold" \
  apt-utils supervisor sudo \
  net-tools openssh-server \
  build-essential cmake git \
  python-pip python-setuptools python-dev \
  openssl libssl-dev \
  xz-utils curl ca-certificates gnupg2 dirmngr

RUN cd /tmp/ \
  && pip install --upgrade pip \
  && pip2.7 install conan \
  && git clone -b development https://github.com/Creepsky/creepMiner \
  && cd creepMiner \
  && conan install . -s compiler.libcxx=libstdc++11 --build=missing \
  && cmake CMakeLists.txt -DNO_GPU=ON \
  && make -j$(nproc) \
  && cp -r /tmp/creepMiner/resources/public /usr/local/sbin/ \
  && cp -r /tmp/creepMiner/resources/frontail.json /etc/ \
  && cp -r /tmp/creepMiner/bin/creepMiner /usr/local/sbin/


# webproc release settings
RUN curl -sL https://github.com/jpillora/webproc/releases/download/0.1.9/webproc_linux_amd64.gz | gzip -d - > /usr/bin/webproc \
    && chmod +x /usr/bin/webproc

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 8.11.2

# Build node.js used for frontail
RUN buildDeps='xz-utils curl ca-certificates gnupg2 dirmngr' \
    && set -ex \
      && for key in \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      56730D5401028683275BD23C23EFEFE93C4CFFFE \
      77984A986EBC2AA786BC0F66B01FBB92821C587A \
      ; do \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
      done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && apt-get purge -y --auto-remove $buildDeps \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN npm i frontail -g

# Add init and supervisord config
ADD helper/init /sbin/init
ADD helper/supervisord.conf /etc/supervisor/supervisord.conf
ADD helper/mining.conf /usr/local/sbin/mining.conf
RUN chmod 755 /sbin/init

# Set root password to toor
RUN echo 'root:toor' | chpasswd

# Expose port 8124 for creepMiner UI, 9001 for supervisord or webproc and 9002 for frontail
EXPOSE 8124 9001 9002

# Use baseimage-docker's init system.
CMD ["/sbin/init"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*