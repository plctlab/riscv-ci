set -e

git clone https://github.com/mozilla/gecko-dev.git

curl -s https://raw.githubusercontent.com/chromium/chromium/main/tools/clang/scripts/update.py | python3 - --output-dir=$PWD/clang
export PATH="$PWD/clang/bin/"


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
ac_add_options --disable-wasm-memory64
ac_add_options --enable-simulator=riscv64
ac_add_options --enable-jit" >> mozconfig

export MOZCONFIG=$PWD/mozconfig

cd gecko-dev

git log -1

./mach build

./mach jittest

