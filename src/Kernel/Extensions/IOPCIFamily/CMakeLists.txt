if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(iopci_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/IOPCIFamily)
    set(iopci_info_plist ${iopci_source_dir}/Info-IOPCIFamily.plist)
else()
    set(iopci_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
    set(iopci_info_plist Info.plist)
endif()

add_kext_bundle(IOPCIFamily KERNEL_PRIVATE INFO_PLIST ${iopci_info_plist} BUNDLE_IDENTIFIER com.apple.iokit.IOPCIFamily BUNDLE_VERSION 2.4.1)
target_sources(IOPCIFamily PRIVATE
    ${iopci_source_dir}/IOPCIBridge.cpp
    ${iopci_source_dir}/IOPCIConfigurator.cpp
    ${iopci_source_dir}/IOPCIDevice.cpp
    ${iopci_source_dir}/IOPCIDeviceI386.cpp
    ${iopci_source_dir}/IOPCIDeviceMappedIO.cpp
    ${iopci_source_dir}/IOPCIMessagedInterruptController.cpp
    ${iopci_source_dir}/IOPCIRange.cpp
)

set_property(TARGET IOPCIFamily PROPERTY CXX_STANDARD 11)
target_compile_options(IOPCIFamily PRIVATE -Wno-implicit-int-conversion -Wno-inconsistent-missing-override -Wno-sign-conversion -Wno-shadow)
target_link_libraries(IOPCIFamily PRIVATE
    IOACPIFamilyHeaders
    IOPCIFamilyHeaders
)

add_library(IOPCIFamilyHeaders INTERFACE)
target_include_directories(IOPCIFamilyHeaders INTERFACE ${iopci_source_dir})

if(NOT PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    add_subdirectory(ApplePIODMA)
endif()
