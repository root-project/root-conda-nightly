### Test conda ROOT

[![Build Status](https://epsft-jenkins.cern.ch/buildStatus/icon?job=root-conda-roottest)](https://epsft-jenkins.cern.ch/job/root-conda-roottest)

The repository contains a script that:

- installs [ROOT](github.com/root-project/root) via conda (currently downloading [this package](https://anaconda.org/chrisburr/root))
- downloads and compiles [roottest](http://github.com/root-project/roottest)
- runs all available tests via `ctest`

At least for now, the script is only guaranteed to work when run inside the
continuumio/miniconda3 docker container with ROOT master, roottest master.
