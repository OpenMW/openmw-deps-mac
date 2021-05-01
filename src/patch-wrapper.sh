#!/bin/sh
set -e

PATCHFILE=$1

if ! patch -N -R -p1 --dry-run --silent < "$PATCHFILE" 2>&1 > /dev/null; then
    patch -p1 < "$PATCHFILE"
else
    echo "It looks like the patch was already applied."
fi
