## ROOT conda CI scripts

### Local usage

```bash
$ ./build_master.sh -h
usage: ./build_master.sh [options]
Build the root conda-packages
--git-url=...       Git URL to get the git sources from (default: https://github.com/root-project/root.git)
--git-rev=...       Git revision to checkout from --git-url (default: master)
--version=...       Version to set in the conda-packages (default: VERSION.DATE.TIME)
--build-number=...  Build number to set in the conda-packages (default: 0)
--build-type=...    CMake build type to use for llvm/clang/root (default: Release)
-j=N                Number of cores to use (default: NPROC)
--test              Run unit tests during the build process (failures are permitted)
```

### test\_conda\_root.sh

This script is meant to be run inside the condaforge/linux-anvil-comp7 docker image.

It executes the following operations:
- install [ROOT](github.com/root-project/root) via conda+conda-forge
- download and compile [roottest](http://github.com/root-project/roottest) against that pre-existing ROOT installation
- run all available tests via `ctest`

#### Example usage:

```bash
$ docker run -t --detach -e ROOTTEST_BRANCH=v6-20-06 --name testconda quay.io/condaforge/linux-anvil-cos7-cuda:10.2
$ docker cp test_conda_root.sh testconda:.
$ docker exec -it testconda bash -i test_conda_root.sh
```

### build_master.sh

This script builds ROOT master as a conda package, thanks to Chris Burr.
