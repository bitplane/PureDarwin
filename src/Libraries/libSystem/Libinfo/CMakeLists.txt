set(libinfo_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/Libinfo)

if(NOT EXISTS ${libinfo_source_dir}/Libinfo.xcodeproj/project.pbxproj)
    message(FATAL_ERROR "Libinfo source tree not found: ${libinfo_source_dir}")
endif()

execute_process(
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/pbx-sources.py
        ${libinfo_source_dir}/Libinfo.xcodeproj/project.pbxproj Libinfo
    OUTPUT_VARIABLE libinfo_source_text
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
string(REPLACE "\n" ";" libinfo_source_paths "${libinfo_source_text}")
set(libinfo_sources)
foreach(libinfo_source_path IN LISTS libinfo_source_paths)
    list(APPEND libinfo_sources ${libinfo_source_dir}/${libinfo_source_path})
endforeach()
list(FILTER libinfo_sources EXCLUDE REGEX
    "/(dns|membership|nis|rpc|util)\\.subproj/|/(configuration_profile|mdns_module)\\.c$")

add_darwin_object_library(libsystem_info_runtime)
set_property(TARGET libsystem_info_runtime PROPERTY POSITION_INDEPENDENT_CODE ON)
add_dependencies(libsystem_info_runtime libsystem_kernel_static)
target_sources(libsystem_info_runtime PRIVATE
    ${libinfo_sources}
    compat/mdns_disabled.c)
target_compile_definitions(libsystem_info_runtime PRIVATE
    __DARWIN_NON_CANCELABLE=1
    __MigTypeCheck=1
    INET6=1
    CONFIG_MAC
    SYNTH_ROOTFS)
target_compile_options(libsystem_info_runtime PRIVATE
    -fno-common
    -Wno-deprecated-declarations)
target_include_directories(libsystem_info_runtime PRIVATE
    ${libinfo_source_dir}
    ${libinfo_source_dir}/dns.subproj
    ${libinfo_source_dir}/gen.subproj
    ${libinfo_source_dir}/lookup.subproj
    ${libinfo_source_dir}/membership.subproj
    ${libinfo_source_dir}/nis.subproj
    ${libinfo_source_dir}/rpc.subproj
    ${libinfo_source_dir}/util.subproj
    ${CMAKE_CURRENT_SOURCE_DIR}/compat
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libresolv
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/syslog/libsystem_asl.tproj/include)
target_link_libraries(libsystem_info_runtime PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    dyld_headers
    libc_private_headers
    libresolv_headers
    libnotify_headers
    libplatform_headers
    libsystem_kernel_private_headers
    libsystem_private_headers
    pthread_common_headers
    xnu_headers
    xnu_private_headers)

add_darwin_circular_library(libsystem_info
    INSTALL_NAME /usr/lib/system/libsystem_info.dylib
    OBJECT_LIBRARIES libsystem_info_runtime
    SIBLINGS
        dispatch
        libsystem_blocks
        libsystem_c
        libsystem_m
        libsystem_malloc
        libsystem_notify
        libsystem_platform
        libsystem_pthread
    STRONG_DEPENDENCIES libsystem_kernel
    LINK_OPTIONS "LINKER:-umbrella,System")
install(TARGETS libsystem_info DESTINATION usr/lib/system COMPONENT BaseSystem)
