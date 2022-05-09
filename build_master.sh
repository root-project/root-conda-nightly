#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

# ROOT tends to use 120% of cores for builds
export CPU_COUNT=$(expr 12 \* $(nproc) / 10 )
# Tell the build-locally.py not to pass -it to docker
export CI=1

ROOT_CONDA_VERSION=6.27.0
ROOT_CONDA_BUILD_NUMBER=$(date +%Y%M%d)

CONDA_FORGE_DOCKER_RUN_ARGS="--rm"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_IS_CI=1"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_RUN_GTESTS=1"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_VERSION=${ROOT_CONDA_VERSION}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_NUMBER=${ROOT_CONDA_BUILD_NUMBER}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_GIT_URL=https://github.com/root-project/root.git"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_GIT_REV=master"
# CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_TYPE=Debug"
export CONDA_FORGE_DOCKER_RUN_ARGS

rm -rf llvmdev-feedstock; git clone https://github.com/chrisburr/llvmdev-feedstock.git -b root-nightlies
rm -rf clangdev-feedstock; git clone https://github.com/chrisburr/clangdev-feedstock.git -b root-nightlies
# rm -rf cling-feedstock; git clone https://github.com/chrisburr/cling-feedstock.git -b root-nightlies-2
rm -rf root-feedstock; git clone https://github.com/chrisburr/root-feedstock.git -b root-nightlies

# Update the clang patches from http://root.cern/git/clang.git
pushd clangdev-feedstock
test $(grep --count '# Taken from cloning http://root.cern/git/clang.git and running' recipe/meta.yaml) = 2
head -n $(grep -n '# Taken from cloning http://root.cern/git/clang.git and running' recipe/meta.yaml | cut -d ':' -f1 | head -n 1 | awk '{print $1+2}' ) recipe/meta.yaml > recipe/meta.yaml.new
pushd recipe/patches/root/
rm 0*.patch
git clone http://root.cern/git/clang.git roots-clang
git --git-dir=$PWD/roots-clang/.git format-patch cc54f73e76332c635d97a53b5ec369901173be53~1..origin/ROOT-patches
rm -rf roots-clang/
# Apply a hack so conda build doesn't create a directory name "b" for the new file
sed -i.bak 's@b/lib/Sema/HackForDefaultTemplateArg.h@lib/Sema/HackForDefaultTemplateArg.h@g' *New-file-for-4453ba7.patch; rm *New-file-for-4453ba7.patch.bak
ls *.patch | sort | awk '{printf "%-63s\n", $0}' | sed -E 's@^(.+)$@      - patches/root/\1  # [variant and variant.startswith("root_")]@g' >> ../../meta.yaml.new
popd
tail -n +$(grep -n '# Taken from cloning http://root.cern/git/clang.git and running' recipe/meta.yaml | cut -d ':' -f1 | tail -n 1 | awk '{print $1-1}' ) recipe/meta.yaml >> recipe/meta.yaml.new
mv recipe/meta.yaml.new recipe/meta.yaml
git diff --color | cat
popd

df -h .
df -h
docker system df
timeout 60s docker system prune -f || echo $?

# Build llvm
pushd llvmdev-feedstock
git show
./build-locally.py "linux_64_variantcling_v0.9"
timeout 60s docker system prune -f || echo $?
popd
mv llvmdev-feedstock/build_artifacts clangdev-feedstock/build_artifacts

# Build clang
pushd clangdev-feedstock
git show
metadata_name=$(basename --suffix=.yaml $(echo .ci_support/linux_64_*root_*.yaml))
echo "Clang build metadata name is ${metadata_name}"
./build-locally.py "${metadata_name}"
timeout 60s docker system prune -f || echo $?
popd

# # Build cling
# mv clangdev-feedstock/build_artifacts cling-feedstock/build_artifacts
# pushd cling-feedstock
# ./build-locally.py linux_64_
# popd
# mv cling-feedstock/build_artifacts root-feedstock/build_artifacts
mv clangdev-feedstock/build_artifacts root-feedstock/build_artifacts

# Build ROOT
pushd root-feedstock
git show
metadata_name=$(basename --suffix=.yaml $(echo .ci_support/linux_64_*python3.9*cpython.yaml))
echo "Clang build metadata name is ${metadata_name}"
./build-locally.py "${metadata_name}"
timeout 60s docker system prune -f || echo $?
popd
