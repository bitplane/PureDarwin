set(libnotify_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libnotify)

if(NOT EXISTS ${libnotify_source_dir}/notify_ipc.defs)
    message(FATAL_ERROR "Libnotify source tree not found: ${libnotify_source_dir}")
endif()

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/servers)
configure_file(
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/launchd/liblaunch/bootstrap.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/servers/bootstrap.h COPYONLY)
file(COPY ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/dispatch/
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/include/dispatch
    FILES_MATCHING PATTERN "*.h")
file(COPY ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/private/
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/include/dispatch
    FILES_MATCHING PATTERN "*.h")
file(COPY ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/os/
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/include/os
    FILES_MATCHING PATTERN "*.h")

add_library(libnotify_headers INTERFACE)
target_include_directories(libnotify_headers INTERFACE
    ${libnotify_source_dir}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/include)
install(FILES
    ${libnotify_source_dir}/notify.h
    DESTINATION usr/include COMPONENT DeveloperTools)

add_darwin_object_library(libsystem_notify_runtime)
set_property(TARGET libsystem_notify_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)
add_dependencies(libsystem_notify_runtime libsystem_kernel_static)

set(libnotify_ipc_header ${CMAKE_CURRENT_BINARY_DIR}/notify_ipc.h)
set(libnotify_ipc_source ${CMAKE_CURRENT_BINARY_DIR}/notify_ipcUser.c)
mig(${libnotify_source_dir}/notify_ipc.defs
    INCLUDES_FROM_TARGET libsystem_notify_runtime
    USER_HEADER ${libnotify_ipc_header}
    USER_SOURCE ${libnotify_ipc_source}
    NOVOUCHERS)

target_sources(libsystem_notify_runtime PRIVATE
    ${libnotify_source_dir}/libnotify.c
    ${libnotify_source_dir}/notify_client.c
    ${libnotify_source_dir}/table.c
    ${libnotify_ipc_source})
target_compile_definitions(libsystem_notify_runtime PRIVATE
    __DARWIN_NON_CANCELABLE=1)
target_compile_options(libsystem_notify_runtime PRIVATE
    -fblocks
    -fno-common
    -fno-exceptions
    "SHELL:-include sys/fileport.h"
    "SHELL:-include ${CMAKE_SOURCE_DIR}/src/Libraries/AvailabilityVersions/include/os/availability.h")
target_include_directories(libsystem_notify_runtime BEFORE PRIVATE
    ${CMAKE_SOURCE_DIR}/src/Libraries/AvailabilityVersions/include)
target_include_directories(libsystem_notify_runtime PRIVATE
    ${libnotify_source_dir}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/launchd/liblaunch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/src/BlocksRuntime
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/EXTERNAL_HEADERS)
target_link_libraries(libsystem_notify_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    libc_private_headers
    libnotify_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(libsystem_notify
    INSTALL_NAME /usr/lib/system/libsystem_notify.dylib
    OBJECT_LIBRARIES libsystem_notify_runtime
    SIBLINGS
        libsystem_blocks
        libsystem_c
        libsystem_malloc
        libsystem_platform
        libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libsystem_notify DESTINATION usr/lib/system COMPONENT BaseSystem)
