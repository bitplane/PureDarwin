set(applefs_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/AppleFileSystemDriver)

add_kext_bundle(AppleFileSystemDriver KERNEL_PRIVATE
    INFO_PLIST ${applefs_source_dir}/Info.plist
    BUNDLE_IDENTIFIER com.apple.driver.AppleFileSystemDriver
    BUNDLE_VERSION 3.0.1)

target_sources(AppleFileSystemDriver PRIVATE
    ${applefs_source_dir}/AppleFileSystemDriver.cpp)
target_include_directories(AppleFileSystemDriver PRIVATE ${applefs_source_dir})
target_link_libraries(AppleFileSystemDriver PRIVATE
    HFSHeaders
    IOStorageFamilyHeaders)
target_compile_options(AppleFileSystemDriver PRIVATE
    -Wno-implicit-int-conversion
    -Wno-sign-conversion)
