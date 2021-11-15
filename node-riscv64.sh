#!/bin/bash

# Add riscv64 toolchain into PATH

wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2021.09.21/riscv64-glibc-ubuntu-20.04-nightly-2021.09.21-nightly.tar.gz && \
     tar xzvf riscv64-glibc-ubuntu-20.04-nightly-2021.09.21-nightly.tar.gz
export PATH="$PATH:~/riscv/bin/"


git clone https://github.com/v8-riscv/node.git
cd node
export CC=riscv64-unknown-linux-gnu-gcc
export CXX=riscv64-unknown-linux-gnu-g++
export CC_host=gcc
export CXX_host=g++

./configure --cross-compiling --dest-cpu=riscv64  --verbose --openssl-no-asm
make -j$(nproc)
