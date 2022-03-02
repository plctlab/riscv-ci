git clone https://github.com/pz9115/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add lsh https://github.com/LiaoShiHua/riscv-gcc.git
git fetch lsh
git checkout lsh/riscv-gcc-experiment-zceb

cd ../riscv-binutils

git remote add lin https://github.com/linsinan1995/riscv-binutils-gdb.git
git fetch lin 
git checkout lin/riscv-binutils-experiment-zceb@clean-up

cd ..

sed -i "s|SPIKE_BRANCH:=master|SPIKE_BRANCH:=plct-zce-dev|" Makefile.in
sed -i "s|/riscv/riscv-isa-sim|/plctlab/plct-spike|" Makefile.in

sed -i '6c \ \ \ \ --isa=RV${xlen}imac_zceb \\' scripts/wrapper/spike/riscv64-unknown-elf-run 

./configure --prefix="$PWD/opt-riscv-rv64zceb" --with-arch=rv64imac_zceb --with-abi=lp64 --with-multilib-generator="rv64imac_zceb-lp64--"
make report-gcc-newlib -j $(nproc) SIM=spike
make report-binutils-newlib -j $(nproc) SIM=spike
