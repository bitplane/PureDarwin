add_subdirectory(Extensions)
add_subdirectory(libkmod)
add_subdirectory(libfirehose_kernel)

set(profile_runtime_library_path "")
if(PUREDARWIN_COMPILER_RT_SOURCE_DIR)
    add_darwin_static_library(compiler_rt_profile)
    target_sources(compiler_rt_profile PRIVATE
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile/InstrProfiling.c
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile/InstrProfilingBuffer.c
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile/InstrProfilingPlatformDarwin.c
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile/InstrProfilingWriter.c
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile/InstrProfilingInternal.c
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile/InstrProfilingVersionVar.c
    )
    target_include_directories(compiler_rt_profile PRIVATE
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/include
        ${PUREDARWIN_COMPILER_RT_SOURCE_DIR}/lib/profile
        ${PUREDARWIN_SOURCE_DIR}/src/Libraries/libSystem/libsystem_kernel/include
    )
    target_compile_definitions(compiler_rt_profile PRIVATE VISIBILITY_HIDDEN)
    target_compile_options(compiler_rt_profile PRIVATE
        -ibuiltininc -fPIC -O3 -fvisibility=hidden -fomit-frame-pointer
    )
    target_link_libraries(compiler_rt_profile PRIVATE
        AvailabilityHeaders libc_public_headers pthread_common_headers
        xnu_headers xnu_kernel_headers
    )
    set(profile_runtime_library_path $<TARGET_FILE:compiler_rt_profile>)
endif()

add_subdirectory(xnu)
