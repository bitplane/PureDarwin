#include <mach-o/dyld_priv.h>

namespace dyld {
[[noreturn]] void halt(const char* message);
}

namespace dyld3 {
const mach_header* dyld_image_header_containing_address(const void* address)
{
    return ::dyld_image_header_containing_address(address);
}
}

namespace std {
inline namespace __1 {
template <bool>
struct __basic_string_common;

template <>
[[noreturn]] void __basic_string_common<true>::__throw_length_error() const
{
    dyld::halt("libc++ string length error");
}
}
}
