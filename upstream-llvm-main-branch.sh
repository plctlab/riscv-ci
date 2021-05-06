rm -rf build
mkdir build
cd build
cmake -DLLVM_ENALBE_PROJECTS="clang;lld" -DLLVM_PARALLEL_LINK_JOBS=3 -G Ninja ../llvm
ninja
ninja check

