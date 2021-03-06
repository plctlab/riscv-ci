.PHONY: gen

gen:
	OSTYPE=ubuntu2004 ./gen-riscv-gnu-pipeline.sh > riscv-gnu-detailed-pipeline-ubuntu2004.jenkinsfile
	OSTYPE=ubuntu1804 ./gen-riscv-gnu-pipeline.sh > riscv-gnu-detailed-pipeline-ubuntu1804.jenkinsfile
