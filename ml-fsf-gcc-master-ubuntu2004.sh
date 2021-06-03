#!/bin/bash

if [ ! -e riscv-gnu-toolchain ]; then
	git clone https://github.com/riscv/riscv-gnu-toolchain 
fi

cd riscv-gnu-toolchain
# FIXME CA failure for QEMU submodule. work around.
GIT_SSL_NO_VERIFY=1 git submodule update --init

cd riscv-gcc
git remote | grep -q fsf || git remote add fsf git://gcc.gnu.org/git/gcc.git
git fetch fsf

git reset --hard
git clean -fdx
git checkout -b "patch-${patch_id}-${BUILD_ID}" fsf/master

pwclient apply -p gcc "${patch_id}"
# pwclient git-am -p gcc "${patch_id}"

cd ..

# RV64 Tests
rm -rf "$PWD/opt-riscv64"
./configure --prefix="$PWD/opt-riscv64/" \
	--with-arch=rv64gc \
	--with-abi=lp64d \
	--with-mulitilib-generator="rv64gc-lp64d--"
make clean
make report-binutils-newlib -j $(nproc)
make report-gcc-newlib -j $(nproc)

# test rv32:
rm -rf "$PWD/opt-riscv32"
./configure --prefix="$PWD/opt-riscv32/" \
	--with-arch=rv32gc \
	--with-abi=ilp32d \
	--with-mulitilib-generator="rv32gc-ilp32d--"
make clean
make report-binutils-newlib -j $(nproc)
make report-gcc-newlib -j $(nproc)
