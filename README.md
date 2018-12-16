[![Build Status](https://travis-ci.org/OpenMW/openmw-deps-mac.svg?branch=master)](https://travis-ci.org/OpenMW/openmw-deps-mac)

This repository's intent is to provide an automated way to build all dependencies
required for [OpenMW](https://github.com/openmw/openmw).

# Prerequisites

* Xcode, 10.* is recommended, although it's possible to build using an older Xcode version by passing macOS SDK version to CMake like this: `-DCMAKE_OSX_SYSROOT=macosx10.13` (corresponds to Xcode 9.*).
* CMake
* pkg-config
* yasm

# Building & installing

* Clone the repo
* Create build dir
* Run CMake. Example (it assumes that the build directory is a child of source directory): `cmake ..`

* Build: `make`

* Now all files should be in `/your/build/directory/path/openmw-deps`, you should specify this path while running CMake for OpenMW later

# Caveats

## Unwanted libraries on system paths

Some of libraries and frameworks installed in the system paths (Homebrew formulae included) may be picked up during
a build and lead to including unexpected header files or linking with unexpected binaries.
For example, OpenSceneGraph tries to use libtiff if present. Another example can be seen in #35.
To prevent that OS X sandboxing mechanism can be used.

Here's how the example commands above may look like that with `sandbox-exec`:

```bash
$ sandbox-exec -f ../sandbox.sb cmake ..
$ sandbox-exec -f ../sandbox.sb make
```

Please note that sandbox profile assumes that CMake, pkg-config & yasm are installed with Homebrew in default prefix.
