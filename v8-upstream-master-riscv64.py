#!/usr/bin/env python3

import tools.v8 as v8

v8.fetch_depot_tools()
v8.fetch_v8(v8.ROOT_DIR, clean=True)

v8.build_v8(v8.ROOT_DIR, "riscv64.optdebug.sim", v8.RISCV64_OPTDEBUG_SIM_CONFIG)
v8.build_v8(v8.ROOT_DIR, "riscv64.release.sim", v8.RISCV64_RELEASE_SIM_CONFIG)

# NOTE(2021-08-21): Run 10 times to provoke random bugs. Apparently, this is the
# only difference between the normal runners and the 'fastcheck' variants.
for iteration in range(10):
    v8.run_tests_all(v8.ROOT_DIR, "riscv64.optdebug.sim")
    v8.run_tests_all(v8.ROOT_DIR, "riscv64.release.sim")
