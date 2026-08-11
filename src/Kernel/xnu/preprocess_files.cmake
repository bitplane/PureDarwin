file(MAKE_DIRECTORY ${XNU_OBJ}/makedefs)
file(MAKE_DIRECTORY ${XNU_OBJ}/bsd/sys)

if(XNU_EXTERNAL_SOURCE)
    configure_file(${XNU_SRC}/makedefs/MakeInc.cmd ${XNU_OBJ}/makedefs/MakeInc.cmd COPYONLY)

    file(READ ${XNU_SRC}/makedefs/MakeInc.def make_inc_def)
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
