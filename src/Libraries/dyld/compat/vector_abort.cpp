extern "C" [[noreturn]] void libcxx_vector_length_error()
    __asm("__ZNKSt3__120__vector_base_commonILb1EE20__throw_length_errorEv");

extern "C" [[noreturn]] void libcxx_vector_length_error()
{
    __builtin_trap();
}
