git clone https://github.com/pz9115/riscv-gnu-toolchain.git 
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add up git://gcc.gnu.org/git/gcc.git
git fetch up
git checkout up/trunk
cd ../riscv-binutils
git remote add up git://sourceware.org/git/binutils-gdb.git
git fetch up
git checkout up/master
cd ../qemu
git remote add plctlab https://github.com/plctlab/plct-qemu.git
git fetch plctlab
git checkout plctlab/new-machine-dev

cd ..

# make rv64
./configure --prefix="$PWD/opt-riscv-rv64/" --with-arch=rv64gc --with-abi=lp64 --with-multilib-generator="rv64gc-lp64--"
make -j $(nproc)

# test rv64
make check-gcc-newlib -j $(nproc)
make check-binutils -j $(nproc)
