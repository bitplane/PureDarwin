set(libm_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libm)

if(NOT EXISTS ${libm_source_dir}/Libm.xcodeproj/project.pbxproj)
    message(FATAL_ERROR "Libm source tree not found: ${libm_source_dir}")
endif()

execute_process(
    COMMAND ${CMAKE_C_COMPILER} -print-resource-dir
    OUTPUT_VARIABLE libm_clang_resource_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)

# Preserve the source membership of Apple's Libm.a target, then apply its
# architecture-directory selection for x86_64.
execute_process(
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/pbx-sources.py
        ${libm_source_dir}/Libm.xcodeproj/project.pbxproj Libm.a
    OUTPUT_VARIABLE libm_runtime_source_text
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
string(REPLACE "\n" ";" libm_runtime_source_paths "${libm_runtime_source_text}")
list(FILTER libm_runtime_source_paths INCLUDE REGEX
    "^Source/([^/]+|Intel/([^/]+|x86_64/[^/]+))\\.(c|s)$")
list(FILTER libm_runtime_source_paths EXCLUDE REGEX "^Source/version_info\\.c$")
set(libm_runtime_sources)
foreach(libm_source_path IN LISTS libm_runtime_source_paths)
    list(APPEND libm_runtime_sources ${libm_source_dir}/${libm_source_path})
endforeach()
# Libm.a depends on libmathCommon.o.  Its architecture-specific implementations
# supplement the direct target sources; overlapping objects are archive details
# and must not be linked twice into libsystem_m.
list(APPEND libm_runtime_sources
    ${libm_source_dir}/Source/Intel/nan.c
    ${libm_source_dir}/Source/Intel/nextafterf.s)
set(libm_fenv_source ${libm_source_dir}/Source/Intel/fenv.c)
list(REMOVE_ITEM libm_runtime_sources ${libm_fenv_source})
set(libm_frexp_source ${libm_source_dir}/Source/Intel/frexp.s)
list(REMOVE_ITEM libm_runtime_sources ${libm_frexp_source})
# Clang's Mach-O assembler uses the canonical spelling for sign extension.
file(READ ${libm_frexp_source} libm_frexp_text)
string(REPLACE "movsxw" "movswl" libm_frexp_text "${libm_frexp_text}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/frexp.s "${libm_frexp_text}")
list(APPEND libm_runtime_sources ${CMAKE_CURRENT_BINARY_DIR}/frexp.s)

set(libm_include_dir ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${libm_include_dir}/architecture/i386)
configure_file(${libm_source_dir}/Source/Intel/math.h
    ${libm_include_dir}/architecture/i386/math.h COPYONLY)
configure_file(${libm_source_dir}/Source/Intel/fenv.h
    ${libm_include_dir}/architecture/i386/fenv.h COPYONLY)
# The Intel source set uses the shared fdlibm private definitions, but this
# release only carries the architecture-neutral header under Source/ARM.
configure_file(${libm_source_dir}/Source/ARM/math_private.h
    ${libm_include_dir}/math_private.h COPYONLY)
configure_file(${libm_source_dir}/Source/Intel/xmmLibm_prefix.h
    ${libm_include_dir}/xmmLibm_Prefix.h COPYONLY)
file(WRITE ${libm_include_dir}/fenv_private.h
    "#include <fenv.h>\n")

add_darwin_object_library(libsystem_m_runtime)
set_property(TARGET libsystem_m_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)
target_sources(libsystem_m_runtime PRIVATE ${libm_runtime_sources})
target_compile_definitions(libsystem_m_runtime PRIVATE
    _APPLE_C_SOURCE
    _FORTIFY_SOURCE=0)
target_compile_options(libsystem_m_runtime PRIVATE
    -fno-builtin
    -fno-common
    -ftrapping-math
    -msse3
    "SHELL:-isystem ${libm_clang_resource_dir}/include"
    -Wno-deprecated-declarations)
target_include_directories(libsystem_m_runtime PRIVATE
    ${libm_include_dir}
    ${libm_source_dir}/Source
    ${libm_source_dir}/Source/Intel
    ${libm_source_dir}/Source/Intel/x86_64)
target_link_libraries(libsystem_m_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    libc_private_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

# The Xcode build contributes fenv.c through libmathCommon, whose legacy
# variant owns the public fenv entry points.  The rest of Libm uses the normal
# variant; applying this definition globally suppresses or renames C99 APIs.
add_darwin_object_library(libsystem_m_fenv_runtime)
set_property(TARGET libsystem_m_fenv_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)
target_sources(libsystem_m_fenv_runtime PRIVATE ${libm_fenv_source})
target_compile_definitions(libsystem_m_fenv_runtime PRIVATE
    BUILDING_FOR_CARBONCORE_LEGACY=1
    _APPLE_C_SOURCE
    _FORTIFY_SOURCE=0)
target_compile_options(libsystem_m_fenv_runtime PRIVATE
    -fno-builtin
    -fno-common
    -ftrapping-math
    -msse3
    "SHELL:-isystem ${libm_clang_resource_dir}/include")
target_include_directories(libsystem_m_fenv_runtime PRIVATE
    ${libm_include_dir}
    ${libm_source_dir}/Source
    ${libm_source_dir}/Source/Intel)
target_link_libraries(libsystem_m_fenv_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    libc_private_headers
    libplatform_headers
    libplatform_private_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(libsystem_m
    INSTALL_NAME /usr/lib/system/libsystem_m.dylib
    OBJECT_LIBRARIES libsystem_m_runtime libsystem_m_fenv_runtime
    SIBLINGS libsystem_c libsystem_platform
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libsystem_m DESTINATION usr/lib/system COMPONENT BaseSystem)
