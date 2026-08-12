set(libdispatch_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch)

if(NOT EXISTS ${libdispatch_source_dir}/src/queue.c)
    message(FATAL_ERROR "Libdispatch source tree not found: ${libdispatch_source_dir}")
endif()

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/config)
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/../libdispatch/config/config.h
    ${CMAKE_CURRENT_BINARY_DIR}/config/config.h COPYONLY)
configure_file(
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libpthread/private/tsd_private.h
    ${CMAKE_CURRENT_BINARY_DIR}/pthread_machdep.h COPYONLY)

add_darwin_object_library(libdispatch_runtime)
set_property(TARGET libdispatch_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)

set(protocol_header ${CMAKE_CURRENT_BINARY_DIR}/protocol.h)
set(protocol_server_header ${CMAKE_CURRENT_BINARY_DIR}/protocolServer.h)
set(protocol_server_source ${CMAKE_CURRENT_BINARY_DIR}/protocolServer.c)
mig(${libdispatch_source_dir}/src/protocol.defs
    INCLUDES_FROM_TARGET libdispatch_runtime
    USER_HEADER ${protocol_header}
    SERVER_HEADER ${protocol_server_header}
    SERVER_SOURCE ${protocol_server_source}
    NOVOUCHERS)

set(firehose_header ${CMAKE_CURRENT_BINARY_DIR}/firehose.h)
mig(${libdispatch_source_dir}/src/firehose/firehose.defs
    INCLUDES_FROM_TARGET libdispatch_runtime
    USER_HEADER ${firehose_header}
    NOVOUCHERS)

set(firehose_reply_server_header
    ${CMAKE_CURRENT_BINARY_DIR}/firehose_replyServer.h)
set(firehose_reply_server_source
    ${CMAKE_CURRENT_BINARY_DIR}/firehose_replyServer.c)
mig(${libdispatch_source_dir}/src/firehose/firehose_reply.defs
    INCLUDES_FROM_TARGET libdispatch_runtime
    SERVER_HEADER ${firehose_reply_server_header}
    SERVER_SOURCE ${firehose_reply_server_source}
    NOVOUCHERS)

target_sources(libdispatch_runtime PRIVATE
    ${libdispatch_source_dir}/resolver/resolver.c
    ${libdispatch_source_dir}/src/init.c
    ${libdispatch_source_dir}/src/object.c
    ${libdispatch_source_dir}/src/block.cpp
    ${libdispatch_source_dir}/src/shims/lock.c
    ${libdispatch_source_dir}/src/semaphore.c
    ${libdispatch_source_dir}/src/once.c
    ${libdispatch_source_dir}/src/queue.c
    ${libdispatch_source_dir}/src/apply.c
    ${libdispatch_source_dir}/src/source.c
    ${libdispatch_source_dir}/src/mach.c
    ${libdispatch_source_dir}/src/event/event.c
    ${libdispatch_source_dir}/src/event/event_kevent.c
    ${libdispatch_source_dir}/src/voucher.c
    ${libdispatch_source_dir}/src/firehose/firehose_buffer.c
    ${libdispatch_source_dir}/src/io.c
    ${libdispatch_source_dir}/src/data.c
    ${libdispatch_source_dir}/src/transform.c
    ${libdispatch_source_dir}/src/time.c
    ${libdispatch_source_dir}/src/allocator.c
    ${libdispatch_source_dir}/src/benchmark.c
    ${firehose_header}
    ${protocol_server_source}
    ${firehose_reply_server_source})

target_include_directories(libdispatch_runtime PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${libdispatch_source_dir}
    ${libdispatch_source_dir}/private
    ${libdispatch_source_dir}/src
    ${libdispatch_source_dir}/src/BlocksRuntime
    ${libdispatch_source_dir}/src/event
    ${libdispatch_source_dir}/src/firehose
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/bsd
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/libproc)
target_compile_definitions(libdispatch_runtime PRIVATE
    DISPATCH_USE_DTRACE=0
    PRIVATE=1
    USE_OBJC=0
    __DARWIN_NON_CANCELABLE=1
    DISPATCH_USE_INTERNAL_WORKQUEUE=0
    HAVE_PTHREAD_WORKQUEUES=1
    TARGET_OS_MACOSX=1)
target_compile_options(libdispatch_runtime PRIVATE
    -fblocks
    -fno-exceptions
    "SHELL:-include os/base_private.h"
    -Wno-deprecated-declarations)
target_link_libraries(libdispatch_runtime PRIVATE
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

add_darwin_circular_library(dispatch
    INSTALL_NAME /usr/lib/system/libdispatch.dylib
    OBJECT_LIBRARIES libdispatch_runtime
    SIBLINGS
        libsystem_blocks
        libsystem_c
        libsystem_malloc
        libsystem_platform
        libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS dispatch DESTINATION usr/lib/system COMPONENT BaseSystem)
