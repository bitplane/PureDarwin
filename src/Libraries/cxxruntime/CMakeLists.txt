foreach(source_dir
    PUREDARWIN_LIBCXX_SOURCE_DIR
    PUREDARWIN_LIBCXXABI_SOURCE_DIR
    PUREDARWIN_LIBUNWIND_SOURCE_DIR)
    if(NOT IS_DIRECTORY "${${source_dir}}")
        message(FATAL_ERROR "${source_dir} is not a source tree: ${${source_dir}}")
    endif()
endforeach()

set(libunwind_source_dir ${PUREDARWIN_LIBUNWIND_SOURCE_DIR}/src)
add_darwin_static_library(unwind_dyld)
target_sources(unwind_dyld PRIVATE
    ${libunwind_source_dir}/libunwind.cpp
    ${libunwind_source_dir}/Unwind_AppleExtras.cpp
    ${libunwind_source_dir}/UnwindLevel1.c
    ${libunwind_source_dir}/UnwindLevel1-gcc-ext.c
    ${libunwind_source_dir}/Unwind-sjlj.c
    ${libunwind_source_dir}/UnwindRegistersRestore.S
    ${libunwind_source_dir}/UnwindRegistersSave.S)
target_include_directories(unwind_dyld PRIVATE
    ${PUREDARWIN_LIBUNWIND_SOURCE_DIR}/include
    ${libunwind_source_dir}
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld/include)
target_compile_definitions(unwind_dyld PRIVATE _LIBUNWIND_BUILDING_LIBRARY)
target_compile_options(unwind_dyld PRIVATE -fno-exceptions -fno-rtti -funwind-tables)
target_link_libraries(unwind_dyld PRIVATE
    AvailabilityHeaders
    clang_bootstrap_headers
    libc_public_headers
    pthread_common_headers
    xnu_headers)

set(libcxxabi_source_dir ${PUREDARWIN_LIBCXXABI_SOURCE_DIR}/src)
add_darwin_static_library(cxxabi_dyld)
target_sources(cxxabi_dyld PRIVATE
    ${libcxxabi_source_dir}/cxa_aux_runtime.cpp
    ${libcxxabi_source_dir}/cxa_default_handlers.cpp
    ${libcxxabi_source_dir}/cxa_demangle.cpp
    ${libcxxabi_source_dir}/cxa_exception_storage.cpp
    ${libcxxabi_source_dir}/cxa_guard.cpp
    ${libcxxabi_source_dir}/cxa_handlers.cpp
    ${libcxxabi_source_dir}/cxa_unexpected.cpp
    ${libcxxabi_source_dir}/cxa_vector.cpp
    ${libcxxabi_source_dir}/cxa_virtual.cpp
    ${libcxxabi_source_dir}/stdlib_exception.cpp
    ${libcxxabi_source_dir}/stdlib_new_delete.cpp
    ${libcxxabi_source_dir}/stdlib_stdexcept.cpp
    ${libcxxabi_source_dir}/stdlib_typeinfo.cpp
    ${libcxxabi_source_dir}/abort_message.cpp
    ${libcxxabi_source_dir}/fallback_malloc.cpp
    ${libcxxabi_source_dir}/private_typeinfo.cpp
    ${libcxxabi_source_dir}/cxa_exception.cpp
    ${libcxxabi_source_dir}/cxa_personality.cpp)
target_include_directories(cxxabi_dyld PRIVATE
    ${PUREDARWIN_LIBCXXABI_SOURCE_DIR}/include
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/include
    ${PUREDARWIN_LIBUNWIND_SOURCE_DIR}/include
    ${libcxxabi_source_dir})
target_compile_definitions(cxxabi_dyld PRIVATE
    LIBCXXABI_BUILDING_LIBRARY
    _LIBCPP_BUILDING_LIBRARY)
target_compile_options(cxxabi_dyld PRIVATE -fno-rtti)
target_link_libraries(cxxabi_dyld PRIVATE
    AvailabilityHeaders
    clang_bootstrap_headers
    libc_private_headers
    libc_public_headers
    libsystem_kernel_private_headers
    pthread_common_headers
    unwind_dyld
    xnu_headers)

add_darwin_static_library(cxx_dyld)
target_sources(cxx_dyld PRIVATE
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/src/new.cpp
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/src/stdexcept.cpp
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/src/string.cpp)
target_include_directories(cxx_dyld PRIVATE
    ${PUREDARWIN_LIBCXX_SOURCE_DIR}/include
    ${PUREDARWIN_LIBCXXABI_SOURCE_DIR}/include)
target_compile_definitions(cxx_dyld PRIVATE
    _LIBCPP_BUILDING_LIBRARY
    _LIBCPP_NO_EXCEPTIONS=1)
target_compile_options(cxx_dyld PRIVATE -fno-rtti)
target_link_libraries(cxx_dyld PRIVATE
    AvailabilityHeaders
    clang_bootstrap_headers
    libc_private_headers
    libc_public_headers
    libsystem_kernel_private_headers
    pthread_common_headers
    cxxabi_dyld
    xnu_headers)
