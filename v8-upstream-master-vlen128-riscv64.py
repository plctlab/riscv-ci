#!/usr/bin/env python3

import tools.v8 as v8
import tools.variants as variants

v8.fetch_depot_tools()
v8.fetch()

v8.build(variants.RISCV64_OPTDEBUG_SIM)
v8.build(variants.RISCV64_RELEASE_SIM_VLEN128)

v8.run_tests(variants.RISCV64_OPTDEBUG_SIM)
v8.run_tests(variants.RISCV64_RELEASE_SIM_VLEN128)
