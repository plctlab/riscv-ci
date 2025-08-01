#!/bin/bash

set -e

V8_ROOT=$PWD/v8-riscv
BASE_DIR=$PWD
SYSROOT=$PWD/riscv/sysroot/
INSN_PLUGIN=$PWD/install-qemu/plugin/libinsn.so


prepare_sysroot () {
wget https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2024.04.12/riscv64-glibc-ubuntu-22.04-gcc-nightly-2024.04.12-nightly.tar.gz

tar zxvf riscv64-glibc-ubuntu-22.04-gcc-nightly-2024.04.12-nightly.tar.gz
}

prepare_qemu () {
mkdir -p "$BASE_DIR/install-qemu"

git clone git@github.com:qemu/qemu.git

cd qemu

git checkout -t remotes/origin/stable-9.0

mkdir build
cd build

../configure --target-list=riscv64-linux-user --enable-user --enable-slirp --enable-plugins --prefix="$BASE_DIR/install-qemu"

make
make install

cp -a ./tests/plugin/ "$BASE_DIR/install-qemu"
cd $BASE_DIR
}

[ -d depot_tools ] || git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PWD/depot_tools:/opt/riscv/bin/:$PATH"

# ref: https://github.com/v8-riscv/v8/wiki/get-the-source
rm -rf $V8_ROOT
  mkdir -p $V8_ROOT
  cd $V8_ROOT
  fetch v8
  cd v8
  

gclient sync

# Copied from v8-riscv-tools/run-tests.py
# suppose it is in the v8 folder
# arg 1: outdir
# arg 2: extra args for run-tests.py
run_sim_test () {
  ARGS="-p verbose  --outdir=$1"
  SUFFIX=""
  BTYPE="${1##*riscv64.sim.}"
  while [ $# -ge 2 ]; do
    [ x$2 = x"stress" ] && ARGS="$ARGS --variants=stress" && SUFFIX="$SUFFIX.stress"
    # FIXME: pass jitless to run-test.py would cause error.
    [ x$2 = x"jitless" ] && ARGS="$ARGS --jitless" && SUFFIX="$SUFFIX.jitless"
    shift
  done

  python3 ./tools/run-tests.py $ARGS # 2>&1 | tee "$LOG_FILE.simbuild.$BTYPE.${t}${SUFFIX}"
}

run_benchmark() {
# set up qemu path
   export PATH="$BASE_DIR/install-qemu/bin:$PATH"
# try qemu-riscv64
   qemu-riscv64 -h
# run with proper cmd line
   cd "$V8_ROOT/v8"
   qemu-riscv64 -L $SYSROOT -plugin $INSN_PLUGIN -d plugin  ./out/riscv64.sim.release/d8 $V8_ROOT/test/benchmarks/data/sunspider/3d-cube.js
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
  run_sim_test out/riscv64.sim.debug # 2>&1 | tee "$LOG_FILE.sim.debug"
  run_sim_test out/riscv64.sim.debug stress # 2>&1 | tee "$LOG_FILE.sim.debug.stress"
  #run_sim_test out/riscv64.sim.debug jitless

  # build simulator config
  gn gen out/riscv64.sim.release \
    --args='is_component_build=false
    is_debug=false
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.release -j 16 || exit 4
  run_sim_test out/riscv64.sim.release # 2>&1 | tee "$LOG_FILE.sim.release"
  run_sim_test out/riscv64.sim.release stress # 2>&1 | tee "$LOG_FILE.sim.release.stress"
  #run_sim_test out/riscv64.sim.release jitless
  run_benchmark
}



cd "$V8_ROOT/v8"

git log -1

#run_x86_build_checks
prepare_sysroot
prepare_qemu
run_all_sim_build_checks
# build_cross_builds
# run_on_qemu

