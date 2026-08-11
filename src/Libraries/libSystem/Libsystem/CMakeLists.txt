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
