git clone https://github.com/plctlab/riscv-vector-intrinsic-fuzzing.git rif
cd rif

git checkout --reset develop

# No submodues yet.
#git submodule update --init --recursive

rm -rf build
mkdir build
cd build
cmake ..
make -j $(nproc)
make test ARGS=-V

