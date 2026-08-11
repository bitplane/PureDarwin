if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(iostorage_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/IOStorageFamily)
    set(iostorage_include_dir ${CMAKE_CURRENT_BINARY_DIR}/external_include)
    file(GLOB iostorage_headers ${iostorage_source_dir}/*.h)
    file(MAKE_DIRECTORY ${iostorage_include_dir}/IOKit/storage)
    file(COPY ${iostorage_headers} DESTINATION ${iostorage_include_dir}/IOKit/storage)
    set(iostorage_info_plist ${iostorage_source_dir}/Info.plist)
else()
    set(iostorage_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
    set(iostorage_include_dir ${CMAKE_CURRENT_SOURCE_DIR}/include)
    set(iostorage_info_plist Info.plist)
endif()

add_kext_bundle(IOStorageFamily INFO_PLIST ${iostorage_info_plist} KERNEL_PRIVATE
    BUNDLE_IDENTIFIER com.apple.iokit.IOStorageFamily BUNDLE_VERSION 2.1)

target_sources(IOStorageFamily PRIVATE
    ${iostorage_source_dir}/IOAppleLabelScheme.cpp
    ${iostorage_source_dir}/IOApplePartitionScheme.cpp
    ${iostorage_source_dir}/IOBlockStorageDevice.cpp
    ${iostorage_source_dir}/IOBlockStorageDriver.cpp
    ${iostorage_source_dir}/IOFDiskPartitionScheme.cpp
    ${iostorage_source_dir}/IOFilterScheme.cpp
    ${iostorage_source_dir}/IOGUIDPartitionScheme.cpp
    ${iostorage_source_dir}/IOMedia.cpp
    ${iostorage_source_dir}/IOMediaBSDClient.cpp
    ${iostorage_source_dir}/IOPartitionScheme.cpp
    ${iostorage_source_dir}/IOStorage.cpp
)
target_include_directories(IOStorageFamily PRIVATE ${iostorage_include_dir})
target_compile_options(IOStorageFamily PRIVATE -Wno-implicit-int-conversion -Wno-sign-conversion -Wno-deprecated-declarations)
set_property(TARGET IOStorageFamily PROPERTY CXX_STANDARD 17)
install(TARGETS IOStorageFamily DESTINATION System/Library/Extensions COMPONENT BaseSystem)

# FIXME: Re-enable these when we have our own tools for handling image resource files.
# add_bundle_iconset(IOStorageFamily IconResources/External.iconset)
# add_bundle_iconset(IOStorageFamily IconResources/Internal.iconset)
# add_bundle_iconset(IOStorageFamily IconResources/Removable.iconset)
# add_bundle_resources(IOStorageFamily en.lproj/InfoPlist.strings)


add_library(IOStorageFamilyHeaders INTERFACE)
target_include_directories(IOStorageFamilyHeaders INTERFACE ${iostorage_include_dir})


add_darwin_object_library(IOStorageFamilyUserHeaders)
target_sources(IOStorageFamilyUserHeaders PRIVATE user_stub.c)
target_include_directories(IOStorageFamilyUserHeaders INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/user_include)
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/user_include/IOKit/storage)

set(HEADERS
    IOAppleLabelScheme.h
    IOApplePartitionScheme.h
    IOBlockStorageDevice.h
    IOBlockStorageDriver.h
    IOFDiskPartitionScheme.h
    IOFilterScheme.h
    IOGUIDPartitionScheme.h
    IOMedia.h
    IOMediaBSDClient.h
    IOPartitionScheme.h
    IOStorage.h
    IOStorageCardCharacteristics.h
    IOStorageControllerCharacteristics.h
    IOStorageDeviceCharacteristics.h
    IOStorageProtocolCharacteristics.h
)
foreach(file IN LISTS HEADERS)
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/user_include/IOKit/storage/${file}
        COMMAND $<TARGET_FILE:unifdef> -UKERNEL -o ${CMAKE_CURRENT_BINARY_DIR}/user_include/IOKit/storage/${file} ${iostorage_include_dir}/IOKit/storage/${file}
        DEPENDS unifdef ${iostorage_include_dir}/IOKit/storage/${file}
        COMMENT "unifdef ${file}" VERBATIM
    )
    target_sources(IOStorageFamilyUserHeaders PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/user_include/IOKit/storage/${file})
endforeach()

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/user_include/IOKit/storage DESTINATION System/Library/Frameworks/IOKit.framework/Versions/A/Headers/IOKit COMPONENT DeveloperTools)
install(DIRECTORY ${iostorage_include_dir}/IOKit/storage DESTINATION System/Library/Frameworks/Kernel.framework/Versions/A/Headers/IOKit COMPONENT DeveloperTools)
