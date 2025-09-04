# LKGB: Last known good build.

import os
import traceback

from io import TextIOWrapper
from urllib.request import urlopen

BUILD_VIEW_URL = "https://ci.rvperf.org/view/V8/"
BUILD_ID = os.getenv("BUILD_ID", "<unknown>")

SECTION_MARKER       = "--++==**@@"
SECTION_MARKER_BEGIN = SECTION_MARKER + " BEGIN:"
SECTION_MARKER_END   = SECTION_MARKER + " END:"

SECTION_BUILTIN_SIZES = "builtin sizes"
SECTION_BENCHMARK     = "benchmark:"

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

# Gather information about last successful build.
def last_successful_build(job):
    # If fetching or decoding the build information fails, we print the exception
    # but return 'none' as the result of this method. This allows us to continue
    # and produce a log from this run that can be used by future runs.
    try:
        url_base = f"{BUILD_VIEW_URL}/job/{job}/"
        with urlopen(f"{url_base}/lastSuccessfulBuild/buildNumber") as response:
            id = int(response.read().decode('utf-8').strip())
        with urlopen(f"{url_base}/{id}/consoleFull") as response:
            # Create a log with all the lines from the console. Make sure to
            # remove trailing whitespace (newlines, etc.), so the log gets a
            # bit easier to work with going forward.
            log = []
            for line in TextIOWrapper(response, encoding="utf-8").readlines():
                log.append(line.rstrip())
        return BuildInformation(job, id, log)
    except Exception:
        print(traceback.format_exc())
        return None

# Compute the average of a sequence of numbers in log output. Returns None
# if we can't find the prefix in the output.
def compute_average(prefix, output):
    sum = 0.0
    count = 0
    for line in output:
        if not line.startswith(prefix): continue
        sum += float(line[len(prefix):])
        count += 1
    if count == 0: return None
    return sum / count
