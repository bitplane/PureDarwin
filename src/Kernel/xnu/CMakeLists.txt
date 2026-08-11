find_program(dsymutil_path NAMES dsymutil llvm-dsymutil REQUIRED)
find_program(bash_path NAMES bash REQUIRED)

if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(xnu_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu)
    set(xnu_external_source TRUE)
else()
    set(xnu_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
    set(xnu_external_source FALSE)
endif()

if(NOT EXISTS ${xnu_source_dir}/Makefile)
    message(FATAL_ERROR "XNU source tree not found: ${xnu_source_dir}")
endif()

set(xnu_host_cflags "")
if(NOT APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
    # XNU's make-built host tools do not inherit the CMake host options.
    set(xnu_host_cflags "-D__arm64__=1 -fsigned-char")
endif()

include(ProcessorCount)
ProcessorCount(host_cpu_count)
if(host_cpu_count EQUAL 0)
    set(host_cpu_count 1)
endif()
set(PUREDARWIN_BUILD_JOBS ${host_cpu_count} CACHE STRING "Parallel XNU build jobs")
set(xnu_make_environment
    SYSCTL_HW_PHYSICALCPU=${PUREDARWIN_BUILD_JOBS}
    SYSCTL_HW_LOGICALCPU=${PUREDARWIN_BUILD_JOBS}
    MAKEJOBS=--jobs=${PUREDARWIN_BUILD_JOBS}
    MEMORY_SIZE=268435456
    SDKROOT_RESOLVED=/
    HOST_SDKROOT_RESOLVED=/
    PLATFORM=MacOSX
    SDKVERSION=10.13
    HOST_OS_VERSION=11.0
    CC=${CMAKE_C_COMPILER}
    CXX=${CMAKE_CXX_COMPILER}
    PUREDARWIN_HOST_CCTOOLS_INCLUDE=${PUREDARWIN_SOURCE_DIR}/tools/cctools/include
    PUREDARWIN_HOST_LIBMACHO=$<TARGET_FILE:host_libmacho>
    PUREDARWIN_HOST_LIBSTUFF=$<TARGET_FILE:host_libstuff>
    PUREDARWIN_HOST_CFLAGS=${xnu_host_cflags}
    HOST_CC=${CMAKE_C_COMPILER}
    HOST_FLEX=flex
    HOST_BISON=bison
    HOST_GM4=m4
    HOST_CODESIGN=true
    HOST_CODESIGN_ALLOCATE=$<TARGET_FILE:host_codesign_allocate>
    EMBEDDED_DEVICE_MAP=false
    MIG=${PUREDARWIN_SOURCE_DIR}/tools/mig/mig.sh
    MIGCOM=$<TARGET_FILE:migcom>
    STRIP=$<TARGET_FILE:host_strip>
    LIPO=$<TARGET_FILE:host_lipo>
    LIBTOOL=$<TARGET_FILE:host_libtool>
    NM=$<TARGET_FILE:host_nm>
    NMEDIT=$<TARGET_FILE:host_nmedit>
    UNIFDEF=$<TARGET_FILE:unifdef>
    DSYMUTIL=${dsymutil_path}
    CTFCONVERT=$<TARGET_FILE:host_ctfconvert>
    CTFMERGE=$<TARGET_FILE:host_ctfmerge>
    CTFINSERT=$<TARGET_FILE:host_ctf_insert>
    SHELL=${bash_path}
    PUREDARWIN_TARGET_TRIPLE=${PUREDARWIN_TARGET_TRIPLE}
)

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install)
externalproject_add(xnu_headers.extproj
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_build
    SOURCE_DIR ${xnu_source_dir}
    CONFIGURE_COMMAND true # disable auto CMake configure
    BUILD_COMMAND
        cmake
            -D XNU_SRC=${xnu_source_dir}
            -D XNU_EXTERNAL_SOURCE=${xnu_external_source}
            -D XNU_OBJ=<BINARY_DIR>
            -D PUREDARWIN_TARGET_TRIPLE=${PUREDARWIN_TARGET_TRIPLE}
            -D CODESIGN_ALLOCATE_PATH=$<TARGET_FILE:host_codesign_allocate>
            -D CTFCONVERT_PATH=$<TARGET_FILE:host_ctfconvert>
            -D CTFMERGE_PATH=$<TARGET_FILE:host_ctfmerge>
            -D CTFINSERT_PATH=$<TARGET_FILE:host_ctf_insert>
            -D AVAILABILITY_PL_PATH=$<TARGET_FILE:availability.pl>
            -D MIG_PATH=${PUREDARWIN_SOURCE_DIR}/tools/mig/mig.sh
            -D MIGCOM_PATH=$<TARGET_FILE:migcom>
            -D STRIP_PATH=$<TARGET_FILE:host_strip>
            -D LIPO_PATH=$<TARGET_FILE:host_lipo>
            -D NM_PATH=$<TARGET_FILE:host_nm>
            -D NMEDIT_PATH=$<TARGET_FILE:host_nmedit>
            -D LIBTOOL_PATH=$<TARGET_FILE:host_libtool>
            -D UNIFDEF_PATH=$<TARGET_FILE:unifdef>
            -D DSYMUTIL_PATH=${dsymutil_path}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/preprocess_files.cmake
    COMMAND
        make -C <SOURCE_DIR> installhdrs ${xnu_make_environment}
            MAKE_SYMBOL_ALIASING=<BINARY_DIR>/bsd/sys/make_symbol_aliasing.sh
            ARCH_CONFIGS=X86_64 BUILD_LTO=0
            BUILD_WERROR=0 DO_CTFMERGE=0 KERNEL_CONFIGS=RELEASE
            PUREDARWIN_LD_PATH=$<TARGET_FILE:host_ld>
            PUREDARWIN_FIREHOSE_LIBRARY_DIR=$<TARGET_FILE_DIR:libfirehose_kernel>
            PUREDARWIN_FIREHOSE_INCLUDE=$<TARGET_PROPERTY:libfirehose_kernel,INTERFACE_INCLUDE_DIRECTORIES>
            PUREDARWIN_PROFILE_RUNTIME=${profile_runtime_library_path}
            PUREDARWIN_PTHREAD_INCLUDE=$<TARGET_PROPERTY:pthread_common_headers,INTERFACE_INCLUDE_DIRECTORIES>
            PUREDARWIN_AVAILABILITY_INCLUDE=$<TARGET_PROPERTY:AvailabilityHeaders,INTERFACE_INCLUDE_DIRECTORIES>
            SRCROOT=${xnu_source_dir} OBJROOT=<BINARY_DIR>
            DSTROOT=${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install
    INSTALL_COMMAND true # installed during build
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
)
add_dependencies(xnu_headers.extproj host_codesign_allocate
    migcom host_strip host_lipo host_nm unifdef host_nmedit
    host_ctfconvert host_ctfmerge availability.pl)

add_library(xnu_headers INTERFACE)
add_dependencies(xnu_headers xnu_headers.extproj)
target_include_directories(xnu_headers INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install/usr/include
)
add_library(xnu_private_headers INTERFACE)
add_dependencies(xnu_private_headers xnu_headers.extproj)
target_include_directories(xnu_private_headers INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install/usr/local/include
    ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders
)
target_compile_options(xnu_private_headers INTERFACE
    -F${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install/System/Library/Frameworks
)
add_library(xnu_kernel_headers INTERFACE)
add_dependencies(xnu_kernel_headers xnu_headers.extproj)
target_include_directories(xnu_kernel_headers INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install/System/Library/Frameworks/Kernel.framework/Versions/A/Headers
)
add_library(xnu_kernel_private_headers INTERFACE)
add_dependencies(xnu_kernel_private_headers xnu_headers.extproj)
target_include_directories(xnu_kernel_private_headers INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/xnu_header_install/System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders
)



externalproject_add(xnu
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/xnu_build
    SOURCE_DIR ${xnu_source_dir}
    CONFIGURE_COMMAND true # disable auto CMake configure
    BUILD_COMMAND
        cmake
            -D XNU_SRC=${xnu_source_dir}
            -D XNU_EXTERNAL_SOURCE=${xnu_external_source}
            -D XNU_OBJ=<BINARY_DIR>
            -D PUREDARWIN_TARGET_TRIPLE=${PUREDARWIN_TARGET_TRIPLE}
            -D CODESIGN_ALLOCATE_PATH=$<TARGET_FILE:host_codesign_allocate>
            -D CTFCONVERT_PATH=$<TARGET_FILE:host_ctfconvert>
            -D CTFMERGE_PATH=$<TARGET_FILE:host_ctfmerge>
            -D CTFINSERT_PATH=$<TARGET_FILE:host_ctf_insert>
            -D AVAILABILITY_PL_PATH=$<TARGET_FILE:availability.pl>
            -D LD_PATH=$<TARGET_FILE:host_ld>
            -D MIG_PATH=${PUREDARWIN_SOURCE_DIR}/tools/mig/mig.sh
            -D MIGCOM_PATH=$<TARGET_FILE:migcom>
            -D STRIP_PATH=$<TARGET_FILE:host_strip>
            -D LIPO_PATH=$<TARGET_FILE:host_lipo>
            -D NM_PATH=$<TARGET_FILE:host_nm>
            -D NMEDIT_PATH=$<TARGET_FILE:host_nmedit>
            -D LIBTOOL_PATH=$<TARGET_FILE:host_libtool>
            -D UNIFDEF_PATH=$<TARGET_FILE:unifdef>
            -D DSYMUTIL_PATH=${dsymutil_path}
            -D FIREHOSE_KERNEL_LIBRARY_PATH=$<TARGET_FILE:libfirehose_kernel>
            -D FIREHOSE_KERNEL_LIBRARY_DIR=$<TARGET_FILE_DIR:libfirehose_kernel>
            -D FIREHOSE_KERNEL_HEADER_PATH=$<TARGET_PROPERTY:libfirehose_kernel,INTERFACE_INCLUDE_DIRECTORIES>
            -D PROFILE_RUNTIME_LIBRARY_PATH=${profile_runtime_library_path}
            -D PTHREAD_HEADER_PATH=$<TARGET_PROPERTY:pthread_common_headers,INTERFACE_INCLUDE_DIRECTORIES>
            -P ${CMAKE_CURRENT_SOURCE_DIR}/preprocess_files.cmake
    COMMAND
        make -C <SOURCE_DIR> install ${xnu_make_environment}
            MAKE_SYMBOL_ALIASING=<BINARY_DIR>/bsd/sys/make_symbol_aliasing.sh
            ARCH_CONFIGS=X86_64 BUILD_LTO=0
            BUILD_WERROR=0 DO_CTFMERGE=0 KERNEL_CONFIGS=RELEASE
            SRCROOT=${xnu_source_dir} OBJROOT=<BINARY_DIR>
            SYMROOT=${CMAKE_CURRENT_BINARY_DIR}/xnu_sym DSTROOT=${CMAKE_CURRENT_BINARY_DIR}/xnu
    INSTALL_COMMAND true # installed during build
    USES_TERMINAL_CONFIGURE TRUE
    USES_TERMINAL_BUILD TRUE
)
add_dependencies(xnu
    xnu_headers libfirehose_kernel host_codesign_allocate host_ctfconvert host_ctfmerge
    migcom host_strip host_lipo host_nm unifdef host_nmedit availability.pl host_ld
    dyld_availability_headers
)
if(TARGET compiler_rt_profile)
    add_dependencies(xnu compiler_rt_profile)
endif()

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/Kernel.framework/Versions/A/Resources DESTINATION System/Library/Frameworks/Kernel.framework/Versions/A COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/Kernel.framework/Versions/A/Headers DESTINATION System/Library/Frameworks/Kernel.framework/Versions/A COMPONENT DeveloperTools)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/Kernel.framework/Versions/A/PrivateHeaders DESTINATION System/Library/Frameworks/Kernel.framework/Versions/A COMPONENT DeveloperInternal)

# Note: This really ought to be associated with a custom build command like 'install_framework_symlinks' or something
install_symlink(System/Library/Frameworks/Kernel.framework/Versions/Current Versions/A COMPONENT BaseSystem)
install_symlink(System/Library/Frameworks/Kernel.framework/Resources Versions/Current/Resources COMPONENT BaseSystem)
install_symlink(System/Library/Frameworks/Kernel.framework/Headers Versions/Current/Headers COMPONENT DeveloperTools)
install_symlink(System/Library/Frameworks/Kernel.framework/PrivateHeaders Versions/Current/PrivateHeaders COMPONENT DeveloperInternal)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders DESTINATION System/Library/Frameworks/System.framework/Versions/B COMPONENT DeveloperInternal)

