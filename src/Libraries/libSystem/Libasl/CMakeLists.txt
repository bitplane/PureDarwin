set(syslog_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/syslog)
set(libasl_source_dir ${syslog_source_dir}/libsystem_asl.tproj)

if(NOT EXISTS ${libasl_source_dir}/src/asl.c)
    message(FATAL_ERROR "syslog source tree not found: ${syslog_source_dir}")
endif()

add_darwin_object_library(libsystem_asl_runtime)
set_property(TARGET libsystem_asl_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)

set(asl_ipc_header ${CMAKE_CURRENT_BINARY_DIR}/asl_ipc.h)
set(asl_ipc_source ${CMAKE_CURRENT_BINARY_DIR}/asl_ipcUser.c)
mig(${syslog_source_dir}/aslcommon/asl_ipc.defs
    INCLUDES_FROM_TARGET libsystem_asl_runtime
    USER_HEADER ${asl_ipc_header}
    USER_SOURCE ${asl_ipc_source}
    NOVOUCHERS)

target_sources(libsystem_asl_runtime PRIVATE
    ${libasl_source_dir}/src/asl_client.c
    ${libasl_source_dir}/src/asl.c
    ${libasl_source_dir}/src/asl_core.c
    ${libasl_source_dir}/src/asl_string.c
    ${libasl_source_dir}/src/asl_fd.c
    ${libasl_source_dir}/src/asl_msg_list.c
    ${libasl_source_dir}/src/asl_file.c
    ${libasl_source_dir}/src/asl_legacy1.c
    ${libasl_source_dir}/src/asl_msg.c
    ${libasl_source_dir}/src/asl_store.c
    ${libasl_source_dir}/src/asl_util.c
    ${libasl_source_dir}/src/asl_object.c
    ${libasl_source_dir}/src/syslog.c
    ${asl_ipc_header}
    ${asl_ipc_source})
target_compile_definitions(libsystem_asl_runtime PRIVATE
    PRIVATE=1
    USE_OBJC=0
    __DARWIN_NON_CANCELABLE=1)
target_compile_options(libsystem_asl_runtime PRIVATE
    -fblocks
    -fno-common
    "SHELL:-include os/base_private.h")
target_include_directories(libsystem_asl_runtime PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${libasl_source_dir}/include
    ${libasl_source_dir}/src
    ${syslog_source_dir}/aslcommon
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libinfo/lookup.subproj
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/launchd/liblaunch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/bsd)
target_link_libraries(libsystem_asl_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    dyld_headers
    libc_private_headers
    libnotify_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(libsystem_asl
    INSTALL_NAME /usr/lib/system/libsystem_asl.dylib
    OBJECT_LIBRARIES libsystem_asl_runtime
    SIBLINGS
        dispatch
        liblaunch
        libsystem_blocks
        libsystem_c
        libsystem_malloc
        libsystem_notify
        libsystem_platform
        libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libsystem_asl DESTINATION usr/lib/system COMPONENT BaseSystem)

