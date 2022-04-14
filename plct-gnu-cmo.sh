git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add cmo https://github.com/yulong-plct/riscv-gcc.git
git fetch cmo
git checkout cmo/cmodev-upstream

cd ../riscv-binutils

git remote add cmo git://sourceware.org/git/binutils-gdb.git
git fetch cmo 
git checkout cmo/master 

cd ../qemu
git fetch origin
git checkout origin/master

cd ..

sed -i '15c qemu-riscv$xlen -cpu rv64,Zicbom=on,Zicboz=on,Zicbop=on -r 5.10 "${qemu_args[@]}" -L ${RISC_V_SYSROOT} "$@"' scripts/wrapper/qemu/riscv64-unknown-elf-run 


./configure --prefix="$PWD/opt-riscv-rv64cmo" --with-arch=rv64gc_zicbom_zicboz_zicbop --with-abi=lp64d --with-multilib-generator="rv64gc_zicbom_zicboz_zicbop-lp64d--"
make report-gcc-newlib -j $(nproc)
make report-binutils-newlib -j $(nproc)
