This repository's intent is to provide an automated way to build all dependencies
required for [OpenMW](https://github.com/openmw/openmw).

# Prerequisites

* Xcode with OS X 10.11 SDK (7.0+)
* CMake
* pkg-config

# Building & installing

* Clone the repo
* Create build dir
* Run CMake. Example (it assumes that the build directory is a child of source directory): `cmake ..`

* Build: `make`

* Now all files should be in `/your/build/directory/path/openmw-deps`, you should specify this path while running CMake for OpenMW later
