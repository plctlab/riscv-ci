#!/bin/bash
git -C riscv-ci pull || git clone https://https://github.com/plctlab/riscv-ci riscv-ci
python3 $PWD/riscv-ci/v8-upstream-master-riscv64.py
