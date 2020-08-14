## ROOT conda CI scripts

### test\_conda\_root.sh

This script is meant to be run inside the condaforge/linux-anvil-comp7 docker image.

It executes the following operations:
- install [ROOT](github.com/root-project/root) via conda+conda-forge
- download and compile [roottest](http://github.com/root-project/roottest) against that pre-existing ROOT installation
- run all available tests via `ctest`

#### Example usage:

```bash
$ docker run -t --detach -e ROOTTEST_BRANCH=v6-20-06 --name testconda condaforge/linux-anvil-comp7
$ docker cp test_conda_root.sh testconda:.
$ docker exec -it testconda bash -i test_conda_root.sh
```

### build_master.sh

This script builds ROOT master as a conda package, thanks to Chris Burr.
