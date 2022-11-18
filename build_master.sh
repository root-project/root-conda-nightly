#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ROOT_CONDA_GIT_URL="https://github.com/root-project/root.git"
ROOT_CONDA_GIT_REV="master"
ROOT_CONDA_VERSION=6.27.0.$(date -u +%Y.%m.%d.%H.%M)
ROOT_CONDA_BUILD_NUMBER=0
ROOT_CONDA_BUILD_TYPE="Release"
ROOT_CONDA_RUN_GTESTS=0
CPU_COUNT=$(nproc)

docker run --rm quay.io/condaforge/linux-anvil-cos7-x86_64@sha256:673aa8083428c00b71e2d20133361c569f371bb8a2c0973c64ea4ecb35e52e0a ping -c 10 conda.anaconda.org

USAGE="usage: $0 [options]
Build the root conda-packages
--git-url=...       Git URL to get the git sources from (default: ${ROOT_CONDA_GIT_URL})
--git-rev=...       Git revision to checkout from --git-url (default: ${ROOT_CONDA_GIT_REV})
--version=...       Version to set in the conda-packages (default: ${ROOT_CONDA_VERSION})
--build-number=...  Build number to set in the conda-packages (default: ${ROOT_CONDA_BUILD_NUMBER})
--build-type=...    CMake build type to use for llvm/clang/root (default: ${ROOT_CONDA_BUILD_TYPE})
-j=N                Number of cores to use (default: ${CPU_COUNT})
--test              Run unit tests during the build process (failures are permitted)
--clean             Delete directories used for previous builds
"

for i in "$@"; do
  case $i in
    -u=*|--git-url=*)
      ROOT_CONDA_GIT_URL="${i#*=}"
      shift
      ;;
    -r=*|--git-rev=*)
      ROOT_CONDA_GIT_REV="${i#*=}"
      shift
      ;;
    -v=*|--version=*)
      ROOT_CONDA_VERSION="${i#*=}"
      shift
      ;;
    -t=*|--build-type=*)
      ROOT_CONDA_BUILD_TYPE="${i#*=}"
      shift
      ;;
    -n=*|--build-number=*)
      ROOT_CONDA_BUILD_NUMBER="${i#*=}"
      shift
      ;;
    -j=*)
      CPU_COUNT="${i#*=}"
      shift
      ;;
    --test)
      ROOT_CONDA_RUN_GTESTS=1
      shift
      ;;
    --clean)
      rm -rf clangdev-feedstock/ llvmdev-feedstock/ root-feedstock/ mounted-for-tmp/ mounted-for-pkgs/
      echo Directories cleaned
      exit 0
      ;;
    -h|--help)
      echo "${USAGE}"
      exit 0
      ;;
    -*)
      echo "Unknown option $i"
      echo
      echo "${USAGE}"
      exit 1
      ;;
    *)
      ;;
  esac
done

if [ -d llvmdev-feedstock/ ] || [ -d clangdev-feedstock/ ] || [ -d root-feedstock/ ] || [ -d mounted-for-tmp/ ]; then
    echo ERROR: Found local feedstock clones, try running with --clean
    exit 1
fi

set -x
CONDA_FORGE_DOCKER_RUN_ARGS="--rm"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_IS_CI=1"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_RUN_GTESTS=${ROOT_CONDA_RUN_GTESTS}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_VERSION=${ROOT_CONDA_VERSION}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_NUMBER=${ROOT_CONDA_BUILD_NUMBER}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_GIT_URL=${ROOT_CONDA_GIT_URL}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_GIT_REV=${ROOT_CONDA_GIT_REV}"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e ROOT_CONDA_BUILD_TYPE=${ROOT_CONDA_BUILD_TYPE}"
# Avoid issues with /tmp not being large enough (especially problematic for debug builds)
mkdir -p "$PWD/mounted-for-tmp"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -v $PWD/mounted-for-tmp:/mounted-for-tmp"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -e TMPDIR=/mounted-for-tmp"
mkdir -p "$PWD/mounted-for-pkgs"
CONDA_FORGE_DOCKER_RUN_ARGS+=" -v $PWD/mounted-for-pkgs:/opt/conda/pkgs"

export CONDA_FORGE_DOCKER_RUN_ARGS
export CPU_COUNT
# Tell the build-locally.py not to pass -it to docker
export CI=1

rm -rf llvmdev-feedstock; git clone https://github.com/chrisburr/llvmdev-feedstock.git -b root-nightlies
rm -rf clangdev-feedstock; git clone https://github.com/chrisburr/clangdev-feedstock.git -b root-nightlies
# rm -rf cling-feedstock; git clone https://github.com/chrisburr/cling-feedstock.git -b root-nightlies-2
rm -rf root-feedstock; git clone https://github.com/chrisburr/root-feedstock.git -b root-nightlies

# Update the clang patches from http://root.cern/git/clang.git
pushd clangdev-feedstock
test "$(grep --count '# Taken from cloning http://root.cern/git/clang.git and running' recipe/meta.yaml)" = 2
head -n "$(grep -n '# Taken from cloning http://root.cern/git/clang.git and running' recipe/meta.yaml | cut -d ':' -f1 | head -n 1 | awk '{print $1+2}' )" recipe/meta.yaml > recipe/meta.yaml.new
pushd recipe/patches/root/
rm 0*.patch
git clone http://root.cern/git/clang.git roots-clang
git --git-dir="$PWD/roots-clang/.git" format-patch cc54f73e76332c635d97a53b5ec369901173be53~1..origin/ROOT-patches
rm -rf roots-clang/
# Apply a hack so conda build doesn't create a directory name "b" for the new file
sed -i.bak 's@b/lib/Sema/HackForDefaultTemplateArg.h@lib/Sema/HackForDefaultTemplateArg.h@g' ./*New-file-for-4453ba7.patch; rm ./*New-file-for-4453ba7.patch.bak
ls *.patch | sort | awk '{printf "%-63s\n", $0}' | sed -E 's@^(.+)$@      - patches/root/\1  # [variant and variant.startswith("root_")]@g' >> ../../meta.yaml.new
popd
tail -n "+$(grep -n '# Taken from cloning http://root.cern/git/clang.git and running' recipe/meta.yaml | cut -d ':' -f1 | tail -n 1 | awk '{print $1-1}' )" recipe/meta.yaml >> recipe/meta.yaml.new
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
metadata_name=$(basename --suffix=.yaml "$(echo .ci_support/linux_64_*cling_master.yaml)")
./build-locally.py "${metadata_name}"
timeout 60s docker system prune -f || echo $?
popd
mv llvmdev-feedstock/build_artifacts clangdev-feedstock/build_artifacts

# Build clang
pushd clangdev-feedstock
git show
metadata_name=$(basename --suffix=.yaml "$(echo .ci_support/linux_64_*root_*.yaml)")
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
metadata_name=$(basename --suffix=.yaml "$(echo .ci_support/linux_64_*python3.9*cpython.yaml)")
echo "Clang build metadata name is ${metadata_name}"
./build-locally.py "${metadata_name}"
timeout 60s docker system prune -f || echo $?
popd

rm -rf "$PWD/mounted-for-tmp"
