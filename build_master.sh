#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
set -x

set +ux
echo -n "activating conda..."
conda activate
echo "done"
conda update --yes --all --quiet
conda install --yes --quiet -c conda-build git
set -ux

export ROOT_CONDA_BUILD_NUMBER="$(date +%Y%M%d)"
export ROOT_CONDA_GIT_URL=https://github.com/root-project/root.git
export ROOT_CONDA_GIT_REV=master
export ROOT_CONDA_USE_CCACHE=0  # disabled at least for now
export ROOT_CONDA_RUN_GTESTS=1

git clone https://github.com/chrisburr/clangdev-feedstock.git -b root-nightlies
git clone https://github.com/chrisburr/root-feedstock.git -b root-nightlies

pushd clangdev-feedstock
./build-locally.py linux_clang_variantroot_20200518
popd

# Sudo required as build_artifacts contains files which are owned by ROOT
sudo mv clangdev-feedstock/build_artifacts root-feedstock/build_artifacts

pushd root-feedstock
./build-locally.py linux_python3.8.____cpython
popd
