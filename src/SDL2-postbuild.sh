#!/bin/sh

find . -type f -name '*.dylib' | xargs -I {} sh -c 'echo "-id @rpath/$(basename {}) {}"' | xargs install_name_tool
