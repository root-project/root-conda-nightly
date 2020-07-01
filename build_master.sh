#!/bin/bash

export ROOT_CONDA_BUILD_NUMBER=20200630
export ROOT_CONDA_GIT_URL=https://github.com/root-project/root.git
export ROOT_CONDA_GIT_REV=master
export ROOT_CONDA_USE_CCACHE=1
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
