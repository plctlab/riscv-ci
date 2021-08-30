
#get source
git clone https://github.com/riscv/riscv-gnu-toolchain 
cd riscv-gnu-toolchain
git submodule update --init

cd riscv-gcc
git fetch origin
git checkout origin/riscv-gcc-10.1-rvv-dev

cd ../riscv-binutils
git fetch origin
git checkout origin/rvv-1.0.x-zfh
cd ..


# make rv64
./configure --prefix="$PWD/opt-riscv-rv64/" --with-arch=rv64gcv --with-abi=lp64d --with-multilib-generator="rv64gcv-lp64d--"
make -j $(nproc)

# test rv64
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

# make rv32
make clean
./configure --prefix="$PWD/opt-riscv-rv32/" --with-arch=rv32gcv --with-abi=ilp32d --with-multilib-generator="rv32gcv-ilp32d--"
make -j $(nproc)

make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
