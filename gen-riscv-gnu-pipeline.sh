#!/bin/bash

set -e

if [ x"$OSTYPE" = x"" ]; then
	echo "usage: OSTYPE=ubuntu2004 $0"
	exit 1
fi

echo "pipeline {"
# TODO: enable ubuntu 18.04 and CentOS. move agent to stage.
echo "  agent {"
echo "    label '$OSTYPE'"
echo "  }"
echo "  stages {"

echo "    stage('Get the source') {"
echo "      steps {"
echo "        sh 'rm -rf riscv-gnu-toolchain'"
echo "        sh 'git clone --shallow-since=2021-03-01 --shallow-submodules https://github.com/riscv/riscv-gnu-toolchain'"
#echo "        sh 'cd riscv-gnu-toolchain && git submodule update --init'"
echo "        sh 'cd riscv-gnu-toolchain && git config -f .gitmodules submodule.*.shallow true &&  git submodule update --init'"

if [ x"$OSTYPE" = x"ubuntu2004" ]; then

	echo "        sh 'cd riscv-gnu-toolchain/qemu && git checkout -f v5.2.0 && git submodule update -f  --init'"
fi

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
	echo "    stage('build $target on $OSTYPE') {"
	echo "      steps {"
	echo "        dir ('riscv-gnu-toolchain/regression') {"
	echo "          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {"
	echo "              sh 'make -j \$(nproc) stamps/build-$target'"
	echo "          }"
	echo "        }"
	echo "      }"
	echo "    }"
	echo "    stage('report binutils $target on $OSTYPE') {"
	echo "      steps {"
	echo "        dir ('riscv-gnu-toolchain/regression') {"
	echo "          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {"
	echo "              sh 'make -j \$(nproc) report-binutils-$target'"
	echo "          }"
	echo "        }"
	echo "      }"
	echo "    }"
	echo "    stage('report gcc $target on $OSTYPE') {"
	echo "      steps {"
	echo "        dir ('riscv-gnu-toolchain/regression') {"
	echo "          catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {"
	echo "              sh 'make -j \$(nproc) report-gcc-$target'"
	echo "          }"
	echo "        }"
	echo "      }"
	echo "    }"
done
echo "  }"
echo "}"
