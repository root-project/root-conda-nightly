#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

# ROOT tends to use 120% of cores for builds
export CPU_COUNT=$(expr 12 \* $(nproc) / 10 )
# Tell the build-locally.py not to pass -it to docker
export CI=1

ROOT_CONDA_VERSION=6.24.0
ROOT_CONDA_BUILD_NUMBER=$(date +%Y%M%d)

CONDA_FORGE_DOCKER_RUN_ARGS="--rm"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_IS_CI=1"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_RUN_GTESTS=1"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_VERSION=${ROOT_CONDA_VERSION}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_NUMBER=${ROOT_CONDA_BUILD_NUMBER}"
# CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_GIT_URL=https://github.com/root-project/root.git"
# CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_GIT_REV=master"
# CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_TYPE=Debug"
export CONDA_FORGE_DOCKER_RUN_ARGS

rm -rf clangdev-feedstock && git clone https://github.com/chrisburr/clangdev-feedstock.git -b prepare-root-6.24.00-release
# rm -rf cling-feedstock && git clone https://github.com/chrisburr/cling-feedstock.git -b root-nightlies-2
rm -rf root-feedstock && git clone https://github.com/chrisburr/root-feedstock.git -b root-nightlies-2

# Build clang
# pushd clangdev-feedstock
# git show
# sed -i "s@build_number = 1@build_number = ${ROOT_CONDA_BUILD_NUMBER}@g" recipe/meta.yaml
# metadata_name=$(basename --suffix=.yaml $(echo .ci_support/linux_64_variantroot_*.yaml))
# echo "Clang build metadata name is ${metadata_name}"
# ./build-locally.py "${metadata_name}"
# popd

# # Build cling
# mv clangdev-feedstock/build_artifacts cling-feedstock/build_artifacts
# pushd cling-feedstock
# ./build-locally.py linux_64_
# popd
# mv cling-feedstock/build_artifacts root-feedstock/build_artifacts

# mv clangdev-feedstock/build_artifacts root-feedstock/build_artifacts

# Build ROOT
pushd root-feedstock
git show
metadata_name=$(basename --suffix=.yaml $(echo .ci_support/linux_64_*python3.8*cpython.yaml))
echo "Clang build metadata name is ${metadata_name}"
./build-locally.py "${metadata_name}"
popd
