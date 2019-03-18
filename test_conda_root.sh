#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

#--- configuration vars ---#
ROOT_CHANNEL="conda-forge"
JOB_DIR="/root/job"

#--- setup environment ---#
mkdir -p "${JOB_DIR}"
pushd "${JOB_DIR}"

#--- install ROOT from conda ---#
apt-get install --yes --quiet binutils # to have `ar` in PATH
conda update --yes --all --quiet
conda install --yes --quiet -c "${ROOT_CHANNEL}" root cmake make

#--- get roottest ---#
git clone --branch v6-16-00-patches --depth 1 https://github.com/root-project/roottest

#--- build roottest ---#
set +x
source "${CONDA_PREFIX}/etc/profile.d/conda.sh" # to get `conda activate`
set +u
conda activate # set AR, CXX, CC env variables to the right values (note that gcc won't be in PATH)
set -xu

echo "***** ENVIRONMENT VARIABLES WHEN BUILDING ROOTTEST *****"
declare -p
echo "********************************************************"

BUILD_DIR="${JOB_DIR}/roottest_build"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"
cmake -DCMAKE_AR="${AR}" "${JOB_DIR}/roottest"
cmake --build .

#--- run tests ---#
ctest --output-on-failure

popd
popd
