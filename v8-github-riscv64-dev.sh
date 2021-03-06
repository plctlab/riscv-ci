#!/bin/bash

set -ex

V8_ROOT=$PWD/v8-riscv
#RV_HOME=/opt/riscv
QEMU_ADDR=riscv@localhost

# Debug. Clean build.
#rm -rf depot_tools
#rm -rf "V8_ROOT"

[ -d depot_tools ] || git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PWD/depot_tools:/opt/riscv/bin/:$PATH"

# ref: https://github.com/v8-riscv/v8/wiki/get-the-source
rm -rf $V8_ROOT
mkdir -p $V8_ROOT
cd $V8_ROOT
fetch v8
gclient sync

cd $V8_ROOT/v8
git remote | grep -q riscv || git remote add riscv https://github.com/v8-riscv/v8.git

git fetch riscv

git checkout riscv/riscv64-dev
gclient sync


# for debug
git log -1




cd $V8_ROOT/v8
rm -f build.patch
wget -O build.patch https://raw.githubusercontent.com/v8-riscv/v8-riscv-tools/main/riscv64-cross-build.patch
#cd build
git apply build.patch
#cd ..

#rm -f buildtools.patch
#wget -O buildtools.patch https://raw.githubusercontent.com/v8-riscv/v8-riscv-tools/main/riscv64-cross-buildtools.patch
#git apply buildtools.patch

sed -i 's,riscv64-linux-gnu,riscv64-unknown-linux-gnu,' \
    $V8_ROOT/v8/build/toolchain/linux/BUILD.gn

#gclient sync

###########################################################
# Simulator Build
###########################################################

# TODO
# arg 1: d8 folder
# arg 2: benchmark name
# arg 3: logfile
run_js_test_qemu () {
  ssh -p $QEMU_SSH_PORT $QEMU_ADDR python2 \
    ./tools/run-tests.py \
    -j 8 \
    --outdir="$1" \
    -p verbose --report \
    "$2" # 2>&1 | tee "$3"
}

# TODO
# arg 1: d8 path
# arg 2: benchmark name
# arg 3: logfile
run_js_bench_qemu () {
  ssh -p $QEMU_SSH_PORT $QEMU_ADDR python2 test/benchmarks/csuite/csuite.py \
    -r 1 \
    "$2" \
    baseline \
    "$1/d8" # 2>&1 | tee "$3"
}

# Copied from v8-riscv-tools/run-tests.py
# suppose it is in the v8 folder
# arg 1: outdir
# arg 2: extra args for run-tests.py
run_sim_test () {
  ARGS="-p verbose --report --outdir=$1"
  SUFFIX=""
  BTYPE="${1##*riscv64.sim.}"
  while [ $# -ge 2 ]; do
    [ x$2 = x"stress" ] && ARGS="$ARGS --variants=stress" && SUFFIX="$SUFFIX.stress"
    # FIXME: pass jitless to run-test.py would cause error.
    [ x$2 = x"jitless" ] && ARGS="$ARGS --jitless" && SUFFIX="$SUFFIX.jitless"
    shift
  done

  for t in cctest unittests wasm-api-tests wasm-js mjsunit intl message debugger inspector wasm-spec-tests fuzzer
  do
    ./tools/run-tests.py $ARGS $t # 2>&1 | tee "$LOG_FILE.simbuild.$BTYPE.${t}${SUFFIX}"
  done
}

run_x86_build_checks () {
  cd "$V8_ROOT/v8"
  tools/dev/gm.py x64.release.check
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
  ninja -C out/riscv64.sim.debug -j $(nproc) || exit 3
  run_sim_test out/riscv64.sim.debug # 2>&1 | tee "$LOG_FILE.sim.debug"
  #run_sim_test out/riscv64.sim.debug stress # 2>&1 | tee "$LOG_FILE.sim.debug.stress"
  #run_sim_test out/riscv64.sim.debug jitless

  # build simulator config
  # FIXME: temp disable warn as error due to https://github.com/v8-riscv/v8/issues/217
  gn gen out/riscv64.sim.release \
    --args='is_component_build=false
    is_debug=false
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    treat_warnings_as_errors=false
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.release -j $(nproc) || exit 4
  run_sim_test out/riscv64.sim.release # 2>&1 | tee "$LOG_FILE.sim.release"
  #run_sim_test out/riscv64.sim.release stress # 2>&1 | tee "$LOG_FILE.sim.release.stress"
  #run_sim_test out/riscv64.sim.release jitless

}

build_cross_builds () {
  cd "$V8_ROOT/v8"
  gn gen out/riscv64.native.release \
      --args='is_component_build=false
      is_debug=false
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      treat_warnings_as_errors=false
      symbol_level = 0' \
  && ninja -C out/riscv64.native.release -j $(nproc) || exit 5

  gn gen out/riscv64.native.debug \
      --args='is_component_build=false
      is_debug=true
      target_cpu="riscv64"
      v8_target_cpu="riscv64"
      use_goma=false
      goma_dir="None"
      treat_warnings_as_errors=false
      symbol_level = 0' \
  && ninja -C out/riscv64.native.debug -j $(nproc) || exit 6

}

run_on_qemu () {
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.debug/ $QEMU_ADDR:~/riscv64.native.debug/ && \
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/out/riscv64.native.release/ $QEMU_ADDR:~/riscv64.native.release/ && \
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/tools/ $QEMU_ADDR:~/tools/ && \
  rsync -a --delete -e "ssh -p $QEMU_SSH_PORT" "$V8_ROOT"/v8/test/ $QEMU_ADDR:~/test/

  for test_set in cctest unittests wasm-api-tests mjsunit intl message debugger inspector mkgrokdump wasm-js wasm-spec-tests
  do
    run_js_test_qemu riscv64.native.debug   "$test_set" "$LOG_FILE.debug.$test_set"
    run_js_test_qemu riscv64.native.release "$test_set" "$LOG_FILE.release.$test_set"
  done

  for bench in kraken octane sunspider
  do
    run_js_bench_qemu riscv64.native.debug   "$bench" "$LOG_FILE.debug.$bench"
    run_js_bench_qemu riscv64.native.release "$bench" "$LOG_FILE.release.$bench"
  done

}


cd "$V8_ROOT/v8"

git log -1

run_x86_build_checks
run_all_sim_build_checks
build_cross_builds
# run_on_qemu


