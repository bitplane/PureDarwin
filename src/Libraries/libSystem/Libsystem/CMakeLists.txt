set(libsystem_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libsystem)

if(NOT EXISTS ${libsystem_source_dir}/alloc_once_private.h)
    message(FATAL_ERROR "Libsystem source tree not found: ${libsystem_source_dir}")
endif()

set(libsystem_private_include ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${libsystem_private_include}/os)
configure_file(
    ${libsystem_source_dir}/alloc_once_private.h
    ${libsystem_private_include}/os/alloc_once_private.h
    COPYONLY)

add_library(libsystem_private_headers INTERFACE)
target_include_directories(libsystem_private_headers INTERFACE
    ${libsystem_private_include})

add_darwin_shared_library(System INSTALL_NAME /usr/lib/libSystem.B.dylib)
set_target_properties(System PROPERTIES OUTPUT_NAME System.B)
target_sources(System PRIVATE
    ${libsystem_source_dir}/init.c
    ${libsystem_source_dir}/CompatibilityHacks.c
    ${CMAKE_CURRENT_SOURCE_DIR}/missing_runtime.c)
target_include_directories(System PRIVATE
    ${libsystem_source_dir}
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libmalloc/src
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform/private
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libpthread/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libpthread/private
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers)
target_compile_definitions(System PRIVATE
    CURRENT_VARIANT_normal=1)
target_link_libraries(System PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    dyld_headers
    libc_private_headers
    libc_public_headers
    libmalloc_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    pthread_common_headers
    pthread_common_private_headers
    xnu_headers
    xnu_private_headers
    dispatch
    libdyld
    liblaunch
    libsystem_asl
    libsystem_blocks
    libsystem_c
    libsystem_darwin
    libsystem_info
    libsystem_kernel
    libsystem_m
    libsystem_malloc
    libsystem_notify
    libsystem_platform
    libsystem_pthread)
target_link_options(System PRIVATE
    "LINKER:-reexport_library,$<TARGET_FILE:dispatch>"
    "LINKER:-reexport_library,$<TARGET_FILE:libdyld>"
    "LINKER:-reexport_library,$<TARGET_FILE:liblaunch>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_asl>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_blocks>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_c>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_darwin>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_info>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_kernel>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_m>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_malloc>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_notify>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_platform>"
    "LINKER:-reexport_library,$<TARGET_FILE:libsystem_pthread>")

install(TARGETS System DESTINATION usr/lib COMPONENT BaseSystem)
