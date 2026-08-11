set(hfs_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/hfs)
set(hfs_core_dir ${hfs_source_dir}/core)
set(hfs_include_dir ${CMAKE_CURRENT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${hfs_include_dir}/hfs)
file(COPY
    ${hfs_core_dir}/hfs_format.h
    ${hfs_core_dir}/hfs_unistr.h
    DESTINATION ${hfs_include_dir}/hfs)

add_library(HFSHeaders INTERFACE)
target_include_directories(HFSHeaders INTERFACE ${hfs_include_dir})

add_kext_bundle(HFS KERNEL_PRIVATE
    INFO_PLIST ${hfs_core_dir}/macosx-Info.plist
    BUNDLE_IDENTIFIER com.apple.filesystems.hfs.kext
    BUNDLE_VERSION 407.30.1)

target_sources(HFS PRIVATE
    ${hfs_core_dir}/BTree.c
    ${hfs_core_dir}/BTreeAllocate.c
    ${hfs_core_dir}/BTreeMiscOps.c
    ${hfs_core_dir}/BTreeNodeOps.c
    ${hfs_core_dir}/BTreeNodeReserve.c
    ${hfs_core_dir}/BTreeScanner.c
    ${hfs_core_dir}/BTreeTreeOps.c
    ${hfs_core_dir}/BTreeWrapper.c
    ${hfs_core_dir}/CatalogUtilities.c
    ${hfs_core_dir}/FileExtentMapping.c
    ${hfs_core_dir}/FileIDsServices.c
    ${hfs_core_dir}/MacOSStubs.c
    ${hfs_core_dir}/UnicodeWrappers.c
    ${hfs_core_dir}/VolumeAllocation.c
    ${hfs_core_dir}/hfs_attrlist.c
    ${hfs_core_dir}/hfs_btreeio.c
    ${hfs_core_dir}/hfs_catalog.c
    ${hfs_core_dir}/hfs_chash.c
    ${hfs_core_dir}/hfs_cnode.c
    ${hfs_core_dir}/hfs_cprotect.c
    ${hfs_core_dir}/hfs_endian.c
    ${hfs_core_dir}/hfs_extents.c
    ${hfs_core_dir}/hfs_fsinfo.c
    ${hfs_core_dir}/hfs_hotfiles.c
    ${hfs_core_dir}/hfs_iokit.cpp
    ${hfs_core_dir}/hfs_journal.c
    ${hfs_core_dir}/hfs_key_roll.c
    ${hfs_core_dir}/hfs_link.c
    ${hfs_core_dir}/hfs_lookup.c
    ${hfs_core_dir}/hfs_notification.c
    ${hfs_core_dir}/hfs_quota.c
    ${hfs_core_dir}/hfs_readwrite.c
    ${hfs_core_dir}/hfs_resize.c
    ${hfs_core_dir}/hfs_search.c
    ${hfs_core_dir}/hfs_vfsops.c
    ${hfs_core_dir}/hfs_vfsutils.c
    ${hfs_core_dir}/hfs_vnops.c
    ${hfs_core_dir}/hfs_xattr.c
    ${hfs_core_dir}/rangelist.c)

target_include_directories(HFS PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${hfs_core_dir})
target_link_libraries(HFS PRIVATE
    IOStorageFamilyHeaders
    corecrypto_headers)
target_compile_options(HFS PRIVATE
    -include ${hfs_core_dir}/kext-config.h
    -Wno-implicit-int-conversion
    -Wno-shorten-64-to-32
    -Wno-sign-conversion)
set_property(TARGET HFS PROPERTY C_STANDARD 99)

set(hfs_encodings_dir ${hfs_source_dir}/hfs_encodings)
add_kext_bundle(HFSEncodings KERNEL_PRIVATE
    INFO_PLIST ${hfs_encodings_dir}/HFSEncodings-Info.plist
    BUNDLE_IDENTIFIER com.apple.filesystems.hfs.encodings.kext
    BUNDLE_VERSION 1.0)
target_sources(HFSEncodings PRIVATE
    ${hfs_encodings_dir}/hfs_encodinghint.c
    ${hfs_encodings_dir}/hfs_encodings.c
    ${hfs_encodings_dir}/hfs_encodings_kext.cpp)
target_include_directories(HFSEncodings PRIVATE ${hfs_encodings_dir})
target_compile_options(HFSEncodings PRIVATE
    -Wno-implicit-int-conversion
    -Wno-sign-conversion)
set_property(TARGET HFSEncodings PROPERTY CXX_STANDARD 11)
