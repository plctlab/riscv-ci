# apt-get install device-tree-compiler
export RISCV=$PWD/install
rm -rf build
mkdir build
cd build
../configure --prefix=$RISCV
make -j $(nproc)
make install
#make check
#make report
