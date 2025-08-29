#!/usr/bin/env python3

import glob
import difflib
import os
import traceback

from io import TextIOWrapper
from urllib.request import urlopen

import tools.v8 as v8
import tools.variants as variants

JOB = "v8-upstream-master-fastcheck-riscv64-pts"
BUILD_VIEW_URL = "https://ci.rvperf.org/view/V8/"
BUILD_ID = os.getenv("BUILD_ID", "<unknown>")

SECTION_MARKER       = "--++==**@@"
SECTION_MARKER_BEGIN = SECTION_MARKER + " BEGIN:"
SECTION_MARKER_END   = SECTION_MARKER + " END:"

SECTION_BUILTIN_SIZES = "builtin sizes"

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
""", wrapper=[
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

    # TODO(kasperl@rivosinc.com): Same output as bash variant for now.
    def print_bash_output(self):
        print(f"{len(self.log)} lastSuccessfulBuild.log")
        BUILD_NUMBER = os.getenv("BUILD_NUMBER", "<unknown>")
        WORKSPACE = os.getenv("WORKSPACE", "<unknown>")
        print(f"run_get_lastSuccessfulBuild_info "
              f"{BUILD_NUMBER} {BUILD_ID} {WORKSPACE} "
              f"Done")

# Print information about builtin sizes.
def report_builtin_sizes(last):
    builtin_sizes = v8.run_d8(RISCV64_PTS_RELEASE, [
            "--print-builtin-size",
            os.path.join("test", "benchmarks", "data", "sunspider", "3d-cube.js")
        ],
        cwd=os.path.join(v8.ROOT_DIR, "v8"),
        echo_output=False)
    BuildInformation.print_section(SECTION_BUILTIN_SIZES, builtin_sizes)
    if last is None:
        print("No previous build found: Skipping builtin size comparison", flush=True)
        return
    if not SECTION_BUILTIN_SIZES in last.sections:
        print(f"Didn't find section in output for build {last.id}", flush=True)
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
        print(f"No differences in builtin sizes from build {last.id} to {BUILD_ID}",
              flush=True)
    else:
        print("Builtin sizes changed:")
        for line in diff: print(line, flush=True)

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
v8.fetch()
v8.fetch_sysroot("riscv64")
v8.build_d8(RISCV64_PTS_RELEASE)

last = last_successful_build()
report_builtin_sizes(last)
if last is not None: last.print_bash_output()
sunspider = find_sunspider_benchmarks()
run_benchmarks(RISCV64_PTS_RELEASE, sunspider)

# TODO(kasperl@rivosinc.com): Print a marker so we can more easily find the
# cutoff between the Python and the bash implementations.
print("======================================================", flush=True)
