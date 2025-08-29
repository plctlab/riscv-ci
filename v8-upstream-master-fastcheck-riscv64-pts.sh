#!/bin/bash
git -C riscv-ci pull || git clone https://github.com/plctlab/riscv-ci riscv-ci
python3 $PWD/riscv-ci/v8-upstream-master-fastcheck-riscv64-pts.py || true

#############################################################################
# TODO(kasperl@rivosinc.com): We're keeping the current bash version of the
# performance tracking system (pts) here, until we've rewritten it completely
# in Python.
#############################################################################

# The Python version will make sure we have a properly initialized root
# directory and it will have fetched the depot_tools.
set -e
V8_ROOT=$PWD/v8-riscv
echo $PWD
export PATH="$PWD/depot_tools:/opt/riscv/bin/:$PATH"
cd "$V8_ROOT/v8"

# Re-use the binary produced by the Python version to avoid recompiling.
D8="$V8_ROOT/v8/out.gn/riscv64.pts.release/d8"

# JetStream2.0
rm -rf JetStream
git clone -b JetStream2.0 --single-branch  https://github.com/WebKit/JetStream.git
cd JetStream
wget  https://raw.githubusercontent.com/plctlab/riscv-ci/main/patches/0001-Make-it-so-JetStream2-can-run-with-the-d8-shell.patch
patch -p1 <0001-Make-it-so-JetStream2-can-run-with-the-d8-shell.patch

# show directory
cd "$V8_ROOT/v8" && ls -al .

run_get_builtinsize() {
  qemu-riscv64 -h
  ls -l  /usr/local
  ls -l  /usr/local/bin
  ls -l  /usr/local/bin/plugin
  ls -l  /usr/local/riscv
  cd "$V8_ROOT/v8"
  # The Python version already generates the same output, so we just repeat this
  # to get it dumped into a file so we can diff it against the last successful.
  qemu-riscv64 -L /usr/local/riscv/sysroot $D8 --print-builtin-size ./test/benchmarks/data/sunspider/3d-cube.js > logbtsize-now.txt 2>&1
  wc -l logbtsize-now.txt
}

run_get_lastSuccessfulBuild_info() {
  cd "$V8_ROOT/v8"
  # Get the lastSuccessfulBuild number
  BUILD_NUM=$(curl -s https://ci.rvperf.org/view/V8/job/v8-upstream-master-fastcheck-riscv64-pts/lastSuccessfulBuild/buildNumber | grep -o '[0-9]*')
  curl -s "https://ci.rvperf.org/view/V8/job/v8-upstream-master-fastcheck-riscv64-pts/$BUILD_NUM/consoleFull" |  tr -d '\r'  > lastSuccessfulBuild.log 2>&1
  wc -l lastSuccessfulBuild.log
  echo "run_get_lastSuccessfulBuild_info $BUILD_NUMBER $BUILD_ID $WORKSPACE Done"
}

run_cmp_builtinsize() {
  cd "$V8_ROOT/v8"
  grep -E '^[A-Z]{3} Builtin, ' lastSuccessfulBuild.log >logbtsize-lsb.txt 2>&1
  wc -l logbtsize-lsb.txt
  wc -l logbtsize-now.txt
  echo "DIFF builtin size"
  diff logbtsize-lsb.txt logbtsize-now.txt || true
}

run_Sunspider() {
  cd "$V8_ROOT/v8/"
  # Clean the log files before we start appending to them.
  for i in {1..3}; do
    rm -f ss-benchmark-${i}.log
  done
  for i in {1..3}; do
    for file in test/benchmarks/data/sunspider/*.js; do
      echo "Running $(basename "$file")" >> ss-benchmark-${i}.log 2>&1
      qemu-riscv64 -L /usr/local/riscv/sysroot -plugin /usr/local/bin/plugin/libinsn.so -d plugin $D8 "$file" >> ss-benchmark-${i}.log 2>&1
    done
  done
  for i in {1..3}; do
    grep -E "^(Running|total insn)" ss-benchmark-${i}.log | awk '{print($NF)}' | paste -d ' ' - - > ss-result-${i}.log
  done
  # This line prints the CI result into the log so that the next CI can use this information for comparison.
  awk '{a[FNR]=$1; b[FNR]+=$2} END{for(i=1;i<=FNR;i++) printf("Benchmarking %s\ntotal insn %d\n", a[i], b[i]/3)}' ss-result-1.log ss-result-2.log ss-result-3.log
  awk '{a[FNR]=$1; b[FNR]+=$2} END{for(i=1;i<=FNR;i++) printf("%s %d\n", a[i], b[i]/3)}' ss-result-1.log ss-result-2.log ss-result-3.log >ss-result-now.txt
  ls -al ss-result*
  wc -l ss-result*
  cat ss-result-now.txt
}

run_cmp_Sunspider() {
  cd "$V8_ROOT/v8/"
  grep -E "^(Benchmarking|total insn)" lastSuccessfulBuild.log | awk '{print($NF)}' | paste -d ' ' - - >ss-result-lsb.txt 2>&1
  wc -l ss-result-lsb.txt
  echo "Sunspider lastSuccessfulBuild result: "
  cat ss-result-lsb.txt
  echo "Sunspider current build result: "
  cat ss-result-now.txt
  echo "Sunspider diff: "
  diff ss-result-lsb.txt ss-result-now.txt || true
  awk '{name[FNR]=$1; score[NR]=$2} END{for(i=1;i<=FNR;i++) printf("%27s lsb:%10d curr:%10d diff:%9d ratio:%6.2f%%\n",name[i],score[i],score[i+FNR],score[i]-score[i+FNR],(score[i]-score[i+FNR])/score[i]*100)}' ss-result-lsb.txt ss-result-now.txt ||true
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
    echo "Running Group: $prefix Name: $suffix"

    #qemu-riscv64 -L /usr/local/riscv/sysroot -plugin /usr/local/bin/plugin/libinsn.so -d plugin $D8 ./pts-jetstream.js ./cli.js -- $suffix || exit 7
    #just run without insn plugin
    qemu-riscv64 -L /usr/local/riscv/sysroot $D8 ./pts-jetstream.js ./cli.js -- $suffix || exit 5
  done
}

cd "$V8_ROOT/v8"

git log -1

run_get_builtinsize
run_get_lastSuccessfulBuild_info
run_cmp_builtinsize
#run_JetStream
run_Sunspider
run_cmp_Sunspider
