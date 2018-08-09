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

RUN curl -Lso /tmp/dnscrypt.tar.gz \
         https://github.com/jedisct1/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_x86_64-${dnscrypt_version}.tar.gz && \
    curl -Lso /tmp/dnscrypt.tar.gz.minisig \
         https://github.com/jedisct1/dnscrypt-proxy/releases/download/${dnscrypt_version}/dnscrypt-proxy-linux_x86_64-${dnscrypt_version}.tar.gz.minisig && \
    cd /tmp && \
    minisign -Vm dnscrypt.tar.gz -P $dnscrypt_pubkey && \
    tar -xzf dnscrypt.tar.gz

# FROM ubuntu:1804
