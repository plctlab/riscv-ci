rm -rf build
mkdir build
cd build
../configure
make -j $(nproc) check

