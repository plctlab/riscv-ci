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


# Helper function that runs a command given by the arguments in a subprocess.
# Notice that we default to checking that it runs successfully and we show
# useful information about the working directory.
def exec(arguments, cwd=CWD, check=True):
    if cwd != CWD: print("+ " + "cd " + cwd, flush=True)
    commandline = " ".join([f"'{x}'" if " " in x else x for x in arguments])
    print(f"+ {commandline}", flush=True)
    # Extend the PATH of the subprocess, so the correct depot_tools are used.
    # This is necessary at least when calling out to tools/run-tests.py.
    env = dict(os.environ)
    env["PATH"] = DEPOT_TOOLS_DIR + os.pathsep + env["PATH"]
    subprocess.run(arguments, cwd=cwd, check=check, env=env)
    if cwd != CWD: print("+ " + "cd " + CWD, flush=True)

def fetch_depot_tools():
    if os.path.isdir(DEPOT_TOOLS_DIR): return
    exec(["git", "clone", DEPOT_TOOLS_URL, DEPOT_TOOLS_DIR])

def fetch(clean=False):
    if clean and os.path.isdir(ROOT_DIR):
        shutil.rmtree(ROOT_DIR, ignore_errors=True)
    if not os.path.isdir(ROOT_DIR):
        os.mkdir(ROOT_DIR)
    v8 = os.path.join(ROOT_DIR, "v8")
    if os.path.isdir(v8):
        # We already have a checked out version of v8, so we assume it is already
        # on the main branch and just pull there.
        exec(["git", "pull"], cwd=v8)
    else:
        # We do not have a checkout of v8 yet, so we use 'fetch' to get the initial
        # version of it and make sure to change to the main branch.
        exec([FETCH_PATH, "v8"], cwd=ROOT_DIR)
        exec(["git", "checkout", "main"], cwd=v8)
    exec([GCLIENT_PATH, "sync"], cwd=v8)

def build(variant):
    v8 = os.path.join(ROOT_DIR, "v8")
    exec(["git", "log", "-1"], cwd=v8)
    outdir = variant.output_directory()
    args = variant.gn_generate_args()
    exec([GN_PATH, "gen", outdir, f"--args={args}"], cwd=v8)
    exec([AUTONINJA_PATH, "-C", outdir], cwd=v8)

def run_tests_specific(variant, tests, *extra):
    v8 = os.path.join(ROOT_DIR, "v8")
    outdir = variant.output_directory()
    arguments = [
        PYTHON,
        "tools/run-tests.py",
        tests,
        "--progress=verbose",
        "--rerun-failures-count=2",
        f"--outdir={outdir}",
    ]
    exec(arguments + list(extra), cwd=v8)

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
