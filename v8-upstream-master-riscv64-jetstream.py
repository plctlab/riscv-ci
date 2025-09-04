#!/usr/bin/env python3

from tools.lkgb import *
from tools.summary import Summary
import tools.v8 as v8
import tools.variants as variants

JOB = "v8-upstream-master-riscv64-jetstream"

JETSTREAM_COMMIT = "f8e3d7e50ed5c7ac071a9d90d3ee36cb68a8678c"

# Helper to compute the result of running a JetStream benchmark. We prefer
# the "Average:" scores for now, but if we can't find that we'll settle for
# the "Score:" ones. The average scores disregard the warmup cost, so they
# reflect the peak performance better.
def compute_result(output):
    if output is None: return None
    average = compute_average("Average:", output)
    if average is not None: return average
    return compute_average("Score:", output)

# Run a list of benchmarks.
def run_benchmarks(variant, suite, benchmarks, last):
    summary = Summary(f"Benchmarks - {suite}")
    results = dict()
    for benchmark in benchmarks:
        section = f"{SECTION_BENCHMARK}{suite}:{benchmark}"
        output = results.get(section)
        if output is None: results[section] = output = []
        print(f"Running {suite}:{benchmark}", flush=True)
        # We can't run the benchmarks with the predictable flag, because some of
        # them simply take too long because they need OSR to get the optimizations
        # to kick in.
        arguments = [
            "cli.js",
            "--",
            "--iteration-count=4",
            "--worst-case-count=2",
            benchmark,
        ]
        for line in v8.run_d8(variant, arguments, cwd=v8.JETSTREAM_DIR):
            # The results for an individual benchmark are indented. Those are the
            # results we're looking for here, so filter everything else out.
            if not line.startswith(" " * 4): continue
            stripped = line.strip()
            if stripped.startswith("Average:") or stripped.startswith("Score:"):
                output.append(stripped)
    for section, output in results.items():
        BuildInformation.print_section(section, output)
    if last is None:
        summary.set_status("No previous build found")
        return
    summary.set_status(
        f"Compared builds {last.id} (lsb) and {BUILD_ID} (curr)")
    sections = set(results.keys()) | set(last.sections.keys())
    for section in sorted(sections):
        name = section.split(':')[-1]
        output_now = results.get(section)
        output_last = last.sections.get(section)
        # Compute the current and previous results if we can find them
        # in the logs. Deal with the case where we can't by putting a
        # recognizable marker in the output.
        curr = lsb = "?" * 10
        result_now = compute_result(output_now)
        if result_now is not None: curr = f"{result_now:7.2f}"
        result_last = compute_result(output_last)
        if result_last is not None: lsb = f"{result_last:7.2f}"
        # Compute the difference if we've got both current and previous results.
        diff = ratio = "?" * 9
        if (result_now is not None) and (result_last is not None):
            diff = f"{result_last - result_now:6.2f}"
            ratio = f"{diff / result_last * 100.0:6.2f}"
        # Add a single line to the summary with the details.
        summary.add_details(
            f"{name:>27s} lsb:{lsb} curr:{curr} diff:{diff} ratio:{ratio}%")

v8.fetch_depot_tools()
v8.fetch_jetstream(JETSTREAM_COMMIT)
v8.fetch()
v8.build_d8(variants.RISCV64_RELEASE_SIM)

last = last_successful_build(JOB)

jetstream = sorted(v8.run_d8(
    variants.RISCV64_RELEASE_SIM,
    ["cli.js", "--", "--dump-test-list"],
    echo_output=False,
    cwd=v8.JETSTREAM_DIR))
run_benchmarks(variants.RISCV64_RELEASE_SIM, "jetstream", jetstream, last)

Summary.show_all()
