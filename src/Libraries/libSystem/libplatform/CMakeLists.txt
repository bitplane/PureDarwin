# TODO: Build libsystem_platform.dylib here.

if(PUREDARWIN_EXTERNAL_SOURCE_ROOT)
    set(libplatform_source_dir ${PUREDARWIN_EXTERNAL_SOURCE_ROOT}/libplatform)
else()
    set(libplatform_source_dir ${CMAKE_CURRENT_SOURCE_DIR})
endif()

if(NOT EXISTS ${libplatform_source_dir}/include/setjmp.h)
    message(FATAL_ERROR "libplatform source tree not found: ${libplatform_source_dir}")
endif()

add_library(libplatform_headers INTERFACE)
target_include_directories(libplatform_headers INTERFACE ${libplatform_source_dir}/include)

add_library(libplatform_private_headers INTERFACE)
target_include_directories(libplatform_private_headers INTERFACE
    ${libplatform_source_dir}/private
    ${libplatform_source_dir}/private/os
)

add_darwin_static_library(libplatform_dyld)
target_sources(libplatform_dyld PRIVATE
    ${libplatform_source_dir}/src/atomics/x86_64/OSAtomic.s
    ${libplatform_source_dir}/src/simple/getenv.c
    ${libplatform_source_dir}/src/simple/string_io.c
    ${libplatform_source_dir}/src/string/generic/bzero.c
    ${libplatform_source_dir}/src/string/generic/memchr.c
    ${libplatform_source_dir}/src/string/generic/memcmp.c
    ${libplatform_source_dir}/src/string/generic/memmove.c
    ${libplatform_source_dir}/src/string/generic/strchr.c
    ${libplatform_source_dir}/src/string/generic/strcmp.c
    ${libplatform_source_dir}/src/string/generic/strncmp.c)
target_compile_definitions(libplatform_dyld PRIVATE VARIANT_STATIC=1)
target_include_directories(libplatform_dyld PRIVATE
    ${libplatform_source_dir}/include
    ${libplatform_source_dir}/internal
    ${libplatform_source_dir}/private)
target_link_libraries(libplatform_dyld PRIVATE
    AvailabilityHeaders
    architecture_headers
    libc_private_headers
    libsystem_kernel_private_headers
    xnu_headers
    xnu_private_headers)

install(
    FILES ${libplatform_source_dir}/include/setjmp.h ${libplatform_source_dir}/include/string_x86.h ${libplatform_source_dir}/include/ucontext.h
    DESTINATION usr/include COMPONENT DeveloperTools
)

install_manpage(man/atomic.3 COMPONENT DeveloperTools ALIASES OSAtomicDequeue.3 OSAtomicEnqueue.3)
install_manpage(man/cache.3 COMPONENT DeveloperTools ALIASES sys_cache_control.3 sys_icache_invalidate.3 sys_dcache_flush.3)
install_manpage(man/ffs.3 COMPONENT DeveloperTools ALIASES ffsl.3 ffsll.3 fls.3 flsl.3 flsll.3)
install_manpage(man/getcontext.3 COMPONENT DeveloperTools ALIASES setcontext.3)
install_manpage(man/makecontext.3 COMPONENT DeveloperTools ALIASES swapcontext.3)
install_manpage(man/setjmp.3 COMPONENT DeveloperTools ALIASES _longjmp.3 _setjmp.3 longjmp.3 longjmperr.3 longjmperror.3 siglongjmp.3 sigsetjmp.3)
install_manpage(man/spinlock_deprecated.3 COMPONENT DeveloperTools ALIASES OSSpinLockLock.3 OSSpinLockTry.3 OSSpinLockUnlock.3)
install_manpage(man/ucontext.3 COMPONENT DeveloperTools)

install_manpage(man/atomic_deprecated.3 COMPONENT DeveloperTools ALIASES
    OSAtomicAdd32.3 OSAtomicAdd32Barrier.3 OSAtomicAdd64.3 OSAtomicAdd64Barrier.3
    OSAtomicAnd32.3 OSAtomicAnd32Barrier.3 OSAtomicAnd32Orig.3 OSAtomicAnd32OrigBarrier.3
    OSAtomicCompareAndSwap32.3 OSAtomicCompareAndSwap32Barrier.3 OSAtomicCompareAndSwap64.3
    OSAtomicCompareAndSwap64Barrier.3 OSAtomicCompareAndSwapInt.3 OSAtomicCompareAndSwapIntBarrier.3
    OSAtomicCompareAndSwapLong.3 OSAtomicCompareAndSwapLongBarrier.3 OSAtomicCompareAndSwapPtr.3
    OSAtomicCompareAndSwapPtrBarrier.3 OSAtomicDecrement32.3 OSAtomicDecrement32Barrier.3
    OSAtomicDecrement64.3 OSAtomicDecrement64Barrier.3 OSAtomicIncrement32.3 OSAtomicIncrement32Barrier.3
    OSAtomicIncrement64.3 OSAtomicIncrement64Barrier.3 OSAtomicOr32.3 OSAtomicOr32Barrier.3 OSAtomicOr32Orig.3
    OSAtomicOr32OrigBarrier.3 OSAtomicTestAndClear.3 OSAtomicTestAndClearBarrier.3 OSAtomicTestAndSet.3
    OSAtomicTestAndSetBarrier.3 OSAtomicXor32.3 OSAtomicXor32Barrier.3 OSAtomicXor32Orig.3 OSAtomicXor32OrigBarrier.3
    OSMemoryBarrier.3
)

install_manpage(man/stdatomic.3 COMPONENT DeveloperTools ALIASES
    ATOMIC_VAR_INIT.3 atomic_compare_exchange_strong.3
    atomic_compare_exchange_strong_explicit.3 atomic_compare_exchange_weak.3
    atomic_compare_exchange_weak_explicit.3 atomic_exchange.3 atomic_exchange_explicit.3
    atomic_fetch_add.3 atomic_fetch_add_explicit.3 atomic_fetch_and.3 atomic_fetch_and_explicit.3
    atomic_fetch_or.3 atomic_fetch_or_explicit.3 atomic_fetch_sub.3 atomic_fetch_sub_explicit.3 atomic_fetch_xor.3
    atomic_fetch_xor_explicit.3 atomic_init.3 atomic_is_lock_free.3 atomic_load.3 atomic_load_explicit.3 atomic_store.3
    atomic_store_explicit.3
)
