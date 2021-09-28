git clone https://github.com/riscv/riscv-gnu-toolchain 
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add pz9115 https://github.com/pz9115/riscv-gcc.git
git fetch pz9115
git checkout pz9115/https://github.com/pz9115/riscv-gcc.git
cd ../riscv-binutils
git remote add pz9115 https://github.com/pz9115/riscv-binutils-gdb.git
git fetch pz9115
git checkout pz9115/riscv-binutils-experimental-v
cd ../qemu
git remote add plctlab https://github.com/plctlab/plct-qemu.git
git fetch plctlab
git checkout plctlab/new-machine-dev

cd ..

# make rv64
./configure --prefix="$PWD/opt-riscv-rv64/" --with-arch=rv64gcv_zba_zbb_zbc_zbs_zbkb_zbkc_zbkx_zkne_zknd_zknh_zksed_zksh_zkt_zpn_zprv_zpsf --with-abi=lp64d --with-multilib-generator="rv64gcv_zba_zbb_zbc_zbs_zbkb_zbkc_zbkx_zkne_zknd_zknh_zksed_zksh_zkt_zpn_zprv_zpsf-lp64d--"
make -j $(nproc)

# test rv64
sed '15c qemu-riscv$xlen -cpu rv64,x-b=true,x-k=true,x-p=true,x-v=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

# make rv32
make clean
./configure --prefix="$PWD/opt-riscv-rv32/" --with-arch=rv32gcv_zba_zbb_zbc_zbs_zbkb_zbkc_zbkx_zkne_zknd_zknh_zksed_zksh_zkt_zpn_zprv_zpsf --with-abi=ilp32d --with-multilib-generator="rv32gcv_zba_zbb_zbc_zbs_zbkb_zbkc_zbkx_zkne_zknd_zknh_zksed_zksh_zkt_zpn_zprv_zpsf-ilp32d--"
make -j $(nproc)

#test rv32
sed '15c qemu-riscv$xlen -cpu rv32,x-b=true,x-k=true,x-p=true,x-v=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv32-unknown-elf-run 
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
