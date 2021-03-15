#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

# ROOT tends to use 120% of cores for builds
export CPU_COUNT=$(expr 12 \* $(nproc) / 10 )

CONDA_FORGE_DOCKER_RUN_ARGS="--rm"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_NUMBER=$(date +%Y%M%d)"
CONDA_FORGE_DOCKER_RUN_ARGS+=" export ROOT_CONDA_GIT_URL=https://github.com/root-project/root.git"
CONDA_FORGE_DOCKER_RUN_ARGS+=" export ROOT_CONDA_GIT_REV=master"
CONDA_FORGE_DOCKER_RUN_ARGS+=" export ROOT_CONDA_USE_CCACHE=0"
CONDA_FORGE_DOCKER_RUN_ARGS+=" export ROOT_CONDA_RUN_GTESTS=1"
export CONDA_FORGE_DOCKER_RUN_ARGS

rm -rf clangdev-feedstock && git clone https://github.com/chrisburr/clangdev-feedstock.git -b root-nightlies-2
rm -rf cling-feedstock && git clone https://github.com/chrisburr/cling-feedstock.git -b root-nightlies-2
rm -rf root-feedstock && git clone https://github.com/chrisburr/root-feedstock.git -b root-nightlies-2

# Build clang
pushd clangdev-feedstock
./build-locally.py linux_64_variantcling_master
popd

# Build cling
mv clangdev-feedstock/build_artifacts cling-feedstock/build_artifacts
pushd cling-feedstock
./build-locally.py linux_64_
popd

# Build ROOT
mv cling-feedstock/build_artifacts root-feedstock/build_artifacts
pushd root-feedstock
./build-locally.py linux_64_
popd
