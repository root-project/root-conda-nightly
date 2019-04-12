#!/bin/bash
set -x

CONTAINER=root-conda-test-$(date +%s)

set -e
docker run --name "${CONTAINER}" -t --detach continuumio/miniconda
docker cp test_conda_root/test_conda_root.sh "${CONTAINER}:/root/."
set +e

docker exec "${CONTAINER}" /bin/bash /root/test_conda_root.sh \
&& docker cp "${CONTAINER}:/root/job/roottest_build/Testing" ctest_output

docker stop "${CONTAINER}"
docker rm "${CONTAINER}"
