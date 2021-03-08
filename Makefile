.PHONY: gen

gen:
	OSTYPE=ubuntu2004 ./gen-riscv-gnu-pipeline.sh > riscv-gnu-toolchain-master-ubuntu2004.jenkinsfile
	OSTYPE=ubuntu1804 ./gen-riscv-gnu-pipeline.sh > riscv-gnu-toolchain-master-ubuntu1804.jenkinsfile
