add_darwin_static_library(CrashReporterClient)
add_library(CrashReporterClient_headers INTERFACE)

target_sources(CrashReporterClient PRIVATE CrashReporterClient.c)

target_link_libraries(CrashReporterClient PRIVATE clang_bootstrap_headers)

target_include_directories(CrashReporterClient_headers INTERFACE include)
target_link_libraries(CrashReporterClient PUBLIC CrashReporterClient_headers)

# I believe this is where this should be placed. The configure-dyld-archives.sh script looks for it here at least.
install(TARGETS CrashReporterClient DESTINATION usr/local/lib COMPONENT DeveloperInternal)

install(FILES include/CrashReporterClient.h DESTINATION usr/local/include COMPONENT DeveloperInternal)
