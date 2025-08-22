#!/usr/bin/env python3

import tools.v8 as v8
import tools.variants as variants

v8.fetch_depot_tools()
v8.fetch()

v8.build(variants.RISCV32_OPTDEBUG_SIM)
v8.build(variants.RISCV32_RELEASE_SIM)

# TODO(kasperl@rivosinc.com): Should we run the stress tests here too?
v8.run_tests(variants.RISCV32_OPTDEBUG_SIM, fast=True, stress=False)
v8.run_tests(variants.RISCV32_RELEASE_SIM, fast=True)
