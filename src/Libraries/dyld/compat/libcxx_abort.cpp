extern "C" [[noreturn]] void libcxx_string_length_error()
    __asm("__ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv");

extern "C" [[noreturn]] void libcxx_string_length_error()
{
    __builtin_trap();
}

extern "C" [[noreturn]] void libcxx_string_out_of_range()
    __asm("__ZNKSt3__121__basic_string_commonILb1EE20__throw_out_of_rangeEv");

extern "C" [[noreturn]] void libcxx_string_out_of_range()
{
    __builtin_trap();
}
