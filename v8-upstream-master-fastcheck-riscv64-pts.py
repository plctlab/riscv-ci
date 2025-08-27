#!/usr/bin/env python3

import glob
import os
from urllib.request import urlopen

import tools.v8 as v8
import tools.variants as variants

URL_BASE = "https://ci.rvperf.org/view/V8/job/v8-upstream-master-fastcheck-riscv64-pts"

# TODO(kasperl@rivosinc.com): Change this to be a native build and run
# it on qemu-riscv64.
RISCV64_PTS_RELEASE = variants.Variant("riscv64.pts.release", f"""
  is_component_build=false
  is_debug=false
  target_cpu="{variants.TARGET_CPU}"
  v8_target_cpu="riscv64"
  v8_enable_backtrace=true
  v8_enable_disassembler=true
  v8_enable_object_print=true
  v8_enable_verify_heap=true
""")

# Print information about builtin sizes.
def report_builtin_sizes():
    builtin_sizes = v8.run_d8(RISCV64_PTS_RELEASE, [
            "--print-builtin-size",
            os.path.join("test", "benchmarks", "data", "sunspider", "3d-cube.js")
        ],
        cwd=os.path.join(v8.ROOT_DIR, "v8"))
    # TODO(kasperl@rivosinc.com): Same output as bash variant for now.
    print(f"{len(builtin_sizes)} logbtsize-now.txt")

# Gather information about last successful build.
def last_successful_build_number():
    success = None
    with urlopen(f"{URL_BASE}/lastSuccessfulBuild/buildNumber") as response:
        success = int(response.read().decode('utf-8').strip())
    with urlopen(f"{URL_BASE}/{success}/consoleFull") as response:
        lines = response.readlines()
        # TODO(kasperl@rivosinc.com): Same output as bash variant for now.
        print(f"{len(lines)} lastSuccessfulBuild.log")
        BUILD_NUMBER = os.getenv("BUILD_NUMBER", "<unknown>")
        BUILD_ID = os.getenv("BUILD_ID", "<unknown>")
        WORKSPACE = os.getenv("WORKSPACE", "<unknown>")
        print(f"run_get_lastSuccessfulBuild_info "
              f"{BUILD_NUMBER} {BUILD_ID} {WORKSPACE} "
              f"Done")
    return success

# Returns a list of all the SunSpider benchmarks.
def find_sunspider_benchmarks():
    return list(glob.iglob(
        os.path.join("test", "benchmarks", "data", "sunspider", "*.js"),
        root_dir=os.path.join(v8.ROOT_DIR, "v8")))

# Run a list of benchmarks.
def run_benchmarks(variant, benchmarks):
    iterations = 3
    for iteration in range(iterations):
        for benchmark in benchmarks:
            name = os.path.basename(benchmark)
            print(f"Running {name} - attempt {iteration + 1}/{iterations}", flush=True)
            v8.run_d8(variant, [benchmark], cwd=os.path.join(v8.ROOT_DIR, "v8"))
            # TODO(kasperl@rivosinc.com): Gather statistics and report them.


v8.fetch_depot_tools()
v8.fetch(clean=True)
v8.build_d8(RISCV64_PTS_RELEASE)

report_builtin_sizes()
last_successful_build_number()
sunspider = find_sunspider_benchmarks()
run_benchmarks(RISCV64_PTS_RELEASE, sunspider)
