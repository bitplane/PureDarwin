# This project just exposes headers in the architecture/ directory that don't live elsewhere.
if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(architecture_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/architecture)
    set(architecture_include_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT})
else()
    set(architecture_source_dir ${CMAKE_CURRENT_SOURCE_DIR}/include/architecture)
    set(architecture_include_dir ${CMAKE_CURRENT_SOURCE_DIR}/include)
endif()

if(NOT EXISTS ${architecture_source_dir}/i386/asm_help.h)
    message(FATAL_ERROR "architecture source tree not found: ${architecture_source_dir}")
endif()

add_library(architecture_headers INTERFACE)

target_include_directories(architecture_headers INTERFACE ${architecture_include_dir})

# Install headers
install(DIRECTORY ${architecture_source_dir} DESTINATION usr/include COMPONENT DeveloperTools)

install(DIRECTORY ${architecture_source_dir} DESTINATION System/Library/Frameworks/System.framework/Versions/B/PrivateHeaders COMPONENT DeveloperInternal)
