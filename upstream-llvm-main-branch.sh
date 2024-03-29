rm -rf build
mkdir build
cd build
cmake \
	-DCMAKE_BUILD_TYPE=Debug \
	-DLLVM_ENABLE_PROJECTS="clang;lld" \
	-DLLVM_PARALLEL_LINK_JOBS=3 \
	-G Ninja \
	../llvm
ninja
ninja check

