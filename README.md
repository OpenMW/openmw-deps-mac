This repository's intent is to provide an automated way to build all dependencies
required for [OpenMW](https://github.com/openmw/openmw).

# Current limitations

Currently this repo doesn't include Boost libraries. If you just want to build
OpenMW and play around, I recommend using Homebrew to install them. If you want
to redistribute, please use this [Homebrew tap](https://github.com/openmw/homebrew-openmw)
and `openmw-boost` formula. It's a temporary solution, though, and this tap will
go away eventually.

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
