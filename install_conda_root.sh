#!/bin/bash
# Install ROOT as a conda package
# If the CUSTOM_CONDA_CHANNEL env variable is set, that channel will take priority over conda-forge
# when looking for root and its dependencies.
# If the ROOT_VERSION env variable is set it will be passed to the conda installation command.

#--- setup environment ---#
set -euo pipefail
IFS=$'\n\t'
set -x

set +ux
echo -n "activating conda..."
conda activate
echo "done"
set -ux

conda update --yes --all --quiet
conda install --yes --quiet ${CUSTOM_CONDA_CHANNEL:+-c ${CUSTOM_CONDA_CHANNEL}} -c conda-forge root${ROOT_VERSION:+=${ROOT_VERSION}}
