#!/usr/bin/env python3

import glob
import difflib
import os

from tools.lkgb import *
from tools.summary import Summary
import tools.v8 as v8
import tools.variants as variants

JOB = "v8-upstream-master-fastcheck-riscv64-pts"

RISCV64_PTS_RELEASE = variants.Variant("riscv64.pts.release", f"""
  is_clang=true
  is_component_build=false
  is_debug=false
  target_cpu="riscv64"
  treat_warnings_as_errors=false
  v8_target_cpu="riscv64"
  v8_enable_backtrace=true
  v8_enable_disassembler=true
  v8_enable_object_print=true
  v8_enable_verify_heap=true
""", prefix=[
  "qemu-riscv64",
  "-L",
  os.path.join(os.path.sep, "usr", "local", "riscv", "sysroot")
])

# Print information about builtin sizes.
def report_builtin_sizes(last):
    summary = Summary("Builtin sizes")
    builtin_sizes = v8.run_d8(RISCV64_PTS_RELEASE, [
            "--print-builtin-size",
            os.path.join("test", "benchmarks", "data", "sunspider", "3d-cube.js")
        ],
        cwd=os.path.join(v8.ROOT_DIR, "v8"),
        echo_output=False)
    BuildInformation.print_section(SECTION_BUILTIN_SIZES, builtin_sizes)
    if last is None:
        summary.set_status("No previous build found")
        return
    if not SECTION_BUILTIN_SIZES in last.sections:
        summary.set_status(f"Didn't find section in output for build {last.id}")
        return
    # Compare the current build's builtin sizes to the last build's builtin
    # sizes and report any differences.
    diff = list(difflib.unified_diff(
        last.sections[SECTION_BUILTIN_SIZES],
        builtin_sizes,
        n=0,
        fromfile=f"Build {last.id}",
        tofile=f"Build {BUILD_ID}"))
    if len(diff) == 0:
        summary.set_status(f"No changes from build {last.id} to {BUILD_ID}")
    else:
        summary.set_status("Found changes")
        summary.add_details(diff)

# Returns a list of all the SunSpider benchmarks.
def find_sunspider_benchmarks():
    return list(glob.iglob(
        os.path.join("test", "benchmarks", "data", "sunspider", "*.js"),
        root_dir=os.path.join(v8.ROOT_DIR, "v8")))

# Run a list of benchmarks.
def run_benchmarks(variant, suite, benchmarks, last, iterations=3):
    summary = Summary(f"Benchmarks - {suite}")
    srcdir = os.path.join(v8.ROOT_DIR, "v8")
    prefix = [
        "-plugin",
        os.path.join(os.path.sep, "usr", "local", "bin", "plugin", "libinsn.so"),
        "-d",
        "plugin",
    ]
    results = dict()
    for iteration in range(iterations):
        for benchmark in benchmarks:
            name = os.path.basename(benchmark)
            section = f"{SECTION_BENCHMARK}{suite}:{name}"
            output = results.get(section)
            if output is None: results[section] = output = []
            print(f"Running {suite}:{name} - iteration {iteration + 1}/{iterations}", flush=True)
            # We run the benchmarks with the predictable flag to try to better isolate
            # the per-change improvements or regressions. The flag is rather intrusive,
            # so it may make the benchmarks less reflecting of real-world performance.
            raw = v8.run_d8(variant, ["--predictable", benchmark],
                            prefix=prefix,
                            echo_output=False,
                            cwd=srcdir)
            output.extend([line for line in raw if line.startswith("total insns:")])
    for section, output in results.items():
        BuildInformation.print_section(section, output)
    if last is None:
        summary.set_status("No previous build found")
        return
    summary.set_status(
        f"Compared builds {last.id} (lsb) and {BUILD_ID} (curr)")
    for section in sorted(results.keys()):
        name = section.split(':')[-1]
        # TODO(kasperl@rivosinc.com): For now, we just skip benchmarks where we don't
        # have previous results. Maybe we should print something for them?
        if not section in last.sections: continue
        output_now = results[section]
        output_last = last.sections[section]
        average_now = compute_average("total insns:", output_now)
        average_last = compute_average("total insns:", output_last)
        diff = average_last - average_now
        ratio = diff / average_last * 100.0
        summary.add_details(
            f"{name:>27s} "
            f"lsb:{int(average_last):10d} "
            f"curr:{int(average_now):10d} "
            f"diff:{int(diff):9d} "
            f"ratio:{ratio:6.2f}%")

v8.fetch_depot_tools()
v8.fetch()
v8.fetch_sysroot("riscv64")
v8.build_d8(RISCV64_PTS_RELEASE)

last = last_successful_build(JOB)
report_builtin_sizes(last)
sunspider = find_sunspider_benchmarks()
run_benchmarks(RISCV64_PTS_RELEASE, "sunspider", sunspider, last)

Summary.show_all()
