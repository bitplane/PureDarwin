set(dyld_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld)

if(NOT EXISTS ${dyld_source_dir}/src/dyld.cpp)
    message(FATAL_ERROR "dyld source tree not found: ${dyld_source_dir}")
endif()
if(NOT EXISTS ${PUREDARWIN_LIBCXX_SOURCE_DIR}/include/vector)
    message(FATAL_ERROR "libc++ source tree not found: ${PUREDARWIN_LIBCXX_SOURCE_DIR}")
endif()

set(dyld_image_loader_source ${CMAKE_CURRENT_BINARY_DIR}/ImageLoader.cpp)
file(READ ${dyld_source_dir}/src/ImageLoader.cpp dyld_image_loader_contents)
set(dyld_stale_image_pair "VECTOR_NEVER_DESTRUCTED_IMPL(ImagePair);")
string(FIND "${dyld_image_loader_contents}" "${dyld_stale_image_pair}"
    dyld_stale_image_pair_offset)
if(dyld_stale_image_pair_offset EQUAL -1)
    message(FATAL_ERROR "dyld ImagePair compatibility patch no longer applies")
endif()
string(REPLACE "${dyld_stale_image_pair}" ""
    dyld_image_loader_contents "${dyld_image_loader_contents}")
file(WRITE ${dyld_image_loader_source} "${dyld_image_loader_contents}")

set(dyld_sdk_root ${CMAKE_CURRENT_BINARY_DIR}/sdk)
set(dyld_generated_include ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY
    ${dyld_sdk_root}/usr/local/libexec
    ${dyld_generated_include}/mach-o)
configure_file(
    ${PUREDARWIN_SOURCE_DIR}/src/Libraries/AvailabilityVersions/availability.pl
    ${dyld_sdk_root}/usr/local/libexec/availability.pl
    COPYONLY)
execute_process(
    COMMAND ${CMAKE_COMMAND} -E env SDKROOT=${dyld_sdk_root}
        perl ${dyld_source_dir}/bin/expand.pl
    INPUT_FILE ${dyld_source_dir}/include/mach-o/dyld_priv.h
    OUTPUT_FILE ${dyld_generated_include}/mach-o/dyld_priv.h
    RESULT_VARIABLE dyld_expand_result)
if(NOT dyld_expand_result EQUAL 0)
    message(FATAL_ERROR "failed to generate dyld_priv.h")
endif()

add_darwin_executable(dyld_runtime NO_STANDARD_LIBRARIES)
set_target_properties(dyld_runtime PROPERTIES
    OUTPUT_NAME dyld
    ENABLE_EXPORTS TRUE)

set(closured_protocol_header ${CMAKE_CURRENT_BINARY_DIR}/closuredProtocol.h)
set(closured_protocol_source ${CMAKE_CURRENT_BINARY_DIR}/closuredProtocolUser.c)
mig(${dyld_source_dir}/dyld3/closured/closuredProtocol.defs
    INCLUDES_FROM_TARGET dyld_runtime
    USER_HEADER ${closured_protocol_header}
    USER_SOURCE ${closured_protocol_source}
    NOVOUCHERS)

target_sources(dyld_runtime PRIVATE
    ${closured_protocol_source}
    common_digest.c
    ${dyld_source_dir}/src/dyldStartup.s
    ${dyld_source_dir}/src/dyldInitialization.cpp
    ${dyld_source_dir}/src/dyld.cpp
    ${dyld_source_dir}/src/dyldAPIs.cpp
    ${dyld_source_dir}/src/dyldExceptions.c
    ${dyld_source_dir}/src/dyld_gdb.cpp
    ${dyld_source_dir}/src/glue.c
    ${dyld_source_dir}/src/ImageLoaderMegaDylib.cpp
    ${dyld_image_loader_source}
    ${dyld_source_dir}/src/ImageLoaderMachO.cpp
    ${dyld_source_dir}/src/stub_binding_helper.s
    ${dyld_source_dir}/src/dyldNew.cpp
    ${dyld_source_dir}/src/ImageLoaderMachOClassic.cpp
    ${dyld_source_dir}/src/ImageLoaderMachOCompressed.cpp
    ${dyld_source_dir}/dyld3/Loading.cpp
    ${dyld_source_dir}/dyld3/MachOParser.cpp
    ${dyld_source_dir}/dyld3/DyldCacheParser.cpp
    ${dyld_source_dir}/dyld3/Diagnostics.cpp
    ${dyld_source_dir}/dyld3/LaunchCacheReader.cpp
    ${dyld_source_dir}/dyld3/SharedCacheRuntime.cpp
    ${dyld_source_dir}/dyld3/shared-cache/DyldSharedCache.cpp
    ${dyld_source_dir}/dyld3/Tracing.cpp)

set_source_files_properties(${closured_protocol_source}
    PROPERTIES OBJECT_DEPENDS ${closured_protocol_header})

target_include_directories(dyld_runtime PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
    ${dyld_generated_include}
    ${dyld_source_dir}/include
    ${dyld_source_dir}/dyld3/shared-cache
    ${dyld_source_dir}/launch-cache
    ${dyld_source_dir}/src
    ${dyld_source_dir}/dyld3
    ${dyld_source_dir}/dyld3/closured)
target_include_directories(dyld_runtime PRIVATE
    ${PUREDARWIN_SOURCE_DIR}/src/Libraries/libSystem/corecrypto/include
    ${PUREDARWIN_SOURCE_DIR}/tools/cctools/include
    ${CMAKE_CURRENT_SOURCE_DIR}/compat
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libdispatch
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform/private
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/libsyscall/wrappers/libproc
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/include
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libm/Source/Intel)
target_link_libraries(dyld_runtime PRIVATE
    AvailabilityHeaders
    CrashReporterClient_headers
    clang_bootstrap_headers
    corecrypto_static
    host_commoncrypto_headers
    host_commoncrypto_private_headers
    libc_private_headers
    libsystem_kernel_private_headers
    libsystem_kernel_static
    libplatform_headers
    pthread_common_private_headers
    xnu_private_headers)
target_compile_definitions(dyld_runtime PRIVATE
    BUILDING_DYLD=1
    DYLD_IN_PROCESS=1
    DYLD_VERSION=519.2.2)
target_compile_options(dyld_runtime PRIVATE
    -Os
    -stdlib=libc++
    -fno-builtin
    -fno-rtti
    -Wno-four-char-constants
    -Wno-unknown-pragmas)
target_link_options(dyld_runtime PRIVATE
    -Wl,-dylinker
    -Wl,-dylinker_install_name,/usr/lib/dyld
    -Wl,-e,__dyld_start
    -Wl,-exported_symbols_list,${dyld_source_dir}/src/dyld.exp
    -Wl,-order_file,${dyld_source_dir}/src/dyld.order
    -Wl,-no_data_const)

install(TARGETS dyld_runtime DESTINATION usr/lib COMPONENT Dyld)
