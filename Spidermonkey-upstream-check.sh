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

# Disable debug checks to better match a release build of Firefox.
ac_add_options --enable-debug

# Use a separate objdir for optimized builds to allow easy
# switching between optimized and debug builds while developing.
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-opt-@CONFIG_GUESS@
ac_add_options --enable-jitspew
ac_add_options --disable-rust-simd
ac_add_options --enable-simulator=riscv64
ac_add_options --enable-jit" > mozconfig

export MOZCONFIG=$PWD/mozconfig

git --version

rm -rf ./firefox
if [ -d 'firefox' ]; then
   cd firefox
   git pull
else
   curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -L -O 
   python3 bootstrap.py  --application-choice=js --no-interactive --no-system-changes
   cd firefox
fi

git log HEAD~1..HEAD

rm -rf ./obj-opt-x86_64-pc-linux-gnu

./mach build

./mach jstests -t 400 --format automation

./mach jit-test -- -t 400 --format automation
./mach jit-test -- --ion -t 800 --format automation --no-progress
./mach jsapi-tests
