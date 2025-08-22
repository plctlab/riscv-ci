#!/usr/bin/env python3

import os
import platform
import shutil
import subprocess
import sys

# TODO(kasperl@rivosinc.com): Enable ccache to speed up compilation on the bots.

CWD = os.getcwd()
PYTHON = sys.executable

V8_ROOT_DIR = os.path.join(CWD, "v8-riscv")

DEPOT_TOOLS_URL = "https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR = os.path.join(CWD, "depot_tools")

FETCH_PATH     = os.path.join(DEPOT_TOOLS_DIR, "fetch")
GCLIENT_PATH   = os.path.join(DEPOT_TOOLS_DIR, "gclient")
GN_PATH        = os.path.join(DEPOT_TOOLS_DIR, "gn")
AUTONINJA_PATH = os.path.join(DEPOT_TOOLS_DIR, "autoninja")

TARGET_CPU_MAPPING = { "x86_64": "x64" }
TARGET_CPU = TARGET_CPU_MAPPING.get(platform.machine(), platform.machine())


#############################################################################
# Configurations.
#############################################################################
RISCV64_OPTDEBUG_SIM_CONFIG = f"""
  is_component_build=false
  is_debug=true
  target_cpu="{TARGET_CPU}"
  v8_enable_backtrace=true
  v8_enable_slow_dchecks=true
  v8_optimized_debug=true
  v8_target_cpu="riscv64"
"""

RISCV64_RELEASE_SIM_CONFIG = f"""
  is_component_build=false
  is_debug=false
  target_cpu="{TARGET_CPU}"
  v8_target_cpu="riscv64"
"""


# Helper function that runs a command given by the arguments in a subprocess.
# Notice that we default to checking that it runs successfully and we show
# useful information about the working directory.
def exec(arguments, cwd=CWD, check=True):
    if cwd != CWD: print("+ " + "cd " + cwd)
    commandline = " ".join([f"'{x}'" if " " in x else x for x in arguments])
    print(f"+ {commandline}", flush=True)
    # Extend the PATH of the subprocess, so the correct depot_tools are used.
    # This is necessary at least when calling out to tools/run-tests.py.
    env = dict(os.environ)
    env["PATH"] = DEPOT_TOOLS_DIR + os.pathsep + env["PATH"]
    subprocess.run(arguments, cwd=cwd, check=check, env=env)
    if cwd != CWD: print("+ " + "cd " + CWD)

def fetch_depot_tools():
    if os.path.isdir(DEPOT_TOOLS_DIR): return
    exec(["git", "clone", DEPOT_TOOLS_URL, DEPOT_TOOLS_DIR])

def fetch_v8(root, clean=False):
    if clean and os.path.isdir(root): shutil.rmtree(root, ignore_errors=True)
    if not os.path.isdir(root): os.mkdir(root)
    v8 = os.path.join(root, "v8")
    if os.path.isdir(v8):
        # We already have a checked out version of v8, so we assume it is already
        # on the main branch and just pull there.
        exec(["git", "pull"], cwd=v8)
    else:
        # We do not have a checkout of v8 yet, so we use 'fetch' to get the initial
        # version of it and make sure to change to the main branch.
        exec([FETCH_PATH, "v8"], cwd=root)
        exec(["git", "checkout", "main"], cwd=v8)
    subprocess.run([GCLIENT_PATH, "sync"], cwd=v8)

def build_v8(root, variant, config):
    v8 = os.path.join(root, "v8")
    exec(["git", "log", "-1"], cwd=v8)
    outdir = os.path.join("out.gn", variant)
    args = " ".join([x.strip() for x in config.splitlines() if x != ""])
    exec([GN_PATH, "gen", outdir, f"--args={args}"], cwd=v8)
    exec([AUTONINJA_PATH, "-C", outdir], cwd=v8)

def run_tests_specific(root, variant, *extra):
    v8 = os.path.join(root, "v8")
    outdir = os.path.join("out.gn", variant)
    arguments = [
        PYTHON,
        "tools/run-tests.py",
        "--progress=verbose",
        f"--outdir={outdir}",
    ]
    exec(arguments + list(extra), cwd=v8)

def run_tests_all(root, variant):
    run_tests_specific(root, variant)
    run_tests_specific(root, variant, "--variants=stress")
    # TODO(kasperl@rivosinc.com): Enable --jitless tests again.

if __name__ == "__main__":
    fetch_depot_tools()
    fetch_v8(V8_ROOT_DIR, clean=True)

    build_v8(V8_ROOT_DIR, "riscv64.optdebug.sim", RISCV64_OPTDEBUG_SIM_CONFIG)
    build_v8(V8_ROOT_DIR, "riscv64.release.sim", RISCV64_RELEASE_SIM_CONFIG)

    # NOTE(2021-08-21): Run 10 times to provoke random bugs. Apparently, this is the
    # only difference between the normal runners and the 'fastcheck' variants.
    for iteration in range(10):
        run_tests_all(V8_ROOT_DIR, "riscv64.optdebug.sim")
        run_tests_all(V8_ROOT_DIR, "riscv64.release.sim")
