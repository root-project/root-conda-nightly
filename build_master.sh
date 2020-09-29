#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

# ROOT tends to use 120% of cores for builds
export CPU_COUNT=$(expr 12 \* $(nproc) / 10 )
export ROOT_CONDA_BUILD_NUMBER="$(date +%Y%M%d)"
export ROOT_CONDA_GIT_URL=https://github.com/root-project/root.git
export ROOT_CONDA_GIT_REV=master
export ROOT_CONDA_USE_CCACHE=0  # disabled at least for now
export ROOT_CONDA_RUN_GTESTS=1

rm -rf clangdev-feedstock && git clone https://github.com/chrisburr/clangdev-feedstock.git -b root-nightlies
rm -rf root-feedstock && git clone https://github.com/chrisburr/root-feedstock.git -b root-nightlies

pushd clangdev-feedstock
./build-locally.py linux_64_clang_variantroot_20200518
popd

mv clangdev-feedstock/build_artifacts root-feedstock/build_artifacts

pushd root-feedstock
./build-locally.py linux_64_python3.8.____cpython
popd
