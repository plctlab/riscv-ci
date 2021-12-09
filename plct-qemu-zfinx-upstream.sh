git clone https://github.com/pz9115/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add syl https://github.com/pz9115/riscv-gcc.git 
git fetch syl
git checkout syl/riscv-gcc-10.2.0-zfinx

cd ../riscv-binutils

git remote add syl https://github.com/pz9115/riscv-binutils-gdb.git
git fetch syl 
git checkout syl/riscv-binutils-2.35-zfinx

cd ../qemu
git remote add plctlab https://github.com/plctlab/plct-qemu.git
git fetch plctlab
git checkout plctlab/plct-zfinx-upstream

cd ..

sed -i '15c qemu-riscv$xlen -cpu rv64,g=false,f=false,d=false,Zfinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 
./configure --prefix="$PWD/opt-riscv-rv64zfinx" --with-arch=rv64imazfinx --with-abi=lp64 --with-multilib-generator="rv64imazfinx-lp64--"
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

make clean
sed -i '15c qemu-riscv$xlen -cpu rv64,g=false,f=false,d=false,Zdinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 
../configure --prefix="$PWD/opt-riscv-rv64zdinx" --with-arch=rv64imazdinx --with-abi=lp64 --with-multilib-generator="rv64imazdinx-lp64--"
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

make clean
sed -i '15c qemu-riscv$xlen -cpu rv32,g=false,f=false,d=false,Zdinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 
../configure --prefix="$PWD/opt-riscv-rv32zdinx" --with-arch=rv32imazdinx --with-abi=ilp32 --with-multilib-generator="rv32imazdinx-ilp32--"
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)

make clean
sed -i '15c qemu-riscv$xlen -cpu rv32,g=false,f=false,d=false,Zfinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 
../configure --prefix="$PWD/opt-riscv-rv32zfinx" --with-arch=rv32imazfinx --with-abi=ilp32 --with-multilib-generator="rv32imazfinx-ilp32--"
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
