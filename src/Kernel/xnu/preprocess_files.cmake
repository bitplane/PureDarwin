file(MAKE_DIRECTORY ${XNU_OBJ}/makedefs)
file(MAKE_DIRECTORY ${XNU_OBJ}/bsd/sys)

if(XNU_EXTERNAL_SOURCE)
    configure_file(${XNU_SRC}/makedefs/MakeInc.cmd ${XNU_OBJ}/makedefs/MakeInc.cmd COPYONLY)

    file(READ ${XNU_SRC}/makedefs/MakeInc.def make_inc_def)
    string(REPLACE
        "ARCH_FLAGS_X86_64\t  = -arch x86_64"
        "ARCH_FLAGS_X86_64\t  = -target ${PUREDARWIN_TARGET_TRIPLE}"
        make_inc_def "${make_inc_def}")
    string(REPLACE
        "LD\t= $(KC++) -nostdlib"
        "LD\t= $(KC++) -nostdlib -fuse-ld=${LD_PATH}"
        make_inc_def "${make_inc_def}")
    string(REPLACE
        "LDFLAGS_KERNEL_SDK\t= -L$(SDKROOT)/usr/local/lib/kernel -lfirehose_kernel"
        "LDFLAGS_KERNEL_SDK\t= -L${FIREHOSE_KERNEL_LIBRARY_DIR} -lfirehose_kernel"
        make_inc_def "${make_inc_def}")
    string(REPLACE
        "LD_KERNEL_LIBS\t= -lcc_kext"
        "LD_KERNEL_LIBS\t= ${PROFILE_RUNTIME_LIBRARY_PATH}"
        make_inc_def "${make_inc_def}")
    string(REPLACE
        "INCFLAGS_EXTERN\t= -I$(SRCROOT)/EXTERNAL_HEADERS"
        "INCFLAGS_EXTERN\t= -I$(SRCROOT)/EXTERNAL_HEADERS -I${PTHREAD_HEADER_PATH}"
        make_inc_def "${make_inc_def}")
    string(REPLACE
        "INCFLAGS_SDK\t= -I$(SDKROOT)/usr/local/include/kernel"
        "INCFLAGS_SDK\t= -I${FIREHOSE_KERNEL_HEADER_PATH}"
        make_inc_def "${make_inc_def}")
    file(WRITE ${XNU_OBJ}/makedefs/MakeInc.def "${make_inc_def}")

    file(READ ${XNU_SRC}/bsd/sys/make_symbol_aliasing.sh make_symbol_aliasing)
    string(REPLACE
        "\${SDKROOT}/usr/local/libexec/availability.pl"
        "${AVAILABILITY_PL_PATH}"
        make_symbol_aliasing "${make_symbol_aliasing}")
    file(WRITE ${XNU_OBJ}/bsd/sys/make_symbol_aliasing.sh "${make_symbol_aliasing}")
    file(CHMOD ${XNU_OBJ}/bsd/sys/make_symbol_aliasing.sh
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
else()
    configure_file(${CMAKE_CURRENT_LIST_DIR}/cmake/MakeInc.cmd.in ${XNU_OBJ}/makedefs/MakeInc.cmd @ONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/cmake/MakeInc.def.in ${XNU_OBJ}/makedefs/MakeInc.def @ONLY)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/cmake/make_symbol_aliasing.sh.in ${XNU_OBJ}/bsd/sys/make_symbol_aliasing.sh @ONLY)
endif()
