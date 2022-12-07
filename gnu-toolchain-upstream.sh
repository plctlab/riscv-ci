git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init --recursive
cd gcc
git fetch origin
git checkout origin/master -f
cd ../binutils
git fetch origin
git checkout orignin/master -f
cd ..

# make rv32
./configure --prefix="$PWD/opt-riscv-rv32/" --with-arch=rv32gc --with-abi=ilp32d
make -j $(nproc)

#test rv32
make report-gcc-newlib -j $(nproc) &&
make report-binutils -j $(nproc)

make clean

# make rv64
./configure --prefix="$PWD/opt-riscv-rv64/" --with-arch=rv64gc --with-abi=lp64d
make -j $(nproc)

# test rv64
make report-gcc-newlib -j $(nproc) &&
make report-binutils -j $(nproc)
