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

cd ../qemu
git remote add plctlab https://github.com/plctlab/plct-qemu.git
git fetch plctlab
git checkout plctlab/plct-zce-dev

cd ..

sed -i '15c qemu-riscv$xlen -cpu rv64,x-zce=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 


./configure --prefix="$PWD/opt-riscv-rv64zceb" --with-arch=rv64imac_zceb --with-abi=lp64 --with-multilib-generator="rv64imac_zceb-lp64--"
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
