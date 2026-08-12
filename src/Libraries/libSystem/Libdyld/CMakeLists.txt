set(dyld_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld)

add_darwin_shared_library(libdyld_bootstrap
    INSTALL_NAME /usr/lib/system/libdyld.dylib)
set_target_properties(libdyld_bootstrap PROPERTIES OUTPUT_NAME dyld_bootstrap)
set_target_properties(libdyld_bootstrap PROPERTIES LINKER_LANGUAGE C)
target_sources(libdyld_bootstrap PRIVATE
    ${dyld_source_dir}/src/dyld_stub_binder.s)
target_include_directories(libdyld_bootstrap PRIVATE
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/EXTERNAL_HEADERS
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform/include)
target_link_libraries(libdyld_bootstrap PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    xnu_headers
    xnu_private_headers)
target_link_options(libdyld_bootstrap PRIVATE
    "LINKER:-flat_namespace"
    "LINKER:-undefined,suppress")

execute_process(
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/pbx-sources.py
        ${dyld_source_dir}/dyld.xcodeproj/project.pbxproj libdyld.dylib
    OUTPUT_VARIABLE libdyld_source_text
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
string(REPLACE "\n" ";" libdyld_source_paths "${libdyld_source_text}")
set(libdyld_sources)
foreach(libdyld_source_path IN LISTS libdyld_source_paths)
    if(NOT libdyld_source_path MATCHES "\\.defs$")
        list(APPEND libdyld_sources ${dyld_source_dir}/${libdyld_source_path})
    endif()
endforeach()

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/servers)
configure_file(
    ${PUREDARWIN_SOURCE_DIR}/tools/cctools/include/foreign/servers/bootstrap.h
    ${CMAKE_CURRENT_BINARY_DIR}/servers/bootstrap.h COPYONLY)

add_darwin_object_library(libdyld_runtime)
set_property(TARGET libdyld_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)

set(closured_protocol_header ${CMAKE_CURRENT_BINARY_DIR}/closuredProtocol.h)
set(closured_protocol_source ${CMAKE_CURRENT_BINARY_DIR}/closuredProtocolUser.c)
mig(${dyld_source_dir}/dyld3/closured/closuredProtocol.defs
    INCLUDES_FROM_TARGET libdyld_runtime
    USER_HEADER ${closured_protocol_header}
    USER_SOURCE ${closured_protocol_source}
    NOVOUCHERS)

target_sources(libdyld_runtime PRIVATE
    ${PUREDARWIN_SOURCE_DIR}/src/Libraries/dyld/common_digest.c
    ${PUREDARWIN_SOURCE_DIR}/src/Libraries/dyld/compat/libcxx_abort.cpp
    ${libdyld_sources}
    ${dyld_source_dir}/dyld3/libclosured-stub.cpp
    ${closured_protocol_header}
    ${closured_protocol_source})
target_include_directories(libdyld_runtime PRIVATE
    $<TARGET_PROPERTY:libc_public_headers,INTERFACE_INCLUDE_DIRECTORIES>
    ${CMAKE_CURRENT_SOURCE_DIR}/compat
    ${CMAKE_CURRENT_BINARY_DIR}
    ${dyld_source_dir}/include
    ${dyld_source_dir}/include/mach-o
    ${dyld_source_dir}/src
    ${dyld_source_dir}/dyld3
    ${dyld_source_dir}/dyld3/shared-cache
    ${dyld_source_dir}/dyld3/closured
    ${PUREDARWIN_SOURCE_DIR}/src/Libraries/dyld/compat
    ${PUREDARWIN_SOURCE_DIR}/src/Libraries/libSystem/corecrypto/include
    ${PUREDARWIN_SOURCE_DIR}/tools/cctools/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/src/BlocksRuntime
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/launchd/liblaunch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform/private
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/mach
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/libproc
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libm/Source/Intel
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/include)
target_compile_definitions(libdyld_runtime PRIVATE
    BUILDING_LIBDYLD=1
    DYLD_IN_PROCESS=1
    DYLD_VERSION=519.2.2
    _LIBCPP_NO_EXCEPTIONS=1)
target_compile_options(libdyld_runtime PRIVATE
    -fblocks
    -fno-exceptions
    -fno-rtti
    -stdlib=libc++
    -Wno-deprecated-declarations
    -Wno-four-char-constants
    -Wno-unknown-pragmas)
target_link_libraries(libdyld_runtime PRIVATE
    AvailabilityHeaders
    CrashReporterClient_headers
    architecture_headers
    clang_bootstrap_headers
    corecrypto_static
    cxx_dyld
    cxxabi_dyld
    dyld_headers
    host_commoncrypto_headers
    host_commoncrypto_private_headers
    libc_dyld
    libc_public_headers
    libc_private_headers
    libplatform_headers
    libplatform_dyld
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    pthread_common_private_headers
    pthread_dyld
    unwind_dyld
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(libdyld
    INSTALL_NAME /usr/lib/system/libdyld.dylib
    OBJECT_LIBRARIES libdyld_runtime
    SIBLINGS
        dispatch
        liblaunch
        libsystem_blocks
        libsystem_c
        libsystem_malloc
        libsystem_platform
        libsystem_pthread
    DEPENDENCIES
        corecrypto_static
        cxx_dyld
        cxxabi_dyld
        unwind_dyld
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libdyld DESTINATION usr/lib/system COMPONENT BaseSystem)
