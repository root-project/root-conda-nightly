#!/bin/bash
# Install ROOT as a conda package
# If the CUSTOM_CONDA_CHANNEL env variable is set, that channel will take priority over conda-forge
# when looking for root and its dependencies.
# If the ROOT_PACKAGE env variable is set e.g. to "root=6.22" or "root-nighly" it will be passed to the conda installation command.

#--- setup environment ---#
set -eo pipefail
IFS=$'\n\t'

conda activate

#--- install host system prerequisites ---#
# see https://github.com/conda-forge/root-feedstock/blob/master/recipe/yum_requirements.txt
/usr/bin/sudo -n yum install -q -y mesa-libGL mesa-dri-drivers libselinux libXdamage libXxf86vm redhat-lsb-core

mamba create --name test-root --yes --quiet ${CUSTOM_CONDA_CHANNEL:+-c=${CUSTOM_CONDA_CHANNEL}} -c conda-forge ${ROOT_PACKAGE:-root}
