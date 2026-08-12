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
