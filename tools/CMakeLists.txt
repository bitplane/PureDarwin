if(NOT APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
    # Apple headers use __arm64__; Linux compilers use __aarch64__.
    add_compile_definitions(__arm64__=1)
endif()

add_subdirectory(cctools)
add_subdirectory(dtrace_ctf)
add_subdirectory(mig)
add_subdirectory(unifdef)
add_subdirectory(xar)
