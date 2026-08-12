struct mach_header;

extern "C" const mach_header*
dyld_image_header_containing_address(const void* address);

namespace dyld {
[[noreturn]] void halt(const char* message);
}

namespace dyld3 {
const mach_header* dyld_image_header_containing_address(const void* address)
{
    return ::dyld_image_header_containing_address(address);
}
}

extern "C" [[noreturn]] void libcxx_string_length_error()
    __asm("__ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv");

extern "C" [[noreturn]] void libcxx_string_length_error()
{
    dyld::halt("libc++ string length error");
}

extern "C" [[noreturn]] void libcxx_string_out_of_range()
    __asm("__ZNKSt3__121__basic_string_commonILb1EE20__throw_out_of_rangeEv");

extern "C" [[noreturn]] void libcxx_string_out_of_range()
{
    dyld::halt("libc++ string out of range");
}

extern "C" [[noreturn]] void libcxx_vector_length_error()
    __asm("__ZNKSt3__120__vector_base_commonILb1EE20__throw_length_errorEv");

extern "C" [[noreturn]] void libcxx_vector_length_error()
{
    dyld::halt("libc++ vector length error");
}
