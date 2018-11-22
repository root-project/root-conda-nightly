#!/bin/bash
set -x
set -e

#--- configuration vars ---#
ROOT_CHANNEL="chrisburr/label/gitlab-root-master-593544"
JOB_DIR="/root/job"

#--- setup environment ---#
mkdir -p "${JOB_DIR}"
pushd "${JOB_DIR}"

#--- install ROOT from conda ---#
conda update --yes --all
conda install --yes -q -c conda-forge/label/gcc7 -c "${ROOT_CHANNEL}" root cmake make

#--- get roottest, patch it to allow building against an already installed ROOT ---#
git clone https://github.com/root-project/roottest
pushd "${JOB_DIR}/roottest"
# `git pull` requires some credentials
git config --global user.email "dummyuser@foo.com"
git config --global user.name "Dummy User"
git checkout -b fix_build_against_installed master
git pull --no-commit https://github.com/vgvassilev/roottest.git Fix-ROOT-9405
popd

#--- build roottest ---#
source "${CONDA_PREFIX}/etc/profile.d/conda.sh" # to get `conda activate`
conda activate # set CXX, CC env variables to the right values (note that gcc won't be in PATH)

#FIXME this +x/-x sandwich works around a bug in thisroot.sh which assume at least one among `man` and `manpath` exists
set +x
set +e
source thisroot.sh # uses the `thisroot.sh` in PATH
set -x
set -e

BUILD_DIR="${JOB_DIR}/roottest_build"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"
cmake "${JOB_DIR}/roottest"
cmake --build .

#--- run tests ---#
ctest

popd
popd
