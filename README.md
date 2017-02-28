[![Build Status](https://travis-ci.org/OpenMW/openmw-deps-mac.svg?branch=master)](https://travis-ci.org/OpenMW/openmw-deps-mac)

This repository's intent is to provide an automated way to build all dependencies
required for [OpenMW](https://github.com/openmw/openmw).

# Prerequisites

* Xcode with OS X 10.11 or 10.12 SDK (>= 7.0, < 9.0). Please note that by default 10.12 SDK is assumed.
Pass `-DCMAKE_OSX_SYSROOT=macosx10.11` argument to cmake call if you'd like to build against Xcode 7.
* CMake
* pkg-config

# Building & installing

* Clone the repo
* Create build dir
* Run CMake. Example (it assumes that the build directory is a child of source directory): `cmake ..`

* Build: `make`

* Now all files should be in `/your/build/directory/path/openmw-deps`, you should specify this path while running CMake for OpenMW later
