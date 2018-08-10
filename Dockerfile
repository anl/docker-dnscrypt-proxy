# FROM ubuntu:18.04 as builder
FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y build-essential \
                       cmake \
                       curl \
                       libsodium-dev \
                       libsodium23 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists

ARG minisign_version=0.8
ARG minisign_checksum=c8bf3765193a72193219141a726fb617e40c957b

RUN curl -Lso /tmp/minisign.tar.gz \
         https://github.com/jedisct1/minisign/archive/${minisign_version}.tar.gz && \
    cd /tmp && \
    echo "$minisign_checksum  /tmp/minisign.tar.gz" | sha1sum -c && \
    tar -xzf minisign.tar.gz && \
    cd minisign-${minisign_version} && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd /

ARG dnscrypt_version=2.0.16
ARG dnscrypt_pubkey=RWTk1xXqcTODeYttYMCMLo0YJHaFEHn7a3akqHlb/7QvIQXHVPxKbjB5

RUN curl -Lso /tmp/dnscrypt-proxy.tar.gz \
         https://github.com/jedisct1/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_x86_64-${dnscrypt_version}.tar.gz && \
    curl -Lso /tmp/dnscrypt-proxy.tar.gz.minisig \
         https://github.com/jedisct1/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_x86_64-${dnscrypt_version}.tar.gz.minisig && \
    cd /tmp && \
    minisign -Vm dnscrypt-proxy.tar.gz -P $dnscrypt_pubkey && \
    tar -xzf dnscrypt-proxy.tar.gz && \
    mv /tmp/linux-x86_64/dnscrypt-proxy /usr/local/bin

ARG confd_version=0.16.0
ARG confd_checksum=3d0a3ca940e5305af1a8294fdf5e370ebc0ac87c

RUN curl -Lso /usr/local/bin/confd \
         https://github.com/kelseyhightower/confd/releases/download/v${confd_version}/confd-${confd_version}-linux-amd64 && \
    echo "$confd_checksum  /usr/local/bin/confd" | sha1sum -c && \
    chmod 555 /usr/local/bin/confd

ARG CONTAINERPILOT_VERSION=3.8.0
ARG CONTAINERPILOT_CHECKSUM=84642c13683ddae6ccb63386e6160e8cb2439c26

RUN curl -Lso /tmp/containerpilot.tar.gz \
      https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VERSION}/containerpilot-${CONTAINERPILOT_VERSION}.tar.gz && \
    echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c && \
    tar -xzf /tmp/containerpilot.tar.gz -C /usr/local/bin

# FROM ubuntu:1804

RUN mkdir /etc/confd
COPY templates /etc/confd/templates
COPY confd /etc/confd/conf.d
COPY containerpilot.json5 /etc/containerpilot.json5

ENV DNSCRYPTPROXY_LISTENADDRESSES="['0.0.0.0:53']"

CMD ["/usr/local/bin/containerpilot", "-config", "/etc/containerpilot.json5" ]
