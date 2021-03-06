#!/bin/bash

set -e

echo "pipeline {"
for OS in ubuntu2004; do
	# TODO: enable ubuntu 18.04 and CentOS. move agent to stage.
	echo "  agent {"
	echo "    label '$OS'"
	echo "  }"
	echo "  stages {"

	echo "    stage('Get the source') {"
	echo "      steps {"
	echo "        sh 'rm -rf riscv-gnu-toolchain'"
	echo "        sh 'git clone https://github.com/riscv/riscv-gnu-toolchain'"
	echo "        sh 'cd riscv-gnu-toolchain'"
	echo "      }"
	echo "    }"

	for target in \
		newlib-rv32i-ilp32-medlow \
		newlib-rv32im-ilp32-medlow \
		newlib-rv32iac-ilp32-medlow \
		newlib-rv32imac-ilp32-medlow \
		newlib-rv32imafc-ilp32f-medlow \
		newlib-rv64imac-lp64-medlow \
		newlib-rv64imafdc-lp64d-medlow \
		linux-rv32imac-ilp32-medlow \
		linux-rv32imafdc-ilp32-medlow \
		linux-rv32imafdc-ilp32d-medlow \
		linux-rv64imac-lp64-medlow \
		linux-rv64imafdc-lp64-medlow \
		linux-rv64imafdc-lp64d-medlow \
		newlib-rv32i-ilp32-medany \
		newlib-rv32im-ilp32-medany \
		newlib-rv32iac-ilp32-medany \
		newlib-rv32imac-ilp32-medany \
		newlib-rv32imafc-ilp32f-medany \
		newlib-rv64imac-lp64-medany \
		newlib-rv64imafdc-lp64d-medany \
		linux-rv32imac-ilp32-medany \
		linux-rv32imafdc-ilp32-medany \
		linux-rv32imafdc-ilp32d-medany \
		linux-rv64imac-lp64-medany \
		linux-rv64imafdc-lp64-medany \
		linux-rv64imafdc-lp64d-medany
	do
		echo "    stage('build $target  on $OS') {"
		echo "      steps {"
		echo "        dir ("riscv-gnu-toolchain/regression") {"
		echo "          sh 'make stamps/build-$target'"
		echo "        }"
		echo "      }"
		echo "    }"
		echo "    stage('report binutils $target  on $OS') {"
		echo "      steps {"
		echo "        dir ("riscv-gnu-toolchain/regression") {"
		echo "          sh 'make stamps/report-binutils-$target'"
		echo "        }"
		echo "      }"
		echo "    }"
		echo "    stage('report gcc $target  on $OS') {"
		echo "      steps {"
		echo "        dir ("riscv-gnu-toolchain/regression") {"
		echo "          sh 'make stamps/report-gcc-$target'"
		echo "        }"
		echo "      }"
		echo "    }"
	done
done
echo "  }"
echo "}"
