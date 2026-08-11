if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(pthread_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libpthread)
else()
    set(pthread_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
endif()

add_library(pthread_common_headers INTERFACE)
target_include_directories(pthread_common_headers INTERFACE
    ${pthread_source_dir}/pthread
    ${pthread_source_dir})

add_library(pthread_common_private_headers INTERFACE)
target_include_directories(pthread_common_private_headers INTERFACE
    ${pthread_source_dir}/private
    ${pthread_source_dir}/src/resolver)

add_darwin_static_library(pthread_dyld)
add_dependencies(pthread_dyld libsystem_kernel_static)
file(COPY ${pthread_source_dir}/private/
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/private_include/pthread)
target_sources(pthread_dyld PRIVATE
    ${pthread_source_dir}/src/resolver/resolver.c
    ${pthread_source_dir}/src/qos.c
    ${pthread_source_dir}/src/pthread.c
    ${pthread_source_dir}/src/pthread_cancelable.c
    ${pthread_source_dir}/src/pthread_cond.c
    ${pthread_source_dir}/src/pthread_mutex.c
    ${pthread_source_dir}/src/pthread_rwlock.c
    ${pthread_source_dir}/src/pthread_support.c
    ${pthread_source_dir}/src/pthread_tsd.c
    ${pthread_source_dir}/src/thread_setup.c
    ${pthread_source_dir}/src/pthread_cwd.c
    ${pthread_source_dir}/src/pthread_atfork.c
    ${pthread_source_dir}/src/pthread_asm.s)
target_include_directories(pthread_dyld PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/private_include
    ${pthread_source_dir}
    ${pthread_source_dir}/private
    ${pthread_source_dir}/src
    ${pthread_source_dir}/src/resolver
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/spawn)
target_include_directories(pthread_dyld BEFORE PRIVATE
    $<TARGET_PROPERTY:xnu_private_headers,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(pthread_dyld PRIVATE
    VARIANT_DYLD=1
    VARIANT_STATIC=1
    __LIBC__
    __DARWIN_UNIX03=1
    __DARWIN_64_BIT_INO_T=1
    __DARWIN_NON_CANCELABLE=1
    __DARWIN_VERS_1050=1
    __PTHREAD_BUILDING_PTHREAD__=1
    _FORTIFY_SOURCE=0)
target_compile_options(pthread_dyld PRIVATE
    -fno-builtin
    -fno-stack-protector
    "SHELL:-include mach/thread_policy.h"
    "SHELL:-include mach/thread_switch.h")
target_link_libraries(pthread_dyld PRIVATE
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
