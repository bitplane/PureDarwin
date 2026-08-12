# Currently, just expose standard headers under include

if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(libc_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libc)
    set(libc_scripts_dir ${libc_source_dir}/xcodescripts)
else()
    set(libc_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
    set(libc_scripts_dir ${libc_source_dir}/scripts)
endif()

if(NOT EXISTS ${libc_scripts_dir}/headers.sh)
    message(FATAL_ERROR "Libc source tree not found: ${libc_source_dir}")
endif()

# We need to generate libc-features.h for even the public headers to work
# THIS IS NOT TRUE. sys/cdefs.h in the include/ directory here IS NOT the actual public header.
# We need to exclude it from our search paths.
add_custom_command(
    OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/include/x86_64/libc-features.h
    COMMAND ${CMAKE_COMMAND} -E env ARCHS=x86_64 SRCROOT=${libc_source_dir} DERIVED_FILES_DIR=${CMAKE_CURRENT_BINARY_DIR}/include PLATFORM_NAME=macosx VARIANT_PLATFORM_NAME=macosx RC_BRIDGE=NO perl ${libc_scripts_dir}/generate_features.pl
    COMMENT "Generating libc-features.h"
)

# The perl script won't do this for us
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

add_darwin_object_library(libc_features)

target_include_directories(libc_features INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/include/x86_64)

target_sources(libc_features PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/include/x86_64/libc-features.h
)

# END GENERATE libc-features.h

# We install the standard C headers to a skeleton tree here
set(libc_headers_dir ${CMAKE_CURRENT_BINARY_DIR}/headers)

add_custom_command(
    OUTPUT ${libc_headers_dir}/libc_headers.stamp
    COMMAND ${CMAKE_COMMAND} -E env ARCHS="arm64 x86_64"
        SRCROOT=${libc_source_dir}
        DERIVED_FILES_DIR=${CMAKE_CURRENT_BINARY_DIR}
        ACTION=installhdrs
        PLATFORM_NAME=macosx
        VARIANT_PLATFORM_NAME=macosx
        RC_BRIDGE=NO
        DEPLOYMENT_LOCATION=NO
        DSTROOT=${libc_headers_dir}
        PUBLIC_HEADERS_FOLDER_PATH=usr/include
        PRIVATE_HEADERS_FOLDER_PATH=usr/local/include
        BUILT_PRODUCTS_DIR=${libc_headers_dir}
        SDK_INSTALL_HEADERS_ROOT=""
        sh -c "${libc_scripts_dir}/headers.sh"
    COMMAND ${CMAKE_COMMAND} -E touch ${libc_headers_dir}/libc_headers.stamp
    COMMENT "Copying libC headers..."
)
add_custom_target(libc_headers_gen_script DEPENDS ${libc_headers_dir}/libc_headers.stamp)

add_library(libc_headers_gen INTERFACE)
add_library(libc_headers_gen_private INTERFACE)

target_include_directories(libc_headers_gen INTERFACE ${libc_headers_dir}/usr/include)
add_dependencies(libc_headers_gen INTERFACE libc_headers_gen_script)

target_include_directories(libc_headers_gen_private INTERFACE
    ${libc_headers_dir}/usr/include
    ${libc_headers_dir}/usr/local/include
    ${libc_headers_dir}/System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders
    ${libc_headers_dir}/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders
)

# This is the only public header directory
install(DIRECTORY ${libc_headers_dir}/usr/include DESTINATION usr COMPONENT DeveloperTools)

# These are private
install(DIRECTORY ${libc_headers_dir}/usr/local/include DESTINATION usr/local COMPONENT DeveloperInternal)
install(DIRECTORY ${libc_headers_dir}/System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders DESTINATION System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders COMPONENT DeveloperInternal)
install(DIRECTORY ${libc_headers_dir}/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders DESTINATION System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders COMPONENT DeveloperInternal)

# END GENERATE INCLUDE DIRECTORY

add_library(libc_private_headers INTERFACE)
add_library(libc_kernel_headers INTERFACE)
add_library(libc_public_headers INTERFACE)

# stdlib.h includes malloc/_malloc.h
target_link_libraries(libc_public_headers INTERFACE libmalloc_headers)

# private headers implies public headers
target_link_libraries(libc_private_headers INTERFACE libc_public_headers)

# Make sure we install headers before use
target_link_libraries(libc_public_headers INTERFACE libc_headers_gen)
target_link_libraries(libc_kernel_headers INTERFACE libc_headers_gen)

target_include_directories(libc_public_headers INTERFACE ${libc_headers_dir}/usr/include)

target_include_directories(libc_private_headers INTERFACE ${libc_headers_dir}/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders)
target_include_directories(libc_private_headers INTERFACE ${libc_headers_dir}/usr/local/include)

target_include_directories(libc_kernel_headers INTERFACE ${libc_headers_dir}/System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders)

# END HEADER INTERFACE

add_darwin_static_library(libc_dyld)
target_sources(libc_dyld PRIVATE
    ${libc_source_dir}/gen/FreeBSD/arc4random.c
    ${libc_source_dir}/gen/FreeBSD/closedir.c
    ${libc_source_dir}/gen/dirfd.c
    ${libc_source_dir}/gen/FreeBSD/getcwd.c
    ${libc_source_dir}/gen/FreeBSD/getpagesize.c
    ${libc_source_dir}/gen/nanosleep.c
    ${libc_source_dir}/gen/FreeBSD/opendir.c
    ${libc_source_dir}/gen/FreeBSD/readdir.c
    ${libc_source_dir}/gen/FreeBSD/scandir.c
    ${libc_source_dir}/gen/FreeBSD/sysctl.c
    ${libc_source_dir}/gen/FreeBSD/sysctlbyname.c
    ${libc_source_dir}/gen/FreeBSD/telldir.c
    ${libc_source_dir}/gen/FreeBSD/usleep.c
    ${libc_source_dir}/stdlib/FreeBSD/atexit.c
    ${libc_source_dir}/stdlib/FreeBSD/exit.c
    ${libc_source_dir}/sys/gettimeofday.c
    ${libc_source_dir}/stdlib/FreeBSD/heapsort.c
    ${libc_source_dir}/stdlib/FreeBSD/merge.c
    ${libc_source_dir}/stdlib/FreeBSD/qsort.c
    ${libc_source_dir}/stdlib/FreeBSD/reallocf.c
    ${libc_source_dir}/stdlib/FreeBSD/realpath.c
    ${libc_source_dir}/string/bcopy.c
    ${libc_source_dir}/string/FreeBSD/strdup.c
    ${libc_source_dir}/string/FreeBSD/strrchr.c
    ${libc_source_dir}/string/FreeBSD/strstr.c
    ${libc_source_dir}/string/strcat.c
    ${libc_source_dir}/string/strlcat.c
    ${libc_source_dir}/string/strlcpy.c
    ${libc_source_dir}/string/FreeBSD/strnlen.c
    ${libc_source_dir}/secure/memset_chk.c
    compat/flsl.c
    ${libc_source_dir}/uuid/uuidsrc/copy.c
    ${libc_source_dir}/x86_64/string/strcpy.s
    ${libc_source_dir}/x86_64/string/strlen.s
    ${libc_source_dir}/x86_64/string/strncpy.s
    ${libc_source_dir}/x86_64/string/strnlen.s
    ${libc_source_dir}/sys/_libc_init.c)
set(libc_dyld_freebsd_sources
    ${libc_source_dir}/gen/FreeBSD/arc4random.c
    ${libc_source_dir}/gen/FreeBSD/closedir.c
    ${libc_source_dir}/gen/FreeBSD/getcwd.c
    ${libc_source_dir}/gen/FreeBSD/getpagesize.c
    ${libc_source_dir}/gen/FreeBSD/opendir.c
    ${libc_source_dir}/gen/FreeBSD/readdir.c
    ${libc_source_dir}/gen/FreeBSD/scandir.c
    ${libc_source_dir}/gen/FreeBSD/sysctl.c
    ${libc_source_dir}/gen/FreeBSD/sysctlbyname.c
    ${libc_source_dir}/gen/FreeBSD/telldir.c
    ${libc_source_dir}/gen/FreeBSD/usleep.c
    ${libc_source_dir}/stdlib/FreeBSD/atexit.c
    ${libc_source_dir}/stdlib/FreeBSD/exit.c
    ${libc_source_dir}/stdlib/FreeBSD/heapsort.c
    ${libc_source_dir}/stdlib/FreeBSD/merge.c
    ${libc_source_dir}/stdlib/FreeBSD/qsort.c
    ${libc_source_dir}/stdlib/FreeBSD/reallocf.c
    ${libc_source_dir}/stdlib/FreeBSD/realpath.c
    ${libc_source_dir}/string/FreeBSD/strdup.c
    ${libc_source_dir}/string/FreeBSD/strnlen.c
    ${libc_source_dir}/string/FreeBSD/strrchr.c
    ${libc_source_dir}/string/FreeBSD/strstr.c)
set_source_files_properties(${libc_dyld_freebsd_sources} PROPERTIES
    COMPILE_OPTIONS "-include;${libc_source_dir}/fbsdcompat/_fbsd_compat_.h")
set_source_files_properties(
    ${libc_source_dir}/gen/FreeBSD/closedir.c
    ${libc_source_dir}/gen/FreeBSD/opendir.c
    ${libc_source_dir}/gen/FreeBSD/readdir.c
    ${libc_source_dir}/gen/FreeBSD/scandir.c
    ${libc_source_dir}/gen/FreeBSD/telldir.c
    PROPERTIES COMPILE_OPTIONS
    "-include;${libc_source_dir}/fbsdcompat/_fbsd_compat_.h;-include;${libc_source_dir}/gen/__dirent.h")
target_include_directories(libc_dyld PRIVATE
    ${libc_source_dir}/fbsdcompat
    ${libc_source_dir}/gen
    ${libc_source_dir}/gen/FreeBSD
    ${libc_source_dir}/locale
    ${libc_source_dir}/stdlib
    ${libc_source_dir}/string
    ${libc_source_dir}/uuid/uuidsrc
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/src/BlocksRuntime)
target_compile_definitions(libc_dyld PRIVATE
    HAVE_STDINT_H=1
    __LIBC__
    __DARWIN_UNIX03=1
    __DARWIN_64_BIT_INO_T=1
    __DARWIN_NON_CANCELABLE=0
    __DARWIN_VERS_1050=1
    _FORTIFY_SOURCE=0
    VARIANT_STATIC=1
    VARIANT_CANCELABLE=1
    VARIANT_DARWINEXTSN=1)
target_link_libraries(libc_dyld PRIVATE
    AvailabilityHeaders
    clang_bootstrap_headers
    libc_features
    libc_private_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_private_headers
    libsystem_kernel_private_headers
    libsystem_kernel_static
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

# Apple's libc project describes the source membership of each archive in its
# PBX project.  Read those build phases directly so the Linux build follows the
# pinned Apple source release without maintaining a second source manifest.
function(libc_pbx_sources output target)
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${PUREDARWIN_SOURCE_DIR}/scripts/pbx-sources.py
            ${libc_source_dir}/Libc.xcodeproj/project.pbxproj ${target}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE source_text
        ERROR_VARIABLE error_text
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Unable to read libc target ${target}: ${error_text}")
    endif()
    string(REPLACE "\n" ";" sources "${source_text}")
    list(TRANSFORM sources PREPEND "${libc_source_dir}/")
    set(existing_sources)
    foreach(source IN LISTS sources)
        if(EXISTS ${source})
            list(APPEND existing_sources ${source})
        endif()
    endforeach()
    set(${output} ${existing_sources} PARENT_SCOPE)
endfunction()

function(add_libc_object_group name)
    add_darwin_object_library(${name})
    target_compile_definitions(${name} PRIVATE
        HAVE_STDINT_H=1
        BUILDING_LIBC
        PRIVATE=1
        __LIBC__
        __DARWIN_UNIX03=1
        __DARWIN_64_BIT_INO_T=1
        __DARWIN_NON_CANCELABLE=1
        __DARWIN_VERS_1050=1
        _FORTIFY_SOURCE=0)
    target_compile_options(${name} PRIVATE
        -fdollars-in-identifiers
        -fno-common
        -Wno-deprecated-declarations
        -Wno-implicit-function-declaration
        -Wno-int-conversion
        -Wno-nullability-completeness)
    target_include_directories(${name} PRIVATE
        ${libc_source_dir}
        ${libc_source_dir}/darwin
        ${libc_source_dir}/gen
        ${libc_source_dir}/include
        ${libc_source_dir}/locale
        ${libc_source_dir}/locale/FreeBSD
        ${libc_source_dir}/stdtime/FreeBSD
        ${libc_source_dir}/stdio
        ${libc_source_dir}/stdio/FreeBSD
        ${libc_source_dir}/include/NetBSD
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libinfo/lookup.subproj
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libinfo/membership.subproj
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libinfo/gen.subproj
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libnotify
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/src/BlocksRuntime
        ${CMAKE_CURRENT_BINARY_DIR}/resolver_headers
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libmalloc/private
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libmalloc/src
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/syslog/libsystem_asl.tproj/include
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libm/Source/Intel
        ${CMAKE_CURRENT_SOURCE_DIR}/compat
        ${PUREDARWIN_SOURCE_DIR}/src/Libraries/libSystem/corecrypto/include
        ${PUREDARWIN_SOURCE_DIR}/tools/cctools/include)
    target_include_directories(${name} PRIVATE
        ${PUREDARWIN_SOURCE_DIR}/tools/cctools/include/foreign)
    target_compile_options(${name} PRIVATE
        "SHELL:-isystem ${PUREDARWIN_CLANG_RESOURCE_DIR}/include")
    target_include_directories(${name} BEFORE PRIVATE
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/spawn)
    target_include_directories(${name} PRIVATE
        ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/libproc)
    target_link_libraries(${name} PRIVATE
        AvailabilityHeaders
        architecture_headers
        clang_bootstrap_headers
        CrashReporterClient_headers
        libc_features
        libc_private_headers
        libplatform_headers
        libplatform_private_headers
        libsystem_kernel_private_headers
        libsystem_private_headers
        pthread_common_headers
        pthread_common_private_headers
        xnu_private_headers
        xnu_headers
        xnu_kernel_headers
        xnu_kernel_private_headers
    )
endfunction()

execute_process(
    COMMAND ${CMAKE_C_COMPILER} -print-resource-dir
    OUTPUT_VARIABLE PUREDARWIN_CLANG_RESOURCE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/resolver_headers/arpa)
configure_file(
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libresolv/nameser.h
    ${CMAKE_CURRENT_BINARY_DIR}/resolver_headers/arpa/nameser.h COPYONLY)
configure_file(
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libresolv/nameser.h
    ${CMAKE_CURRENT_BINARY_DIR}/resolver_headers/nameser.h COPYONLY)
configure_file(
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libresolv/resolv.h
    ${CMAKE_CURRENT_BINARY_DIR}/resolver_headers/resolv.h COPYONLY)

libc_pbx_sources(libc_platform_sources Platform)
list(FILTER libc_platform_sources INCLUDE REGEX "/(darwin/init_cpu_capabilities\\.c|x86_64/)")
add_libc_object_group(libc_platform_runtime)
target_sources(libc_platform_runtime PRIVATE ${libc_platform_sources})

libc_pbx_sources(libc_base_sources Base)
list(FILTER libc_base_sources EXCLUDE REGEX
    "/(darwin/kvm|gen/nlist|string/strcpy|string/strlen|string/strncpy|string/strnlen|sys/OSMemoryNotification)\\.c$")
add_libc_object_group(libc_base_runtime)
target_sources(libc_base_runtime PRIVATE ${libc_base_sources})
set_source_files_properties(${libc_source_dir}/gen/backtrace.c PROPERTIES
    COMPILE_OPTIONS "-include;mach/mach.h")

libc_pbx_sources(libc_freebsd_sources FreeBSD)
list(FILTER libc_freebsd_sources EXCLUDE REGEX "/gdtoa/FreeBSD/machdep_ldis(d|dd|Q)\\.c$")
add_libc_object_group(libc_freebsd_runtime)
target_sources(libc_freebsd_runtime PRIVATE ${libc_freebsd_sources})
# Apple's source release omits the user-space corecrypto DRBG used by the
# normal arc4random variant.  Build Libc's complete entropy-backed fallback.
set_source_files_properties(${libc_source_dir}/gen/FreeBSD/arc4random.c
    PROPERTIES COMPILE_DEFINITIONS VARIANT_STATIC=1)
target_include_directories(libc_freebsd_runtime PRIVATE
    ${libc_source_dir}/fbsdcompat
    ${libc_source_dir}/gdtoa
    ${libc_source_dir}/gdtoa/FreeBSD)
target_compile_options(libc_freebsd_runtime PRIVATE
    "SHELL:-include ${libc_source_dir}/fbsdcompat/_fbsd_compat_.h")
set_source_files_properties(
    ${libc_source_dir}/gen/FreeBSD/closedir.c
    ${libc_source_dir}/gen/FreeBSD/opendir.c
    ${libc_source_dir}/gen/FreeBSD/readdir.c
    ${libc_source_dir}/gen/FreeBSD/rewinddir.c
    ${libc_source_dir}/gen/FreeBSD/seekdir.c
    ${libc_source_dir}/gen/FreeBSD/telldir.c
    PROPERTIES COMPILE_OPTIONS
    "-include;${libc_source_dir}/gen/__dirent.h")
set_source_files_properties(${libc_source_dir}/stdio/FreeBSD/mktemp.c
    PROPERTIES COMPILE_DEFINITIONS "TRUE=1;FALSE=0")

libc_pbx_sources(libc_netbsd_sources NetBSD)
add_libc_object_group(libc_netbsd_runtime)
target_sources(libc_netbsd_runtime PRIVATE ${libc_netbsd_sources})
target_include_directories(libc_netbsd_runtime PRIVATE ${libc_source_dir}/nbsdcompat)
target_compile_options(libc_netbsd_runtime PRIVATE
    "SHELL:-include ${libc_source_dir}/nbsdcompat/_nbsd_compat_.h")

libc_pbx_sources(libc_tre_sources TRE)
add_libc_object_group(libc_tre_runtime)
target_sources(libc_tre_runtime PRIVATE ${libc_tre_sources})
target_compile_definitions(libc_tre_runtime PRIVATE HAVE_CONFIG_H)
target_include_directories(libc_tre_runtime PRIVATE
    ${libc_source_dir}/regex/FreeBSD
    ${libc_source_dir}/regex/TRE
    ${libc_source_dir}/regex/TRE/lib)

libc_pbx_sources(libc_fortify_sources FortifySource)
add_libc_object_group(libc_fortify_runtime)
target_sources(libc_fortify_runtime PRIVATE ${libc_fortify_sources})
