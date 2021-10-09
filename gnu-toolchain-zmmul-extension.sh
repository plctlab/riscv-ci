git clone https://github.com/pz9115/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add lsh https://github.com/Liaoshihua/riscv-gcc.git
git fetch lsh
git checkout lsh/riscv-gcc-11.1.0-zmmul

cd ../riscv-binutils

git remote add lsh https://github.com/Liaoshihua/riscv-binutils-gdb.git
git fetch lsh
git checkout lsh/riscv-binutils-2.37-zmmul

cd ..

./configure --prefix="$PWD/opt-riscv-rv32zmmul/" --with-arch=rv32iafdc_zmmul --with-abi=ilp32d --with-multilib-generator="rv32iafdc_zmmul-ilp32d--"
make -j $(nproc)
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

make clean

./configure --prefix="$PWD/opt-riscv-rv64zmmul/" --with-arch=rv64iafdc_zmmul --with-abi=lp64d --with-multilib-generator="rv64iafdc_zmmul-lp64d--"~

make -j $(nproc)
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
