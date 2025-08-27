import os
import shutil
import subprocess
import sys

# TODO(kasperl@rivosinc.com): Enable ccache to speed up compilation on the bots.

CWD = os.getcwd()
PYTHON = sys.executable

ROOT_DIR = os.path.join(CWD, "v8-riscv")

DEPOT_TOOLS_URL = "https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR = os.path.join(CWD, "depot_tools")

FETCH_PATH     = os.path.join(DEPOT_TOOLS_DIR, "fetch")
GCLIENT_PATH   = os.path.join(DEPOT_TOOLS_DIR, "gclient")
GN_PATH        = os.path.join(DEPOT_TOOLS_DIR, "gn")
AUTONINJA_PATH = os.path.join(DEPOT_TOOLS_DIR, "autoninja")

# Cache the last working directory in a variable, so we can print something
# useful whenever we change the working directory.
_last_cwd = CWD

# Helper function that runs a command given by the arguments in a subprocess.
# Notice that we default to checking that it runs successfully and we show
# useful information about the working directory.
def _exec(arguments, cwd=CWD, check=True, capture_output=False):
    global _last_cwd
    if cwd != _last_cwd:
        print("+ " + "cd " + cwd, flush=True)
        _last_cwd = cwd
    # Extend the PATH of the subprocess, so the correct depot_tools are used.
    # This is necessary at least when calling out to tools/run-tests.py.
    env = dict(os.environ)
    env["PATH"] = DEPOT_TOOLS_DIR + os.pathsep + env["PATH"]
    # If we're capturing the output, we redirect stderr to stdout and ask
    # the subprocess to pipe stdout to us.
    stdout = None
    stderr = None
    if capture_output:
        stdout = subprocess.PIPE
        stderr = subprocess.STDOUT
    # Run the subprocess.
    commandline = " ".join([f"'{x}'" if " " in x else x for x in arguments])
    print(f"+ {commandline}", flush=True)
    process = subprocess.Popen(
        arguments,
        cwd=cwd,
        env=env,
        stderr=stderr,
        stdout=stdout,
        text=True
    )
    # Capture the output (if necessary) and write it to stdout as we go along.
    output = None
    if capture_output:
        output = []
        for line in process.stdout:
            sys.stdout.write(line)
            output.append(line)
    # Wait for the subprocess to terminate and optionally check if the
    # exit code indicates success.
    retcode = process.wait()
    if check and retcode != 0:
        raise subprocess.CalledProcessError(arguments[0], retcode)
    return output

def fetch_depot_tools():
    if os.path.isdir(DEPOT_TOOLS_DIR): return
    _exec(["git", "clone", DEPOT_TOOLS_URL, DEPOT_TOOLS_DIR])

def fetch(clean=False):
    if clean and os.path.isdir(ROOT_DIR):
        shutil.rmtree(ROOT_DIR, ignore_errors=True)
    if not os.path.isdir(ROOT_DIR):
        os.mkdir(ROOT_DIR)
    srcdir = os.path.join(ROOT_DIR, "v8")
    if os.path.isdir(srcdir):
        # We already have a checked out version of v8, so we assume it is already
        # on the main branch and just pull there.
        _exec(["git", "pull"], cwd=srcdir)
    else:
        # We do not have a checkout of v8 yet, so we use 'fetch' to get the initial
        # version of it and make sure to change to the main branch.
        _exec([FETCH_PATH, "v8"], cwd=ROOT_DIR)
        _exec(["git", "checkout", "main"], cwd=srcdir)
    _exec([GCLIENT_PATH, "sync"], cwd=srcdir)

def build(variant, arguments=[]):
    srcdir = os.path.join(ROOT_DIR, "v8")
    _exec(["git", "log", "-1"], cwd=srcdir)
    outdir = variant.output_directory()
    args = variant.gn_generate_args()
    _exec([GN_PATH, "gen", outdir, f"--args={args}"], cwd=srcdir)
    _exec([AUTONINJA_PATH, "-C", outdir] + arguments, cwd=srcdir)

def build_d8(variant):
    build(variant, ["d8"])

def run_tests_specific(variant, tests, *extra):
    srcdir = os.path.join(ROOT_DIR, "v8")
    outdir = variant.output_directory()
    arguments = [
        PYTHON,
        "tools/run-tests.py",
        tests,
        "--progress=verbose",
        "--rerun-failures-count=2",
        f"--outdir={outdir}",
    ]
    _exec(arguments + list(extra), cwd=srcdir)

def run_tests(variant, fast=False, stress=True):
    # The 'default' set of tests is slightly smaller than the 'bot default' set.
    # Unless we're asked to run the tests quickly, we prefer the slightly bigger
    # set of tests to get better coverage.
    tests = "default" if fast else "bot_default"
    # The 'exhaustive' variants include all the 'stress' variants. If we're
    # asked to avoid the 'stress' variants, we can't use it.
    variants = "exhaustive" if stress else "future,default"
    if fast: variants = "stress,default" if stress else "default"
    run_tests_specific(variant, tests, f"--variants={variants}")

def run_d8(variant, arguments, cwd=CWD):
    srcdir = os.path.join(ROOT_DIR, "v8")
    outdir = variant.output_directory()
    return _exec(
        [os.path.join(srcdir, outdir, "d8")] + arguments,
        cwd=cwd,
        capture_output=True
    )
