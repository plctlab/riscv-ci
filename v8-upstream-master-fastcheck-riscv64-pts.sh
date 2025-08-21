#!/bin/bash

set -e

V8_ROOT=$PWD/v8-riscv

echo $PWD

[ -d depot_tools ] || git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH="$PWD/depot_tools:/opt/riscv/bin/:$PATH"

# ref: https://github.com/v8-riscv/v8/wiki/get-the-source
rm -rf $V8_ROOT
  mkdir -p $V8_ROOT
  cd $V8_ROOT
  fetch v8
  cd v8

gclient sync

# JetStream2.0
git clone -b JetStream2.0 --single-branch  https://github.com/WebKit/JetStream.git
cd JetStream
wget  https://raw.githubusercontent.com/plctlab/riscv-ci/main/patches/0001-Make-it-so-JetStream2-can-run-with-the-d8-shell.patch
patch -p1 <0001-Make-it-so-JetStream2-can-run-with-the-d8-shell.patch

# show directory
cd "$V8_ROOT/v8" && ls -al .

run_sim_build () {
  cd "$V8_ROOT/v8"
  # build simulator config
  gn gen out/riscv64.sim.release \
    --args='is_component_build=false
    is_debug=false
    target_cpu="x64"
    v8_target_cpu="riscv64"
    use_goma=false
    goma_dir="None"' && \
  ninja -C out/riscv64.sim.release -j 16 || exit 1
}

run_cross_build() {
  cd "$V8_ROOT/v8"
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
  ninja -C out/riscv64.native.release -j 16 || exit 2
}

run_get_builtinsize() {
  qemu-riscv64 -h
  ls -l  /usr/local
  ls -l  /usr/local/bin
  ls -l  /usr/local/bin/plugin
  ls -l  /usr/local/riscv
  cd "$V8_ROOT/v8"
  qemu-riscv64 -L /usr/local/riscv/sysroot ./out/riscv64.native.release/d8 --print-builtin-size ./test/benchmarks/data/sunspider/3d-cube.js  2>&1 |tee logbtsize-now.txt || exit 3
  ls -l .
}

