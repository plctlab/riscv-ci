git clone https://github.com/pz9115/riscv-gnu-toolchain.git
cd riscv-gnu-toolchain
git submodule update --init
cd riscv-gcc
git remote add syl https://github.com/pz9115/corev-gcc.git
git fetch syl
git checkout syl/development

cd ../riscv-binutils

git remote add syl https://github.com/pz9115/corev-binutils-gdb.git
git fetch syl 
git checkout syl/development 

cd ..

sed -i "s|SPIKE_BRANCH:=master|SPIKE_BRANCH:=plct-zce-dev|" Makefile.in
sed -i "s|/riscv/riscv-isa-sim|/plctlab/plct-spike|" Makefile.in

sed -i '6c \ \ \ \ --isa=RV${xlen}gc_zcee \\' scripts/wrapper/spike/riscv64-unknown-elf-run 

./configure --prefix="$PWD/opt-riscv-rv64zcee" --with-arch=rv64gc_zcee --with-abi=lp64d --with-multilib-generator="rv64gc_zcee-lp64d--"
make report-gcc-newlib -j $(nproc) SIM=spike
make report-binutils-newlib -j $(nproc) SIM=spike
