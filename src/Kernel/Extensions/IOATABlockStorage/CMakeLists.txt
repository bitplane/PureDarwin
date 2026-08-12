set(ioata_block_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/IOATABlockStorage)
set(ioata_block_include_dir ${CMAKE_CURRENT_BINARY_DIR}/external_include)
file(MAKE_DIRECTORY ${ioata_block_include_dir}/IOKit/storage/ata)
file(COPY ${ioata_block_source_dir}/IOATAStorageDefines.h
    DESTINATION ${ioata_block_include_dir}/IOKit/storage/ata)

add_kext_bundle(IOATABlockStorage KERNEL_PRIVATE INFO_PLIST Info.plist
    INSTALL_DESTINATION System/Library/Extensions/IOATAFamily.kext/Contents/PlugIns
    BUNDLE_IDENTIFIER com.apple.iokit.IOATABlockStorage BUNDLE_VERSION 1.3.0)

target_sources(IOATABlockStorage PRIVATE
    ${ioata_block_source_dir}/IOATABlockStorageCommands.cpp
    ${ioata_block_source_dir}/IOATABlockStorageDevice.cpp
    ${ioata_block_source_dir}/IOATABlockStorageDriver.cpp
    ${ioata_block_source_dir}/IOATABlockStorageDriverPM.cpp
)
target_include_directories(IOATABlockStorage PRIVATE
    ${ioata_block_source_dir}
    ${ioata_block_source_dir}/UserClientLib
    ${ioata_block_include_dir}
)
target_link_libraries(IOATABlockStorage PRIVATE
    IOATAFamilyHeaders
    IOATAFamilyPrivateHeaders
    IOStorageFamilyHeaders
)
target_compile_options(IOATABlockStorage PRIVATE
    -Wno-deprecated-declarations
    -Wno-implicit-int-conversion
    -Wno-sign-conversion
)
add_dependencies(IOATABlockStorage IOATAFamily IOStorageFamily)
