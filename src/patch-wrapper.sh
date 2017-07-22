#!/bin/sh

PATCHFILE=$1

if ! patch -N -R -p1 --dry-run --silent < "$PATCHFILE"; then
    patch -p1 < "$PATCHFILE"
else
    echo "It looks like patch was already applied"
fi
