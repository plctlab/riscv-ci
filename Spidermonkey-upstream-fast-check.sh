#!/bin/bash

## System preparation
## sudo apt-get install -y bash findutils gzip libxml2 m4 make perl tar unzip watchman rustc

set -e


rustup toolchain install stable
rustup toolchain list -v
export PATH=/home/jenkinsbot/snap/rustup/common/rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/:$PATH
rustc --version

rm -rf $HOME/.mozbuild

echo "# Build only the JS shell
ac_add_options --enable-application=js

# Enable optimization for speed
ac_add_options  --enable-optimize

ac_add_options  --disable-debug
# Use a separate objdir for optimized builds to allow easy
# switching between optimized and debug builds while developing.
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-opt-@CONFIG_GUESS@
ac_add_options --enable-jitspew
ac_add_options --disable-rust-simd
ac_add_options --enable-gczeal
ac_add_options --enable-simulator=riscv64
ac_add_options --enable-jit
ac_add_options --enable-wasm-jspi" > mozconfig

export MOZCONFIG=$PWD/mozconfig

rm -rf ./firefox

curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -L -O 
python3 bootstrap.py  --application-choice=js --no-interactive --no-system-changes
cd firefox

git log HEAD~1..HEAD

./mach clobber
./mach build

./mach jsapi-tests
./mach jstests -t 400 --format automation
./mach jit-test -- --ion -t 400 --format automation --no-progress
