#!/bin/bash

# Add riscv64 toolchain into PATH
export PATH="$PATH:/opt/riscv/bin"

git clone https://github.com/nodejs/node.git
cd node
export CC=riscv64-unknown-linux-gnu-gcc
export CXX=riscv64-unknown-linux-gnu-g++
export CC_host=clang
export CXX_host=clang++

./configure --cross-compiling --dest-cpu=riscv64  --verbose --openssl-no-asm
make -j$(nproc)
