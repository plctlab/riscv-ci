#!/bin/bash

set -e

git clone https://github.com/riscv/riscv-gnu-toolchain 
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add jw https://github.com/pz9115/riscv-gcc.git
git fetch jw
git checkout jw riscv-gcc-10.2.0-rvb
cd ../riscv-binutils
git remote add jw https://github.com/pz9115/riscv-binutils-gdb.git
git fetch jw
git checkout jw riscv-binutils-experiment

# test:
cd ..
./configure --prefix="$PWD/opt-riscv/" --enable-multilib=true

# you can use make -j* to make speed up
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
