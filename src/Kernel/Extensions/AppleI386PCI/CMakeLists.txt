if(NOT PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    message(FATAL_ERROR "AppleI386PCI requires PUREDARWIN_EXTERNAL_SOURCE_ROOT")
endif()

set(apple_i386_pci_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/AppleI386PCI)

add_kext_bundle(AppleI386PCI KERNEL_PRIVATE INFO_PLIST Info.plist
    BUNDLE_IDENTIFIER com.apple.driver.AppleI386PCI BUNDLE_VERSION 1.3)
target_sources(AppleI386PCI PRIVATE
    ${apple_i386_pci_source_dir}/AppleI386PCI.cpp
)
target_compile_options(AppleI386PCI PRIVATE
    -include${CMAKE_CURRENT_SOURCE_DIR}/PCIBusInfo.h
    -Wno-deprecated-volatile
    -Wno-implicit-int-conversion
    -Wno-inconsistent-missing-override
    -Wno-sign-conversion
)
target_include_directories(AppleI386PCI PRIVATE ${apple_i386_pci_source_dir})
target_link_libraries(AppleI386PCI PRIVATE IOPCIFamilyHeaders)
add_dependencies(AppleI386PCI IOPCIFamily)
