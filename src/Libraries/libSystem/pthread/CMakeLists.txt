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
    ${CMAKE_CURRENT_BINARY_DIR}/private_include
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
    "$<$<COMPILE_LANGUAGE:C>:SHELL:-include mach/thread_policy.h>"
    "$<$<COMPILE_LANGUAGE:C>:SHELL:-include mach/thread_switch.h>")
target_link_libraries(pthread_dyld PRIVATE
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

add_darwin_object_library(pthread_runtime)
target_sources(pthread_runtime PRIVATE
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
    ${pthread_source_dir}/src/pthread_asm.s
    ${pthread_source_dir}/src/variants/pthread_cancelable_cancel.c)
set_source_files_properties(
    ${pthread_source_dir}/src/variants/pthread_cancelable_cancel.c
    PROPERTIES COMPILE_OPTIONS
    "-U__DARWIN_NON_CANCELABLE;-D__DARWIN_NON_CANCELABLE=0")
target_include_directories(pthread_runtime PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/private_include
    ${pthread_source_dir}
    ${pthread_source_dir}/private
    ${pthread_source_dir}/src
    ${pthread_source_dir}/src/resolver
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/spawn)
target_include_directories(pthread_runtime BEFORE PRIVATE
    $<TARGET_PROPERTY:xnu_private_headers,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(pthread_runtime PRIVATE
    LIBC_ALIAS_PTHREAD_CANCEL
    LIBC_ALIAS_PTHREAD_COND_INIT
    LIBC_ALIAS_PTHREAD_COND_TIMEDWAIT
    LIBC_ALIAS_PTHREAD_COND_WAIT
    LIBC_ALIAS_PTHREAD_JOIN
    LIBC_ALIAS_PTHREAD_RWLOCK_DESTROY
    LIBC_ALIAS_PTHREAD_RWLOCK_INIT
    LIBC_ALIAS_PTHREAD_RWLOCK_RDLOCK
    LIBC_ALIAS_PTHREAD_RWLOCK_TRYRDLOCK
    LIBC_ALIAS_PTHREAD_RWLOCK_TRYWRLOCK
    LIBC_ALIAS_PTHREAD_RWLOCK_UNLOCK
    LIBC_ALIAS_PTHREAD_RWLOCK_WRLOCK
    LIBC_ALIAS_PTHREAD_SETCANCELSTATE
    LIBC_ALIAS_PTHREAD_SETCANCELTYPE
    LIBC_ALIAS_PTHREAD_SIGMASK
    LIBC_ALIAS_PTHREAD_TESTCANCEL
    LIBC_ALIAS_SIGWAIT
    PRIVATE=1
    __LIBC__
    __DARWIN_UNIX03=1
    __DARWIN_64_BIT_INO_T=1
    __DARWIN_NON_CANCELABLE=1
    __DARWIN_VERS_1050=1
    __PTHREAD_BUILDING_PTHREAD__=1
    _FORTIFY_SOURCE=0)
target_compile_options(pthread_runtime PRIVATE
    -fno-builtin
    -fno-stack-protector
    -momit-leaf-frame-pointer
    "$<$<COMPILE_LANGUAGE:C>:SHELL:-include mach/thread_policy.h>"
    "$<$<COMPILE_LANGUAGE:C>:SHELL:-include mach/thread_switch.h>")
target_link_libraries(pthread_runtime PRIVATE
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

add_darwin_circular_library(libsystem_pthread
    INSTALL_NAME /usr/lib/system/libsystem_pthread.dylib
    OBJECT_LIBRARIES pthread_runtime
    SIBLINGS libsystem_platform
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
target_link_options(libsystem_pthread PRIVATE
    "LINKER:-alias_list,${pthread_source_dir}/xcodescripts/pthread.aliases"
)
install(TARGETS libsystem_pthread DESTINATION usr/lib/system COMPONENT BaseSystem)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
    DESTINATION usr/include
    COMPONENT DeveloperTools)
