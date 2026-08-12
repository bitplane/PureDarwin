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
    set_property(TARGET ${name} PROPERTY POSITION_INDEPENDENT_CODE ON)
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
    COMMAND ${Python3_EXECUTABLE} ${PUREDARWIN_SOURCE_DIR}/scripts/xcconfig.py
        ${libc_scripts_dir}/libc.xcconfig BASE_EXCLUDED_SOURCE_FILE_NAMES
        CURRENT_ARCH=x86_64 PLATFORM_NAME=macosx
    RESULT_VARIABLE result
    OUTPUT_VARIABLE libc_arch_excluded_sources
    ERROR_VARIABLE error_text
    OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT result EQUAL 0)
    message(FATAL_ERROR "Unable to read libc architecture exclusions: ${error_text}")
endif()
separate_arguments(libc_arch_excluded_sources UNIX_COMMAND
    "${libc_arch_excluded_sources}")

function(add_libc_pbx_group name target)
    cmake_parse_arguments(GROUP "" "INCLUDE;EXCLUDE" "" ${ARGN})
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${PUREDARWIN_SOURCE_DIR}/scripts/pbx-sources.py
            ${libc_source_dir}/Libc.xcodeproj/project.pbxproj ${target}
            --xcconfig ${libc_scripts_dir}/libc.xcconfig
        RESULT_VARIABLE result
        OUTPUT_VARIABLE source_records
        ERROR_VARIABLE error_text
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Unable to read libc target ${target}: ${error_text}")
    endif()
    string(REPLACE "\n" ";" source_records "${source_records}")
    set(group_sources)
    foreach(record IN LISTS source_records)
        string(REPLACE "\t" ";" fields "${record}")
        list(GET fields 0 source)
        set(source_path ${libc_source_dir}/${source})
        get_filename_component(source_name ${source} NAME)
        if(NOT EXISTS ${source_path})
            continue()
        endif()
        if(NOT target STREQUAL "Platform")
            list(FIND libc_arch_excluded_sources ${source_name} excluded_index)
            if(NOT excluded_index EQUAL -1)
                continue()
            endif()
        endif()
        if(GROUP_INCLUDE AND NOT source_path MATCHES "${GROUP_INCLUDE}")
            continue()
        endif()
        if(GROUP_EXCLUDE AND source_path MATCHES "${GROUP_EXCLUDE}")
            continue()
        endif()
        list(APPEND group_sources ${source_path})
        list(LENGTH fields field_count)
        if(field_count GREATER 1)
            list(GET fields 1 source_flags)
            separate_arguments(source_flags UNIX_COMMAND "${source_flags}")
            foreach(flag IN LISTS source_flags)
                set_property(SOURCE ${source_path} APPEND PROPERTY COMPILE_OPTIONS
                    "$<$<STREQUAL:$<TARGET_PROPERTY:NAME>,${name}>:${flag}>")
            endforeach()
        endif()
    endforeach()
    add_libc_object_group(${name})
    target_sources(${name} PRIVATE ${group_sources})
endfunction()

