git submodule update --init

cd riscv-gcc
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-gcc.git
git fetch zfinx
git checkout -f zfinx/riscv-gcc-10.2.0-zfinx
cd ../riscv-binutils
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-binutils-gdb.git
git fetch zfinx
git checkout zfinx/riscv-binutils-2.35-zfinx
cd ../qemu
git remote | grep -q plct-qemu || git remote add plct-qemu https://github.com/isrc-cas/plct-qemu.git || true
git fetch plct-qemu
git checkout plct-qemu/plct-zfinx-dev
cd ..

make clean -j $(nproc) || echo "No need to clean"
# regression test on rv32emac:
./configure --prefix=$PWD/opt-rv32e/ --with-arch=rv32emac --with-abi=ilp32e --with-multilib-generator="rv32emac-ilp32e--"

# you can use make -j* to make speed up
make -j $(nproc) report-gcc-newlib
make -j $(nproc) report-binutils-newlib

# regression test on rv32ezfinx with qemu support:
./configure --prefix="$PWD/opt-rv32e/" --with-arch=rv32emaczfinx --with-abi=ilp32e --with-multilib-generator="rv32emaczfinx-ilp32e--"
make clean -j $(nproc)
sed -i '15c qemu-riscv$xlen -cpu rv32,e=true,i=false,g=false,Zfinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv32-unknown-elf-run
make -j $(nproc) report-gcc-newlib
make -j $(nproc) report-binutils-newlib

# regression test on rv32zdinx with qemu support:
./configure --prefix="$PWD/opt-rv32e/" --with-arch=rv32emaczdinx --with-abi=ilp32e --with-multilib-generator="rv32emaczdinx-ilp32e--"
make clean -j $(nproc)
sed -i '15c qemu-riscv$xlen -cpu rv32,e=true,i=false,g=false,Zdinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv32-unknown-elf-run
make -j $(nproc) report-gcc-newlib
make -j $(nproc) report-binutils-newlib