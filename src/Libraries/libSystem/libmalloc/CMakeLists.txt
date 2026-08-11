# Currently, just expose headers under include/

add_library(libmalloc_headers INTERFACE)

if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(libmalloc_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libmalloc)
else()
    set(libmalloc_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
endif()

if(NOT EXISTS ${libmalloc_source_dir}/include/malloc/malloc.h)
    message(FATAL_ERROR "libmalloc source tree not found: ${libmalloc_source_dir}")
endif()

target_include_directories(libmalloc_headers INTERFACE ${libmalloc_source_dir}/include)
