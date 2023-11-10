#!/bin/bash

# Add riscv64 toolchain into PATH

wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2023.11.08/riscv64-glibc-ubuntu-20.04-gcc-nightly-2023.11.08-nightly.tar.gz && \
     tar xzvf riscv64-glibc-ubuntu-20.04-gcc-nightly-2023.11.08-nightly.tar.gz  -C $HOME/
export PATH="$PATH:$HOME/riscv/bin/"

rm -rf node
git clone https://github.com/nodejs/node.git
cd node 
git config user.email "you@example.com"
git config user.name "Your Name"

git log -1

gcc --version
riscv64-unknown-linux-gnu-gcc --version
export CC=riscv64-unknown-linux-gnu-gcc
export CXX=riscv64-unknown-linux-gnu-g++
export CC_host=gcc
export CXX_host=g++

./configure --cross-compiling --dest-cpu=riscv64  --verbose --openssl-no-asm

# Temporary reduce the parallel jobs to 4 due to new worker limitations.
make -j 4
