#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 external-source-root" >&2
    exit 2
fi

SOURCE_ROOT=$1
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ASL_SOURCE=$SOURCE_ROOT/libplatform/src/simple/asl.c
ASL_PATCH=$SCRIPT_DIR/../patches/libplatform-161.20.1/0001-return-an-error-when-asl-socket-creation-fails.patch

if grep -q 'if (fd == -1) return;' "$ASL_SOURCE"; then
    patch -d "$SOURCE_ROOT/libplatform" -p1 < "$ASL_PATCH"
fi
grep -q 'if (fd == -1) return -1;' "$ASL_SOURCE"
