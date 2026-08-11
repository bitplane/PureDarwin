# Currently, just expose headers under include/

add_library(libmalloc_headers INTERFACE)

if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(libmalloc_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libmalloc)
else()
    set(libmalloc_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
endif()

if(NOT EXISTS ${libmalloc_source_dir}/include/malloc/malloc.h)
    message(FATAL_ERROR "libmalloc source tree not found: ${libmalloc_source_dir}")
endif()

target_include_directories(libmalloc_headers INTERFACE ${libmalloc_source_dir}/include)

add_darwin_object_library(libmalloc_runtime)
add_dependencies(libmalloc_runtime libsystem_kernel)
target_sources(libmalloc_runtime PRIVATE
    ${libmalloc_source_dir}/src/radix_tree.c
    ${libmalloc_source_dir}/src/bitarray.c
    ${libmalloc_source_dir}/src/purgeable_malloc.c
    ${libmalloc_source_dir}/src/magazine_large.c
    ${libmalloc_source_dir}/src/magazine_malloc.c
    ${libmalloc_source_dir}/src/magazine_small.c
    ${libmalloc_source_dir}/src/magazine_rack.c
    ${libmalloc_source_dir}/src/legacy_malloc.c
    ${libmalloc_source_dir}/src/vm.c
    ${libmalloc_source_dir}/src/magazine_lite.c
    ${libmalloc_source_dir}/src/malloc.c
    ${libmalloc_source_dir}/src/frozen_malloc.c
    ${libmalloc_source_dir}/src/nano_malloc.c
    ${libmalloc_source_dir}/src/stack_logging_disk.c
    ${libmalloc_source_dir}/src/magazine_tiny.c)
target_include_directories(libmalloc_runtime PRIVATE
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include
    ${PUREDARWIN_SOURCE_DIR}/tools/cctools/include
    ${libmalloc_source_dir}/include
    ${libmalloc_source_dir}/include/malloc
    ${libmalloc_source_dir}/private
    ${libmalloc_source_dir}/src
    ${libmalloc_source_dir}/resolver)
target_include_directories(libmalloc_runtime BEFORE PRIVATE
    $<TARGET_PROPERTY:libsystem_kernel,INTERFACE_INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:xnu_private_headers,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(libmalloc_runtime PRIVATE
    DARWINTEST=1
    PRIVATE=1
    NDEBUG
    _FORTIFY_SOURCE=0
    OSATOMIC_USE_INLINED=1
    OS_UNFAIR_LOCK_INLINE=1)
target_compile_options(libmalloc_runtime PRIVATE
    -momit-leaf-frame-pointer
    -Wno-format-extra-args
    -Wno-format-invalid-specifier)
target_link_libraries(libmalloc_runtime PRIVATE
    architecture_headers
    AvailabilityHeaders
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

add_darwin_circular_library(libsystem_malloc
    INSTALL_NAME /usr/lib/system/libsystem_malloc.dylib
    OBJECT_LIBRARIES libmalloc_runtime
    SIBLINGS libsystem_platform libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
target_link_options(libsystem_malloc PRIVATE
    "LINKER:-umbrella,System"
    "LINKER:-interposable_list,${libmalloc_source_dir}/xcodeconfig/interposable.list")
install(TARGETS libsystem_malloc DESTINATION usr/lib/system COMPONENT BaseSystem)
