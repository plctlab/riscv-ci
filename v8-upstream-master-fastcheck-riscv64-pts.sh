#!/bin/bash

set -e

V8_ROOT=$PWD/v8-riscv
QEMU_ADDR=riscv@localhost

[ -d depot_tools ] || git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PWD/depot_tools:/opt/riscv/bin/:$PATH"

# ref: https://github.com/v8-riscv/v8/wiki/get-the-source
rm -rf $V8_ROOT
  mkdir -p $V8_ROOT
  cd $V8_ROOT
  fetch v8
  cd v8

gclient sync

run_cross_build() {
  cd "$V8_ROOT/v8"
  # patch to avoid RVV in highway
  wget  https://raw.githubusercontent.com/plctlab/riscv-ci/main/patches/0001-Do-not-build-Highway-with-RVV.patch
  patch -p1 <0001-Do-not-build-Highway-with-RVV.patch
  # install sysroot
  build/linux/sysroot_scripts/install-sysroot.py --arch=riscv64
  # build native config
  gn gen out/riscv64.native.release \
      --args='is_component_build=false
      is_debug=false
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      v8_enable_backtrace = true
      v8_enable_disassembler = true
      v8_enable_object_print = true
      v8_enable_verify_heap = true
      dcheck_always_on = false
      is_clang = true
      treat_warnings_as_errors = false' && \
  ninja -C out/riscv64.native.release -j 16 || exit 3
}

run_native_benchmark() {
  qemu-riscv64 -h
  ls -l  /usr/local
  ls -l  /usr/local/bin
  ls -l  /usr/local/bin/plugin
  ls -l  /usr/local/riscv
# run with proper cmd line
  cd "$V8_ROOT/v8"
  qemu-riscv64 -L /usr/local/riscv/sysroot -plugin /usr/local/bin/plugin/libinsn.so -d plugin  ./out/riscv64.native.release/d8 ./test/benchmarks/data/sunspider/3d-cube.js
}

run_all_sim_build_checks () {
  cd "$V8_ROOT/v8"
  # build simulator config
  gn gen out/riscv64.sim.debug \
    --args='is_component_build=false
    is_debug=true
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.debug -j 16 || exit 3

  # build simulator config
  #gn gen out/riscv64.sim.release \
  #  --args='is_component_build=false
  #  is_debug=false
  #  target_cpu="x64"
  #  v8_target_cpu="riscv64"
  #  use_goma=false
  #  goma_dir="None"' && \
  #ninja -C out/riscv64.sim.release -j 16 || exit 4
}

cd "$V8_ROOT/v8"

git log -1

run_all_sim_build_checks
run_cross_build
run_native_benchmark
