FROM ubuntu:18.04 as builder

RUN apt-get update && \
    apt-get install -y build-essential \
                       cmake \
                       curl \
                       git \
                       libsodium-dev \
                       libsodium23

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
    cmake -DCMAKE_INSTALL_PREFIX=/opt/minisign .. && \
    make && \
    make install && \
    cd /

ARG dnscrypt_version=2.0.25
ARG dnscrypt_pubkey=RWTk1xXqcTODeYttYMCMLo0YJHaFEHn7a3akqHlb/7QvIQXHVPxKbjB5

RUN curl -Lso /tmp/dnscrypt-proxy.tar.gz \
         https://github.com/jedisct1/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_x86_64-${dnscrypt_version}.tar.gz && \
    curl -Lso /tmp/dnscrypt-proxy.tar.gz.minisig \
         https://github.com/jedisct1/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_x86_64-${dnscrypt_version}.tar.gz.minisig && \
    cd /tmp && \
    /opt/minisign/bin/minisign -Vm dnscrypt-proxy.tar.gz -P $dnscrypt_pubkey && \
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

FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y ca-certificates \
                       dnsutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists

COPY --from=builder /usr/local/bin /usr/local/bin
COPY etc /etc

RUN mkdir /etc/dnscrypt-proxy && \
    chown root:root /etc/dnscrypt-proxy && \
    chmod 755 /etc/dnscrypt-proxy && \
    touch /etc/dnscrypt-proxy/blacklist.txt \
          /etc/dnscrypt-proxy/ip-blacklist.txt \
          /etc/dnscrypt-proxy/whitelist.txt
VOLUME /etc/dnscrypt-proxy

RUN mkdir /var/log/dnscrypt-proxy && \
    chown nobody /var/log/dnscrypt-proxy
VOLUME /var/log/dnscrypt-proxy

CMD ["/usr/local/bin/containerpilot", "-config", "/etc/containerpilot.json5" ]
