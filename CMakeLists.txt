if(CMAKE_GENERATOR STREQUAL "Xcode")
    message(FATAL_ERROR "PureDarwin cannot be compiled with Xcode.")
endif()

cmake_minimum_required(VERSION 3.15.1)
project(PUREDARWIN)

find_package(Python3 REQUIRED COMPONENTS Interpreter)

if((NOT CMAKE_C_COMPILER_ID MATCHES "AppleClang") AND (NOT CMAKE_C_COMPILER_ID MATCHES "Clang"))
    message(FATAL_ERROR "PureDarwin must be compiled with clang.")
endif()

cmake_policy(SET CMP0114 NEW)

set(CMAKE_INSTALL_PREFIX "")
set(CMAKE_MACOSX_MIN_VERSION 11.0)
set(PUREDARWIN_COMPILER_RT_SOURCE_DIR "" CACHE PATH "compiler-rt source tree for the XNU profile runtime")
set(PUREDARWIN_EXTERNAL_SOURCE_ROOT "" CACHE PATH "root containing externally supplied Darwin source trees")
set(PUREDARWIN_LIBCXX_SOURCE_DIR "" CACHE PATH "libc++ source tree")
set(PUREDARWIN_LIBCXXABI_SOURCE_DIR "" CACHE PATH "libc++abi source tree")
set(PUREDARWIN_LIBUNWIND_SOURCE_DIR "" CACHE PATH "libunwind source tree")
set(PUREDARWIN_TARGET_TRIPLE "" CACHE STRING "Clang target triple for Darwin binaries")

if(NOT APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
    # Linux on ARM defaults to unsigned char; the vendored Apple and Sun tools
    # assume the signed char of the x86 and Darwin ABIs. Darwin targets keep
    # signed char on every architecture, so this is a no-op for cross-compiled
    # output and only affects natively built host tools.
    add_compile_options(-fsigned-char)
endif()

include(ExternalProject)
include(cmake/asm.cmake)
include(cmake/bundle_resources.cmake)
include(cmake/circular.cmake)
include(cmake/crosscompile.cmake)
include(cmake/get_target_dependencies.cmake)
include(cmake/install_helpers.cmake)
include(cmake/kext.cmake)
include(cmake/mig.cmake)
include(cmake/suppress_warnings.cmake)

add_subdirectory(projects)
add_subdirectory(src)
add_subdirectory(tools)
