rm -rf build
mkdir build
cd build
cmake -DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64;RISCV" -DLLVM_ENALBE_PROJECTS="clang" -DLLVM_PARALLEL_LINK_JOBS=3 -G Ninja ../llvm
ninja
ninja check

