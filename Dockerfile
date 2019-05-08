# BSD License
#
# Copyright (C) 2017-2018 Baidu, Inc. All Rights Reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   * Neither the name of Baidu, Inc., nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Copyright 2019 Supercomputing Systems AG

FROM ubuntu:18.04
MAINTAINER Yu Ding

ENV sdk_bin https://download.01.org/intel-sgx/linux-2.5/ubuntu18.04-server/sgx_linux_x64_sdk_2.5.100.49891.bin
ENV psw_deb https://download.01.org/intel-sgx/linux-2.5/ubuntu18.04-server/libsgx-enclave-common_2.5.101.50123-bionic1_amd64.deb
ENV psw_dev_deb https://download.01.org/intel-sgx/linux-2.5/ubuntu18.04-server/libsgx-enclave-common-dev_2.5.101.50123-bionic1_amd64.deb
ENV psw_dbgsym_deb https://download.01.org/intel-sgx/linux-2.5/ubuntu18.04-server/libsgx-enclave-common-dbgsym_2.5.101.50123-bionic1_amd64.ddeb
ENV substratee_node https://github.com/scs/substraTEE-node/archive/master.zip
ENV substratee_worker https://github.com/scs/substraTEE-worker/archive/master.zip
ENV rust_toolchain nightly
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM xterm

SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y build-essential ocaml ocamlbuild automake autoconf \
    libtool wget python libssl-dev libcurl4-openssl-dev protobuf-compiler \
    libprotobuf-dev sudo kmod vim curl git-core libprotobuf-c0-dev \
    libboost-thread-dev libboost-system-dev liblog4cpp5-dev libjsoncpp-dev \
    alien uuid-dev libxml2-dev cmake pkg-config expect systemd-sysv gdb unzip \
    clang libclang-dev rsync && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/*

RUN mkdir /root/sgx && \
    mkdir /etc/init && \
    wget -O /root/sgx/psw.deb ${psw_deb} && \
    wget -O /root/sgx/psw_dev.deb ${psw_dev_deb} && \
    wget -O /root/sgx/psw_dbgsym.deb ${psw_dbgsym_deb} && \
    wget -O /root/sgx/sdk.bin ${sdk_bin} && \
    cd /root/sgx && \
    dpkg -i /root/sgx/psw.deb && \
    dpkg -i /root/sgx/psw_dev.deb && \
    dpkg -i /root/sgx/psw_dbgsym.deb && \
    chmod +x /root/sgx/sdk.bin && \
    echo -e 'no\n/opt' | /root/sgx/sdk.bin && \
    echo 'source /opt/sgxsdk/environment' >> /root/.bashrc && \
    rm -rf /root/sgx/*

# installing rust-sgx-sdk
RUN wget 'https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init' -O /root/rustup-init && \
    chmod +x /root/rustup-init && \
    echo '1' | /root/rustup-init --default-toolchain ${rust_toolchain} && \
    echo 'source /root/.cargo/env' >> /root/.bashrc && \
    /root/.cargo/bin/rustup component add rust-src && \
    /root/.cargo/bin/cargo install xargo && \
    rm -rf /root/.cargo/registry && rm -rf /root/.cargo/git

### downloading and extracting the substraTEE components
RUN mkdir /substraTEE && \
    wget -O /substraTEE/substraTEE-node.zip ${substratee_node} && \
    wget -O /substraTEE/substraTEE-worker.zip ${substratee_worker} && \
    cd /substraTEE && \
    unzip substraTEE-node.zip && \
    unzip substraTEE-worker.zip && \
    rm substraTEE-*.zip

### building the substraTEE components
RUN source /opt/sgxsdk/environment && \
    source /root/.cargo/env && \
    cd /substraTEE/substraTEE-node-master && \
    ./scripts/init.sh && \
    ./scripts/build.sh && \
    cargo build --release && \
    cd /substraTEE/substraTEE-worker-master && \
    SGX_MODE=SW make

WORKDIR /substraTEE
