#!/bin/bash
set -x
set -e

#--- configuration vars ---#
ROOT_CHANNEL="chrisburr/label/gitlab-root-master-614515"
JOB_DIR="/root/job"

#--- setup environment ---#
mkdir -p "${JOB_DIR}"
pushd "${JOB_DIR}"

#--- install ROOT from conda ---#
# TODO avoid installing blas explicitly when ROOT's conda package lists it as a dependency
conda update --yes --all
conda install --yes -q -c conda-forge/label/gcc7 -c "${ROOT_CHANNEL}" root cmake make blas

#--- get roottest ---#
# TODO go back to using ROOT's roottest master as soon as the issue solved by PR #262 is fixed
git clone https://github.com/bluehood/roottest
pushd roottest
git checkout dev
popd

#--- build roottest ---#
set +x
source "${CONDA_PREFIX}/etc/profile.d/conda.sh" # to get `conda activate`
set -x
conda activate # set AR, CXX, CC env variables to the right values (note that gcc won't be in PATH)

echo "***** ENVIRONMENT VARIABLES WHEN BUILDING ROOTTEST *****"
declare -p
echo "********************************************************"

# TODO figure out why tests (e.g. roottest-cling-stl-dicts-build) fail if AR is not in path
ln -s "${AR}" /usr/bin/ar

BUILD_DIR="${JOB_DIR}/roottest_build"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"
cmake -DCMAKE_AR="${AR}" "${JOB_DIR}/roottest"
cmake --build .

#--- run tests ---#
ctest --output-on-failure

popd
popd
