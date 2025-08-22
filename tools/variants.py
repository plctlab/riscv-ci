import os
import platform

TARGET_CPU_MAPPING = { "x86_64": "x64", "xxx": "x86" }
TARGET_CPU = TARGET_CPU_MAPPING.get(platform.machine(), platform.machine())

class Variant:
    def __init__(self, name, config):
        self.name = name
        self.config = config

    def output_directory(self):
        return os.path.join("out.gn", self.name)

    def gn_generate_args(self):
        lines = self.config.splitlines()
        return " ".join([x.strip() for x in lines if x != ""])

RISCV32_OPTDEBUG_SIM = Variant("riscv32.optdebug.sim", f"""
  is_component_build=false
  is_debug=true
  target_cpu="x86"
  v8_enable_backtrace=true
  v8_enable_slow_dchecks=true
  v8_optimized_debug=true
  v8_target_cpu="riscv32"
""")

RISCV64_OPTDEBUG_SIM = Variant("riscv64.optdebug.sim", f"""
  is_component_build=false
  is_debug=true
  target_cpu="{TARGET_CPU}"
  v8_enable_backtrace=true
  v8_enable_slow_dchecks=true
  v8_optimized_debug=true
  v8_target_cpu="riscv64"
""")

RISCV32_RELEASE_SIM = Variant("riscv32.release.sim", f"""
  is_component_build=false
  is_debug=false
  target_cpu="x86"
  v8_target_cpu="riscv32"
""")

RISCV64_RELEASE_SIM = Variant("riscv64.release.sim", f"""
  is_component_build=false
  is_debug=false
  target_cpu="{TARGET_CPU}"
  v8_target_cpu="riscv64"
""")

RISCV64_PTRCOMP_RELEASE_SIM = Variant("riscv64.ptrcomp.release.sim", f"""
  is_component_build=false
  is_debug=false
  target_cpu="{TARGET_CPU}"
  v8_target_cpu="riscv64"
  v8_enable_pointer_compression=true
""")
