if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(ioata_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/IOATAFamily)
    set(ioata_include_dir ${CMAKE_CURRENT_BINARY_DIR}/external_include)
    file(GLOB ioata_public_headers ${ioata_source_dir}/*.h)
    file(MAKE_DIRECTORY ${ioata_include_dir}/IOKit/ata)
    file(COPY ${ioata_public_headers} DESTINATION ${ioata_include_dir}/IOKit/ata)
    file(MAKE_DIRECTORY ${ioata_include_dir}/IOKit/storage/ata)
    file(COPY ${ioata_source_dir}/IOATAFamilyPriv.h
        DESTINATION ${ioata_include_dir}/IOKit/storage/ata)
    file(MAKE_DIRECTORY ${ioata_include_dir}/IOKit/ndrvsupport)
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/include/IOMacOSTypes.h
        DESTINATION ${ioata_include_dir}/IOKit/ndrvsupport)
    set(ioata_info_plist ${ioata_source_dir}/Info-IOATAFamily.plist)
else()
    set(ioata_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
    set(ioata_include_dir ${CMAKE_CURRENT_SOURCE_DIR}/include)
    set(ioata_private_include_dir ${CMAKE_CURRENT_SOURCE_DIR}/private_include)
    set(ioata_info_plist Info.plist)
endif()

add_kext_bundle(IOATAFamily INFO_PLIST ${ioata_info_plist} KERNEL_PRIVATE
    BUNDLE_IDENTIFIER com.apple.iokit.IOATAFamily BUNDLE_VERSION 2.5.3)

target_sources(IOATAFamily PRIVATE
    ${ioata_source_dir}/ATADeviceNub.cpp
    ${ioata_source_dir}/ATATimerEventSource.cpp
    ${ioata_source_dir}/IOATABusCommand.cpp
    ${ioata_source_dir}/IOATABusInfo.cpp
    ${ioata_source_dir}/IOATACommand.cpp
    ${ioata_source_dir}/IOATAController.cpp
    ${ioata_source_dir}/IOATADevConfig.cpp
    ${ioata_source_dir}/IOATADevice.cpp
    ${ioata_source_dir}/IOATARegI386.cpp
    ${ioata_source_dir}/IOPCIATA.cpp
)
target_include_directories(IOATAFamily PRIVATE ${ioata_source_dir} ${ioata_include_dir})
target_link_libraries(IOATAFamily PRIVATE IOStorageFamilyHeaders IOATAFamilyHeaders)
target_compile_options(IOATAFamily PRIVATE -Wno-implicit-int-conversion -Wno-sign-conversion)

add_library(IOATAFamilyHeaders INTERFACE)
target_include_directories(IOATAFamilyHeaders INTERFACE ${ioata_include_dir})
add_library(IOATAFamilyPrivateHeaders INTERFACE)
target_include_directories(IOATAFamilyPrivateHeaders INTERFACE ${ioata_private_include_dir} ${ioata_include_dir})
