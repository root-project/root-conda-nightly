## Test conda ROOT

[![Build Status](https://epsft-jenkins.cern.ch/buildStatus/icon?job=root-conda-roottest)](https://epsft-jenkins.cern.ch/job/root-conda-roottest)

#### test\_conda\_root.sh

- install [ROOT](github.com/root-project/root) via conda+conda-forge
- download and compile [roottest](http://github.com/root-project/roottest) against that pre-existing ROOT installation
- run all available tests via `ctest`

The corresponding ROOT jenkins job is [here](https://epsft-jenkins.cern.ch/view/ROOT/job/root-conda-roottest).
At the time of writing, the jenkins job configuration is simply:

```
#!/bin/bash
set -x

git clone --depth 1 https://gitlab.cern.ch/eguiraud/test_conda_root.git

CONTAINER=root-conda-test-$(date +%s)
docker run --name ${CONTAINER} -t --detach continuumio/miniconda
docker cp test_conda_root/test_conda_root.sh "${CONTAINER}:/root/."
docker exec "${CONTAINER}" /bin/bash /root/test_conda_root.sh
docker stop "${CONTAINER}"
docker cp "${CONTAINER}:/root/job/roottest_build/Testing" ctest_output
docker rm "${CONTAINER}"
```

#### build\_from\_recipe.sh

- clone root-feedstock recipe
- conda-build it
