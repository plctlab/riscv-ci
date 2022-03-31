git clone https://github.com/pz9115/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add syl https://github.com/pz9115/riscv-gcc.git 
git fetch syl riscv-gcc-10.2.0-zfinx
git checkout syl/riscv-gcc-10.2.0-zfinx

cd ../riscv-binutils

git remote add syl https://github.com/pz9115/riscv-binutils-gdb.git
git fetch syl riscv-binutils-2.35-zfinx
git checkout syl/riscv-binutils-2.35-zfinx

cd ..

sed -i "s|SPIKE_BRANCH:=master|SPIKE_BRANCH:=plct-upstream-zfinx|" Makefile.in
sed -i "s|/riscv/riscv-isa-sim|/plctlab/plct-spike|" Makefile.in

sed -i '6c \ \ \ \ --isa=rv64imac_zdinx_zhinx \\' scripts/wrapper/spike/riscv64-unknown-elf-run

./configure --prefix="$PWD/opt-riscv-rv64zdinx" --with-arch=rv64imazdinx --with-abi=lp64 --with-multilib-generator="rv64imazdinx-lp64--"
make -j $(nproc)
make report-gcc-newlib -j $(nproc) SIM=spike
make report-binutils-newlib -j $(nproc) SIM=spike
make clean

sed -i "s|rv32gc|rv32imazdinx|" Makefile.in
sed -i '6c \ \ \ \ --isa=rv32imac_zdinx_zhinx \\' scripts/wrapper/spike/riscv32-unknown-elf-run
./configure --prefix="$PWD/opt-riscv-rv32zdinx" --with-arch=rv32imazdinx --with-abi=ilp32 --with-multilib-generator="rv32imazdinx-ilp32--"
make -j $(nproc)
make report-gcc-newlib -j $(nproc) SIM=spike
make report-binutils-newlib -j $(nproc) SIM=spike
