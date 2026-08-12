#ifndef PUREDARWIN_LIBDYLD_MATH_H
#define PUREDARWIN_LIBDYLD_MATH_H

#include_next <math.h>

#ifdef __cplusplus
#undef fpclassify
#undef isfinite
#undef isgreater
#undef isgreaterequal
#undef isinf
#undef isless
#undef islessequal
#undef islessgreater
#undef isnan
#undef isnormal
#undef isunordered
#undef signbit

template <class T> inline int fpclassify(T x)
{
    return __builtin_fpclassify(FP_NAN, FP_INFINITE, FP_NORMAL, FP_SUBNORMAL,
        FP_ZERO, x);
}
template <class T> inline bool isfinite(T x) { return __builtin_isfinite(x); }
template <class T> inline bool isinf(T x) { return __builtin_isinf(x); }
template <class T> inline bool isnan(T x) { return __builtin_isnan(x); }
template <class T> inline bool isnormal(T x) { return __builtin_isnormal(x); }
template <class T> inline bool signbit(T x) { return __builtin_signbit(x); }
template <class T, class U> inline bool isgreater(T x, U y)
{
    return __builtin_isgreater(x, y);
}
template <class T, class U> inline bool isgreaterequal(T x, U y)
{
    return __builtin_isgreaterequal(x, y);
}
template <class T, class U> inline bool isless(T x, U y)
{
    return __builtin_isless(x, y);
}
template <class T, class U> inline bool islessequal(T x, U y)
{
    return __builtin_islessequal(x, y);
}
template <class T, class U> inline bool islessgreater(T x, U y)
{
    return __builtin_islessgreater(x, y);
}
template <class T, class U> inline bool isunordered(T x, U y)
{
    return __builtin_isunordered(x, y);
}
#endif

#endif
