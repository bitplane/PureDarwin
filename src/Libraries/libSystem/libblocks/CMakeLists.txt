set(blocks_source_dir
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch/src/BlocksRuntime)

if(NOT EXISTS ${blocks_source_dir}/runtime.c)
    message(FATAL_ERROR "Blocks runtime source tree not found: ${blocks_source_dir}")
endif()

add_darwin_object_library(libsystem_blocks_runtime)
set_property(TARGET libsystem_blocks_runtime PROPERTY
    POSITION_INDEPENDENT_CODE ON)
target_sources(libsystem_blocks_runtime PRIVATE
    ${blocks_source_dir}/data.c
    ${blocks_source_dir}/runtime.c)
target_compile_definitions(libsystem_blocks_runtime PRIVATE
    __BLOCKS__
    __DARWIN_UNIX03=1
    _FORTIFY_SOURCE=0)
target_compile_options(libsystem_blocks_runtime PRIVATE
    -fblocks
    -fno-common
    -Wno-deprecated-declarations)
target_include_directories(libsystem_blocks_runtime PRIVATE
    ${blocks_source_dir})
target_link_libraries(libsystem_blocks_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    libc_private_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    pthread_common_private_headers
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(libsystem_blocks
    INSTALL_NAME /usr/lib/system/libsystem_blocks.dylib
    OBJECT_LIBRARIES libsystem_blocks_runtime
    SIBLINGS libsystem_c libsystem_malloc libsystem_platform libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libsystem_blocks DESTINATION usr/lib/system COMPONENT BaseSystem)
