git clone https://github.com/pz9115/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add jw https://github.com/pz9115/riscv-gcc.git
git fetch jw
git checkout jw/riscv-gcc-10.2.0-rvb
cd ../riscv-binutils
git remote add jw https://github.com/pz9115/riscv-binutils-gdb.git
git fetch jw
git checkout jw/riscv-binutils-b-ext

# test rv64:
cd ..
./configure --prefix="$PWD/opt-riscv/" --with-arch=rv64gc_zba_zbb_zbc_zbe_zbf_zbp_zbr_zbs_zbt --with-abi=lp64d --with-mulitilib-generator="rv64gc_zba_zbb_zbc_zbe_zbf_zbp_zbr_zbs_zbt-lp64d--"

# you can use make -j* to make speed up
# Remove GCC test due to b-ext is not support completely, we will restart it after B-ext GCC part finish by Sifive
# make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

# test rv32:
./configure --prefix="$PWD/opt-riscv/" --with-arch=rv32gc_zba_zbb_zbc_zbe_zbf_zbp_zbr_zbs_zbt --with-abi=ilp32d --with-mulitilib-generator="rv32gc_zba_zbb_zbc_zbe_zbf_zbp_zbr_zbs_zbt-ilp32d--"
make clean 
make report-binutils-newlib -j $(nproc)