git clone https://github.com/riscv/riscv-gnu-toolchain 
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add k https://github.com/pz9115/riscv-gcc.git
git fetch k
git checkout k/riscv-gcc-experimental
cd ../riscv-binutils
git remote add k https://github.com/pz9115/riscv-binutils-gdb.git
git fetch k
git checkout k/riscv-binutils-experimental
cd ..

# test binutils:
./configure --prefix="$PWD/rv64k" --with-arch=rv64gc_zbkb_zbkc_zbkx_zknd_zkne_zknh_zkr_zksed_zksh_zkt --with-abi=lp64d --with-multilib-generator="rv64gc_zbkb_zbkc_zbkx_zknd_zkne_zknh_zkr_zksed_zksh_zkt-lp64d--"

# you can use make -j* to make speed up
make report-binutils-newlib -j $(nproc)

# test rv32:
./configure --prefix="$PWD/rv32k" --with-arch=rv32gc_zbkb_zbkc_zbkx_zknd_zkne_zknh_zkr_zksed_zksh_zkt --with-abi=ilp32d --with-multilib-generator="rv64gc_zbkb_zbkc_zbkx_zknd_zkne_zknh_zkr_zksed_zksh_zkt-ilp32d--"

make clean
make report-binutils-newlib -j $(nproc)

# gc test:
./configure --prefix="$PWD/rv64gc/" --with-arch=rv64gc --with-abi=lp64d --with-mulitilib-generator="rv64gc-lp64d--"
make clean 
make report-gcc -j $(nproc)
make report-binutils-newlib -j $(nproc)

./configure --prefix="$PWD/rv32gc/" --with-arch=rv32gc --with-abi=ilp32d --with-mulitilib-generator="rv32gc-ilp32d--"
make clean 
make report-gcc -j $(nproc)
make report-binutils-newlib -j $(nproc)
