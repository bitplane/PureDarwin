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
LAUNCHD_VPROC_INTERNAL=$SOURCE_ROOT/launchd/liblaunch/vproc_internal.h
LAUNCHD_CLIENT_PATCH=$SCRIPT_DIR/../patches/launchd-842.92.1/0001-keep-client-mig-headers-out-of-launchd-internals.patch
SYSLOG_ASL_MSG_HEADER=$SOURCE_ROOT/syslog/libsystem_asl.tproj/include/asl_msg.h
SYSLOG_ASL_SOURCE=$SOURCE_ROOT/syslog/libsystem_asl.tproj/src/asl.c
SYSLOG_OPTIONAL_SPI_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0001-build-asl-without-unpublished-spis.patch
SYSLOG_ASL_OS_LOG_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0002-build-asl-without-unpublished-os-log.patch
SYSLOG_ACTIVITY_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0003-build-asl-without-unpublished-activity.patch
SYSLOG_ACTIVITY_REPAIR_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0004-complete-partial-activity-preparation.patch
SYSLOG_ACTIVITY_METADATA_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0005-disable-unpublished-activity-metadata.patch
SYSLOG_ASL_UTIL_SOURCE=$SOURCE_ROOT/syslog/libsystem_asl.tproj/src/asl_util.c
SYSLOG_BLOCKS_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0006-build-asl-utilities-without-blocks.patch
SYSLOG_SOURCE=$SOURCE_ROOT/syslog/libsystem_asl.tproj/src/syslog.c
SYSLOG_LEGACY_OS_LOG_PATCH=$SCRIPT_DIR/../patches/syslog-356.50.1/0007-build-syslog-without-unpublished-os-log.patch
XNU_OSKEXT_SOURCE=$SOURCE_ROOT/xnu/libkern/c++/OSKext.cpp
XNU_BOOT_KEXT_PATCH=$SCRIPT_DIR/../patches/xnu-4570.41.2/0001-allow-kernel-boot-to-link-external-extensions.patch
XNU_COMMPAGE_SOURCE=$SOURCE_ROOT/xnu/osfmk/i386/commpage/commpage.c
XNU_COMMPAGE_PATCH=$SCRIPT_DIR/../patches/xnu-4570.41.2/0002-keep-kernel-commpage-mapping-writable.patch
XNU_BOOTSTRAP_SOURCE=$SOURCE_ROOT/xnu/libsa/bootstrap.cpp
XNU_KEC_PATCH=$SCRIPT_DIR/../patches/xnu-4570.41.2/0003-load-declared-kernel-external-components.patch
XNU_EXPORTS=$SOURCE_ROOT/xnu/config/Private.exports
XNU_PRNG_EXPORT_PATCH=$SCRIPT_DIR/../patches/xnu-4570.41.2/0004-export-prng-registration-to-corecrypto.patch

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

if ! grep -q 'PUREDARWIN_LIBLAUNCH_CLIENT' "$LAUNCHD_VPROC_INTERNAL"; then
    patch -d "$SOURCE_ROOT/launchd" -p1 < "$LAUNCHD_CLIENT_PATCH"
fi
grep -q 'PUREDARWIN_LIBLAUNCH_CLIENT' "$LAUNCHD_VPROC_INTERNAL"

if ! grep -q 'PUREDARWIN_NO_XPC' "$SYSLOG_ASL_MSG_HEADER"; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_OPTIONAL_SPI_PATCH"
fi
grep -q 'PUREDARWIN_NO_XPC' "$SYSLOG_ASL_MSG_HEADER"

if ! grep -B1 '#include <os/activity.h>' "$SYSLOG_ASL_SOURCE" | grep -q 'PUREDARWIN_NO_OS_ACTIVITY'; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_ACTIVITY_PATCH"
fi
grep -B1 '#include <os/activity.h>' "$SYSLOG_ASL_SOURCE" | grep -q 'PUREDARWIN_NO_OS_ACTIVITY'

if ! grep -B1 'os_activity_id_t osaid;' "$SYSLOG_ASL_SOURCE" | grep -q 'PUREDARWIN_NO_OS_ACTIVITY'; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_ACTIVITY_REPAIR_PATCH"
fi
grep -B1 'os_activity_id_t osaid;' "$SYSLOG_ASL_SOURCE" | grep -q 'PUREDARWIN_NO_OS_ACTIVITY'

if ! grep -B1 '/\* OSActivityID \*/' "$SYSLOG_ASL_SOURCE" | grep -q 'PUREDARWIN_NO_OS_ACTIVITY'; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_ACTIVITY_METADATA_PATCH"
fi
grep -B1 '/\* OSActivityID \*/' "$SYSLOG_ASL_SOURCE" | grep -q 'PUREDARWIN_NO_OS_ACTIVITY'

if ! grep -q 'PUREDARWIN_NO_OS_LOG' "$SYSLOG_ASL_SOURCE"; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_ASL_OS_LOG_PATCH"
fi
grep -q 'PUREDARWIN_NO_OS_LOG' "$SYSLOG_ASL_SOURCE"

if ! grep -B1 '#include <Block.h>' "$SYSLOG_ASL_UTIL_SOURCE" | grep -q 'PUREDARWIN_NO_XPC'; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_BLOCKS_PATCH"
fi
grep -B1 '#include <Block.h>' "$SYSLOG_ASL_UTIL_SOURCE" | grep -q 'PUREDARWIN_NO_XPC'

if ! grep -q 'PUREDARWIN_NO_OS_LOG' "$SYSLOG_SOURCE"; then
    patch -d "$SOURCE_ROOT/syslog" -p1 < "$SYSLOG_LEGACY_OS_LOG_PATCH"
fi
grep -q 'PUREDARWIN_NO_OS_LOG' "$SYSLOG_SOURCE"

if ! grep -q 'all non-booter callers must be entitled' "$XNU_OSKEXT_SOURCE"; then
    patch -d "$SOURCE_ROOT/xnu" -p1 < "$XNU_BOOT_KEXT_PATCH"
fi
grep -q 'all non-booter callers must be entitled' "$XNU_OSKEXT_SOURCE"

if grep -A4 'mach_make_memory_entry( kernel_map' "$XNU_COMMPAGE_SOURCE" | grep -q '^[[:space:]]*uperm,'; then
    patch -d "$SOURCE_ROOT/xnu" -p1 < "$XNU_COMMPAGE_PATCH"
fi
grep -A4 'mach_make_memory_entry( kernel_map' "$XNU_COMMPAGE_SOURCE" \
    | grep -q 'VM_PROT_READ | VM_PROT_WRITE'

if grep -q '^#define COM_APPLE_KEC' "$XNU_BOOTSTRAP_SOURCE"; then
    patch -d "$SOURCE_ROOT/xnu" -p1 < "$XNU_KEC_PATCH"
fi
! grep -q '^#define COM_APPLE_KEC' "$XNU_BOOTSTRAP_SOURCE"

if ! grep -q '^_register_and_init_prng$' "$XNU_EXPORTS"; then
    patch -d "$SOURCE_ROOT/xnu" -p1 < "$XNU_PRNG_EXPORT_PATCH"
fi
grep -q '^_register_and_init_prng$' "$XNU_EXPORTS"
