#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ROOT_CONDA_GIT_URL="https://github.com/root-project/root.git"
ROOT_CONDA_GIT_REV="master"
ROOT_CONDA_VERSION=6.31.01.$(date -u +%Y.%m.%d.%H.%M)
ROOT_CONDA_BUILD_NUMBER=0
ROOT_CONDA_BUILD_TYPE="Release"
ROOT_CONDA_RUN_GTESTS=0
CPU_COUNT=$(nproc)

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
CONDA_FORGE_DOCKER_RUN_ARGS+=" --net=host"
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

rm -rf clangdev-feedstock; git clone --single-branch --branch nightlies https://github.com/root-project/clangdev-feedstock.git
rm -rf root-feedstock; git clone --single-branch --branch nightlies https://github.com/root-project/root-feedstock.git

df -h .
df -h
docker system df
timeout 60s docker system prune -f || echo $?

# Build clang
pushd clangdev-feedstock
git show
metadata_name=$(basename --suffix=.yaml "$(echo .ci_support/linux_64_*root_*.yaml)")
echo "Clang build metadata name is ${metadata_name}"
./build-locally.py "${metadata_name}"
timeout 60s docker system prune -f || echo $?
popd

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