install_symlink(System/Library/Frameworks/System.framework/Versions/Current Versions/B COMPONENT BaseSystem)
install_symlink(System/Library/Frameworks/System.framework/PrivateHeaders Versions/Current/PrivateHeaders COMPONENT DeveloperInternal)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/DriverKit.framework/Versions/A/Headers DESTINATION System/Library/Frameworks/DriverKit.framework/Versions/A COMPONENT DeveloperTools)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/DriverKit.framework/Versions/A/PrivateHeaders DESTINATION System/Library/Frameworks/DriverKit.framework/Versions/A COMPONENT DeveloperInternal)

install_symlink(System/Library/Frameworks/DriverKit.framework/Versions/Current Versions/A COMPONENT BaseSystem)
install_symlink(System/Library/Frameworks/DriverKit.framework/Headers Versions/Current/Headers COMPONENT DeveloperTools)
install_symlink(System/Library/Frameworks/DriverKit.framework/PrivateHeaders Versions/Current/PrivateHeaders COMPONENT DeveloperInternal)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/IOKit.framework/Versions/A/Headers DESTINATION System/Library/Frameworks/IOKit.framework/Versions/A COMPONENT DeveloperTools)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Frameworks/IOKit.framework/Versions/A/PrivateHeaders DESTINATION System/Library/Frameworks/IOKit.framework/Versions/A COMPONENT DeveloperInternal)

install_symlink(System/Library/Frameworks/IOKit.framework/Versions/Current Versions/A COMPONENT BaseSystem)
install_symlink(System/Library/Frameworks/IOKit.framework/Headers Versions/Current/Headers COMPONENT DeveloperTools)
install_symlink(System/Library/Frameworks/IOKit.framework/PrivateHeaders Versions/Current/PrivateHeaders COMPONENT DeveloperInternal)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Kernels DESTINATION System/Library COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/System/Library/Extensions DESTINATION System/Library COMPONENT BaseSystem)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/usr/include DESTINATION usr COMPONENT DeveloperTools)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/usr/lib DESTINATION usr COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/usr/libexec DESTINATION usr COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/usr/share/man DESTINATION usr/share COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/usr/share/misc DESTINATION usr/share COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/xnu/usr/local DESTINATION usr COMPONENT DeveloperInternal)
