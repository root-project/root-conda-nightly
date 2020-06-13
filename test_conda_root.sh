#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

JOB_DIR="/root/job"

#--- setup environment ---#
if [[ -z "${ROOTTEST_BRANCH}" ]]; then
   echo "Please set the ROOTTEST_BRANCH env variable to the desired git branch for the roottest repository." >&2
   exit 1
fi
mkdir -p "${JOB_DIR}"
pushd "${JOB_DIR}"

#--- install ROOT from conda ---#
set +ux
echo -n "activating conda..."
conda activate
echo "done"
conda update --yes --all --quiet
conda install --yes --quiet -c conda-forge root cmake make
set -ux

#--- get roottest ---#
ROOT_VERSION="v$(root-config --version | sed 's:[\./]:-:g')"
if [[ -z "$ROOT_VERSION" || "$ROOT_VERSION" != "$ROOTTEST_BRANCH" ]]; then
   echo "ROOT_VERSION $ROOT_VERSION for conda-forge ROOT package does not match specified ROOTTEST_BRANCH $ROOTTEST_BRANCH." >&2
   exit 2
fi
git clone --quiet --branch ${ROOTTEST_BRANCH} --depth 1 https://github.com/root-project/roottest

echo "***** ENVIRONMENT VARIABLES WHEN BUILDING ROOTTEST *****"
declare -p
echo "********************************************************"

BUILD_DIR="${JOB_DIR}/roottest_build"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"
# FIXME RDF tests are not built when roottest is built independently of ROOT because 'dataframe' is not set
cmake -Ddataframe=ON "${JOB_DIR}/roottest"
cmake --build .

#--- run tests ---#
ctest -T test --no-compress-output

popd
popd
