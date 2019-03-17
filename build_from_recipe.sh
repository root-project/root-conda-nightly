#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

apt-get update && apt-get install --yes binutils
conda install --yes --quiet conda-build make
git clone http://github.com/conda-forge/root-feedstock
conda build -c conda-forge root-feedstock/recipe
