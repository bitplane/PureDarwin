add_darwin_static_library(libfirehose_kernel)
set_property(TARGET libfirehose_kernel PROPERTY OUTPUT_NAME "firehose_kernel")

if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(libfirehose_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch)
    set(libfirehose_include_dir ${libfirehose_source_dir})
    set(libfirehose_internal_dir ${libfirehose_source_dir}/src/firehose)
    set(libfirehose_xnu_include_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libkern/firehose)
else()
    set(libfirehose_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
    set(libfirehose_include_dir ${libfirehose_source_dir}/include)
    set(libfirehose_internal_dir ${libfirehose_source_dir}/src)
endif()

if(NOT EXISTS ${libfirehose_internal_dir}/firehose_buffer.c)
    message(FATAL_ERROR "libdispatch firehose source tree not found: ${libfirehose_source_dir}")
endif()

target_sources(libfirehose_kernel PRIVATE
    ${libfirehose_internal_dir}/firehose_buffer.c
)

target_include_directories(libfirehose_kernel PUBLIC ${libfirehose_include_dir})
target_include_directories(libfirehose_kernel PRIVATE ${libfirehose_internal_dir})
if(libfirehose_xnu_include_dir)
    target_include_directories(libfirehose_kernel PRIVATE ${libfirehose_xnu_include_dir})
endif()
target_compile_definitions(libfirehose_kernel PRIVATE
    KERNEL=1 DISPATCH_USE_DTRACE=0 OS_ATOMIC_CONFIG_MEMORY_ORDER_DEPENDENCY=1
    OS_ATOMIC_CONFIG_MEMORY_ORDER_DEPENDENCY=1 OS_ATOMIC_CONFIG_STARVATION_FREE_ONLY=0)
target_compile_options(libfirehose_kernel PRIVATE -mkernel -Wno-packed -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration)
target_link_libraries(libfirehose_kernel PRIVATE AvailabilityHeaders)
target_link_libraries(libfirehose_kernel PRIVATE
    xnu_kernel_private_headers xnu_kernel_headers xnu_private_headers
)
target_link_libraries(libfirehose_kernel PRIVATE libplatform_headers libplatform_private_headers)
target_link_libraries(libfirehose_kernel PRIVATE pthread_common_headers pthread_common_private_headers)
