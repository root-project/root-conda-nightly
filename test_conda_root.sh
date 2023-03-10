#!/bin/bash
# Build and run roottest against ROOT installed as a conda package.
# The script assumes that `conda activate` sets an environment where ROOT is present.
# Environment variable JOB_DIR is expected to be set to the desired working directory for this script (must not be empty).
# The output of ctest will be contained in "${JOB_DIR}/ctest_output" after this script executes.

#--- setup environment ---#
set -euo pipefail
IFS=$'\n\t'
set -x

if [[ "$JOB_DIR" != $(readlink -m "$JOB_DIR") ]]; then
   echo "Environment variable JOB_DIR must be set to an absolute path"
   exit 1
fi
mkdir -p "${JOB_DIR}"
pushd "${JOB_DIR}"

# pyspark requires java
/usr/bin/sudo -n yum install -q -y java

#--- activate base conda environment ---#
set +ux
echo -n "activating conda..."
conda activate test-root
echo "done"
if [[ -z "$(which root)" ]]; then
   echo "Could not find ROOT in this environment" >&2
   exit 2
fi
mamba install --yes --quiet -c conda-forge cmake make git pytest pyspark 'nlohmann_json>=3.10.5'
set -ux

#--- build roottest ---#
ROOTTEST_BRANCH="${ROOTTEST_BRANCH-v$(root-config --version | sed 's:[\./]:-:g')}"
# git clone --quiet --branch ${ROOTTEST_BRANCH} --depth 1 https://github.com/root-project/roottest
git clone --quiet --branch master --depth 1 https://github.com/root-project/roottest.git

echo "***** ENVIRONMENT VARIABLES WHEN BUILDING ROOTTEST *****"
declare -p
echo "********************************************************"

BUILD_DIR="${JOB_DIR}/roottest_build"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"
# -DPYTHON_EXECUTABLE_Development_Main=$(which python) is due to bug https://sft.its.cern.ch/jira/browse/ROOT-10905
# no need for -Ddataframe=ON since v6.24, see https://github.com/root-project/roottest/pull/551
cmake -DPYTHON_EXECUTABLE=$(which python) -DPYTHON_EXECUTABLE_Development_Main=$(which python) -Ddataframe=ON "${JOB_DIR}/roottest"
cmake --build . -j$(nproc)

#--- run tests ---#
ctest -T test --no-compress-output -j$(nproc) || true  # ignore ctest exit code, we will parse the logs

popd
popd

mv "${JOB_DIR}/roottest_build/Testing" "${JOB_DIR}/ctest_output"
