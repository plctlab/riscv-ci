git submodule update --init

cd riscv-gcc
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-gcc.git
git fetch zfinx
git checkout -f zfinx/riscv-gcc-10.2.0-zfinx
cd ..

cd riscv-binutils
git remote | grep -q zfinx || git remote add zfinx https://github.com/pz9115/riscv-binutils-gdb.git
git fetch zfinx
git checkout zfinx/riscv-binutils-2.35-zfinx
cd ..

cd qemu
git remote | grep -q plct-qemu || git remote add plct-qemu https://github.com/isrc-cas/plct-qemu.git || true
git fetch plct-qemu
git checkout plct-qemu/plct-zfinx-dev
cd ..

make clean -j $(nproc) || echo "No need to clean"
# regression test on rv64gc:
./configure --prefix="$PWD/opt-rv64/" --with-arch=rv64gc --with-abi=lp64 --with-multilib-generator="rv64gc-lp64--"

# you can use make -j* to make speed up
make -j $(nproc) report-gcc-newlib
make -j $(nproc) report-binutils-newlib

# regression test on rv64zfinx with qemu support:
./configure --prefix="$PWD/opt-rv64/" --with-arch=rv64imaczfinx --with-abi=lp64 --with-multilib-generator="rv64imaczfinx-lp64--"
make clean -j $(nproc)
sed -i '15c qemu-riscv$xlen -cpu rv64,Zfinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run
make -j $(nproc) report-gcc-newlib
make -j $(nproc) report-binutils-newlib

# regression test on rv64zdinx with qemu support:
./configure --prefix="$PWD/opt-rv64/" --with-arch=rv64imaczdinx --with-abi=lp64 --with-multilib-generator="rv64imaczdinx-lp64--"
make clean -j $(nproc)
sed -i '15c qemu-riscv$xlen -cpu rv64,Zdinx=true -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run
make -j $(nproc) report-gcc-newlib
make -j $(nproc) report-binutils-newlib