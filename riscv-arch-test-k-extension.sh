#download and build toolchain
git clone https://github.com/riscv/riscv-crypto.git
cd riscv-crypto
export RISCV_ARCH=riscv64-unknown-elf
source bin/conf.sh
source $REPO_HOME/tools/share.sh

bash $REPO_HOME/tools/clone.sh
cd extern/riscv-isa-sim
git checkout master
git pull
cd ../../

bash $REPO_HOME/tools/binutils-apply.sh

bash $REPO_HOME/tools/toolchain-conf.sh
bash $REPO_HOME/tools/spike-conf.sh

bash $REPO_HOME/tools/toolchain-build.sh
bash $REPO_HOME/tools/spike-build.sh

cd ..

#download riscv-arch-test
git clone -b k-extension https://github.com/liweiwei90/riscv-arch-test.git
cd riscv-arch-test

cp -r ../riscv-crypto/extern/riscv-isa-sim/arch_test_target/spike/* riscv-target/spike/
cd riscv-target/spike/device/rv64i_m
cp -r M K_unratified
sed -i "s|rv64im|rv64ikb|" K_unratified/Makefile.include

cd ../rv32i_m
cp -r M K_unratified
sed -i "s|rv32im|rv32ikb|" K_unratified/Makefile.include

cd ../../../../

#run act tests on spike
make RISCV_TARGET=spike RISCV_DEVICE=K_unratified TARGET_SIM=$PWD/../riscv-crypto/build/riscv64-unknown-elf/bin/spike RISCV_PREFIX=$PWD/../riscv-crypto/build/riscv64-unknown-elf/bin/riscv64-unknown-elf- compile simulate verify XLEN=32

make RISCV_TARGET=spike RISCV_DEVICE=K_unratified TARGET_SIM=$PWD/../riscv-crypto/build/riscv64-unknown-elf/bin/spike RISCV_PREFIX=$PWD/../riscv-crypto/build/riscv64-unknown-elf/bin/riscv64-unknown-elf- compile simulate verify XLEN=64

