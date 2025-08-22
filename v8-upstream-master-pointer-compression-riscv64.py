#!/usr/bin/env python3

import tools.v8 as v8
import tools.variants as variants

v8.fetch_depot_tools()
v8.fetch()

# TODO(kasperl@rivosinc.com): For now, we only run a limited number of tests
# with pointer compression enabled. We should reconsider that.
v8.build(variants.RISCV64_PTRCOMP_RELEASE_SIM)
v8.run_tests(variants.RISCV64_PTRCOMP_RELEASE_SIM, fast=True)
