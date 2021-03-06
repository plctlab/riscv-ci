.PHONY: gen

gen:
	./gen-riscv-gnu-pipeline.sh > riscv-gnu-detailed-pipeline.jenkinsfile