function(add_libc_variant name variant target)
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${PUREDARWIN_SOURCE_DIR}/scripts/pbx-sources.py
            ${libc_source_dir}/Libc.xcodeproj/project.pbxproj ${target}
            --variant-xcconfig ${libc_scripts_dir}/variants.xcconfig
            --variant ${variant}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE source_records
        ERROR_VARIABLE error_text
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Unable to read libc variant ${variant}: ${error_text}")
    endif()
    string(REPLACE "\n" ";" source_records "${source_records}")
    set(variant_sources)
    foreach(record IN LISTS source_records)
        string(REPLACE "\t" ";" fields "${record}")
        list(GET fields 0 source)
        list(APPEND variant_sources ${libc_source_dir}/${source})
        list(LENGTH fields field_count)
        if(field_count GREATER 1)
            list(GET fields 1 source_flags)
            separate_arguments(source_flags UNIX_COMMAND "${source_flags}")
            foreach(flag IN LISTS source_flags)
                set_property(SOURCE ${libc_source_dir}/${source} APPEND PROPERTY
                    COMPILE_OPTIONS
                    "$<$<STREQUAL:$<TARGET_PROPERTY:NAME>,${name}>:${flag}>")
            endforeach()
        endif()
    endforeach()
    add_libc_object_group(${name})
    target_sources(${name} PRIVATE ${variant_sources})
    # Variant sources include FreeBSD compatibility headers by quoted name,
    # but must still use Libc's own <sys/cdefs.h> for ABI suffix selection.
    target_compile_options(${name} PRIVATE
        "SHELL:-iquote ${libc_source_dir}/fbsdcompat"
        "SHELL:-include ${libc_source_dir}/fbsdcompat/sys/cdefs.h")
    execute_process(
        COMMAND ${Python3_EXECUTABLE} ${PUREDARWIN_SOURCE_DIR}/scripts/xcconfig.py
            ${libc_scripts_dir}/variants.xcconfig VARIANT_PREPROCESSOR_MACROS
            VARIANT=${variant} PLATFORM_NAME=macosx CURRENT_ARCH=x86_64
        RESULT_VARIABLE result
        OUTPUT_VARIABLE variant_flags
        ERROR_VARIABLE error_text
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Unable to read libc variant flags ${variant}: ${error_text}")
    endif()
    separate_arguments(variant_flags UNIX_COMMAND "${variant_flags}")
    target_compile_options(${name} PRIVATE ${variant_flags})
    if(variant MATCHES "CANCELABLE")
        target_compile_options(${name} PRIVATE
            -U__DARWIN_NON_CANCELABLE -D__DARWIN_NON_CANCELABLE=0)
    endif()
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

add_library(libresolv_headers INTERFACE)
target_include_directories(libresolv_headers INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/resolver_headers)

add_libc_pbx_group(libc_platform_runtime Platform
    INCLUDE "/(darwin/init_cpu_capabilities\\.c|x86_64/)")
add_libc_pbx_group(libc_base_runtime Base)
target_sources(libc_base_runtime PRIVATE
    compat/flsl.c
    ${CMAKE_SOURCE_DIR}/tools/cctools/libmacho/getsecbyname.c)
target_include_directories(libc_base_runtime PRIVATE
    ${CMAKE_SOURCE_DIR}/tools/cctools/include)
set_source_files_properties(${libc_source_dir}/gen/backtrace.c PROPERTIES
    COMPILE_OPTIONS "-include;mach/mach.h")

add_libc_pbx_group(libc_freebsd_runtime FreeBSD
    EXCLUDE "/gdtoa/FreeBSD/machdep_ldis(d|dd|Q)\\.c$")
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
set_property(SOURCE
    ${libc_source_dir}/gen/FreeBSD/closedir.c
    ${libc_source_dir}/gen/FreeBSD/opendir.c
    ${libc_source_dir}/gen/FreeBSD/readdir.c
    ${libc_source_dir}/gen/FreeBSD/rewinddir.c
    ${libc_source_dir}/gen/FreeBSD/seekdir.c
    ${libc_source_dir}/gen/FreeBSD/telldir.c
    APPEND PROPERTY COMPILE_OPTIONS
    "-include;${libc_source_dir}/gen/__dirent.h")
set_source_files_properties(${libc_source_dir}/stdio/FreeBSD/mktemp.c
    PROPERTIES COMPILE_DEFINITIONS "TRUE=1;FALSE=0")

add_libc_pbx_group(libc_netbsd_runtime NetBSD)
target_include_directories(libc_netbsd_runtime PRIVATE ${libc_source_dir}/nbsdcompat)
target_compile_options(libc_netbsd_runtime PRIVATE
    "SHELL:-include ${libc_source_dir}/nbsdcompat/_nbsd_compat_.h")

add_libc_pbx_group(libc_tre_runtime TRE)
target_compile_definitions(libc_tre_runtime PRIVATE HAVE_CONFIG_H)
target_include_directories(libc_tre_runtime PRIVATE
    ${libc_source_dir}/regex/FreeBSD
    ${libc_source_dir}/regex/TRE
    ${libc_source_dir}/regex/TRE/lib)

add_libc_pbx_group(libc_fortify_runtime FortifySource)

add_libc_variant(libc_cancelable_runtime CANCELABLE Variant_Cancelable)
add_libc_variant(libc_darwinextsn_runtime DARWINEXTSN Variant_DarwinExtsn)
add_libc_variant(libc_darwinextsn_cancelable_runtime
    DARWINEXTSN_CANCELABLE Variant_DarwinExtsn_Cancelable)
add_libc_variant(libc_pre1050_runtime PRE1050 Variant_Pre1050)
add_libc_variant(libc_inode32_runtime INODE32 Variant_Inode32)

add_darwin_circular_library(libsystem_c
    INSTALL_NAME /usr/lib/system/libsystem_c.dylib
    OBJECT_LIBRARIES
        libc_platform_runtime
        libc_base_runtime
        libc_freebsd_runtime
        libc_netbsd_runtime
        libc_tre_runtime
        libc_fortify_runtime
        libc_cancelable_runtime
        libc_darwinextsn_runtime
        libc_darwinextsn_cancelable_runtime
        libc_pre1050_runtime
        libc_inode32_runtime
    STRONG_SIBLINGS libsystem_platform
    SIBLINGS
        dispatch
        liblaunch
        libsystem_asl
        libsystem_blocks
        libsystem_info
        libsystem_m
        libsystem_malloc
        libsystem_notify
        libsystem_pthread
        libsystem_platform
    STRONG_DEPENDENCIES CrashReporterClient libsystem_kernel
    LINK_OPTIONS
        "LINKER:-umbrella,System"
        "LINKER:-undefined,dynamic_lookup")
target_link_options(libsystem_c PRIVATE
    "LINKER:-alias_list,${libc_scripts_dir}/alias.list")
install(TARGETS libsystem_c DESTINATION usr/lib/system COMPONENT BaseSystem)

libc_pbx_sources(libsystem_darwin_sources libsystem_darwin.dylib)
add_libc_object_group(libsystem_darwin_runtime)
target_sources(libsystem_darwin_runtime PRIVATE ${libsystem_darwin_sources})
target_include_directories(libsystem_darwin_runtime PRIVATE
    ${libc_source_dir}/libdarwin)
add_darwin_circular_library(libsystem_darwin
    INSTALL_NAME /usr/lib/system/libsystem_darwin.dylib
    OBJECT_LIBRARIES libsystem_darwin_runtime
    SIBLINGS
        libsystem_c
        libsystem_malloc
        libsystem_platform
        libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libsystem_darwin DESTINATION usr/lib/system COMPONENT BaseSystem)
