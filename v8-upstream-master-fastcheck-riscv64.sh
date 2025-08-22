#!/bin/bash
git -C riscv-ci pull || git clone https://github.com/plctlab/riscv-ci riscv-ci
python3 $PWD/riscv-ci/v8-upstream-master-fastcheck-riscv64.py
