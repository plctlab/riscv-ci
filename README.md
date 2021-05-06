# riscv-ci
Build scripts of ci.rvperf.org

## For PLCT staff:

you can modify your CI jobs by changing the scripts. The jenkins simply runs:

```
wget -O job.sh https://raw.githubusercontent.com/plctlab/riscv-ci/main/${JOB_NAME}.sh
bash -ex job.sh
```
**Please notice that you SHOULD NOT change repo and branch by/in your scripts.**
