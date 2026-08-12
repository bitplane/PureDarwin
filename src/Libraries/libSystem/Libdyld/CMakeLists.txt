set(dyld_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/dyld)

add_darwin_shared_library(libdyld_bootstrap
    INSTALL_NAME /usr/lib/system/libdyld.dylib)
set_target_properties(libdyld_bootstrap PROPERTIES OUTPUT_NAME dyld)
set_target_properties(libdyld_bootstrap PROPERTIES LINKER_LANGUAGE C)
target_sources(libdyld_bootstrap PRIVATE
    ${dyld_source_dir}/src/dyld_stub_binder.s)
target_include_directories(libdyld_bootstrap PRIVATE
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/xnu/EXTERNAL_HEADERS
    ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform/include)
target_link_libraries(libdyld_bootstrap PRIVATE
    AvailabilityHeaders
    architecture_headers
    clang_bootstrap_headers
    xnu_headers
    xnu_private_headers)
target_link_options(libdyld_bootstrap PRIVATE
    "LINKER:-flat_namespace"
    "LINKER:-undefined,suppress")
install(TARGETS libdyld_bootstrap DESTINATION usr/lib/system COMPONENT BaseSystem)
