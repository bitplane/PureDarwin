set(launchd_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/launchd)
set(liblaunch_source_dir ${launchd_source_dir}/liblaunch)

if(NOT EXISTS ${liblaunch_source_dir}/liblaunch.c)
    message(FATAL_ERROR "launchd source tree not found: ${launchd_source_dir}")
endif()

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/servers)
configure_file(
    ${liblaunch_source_dir}/bootstrap.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/servers/bootstrap.h COPYONLY)

add_darwin_object_library(liblaunch_runtime)
set_property(TARGET liblaunch_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)

set(job_header ${CMAKE_CURRENT_BINARY_DIR}/job.h)
set(job_source ${CMAKE_CURRENT_BINARY_DIR}/jobUser.c)
mig(${launchd_source_dir}/src/job.defs
    INCLUDES_FROM_TARGET liblaunch_runtime
    USER_HEADER ${job_header}
    USER_SOURCE ${job_source}
    NOVOUCHERS)

set(helper_header ${CMAKE_CURRENT_BINARY_DIR}/helper.h)
set(helper_source ${CMAKE_CURRENT_BINARY_DIR}/helperUser.c)
set(helper_server_header ${CMAKE_CURRENT_BINARY_DIR}/helperServer.h)
set(helper_server_source ${CMAKE_CURRENT_BINARY_DIR}/helperServer.c)
mig(${launchd_source_dir}/src/helper.defs
    INCLUDES_FROM_TARGET liblaunch_runtime
    USER_HEADER ${helper_header}
    USER_SOURCE ${helper_source}
    SERVER_HEADER ${helper_server_header}
    SERVER_SOURCE ${helper_server_source}
    NOVOUCHERS)

target_sources(liblaunch_runtime PRIVATE
    ${liblaunch_source_dir}/liblaunch.c
    ${liblaunch_source_dir}/libvproc.c
    ${liblaunch_source_dir}/libbootstrap.c
    ${job_header}
    ${job_source}
    ${helper_header}
    ${helper_source}
    ${helper_server_header}
    ${helper_server_source})
target_compile_options(liblaunch_runtime PRIVATE
    -fblocks
    -fno-common
    "SHELL:-include os/base_private.h")
target_compile_definitions(liblaunch_runtime PRIVATE
    PRIVATE=1
    PUREDARWIN_LIBLAUNCH_CLIENT=1
    USE_OBJC=0
    XPC_BUILDING_LAUNCHD=1
    __DARWIN_NON_CANCELABLE=1
    _DARWIN_USE_64_BIT_INODE=1)
target_include_directories(liblaunch_runtime PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/include
    ${liblaunch_source_dir}
    ${launchd_source_dir}/src
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libinfo/lookup.subproj
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch)
target_link_libraries(liblaunch_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    libc_private_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(liblaunch
    INSTALL_NAME /usr/lib/system/liblaunch.dylib
    OBJECT_LIBRARIES liblaunch_runtime
    SIBLINGS
        libsystem_blocks
        libsystem_c
        libsystem_malloc
        libsystem_platform
        libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
target_link_libraries(liblaunch PRIVATE dispatch_firstpass)
install(TARGETS liblaunch DESTINATION usr/lib/system COMPONENT BaseSystem)
