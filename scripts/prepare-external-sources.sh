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
LIBC_DIRSTAT_SOURCE=$SOURCE_ROOT/libc/libdarwin/dirstat.c
LIBC_DIRSTAT_PATCH=$SCRIPT_DIR/../patches/libc-1244.30.3/0001-build-dirstat-without-private-apfs-headers.patch
LIBC_VARIANT_PATCH=$SCRIPT_DIR/../patches/libc-1244.30.3/0002-build-os-variant-without-private-xpc.patch
LIBDISPATCH_INTERNAL=$SOURCE_ROOT/libdispatch/src/internal.h
LIBDISPATCH_ASSERT_PATCH=$SCRIPT_DIR/../patches/libdispatch-913.30.4/0001-avoid-typeof-on-bit-fields.patch

if grep -q 'if (fd == -1) return;' "$ASL_SOURCE"; then
    patch -d "$SOURCE_ROOT/libplatform" -p1 < "$ASL_PATCH"
fi
grep -q 'if (fd == -1) return -1;' "$ASL_SOURCE"

if grep -q '^#if !TARGET_OS_SIMULATOR$' "$LIBC_DIRSTAT_SOURCE"; then
    patch -d "$SOURCE_ROOT/libc" -p1 < "$LIBC_DIRSTAT_PATCH"
fi
grep -q '__has_include(<apfs/apfs_fsctl.h>)' "$LIBC_DIRSTAT_SOURCE"
grep -q '__has_include(<xpc/xpc.h>)' "$SOURCE_ROOT/libc/libdarwin/variant.c" || {
    patch -d "$SOURCE_ROOT/libc" -p1 < "$LIBC_VARIANT_PATCH"
}

if ! grep -q 'long _e = (long)(e);' "$LIBDISPATCH_INTERNAL"; then
    patch -d "$SOURCE_ROOT/libdispatch" -p1 < "$LIBDISPATCH_ASSERT_PATCH"
fi
grep -q 'long _e = (long)(e);' "$LIBDISPATCH_INTERNAL"
