#!/usr/bin/env python3

from tools.lkgb import *
from tools.summary import Summary
import tools.v8 as v8
import tools.variants as variants

JOB = "v8-upstream-master-riscv64-jetstream"

JETSTREAM_COMMIT = "f8e3d7e50ed5c7ac071a9d90d3ee36cb68a8678c"

# Run a list of benchmarks.
def run_benchmarks(variant, suite, benchmarks, last):
    summary = Summary(f"Benchmarks - {suite}")
    results = dict()
    for benchmark in benchmarks:
        section = f"{SECTION_BENCHMARK}{suite}:{benchmark}"
        output = results.get(section)
        if output is None: results[section] = output = []
        print(f"Running {suite}:{benchmark}", flush=True)
        # We run the benchmarks with the predictable flag to try to better isolate
        # the per-change improvements or regressions. The flag is rather intrusive,
        # so it may make the benchmarks less reflecting of real-world performance.
        arguments = [
            "--predictable",
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
    for section in sorted(results.keys()):
        name = section.split(':')[-1]
        # TODO(kasperl@rivosinc.com): For now, we just skip benchmarks where we don't
        # have previous results. Maybe we should print something for them?
        if not section in last.sections: continue
        output_now = results[section]
        output_last = last.sections[section]
        average_now = compute_average("Average:", output_now)
        average_last = compute_average("Average:", output_last)
        diff = average_last - average_now
        ratio = diff / average_last * 100.0
        summary.add_details(
            f"{name:>27s} "
            f"lsb:{int(average_last):10d} "
            f"curr:{int(average_now):10d} "
            f"diff:{int(diff):9d} "
            f"ratio:{ratio:6.2f}%")

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
