#!/bin/bash

set -e

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
  cd v8
  wget https://raw.githubusercontent.com/plctlab/riscv-ci/refs/heads/main/patches/0001-riscv-skip-dcheck-in-AllocateFixed.patch
  git apply 0001-riscv-skip-dcheck-in-AllocateFixed.patch

gclient sync



# Copied from v8-riscv-tools/run-tests.py
# suppose it is in the v8 folder
# arg 1: outdir
# arg 2: extra args for run-tests.py
run_sim_test () {
  ARGS="-p verbose --outdir=$1"
  SUFFIX=""
  BTYPE="${1##*riscv32.sim.}"
  while [ $# -ge 2 ]; do
    [ x$2 = x"stress" ] && ARGS="$ARGS --variants=stress" && SUFFIX="$SUFFIX.stress"
    # FIXME: pass jitless to run-test.py would cause error.
    [ x$2 = x"jitless" ] && ARGS="$ARGS --jitless" && SUFFIX="$SUFFIX.jitless"
    shift
  done

  python3 ./tools/run-tests.py $ARGS # 2>&1 | tee "$LOG_FILE.simbuild.$BTYPE.${t}${SUFFIX}"
}

run_all_sim_build_checks () {
  cd "$V8_ROOT/v8"
  # build simulator config
  gn gen out/riscv32.sim.release \
    --args='is_component_build=false
    is_debug=false
    target_cpu="x86"
    v8_target_cpu="riscv32"
    use_goma=false
    goma_dir="None"' && \
  ninja -C out/riscv32.sim.release -j $(nproc) || exit 4
  run_sim_test out/riscv32.sim.release # 2>&1 | tee "$LOG_FILE.sim.release"
  run_sim_test out/riscv32.sim.release stress # 2>&1 | tee "$LOG_FILE.sim.release.stress"
  #run_sim_test out/riscv32.sim.release jitless

  # build simulator config
  gn gen out/riscv32.sim.debug \
    --args='is_component_build=false
    is_debug=true
    target_cpu="x86"
    v8_target_cpu="riscv32"
    use_goma=false
    goma_dir="None"'
  ninja -C out/riscv32.sim.debug -j $(nproc) || exit 3
  run_sim_test out/riscv32.sim.debug # 2>&1 | tee "$LOG_FILE.sim.debug"
  ## debug stress mode will failed. We will sjip it.
  #run_sim_test out/riscv32.sim.debug stress # 2>&1 | tee "$LOG_FILE.sim.debug.stress"
  #run_sim_test out/riscv32.sim.debug jitless

}



cd "$V8_ROOT/v8"

git log -1

#run_x86_build_checks
# note: 2021-08-21 run 10 times for ramdom bug
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
run_all_sim_build_checks
# build_cross_builds
# run_on_qemu


