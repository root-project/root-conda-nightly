#!/bin/bash
# Install ROOT as a conda package
# TODO: parameterize script over ROOT version/conda package label

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
conda install --yes --quiet -c conda-forge root
