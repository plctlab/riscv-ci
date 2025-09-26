#!/usr/bin/env python3

import tools.v8 as v8
import tools.variants as variants

v8.fetch_depot_tools()
v8.fetch()

v8.build(variants.RISCV64_OPTDEBUG_VLEN128_SIM)
v8.build(variants.RISCV64_RELEASE_VLEN128_SIM)

v8.run_tests(variants.RISCV64_OPTDEBUG_VLEN128_SIM, fast=True)
v8.run_tests(variants.RISCV64_RELEASE_VLEN128_SIM, fast=True)
