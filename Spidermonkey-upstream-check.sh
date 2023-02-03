#!/bin/bash

## System preparation
## sudo apt-get install -y bash findutils gzip libxml2 m4 make perl tar unzip watchman rustc

set -e

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
ac_add_options --disable-bootstrap
ac_add_options --disable-rust-simd
ac_add_options --enable-simulator=riscv64
ac_add_options --enable-jit" > mozconfig

export MOZCONFIG=$PWD/mozconfig

python3 -m pip install --user mercurial
export PATH="$(python3 -m site --user-base)/bin:$PATH"
hg version


if [ -d "mozilla-unified" ];then
   cd mozilla-unified
   hg pull
else
   curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O 
   python3 bootstrap.py  --application-choice=js --no-interactive --no-system-changes
   cd mozilla-unified
fi

hg log -l 1

rm -rf ./obj-opt-x86_64-pc-linux-gnu

./mach build

./mach jsapi-tests
./mach jstests  --format automation
./mach jittest -t 400 --format automation

