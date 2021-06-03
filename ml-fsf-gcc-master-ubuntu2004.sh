#!/bin/bash

if [ ! -e riscv-gnu-toolchain ]; then
	git clone https://github.com/riscv/riscv-gnu-toolchain 
fi

cd riscv-gnu-toolchain
git submodule update --init

cd riscv-gcc
git remote | grep -q fsf || git remote add fsf git://gcc.gnu.org/git/gcc.git
git fetch fsf
git checkout -b "patch-${patch_id}" fsf/master

pwclient git-am -p gcc -s -m "${patch_id}"

cd ..

# RV64 Tests
./configure --prefix="$PWD/opt-riscv/" \
	--with-arch=rv64gcb \
	--with-abi=lp64d \
	--with-mulitilib-generator="rv64gcb-lp64d--"
make clean
make report-binutils-newlib -j $(nproc)
make report-gcc-newlib -j $(nproc)

# test rv32:
./configure --prefix="$PWD/opt-riscv/" \
	--with-arch=rv32gcb \
	--with-abi=ilp32d \
	--with-mulitilib-generator="rv32gcb-ilp32d--"
make clean
make report-binutils-newlib -j $(nproc)
make report-gcc-newlib -j $(nproc)
