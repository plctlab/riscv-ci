#!/bin/bash
git -C riscv-ci pull || git clone https://github.com/plctlab/riscv-ci riscv-ci
python3 $PWD/riscv-ci/v8-upstream-master-fastcheck-riscv64-pts.py

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

# Fetch and patch JetStream 2.0.
rm -rf JetStream
git clone -b JetStream2.0 --single-branch https://github.com/WebKit/JetStream.git
cd JetStream
wget https://raw.githubusercontent.com/plctlab/riscv-ci/main/patches/0001-Make-it-so-JetStream2-can-run-with-the-d8-shell.patch
patch -p1 <0001-Make-it-so-JetStream2-can-run-with-the-d8-shell.patch

# Show directory.
cd "$V8_ROOT/v8" && ls -al .

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

#run_JetStream
