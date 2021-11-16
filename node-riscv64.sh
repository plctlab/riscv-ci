#!/bin/bash

# Add riscv64 toolchain into PATH

wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2021.09.21/riscv64-glibc-ubuntu-20.04-nightly-2021.09.21-nightly.tar.gz && \
     tar xzvf riscv64-glibc-ubuntu-20.04-nightly-2021.09.21-nightly.tar.gz  -C $HOME/
export PATH="$PATH:$HOME/riscv/bin/"

wget https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.0/clang+llvm-13.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz && \
     tar -xf clang+llvm-13.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz -C $HOME/
export PATH="$PATH:$HOME/clang+llvm-13.0.0-x86_64-linux-gnu-ubuntu-20.04/bin/"

git clone https://github.com/v8-riscv/node.git
cd node
export CC=riscv64-unknown-linux-gnu-gcc
export CXX=riscv64-unknown-linux-gnu-g++
export CC_host=clang
export CXX_host=clang++

./configure --cross-compiling --dest-cpu=riscv64  --verbose --openssl-no-asm
make -j$(nproc)
