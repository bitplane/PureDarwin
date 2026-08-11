if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(pthread_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libpthread)
else()
    set(pthread_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
endif()

add_library(pthread_common_headers INTERFACE)
target_include_directories(pthread_common_headers INTERFACE
    ${pthread_source_dir}/pthread
    ${pthread_source_dir})

add_library(pthread_common_private_headers INTERFACE)
target_include_directories(pthread_common_private_headers INTERFACE
    ${pthread_source_dir}/private)
