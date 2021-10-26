git clone https://github.com/pz9115/riscv-gnu-toolchain.git 
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add base https://gcc.gnu.org/git/gcc.git
git fetch base
git checkout base/master
cd ../riscv-binutils
git remote add base https://sourceware.org/git/binutils-gdb.git
git fetch base
git checkout base/master
cd ..

# make rv64
./configure --prefix="$PWD/opt-riscv-rv64/" --with-arch=rv64gc --with-abi=lp64d --with-multilib-generator="rv64gc-lp64d--"
make -j $(nproc)

# test rv64
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

# make rv32
make clean
./configure --prefix="$PWD/opt-riscv-rv32/" --with-arch=rv32gc --with-abi=ilp32d --with-multilib-generator="rv32gc-ilp32d--"
make -j $(nproc)

make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
