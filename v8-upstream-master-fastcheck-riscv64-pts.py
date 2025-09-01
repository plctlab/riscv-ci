#!/usr/bin/env python3

import glob
import difflib
import os
import traceback

from io import TextIOWrapper
from urllib.request import urlopen

from tools.summary import Summary
import tools.v8 as v8
import tools.variants as variants

JOB = "v8-upstream-master-fastcheck-riscv64-pts"
BUILD_VIEW_URL = "https://ci.rvperf.org/view/V8/"
BUILD_ID = os.getenv("BUILD_ID", "<unknown>")

SECTION_MARKER       = "--++==**@@"
SECTION_MARKER_BEGIN = SECTION_MARKER + " BEGIN:"
SECTION_MARKER_END   = SECTION_MARKER + " END:"

SECTION_BUILTIN_SIZES = "builtin sizes"
SECTION_BENCHMARK     = "benchmark:"

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

# We represent the information about previous builds as instances of
# the `BuildInformation` class.
class BuildInformation:
    def __init__(self, job, id, log):
        self.job = job
        self.id = id
        self.log = log
        self.sections = BuildInformation.find_sections(log)

    # The logs from a build may contain marked sections. Find them all
    # in one single pass.
    def find_sections(log):
        sections = dict()
        current = None
        begin = None
        for index in range(len(log)):
            line = log[index]
            if line.startswith(SECTION_MARKER):
                if begin is not None:
                    if not line.startswith(SECTION_MARKER_END):
                        raise RuntimeError(
                            f"Section '{current}' is not properly terminated by end marker")
                    name = line[len(SECTION_MARKER_END):].strip()
                    if current != name:
                        raise RuntimeError(
                            f"Section '{current}' terminated by end marker for '{name}'")
                    sections[current] = log[begin + 1 : index]
                    current = begin = None
                if line.startswith(SECTION_MARKER_BEGIN):
                    current = line[len(SECTION_MARKER_BEGIN):].strip()
                    if current in sections:
                        raise RuntimeError(
                            f"Section '{current}' has already been seen")
                    begin = index
        if current is not None:
            raise RuntimeError(
                f"Section '{current}' is not properly terminated by end marker")
        return sections

    def print_section(name, lines):
        print(f"{SECTION_MARKER_BEGIN} {name}")
        for line in lines: print(line)
        print(f"{SECTION_MARKER_END} {name}", flush=True)

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

# Gather information about last successful build.
def last_successful_build():
    # If fetching or decoding the build information fails, we print the exception
    # but return 'none' as the result of this method. This allows us to continue
    # and produce a log from this run that can be used by future runs.
    try:
        url_base = f"{BUILD_VIEW_URL}/job/{JOB}/"
        with urlopen(f"{url_base}/lastSuccessfulBuild/buildNumber") as response:
            id = int(response.read().decode('utf-8').strip())
        with urlopen(f"{url_base}/{id}/consoleFull") as response:
            # Create a log with all the lines from the console. Make sure to
            # remove trailing whitespace (newlines, etc.), so the log gets a
            # bit easier to work with going forward.
            log = []
            for line in TextIOWrapper(response, encoding="utf-8").readlines():
                log.append(line.rstrip())
        return BuildInformation(JOB, id, log)
    except Exception:
        print(traceback.format_exc())
        return None

# Returns a list of all the SunSpider benchmarks.
def find_sunspider_benchmarks():
    return list(glob.iglob(
        os.path.join("test", "benchmarks", "data", "sunspider", "*.js"),
        root_dir=os.path.join(v8.ROOT_DIR, "v8")))

# Compute the average of a sequence of numbers in log output.
def compute_average(prefix, output):
    sum = 0.0
    count = 0
    for line in output:
        if not line.startswith(prefix): continue
        sum += float(line[len(prefix):])
        count += 1
    return sum / count

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
            print(f"Running {suite}:{name} - attempt {iteration + 1}/{iterations}", flush=True)
            raw = v8.run_d8(variant, [benchmark], prefix=prefix, echo_output=False, cwd=srcdir)
            output.extend([line for line in raw if line.startswith("total insns:")])
    for section, output in results.items():
        BuildInformation.print_section(section, output)
    if last is None:
        summary.set_status("No previous build found")
        return
    summary.set_status(
        f"Compared {last.id} (lsb) and {BUILD_ID} (curr)")
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

last = last_successful_build()
report_builtin_sizes(last)
sunspider = find_sunspider_benchmarks()
run_benchmarks(RISCV64_PTS_RELEASE, "sunspider", sunspider, last)

Summary.show_all()
