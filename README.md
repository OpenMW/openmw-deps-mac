This repository's intent is to provide an automated way to build all dependencies
required for [OpenMW](https://github.com/openmw/openmw).

# Prerequisites

* Xcode with OS X 10.11 SDK (7.0+)
* CMake
* Qt SDK. Only Qt5 is tested so far. Official downloadable SDK is recommended for
making redistributable builds. Otherwise, one from Homebrew should do the trick
* pkg-config

# Building & installing

* Clone the repo
* Create build dir
* Run CMake, Qt SDK path is mandatory. Example (it assumes that the build directory is a child of source directory): `cmake -D PATH_TO_QT=/path/to/Qt/SDK/Qt5/5.5/clang_64 ..`

* Build: `make`

* Now all files should be in `/your/build/directory/path/openmw-deps`, you should specify this path while running CMake for OpenMW later
