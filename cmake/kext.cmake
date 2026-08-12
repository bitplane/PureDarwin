function(add_kext_bundle name)
    cmake_parse_arguments(SL "KERNEL_PRIVATE" "MACOSX_VERSION_MIN;INFO_PLIST;BUNDLE_IDENTIFIER;BUNDLE_VERSION;BUNDLE_NAME;INSTALL_DESTINATION;MAIN_FUNCTION;ANTIMAIN_FUNCTION" "" ${ARGN})

    if(NOT SL_BUNDLE_NAME)
        set(SL_BUNDLE_NAME ${name})
    endif()
    if(NOT SL_INSTALL_DESTINATION)
        set(SL_INSTALL_DESTINATION System/Library/Extensions)
    endif()

    if(SL_MACOSX_VERSION_MIN)
        add_darwin_shared_library(${name} MODULE MACOSX_VERSION_MIN ${SL_MACOSX_VERSION_MIN})
    else()
        add_darwin_shared_library(${name} MODULE)
    endif()

    set_property(TARGET ${name} PROPERTY PREFIX "")
    set_property(TARGET ${name} PROPERTY SUFFIX "")
    set_property(TARGET ${name} PROPERTY OUTPUT_NAME ${SL_BUNDLE_NAME})

    target_compile_definitions(${name} PRIVATE TARGET_OS_OSX KERNEL)
    target_compile_options(${name} PRIVATE
        -ffreestanding
        $<$<COMPILE_LANGUAGE:CXX>:-fapple-kext>
    )
    target_link_options(${name} PRIVATE "LINKER:-kext")
    target_link_options(${name} PRIVATE "SHELL:-undefined dynamic_lookup")

    if(SL_KERNEL_PRIVATE)
        target_compile_definitions(${name} PRIVATE KERNEL_PRIVATE)
        target_link_libraries(${name} PRIVATE xnu_kernel_private_headers)
    endif()

    target_link_libraries(${name} PRIVATE xnu_kernel_headers AvailabilityHeaders)

    set_property(TARGET ${name} PROPERTY BUNDLE TRUE)
    set_property(TARGET ${name} PROPERTY BUNDLE_EXTENSION kext)

    if(SL_INFO_PLIST)
        get_filename_component(SL_INFO_PLIST ${SL_INFO_PLIST} ABSOLUTE)
        set_property(TARGET ${name} PROPERTY MACOSX_BUNDLE_INFO_PLIST ${SL_INFO_PLIST})
    else()
        message(SEND_ERROR "INFO_PLIST argument must be provided to add_darwin_kext()")
    endif()

    if(SL_BUNDLE_IDENTIFIER)
        set_property(TARGET ${name} PROPERTY MACOSX_BUNDLE_GUI_IDENTIFIER ${SL_BUNDLE_IDENTIFIER})
    endif()
    if(SL_BUNDLE_VERSION)
        set_property(TARGET ${name} PROPERTY MACOSX_BUNDLE_BUNDLE_VERSION ${SL_BUNDLE_VERSION})
    endif()

    add_kmod_info(${name} MAIN_FUNCTION ${SL_MAIN_FUNCTION} ANTIMAIN_FUNCTION ${SL_ANTIMAIN_FUNCTION})

    execute_process(
        COMMAND ${CMAKE_C_COMPILER} -E -P -x c
            -DTARGET_OS_OSX=1 -DTARGET_OS_EMBEDDED=0
            ${SL_INFO_PLIST}
        OUTPUT_VARIABLE kext_info_plist
        ERROR_VARIABLE kext_info_plist_error
        RESULT_VARIABLE kext_info_plist_result
    )
    if(NOT kext_info_plist_result EQUAL 0)
        message(FATAL_ERROR
            "Failed to preprocess ${SL_INFO_PLIST}: ${kext_info_plist_error}")
    endif()
    string(REPLACE "\${EXECUTABLE_NAME}" "${SL_BUNDLE_NAME}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "$(EXECUTABLE_NAME)" "${SL_BUNDLE_NAME}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "\${PRODUCT_NAME}" "${SL_BUNDLE_NAME}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "$(PRODUCT_NAME)" "${SL_BUNDLE_NAME}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "\${MODULE_NAME}" "${SL_BUNDLE_IDENTIFIER}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "$(MODULE_NAME)" "${SL_BUNDLE_IDENTIFIER}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "$(PRODUCT_BUNDLE_IDENTIFIER)" "${SL_BUNDLE_IDENTIFIER}" kext_info_plist "${kext_info_plist}")
    string(REPLACE "HFS_KEXT_VERSION" "${SL_BUNDLE_VERSION}" kext_info_plist "${kext_info_plist}")
    set(kext_info_plist_path ${CMAKE_CURRENT_BINARY_DIR}/${SL_BUNDLE_NAME}-Info.plist)
    file(WRITE ${kext_info_plist_path} "${kext_info_plist}")

    set(kext_install_root ${SL_INSTALL_DESTINATION}/${SL_BUNDLE_NAME}.kext/Contents)
    set(kext_install_component KernelExtension-${SL_BUNDLE_NAME})
    install(TARGETS ${name}
        DESTINATION ${kext_install_root}/MacOS
        COMPONENT ${kext_install_component})
    install(FILES ${kext_info_plist_path}
        DESTINATION ${kext_install_root}
        RENAME Info.plist
        COMPONENT ${kext_install_component})
endfunction()

function(add_kmod_info target)
    cmake_parse_arguments(KEXT "" "IDENTIFIER;VERSION;MAIN_FUNCTION;ANTIMAIN_FUNCTION" "" ${ARGN})

    if(NOT KEXT_IDENTIFIER)
        get_property(KEXT_IDENTIFIER TARGET ${target} PROPERTY MACOSX_BUNDLE_GUI_IDENTIFIER)
    endif()
    if(NOT KEXT_IDENTIFIER)
        message(SEND_ERROR "MACOSX_BUNDLE_GUI_IDENTIFIER is not set on kext target ${target}")
        return()
    endif()

    if(NOT KEXT_VERSION)
        get_property(KEXT_VERSION TARGET ${target} PROPERTY MACOSX_BUNDLE_BUNDLE_VERSION)
    endif()
    if(NOT KEXT_VERSION)
        message(SEND_ERROR "MACOSX_BUNDLE_BUNDLE_VERSION is not set on kext target ${target}")
        return()
    endif()

    if(KEXT_MAIN_FUNCTION)
        set(KEXT_MAIN_FUNCTION_DECL "extern kern_return_t ${KEXT_MAIN_FUNCTION}(kmod_info_t *ki, void *data);")
    else()
        set(KEXT_MAIN_FUNCTION "0")
    endif()

    if(KEXT_ANTIMAIN_FUNCTION)
        set(KEXT_ANTIMAIN_FUNCTION_DECL "extern kern_return_t ${KEXT_ANTIMAIN_FUNCTION}(kmod_info_t *ki, void *data);")
    else()
        set(KEXT_ANTIMAIN_FUNCTION "0")
    endif()

    configure_file(${PUREDARWIN_SOURCE_DIR}/cmake/templates/kmod_info.c.in ${CMAKE_CURRENT_BINARY_DIR}/kmod_info.c)
    target_sources(${target} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/kmod_info.c)
    target_link_libraries(${target} PRIVATE libkmod)
endfunction()
