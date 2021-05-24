git clone https://github.com/riscv/riscv-gnu-toolchain 
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add k https://github.com/WuSiYu/riscv-gcc
git fetch k
git checkout k/riscv-gcc-10.2.0-crypto
cd ../riscv-binutils
git remote add k https://github.com/pz9115/riscv-binutils-gdb.git
git fetch k
git checkout k/riscv-binutils-2.36-k-ext
cd ..

# test:
./configure --prefix="$PWD/rv64gck_zks" --with-arch=rv64gck_zks --with-abi=lp64d --with-multilib-generator="rv64gck_zks-lp64d--"

# you can use make -j* to make speed up
# Remove GCC test due to b-ext is not support completely, we will restart it after B-ext GCC part finish by Sifive
make report-gcc -j $(nproc)
make report-binutils -j $(nproc)

# test rv32:
./configure --prefix="$PWD/rv32gck_zks" --with-arch=rv32gck_zks --with-abi=ilp32d --with-multilib-generator="rv64gck_zks-ilp32d--"
make clean 
make report-gcc -j $(nproc)
make report-binutils-newlib -j $(nproc)

# gc test:
./configure --prefix="$PWD/rv32gc/" --with-arch=rv64gc --with-abi=lp64d --with-mulitilib-generator="rv64gc-lp64d--"
make clean 
make report-gcc -j $(nproc)
make report-binutils-newlib -j $(nproc)

./configure --prefix="$PWD/rv32gc/" --with-arch=rv32gc --with-abi=ilp32d --with-mulitilib-generator="rv32gc-ilp32d--"
make clean 
make report-gcc -j $(nproc)
make report-binutils-newlib -j $(nproc)