run_get_lastSuccessfulBuild_info() {
  cd "$V8_ROOT/v8"
# get the lastSuccessfulBuild number
  BUILD_NUM=$(curl -s https://ci.rvperf.org/view/V8/job/v8-upstream-master-fastcheck-riscv64-pts/lastSuccessfulBuild/buildNumber | grep -o '[0-9]*')
  curl -s "https://ci.rvperf.org/view/V8/job/v8-upstream-master-fastcheck-riscv64-pts/$BUILD_NUM/consoleFull" |  tr -d '\r'  2>&1 |tee lastSuccessfulBuild.log
}

run_cmp_builtinsize() {
  cd "$V8_ROOT/v8"
  grep -E '^[A-Z]{3} Builtin, ' lastSuccessfulBuild.log 2>&1 |tee logbtsize-lsb.txt
  wc -l logbtsize-lsb.txt
  wc -l logbtsize-now.txt
  echo "CMP builtin size"
  comm -3 <(sort logbtsize-lsb.txt) <(sort logbtsize-now.txt)
  echo "DIFF builtin size"
  diff logbtsize-lsb.txt logbtsize-now.txt
}

run_Sunspider() {
  cd "$V8_ROOT/v8/"
  for file in test/benchmarks/data/sunspider/*.js; do
    echo "Benchmarking $(basename "$file")" 2>&1 | tee -a ss-benchmark.log
    qemu-riscv64 -L /usr/local/riscv/sysroot -plugin /usr/local/bin/plugin/libinsn.so -d plugin  ./out/riscv64.native.release/d8 "$file" 2>&1 |tee -a ss-benchmark.log
  done
}

run_cmp_Sunspider() {
  cd "$V8_ROOT/v8/"
  grep -E "^(Benchmarking|total insn)" lastSuccessfulBuild.log | awk '{print($NF)}' | paste -d ' ' - - > ss-result-lsb.txt
  grep -E "^(Benchmarking|total insn)" ss-benchmark.log | awk '{print($NF)}' | paste -d ' ' - - > ss-result-now.txt
  echo "Sunspider lastSuccessfulBuild result: "
  cat ss-result-lsb.txt
  echo "Sunspider current build result: "
  cat ss-result-now.txt
  echo "Sunspider diff: "
  comm -12 <(sort ss-result-lsb.txt) <(sort ss-result-now.txt)
}

run_JetStream() {
cd "$V8_ROOT/v8/JetStream"
declare -a data=(
"ARES , Air"
"ARES , Basic"
"ARES , ML"
"ARES , Babylon"
"CDJS , cdjs"
"CodeLoad , first-inspector-code-load"
"CodeLoad , multi-inspector-code-load"
"Octane , Box2D"
"Octane , octane-code-load"
"Octane , crypto"
"Octane , delta-blue"
"Octane , earley-boyer"
"Octane , gbemu"
"Octane , mandreel"
"Octane , navier-stokes"
"Octane , pdfjs"
"Octane , raytrace"
"Octane , regexp"
"Octane , richards"
"Octane , splay"
"Octane , typescript"
"Octane , octane-zlib"
"RexBench , FlightPlanner"
"RexBench , OfflineAssembler"
"RexBench , UniPoker"
"SeaMonster , ai-astar"
"SeaMonster , gaussian-blur"
"SeaMonster , stanford-crypto-aes"
"SeaMonster , stanford-crypto-pbkdf2"
"SeaMonster , stanford-crypto-sha256"
"SeaMonster , json-stringify-inspector"
"SeaMonster , json-parse-inspector"
"Simple , async-fs"
"Simple , float-mm.c"
"Simple , hash-map"
"SunSpider , 3d-cube-SP"
"SunSpider , 3d-raytrace-SP"
"SunSpider , base64-SP"
"SunSpider , crypto-aes-SP"
"SunSpider , crypto-md5-SP"
"SunSpider , crypto-sha1-SP"
"SunSpider , date-format-tofte-SP"
"SunSpider , date-format-xparb-SP"
"SunSpider , n-body-SP"
"SunSpider , regex-dna-SP"
"SunSpider , string-unpack-code-SP"
"SunSpider , tagcloud-SP"
"Wasm , HashSet-wasm"
"Wasm , tsf-wasm"
"Wasm , quicksort-wasm"
"Wasm , gcc-loops-wasm"
"Wasm , richards-wasm"
"WSL , WSL"
"WTB , acorn-wtb"
"WTB , babylon-wtb"
"WTB , chai-wtb"
"WTB , coffeescript-wtb"
"WTB , espree-wtb"
"WTB , jshint-wtb"
"WTB , lebab-wtb"
"WTB , prepack-wtb"
"WTB , uglify-js-wtb"
)

  for item in "${data[@]}"; do
    IFS=',' read -r prefix suffix <<< "$item"
    suffix=$(echo "$suffix" | xargs)
    prefix=$(echo "$prefix" | xargs)
    echo "Running  Group: $prefix Name: $suffix"

    #qemu-riscv64 -L /usr/local/riscv/sysroot -plugin /usr/local/bin/plugin/libinsn.so -d plugin  ../out/riscv64.native.release/d8 ./pts-jetstream.js ./cli.js -- $suffix || exit 7
    #just run without insn plugin
    qemu-riscv64 -L /usr/local/riscv/sysroot ../out/riscv64.native.release/d8 ./pts-jetstream.js ./cli.js -- $suffix || exit 5
  done
}

cd "$V8_ROOT/v8"

git log -1

#run_sim_build
run_cross_build
run_get_builtinsize
run_get_lastSuccessfulBuild_info
run_cmp_builtinsize
#run_JetStream
run_Sunspider
run_cmp_Sunspider
