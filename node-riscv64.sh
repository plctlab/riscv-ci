#!/bin/bash

# Add riscv64 toolchain into PATH
export PATH="$PATH:/opt/riscv/bin"

git clone https://github.com/v8-riscv/node.git
cd node
export CC=riscv64-unknown-linux-gnu-gcc
export CXX=riscv64-unknown-linux-gnu-g++
export CC_host=gcc
export CXX_host=g++

./configure --cross-compiling --dest-cpu=riscv64  --verbose --openssl-no-asm
make -j$(nproc)
