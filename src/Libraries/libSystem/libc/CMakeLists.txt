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
        ${CMAKE_CURRENT_BINARY_DIR}/include/libc-features.h
    COMMAND ${CMAKE_COMMAND} -E env ARCHS="x86_64 arm64" SRCROOT=${libc_source_dir} DERIVED_FILES_DIR=${CMAKE_CURRENT_BINARY_DIR}/include PLATFORM_NAME=macosx VARIANT_PLATFORM_NAME=macosx RC_BRIDGE=NO perl ${libc_scripts_dir}/generate_features.pl
    COMMENT "Generating libc-features.h"
)

# The perl script won't do this for us
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

add_darwin_object_library(libc_features)

target_include_directories(libc_features INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)

target_sources(libc_features PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/include/libc-features.h
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
