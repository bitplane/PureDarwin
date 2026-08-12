typedef unsigned __int128 uint128_t;

uint128_t
__udivti3(uint128_t dividend, uint128_t divisor)
{
    uint128_t quotient = 0;
    uint128_t remainder = 0;
    unsigned int bit;

    for (bit = 128; bit != 0; --bit) {
        remainder = (remainder << 1) | ((dividend >> (bit - 1)) & 1);
        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (uint128_t)1 << (bit - 1);
        }
    }

    return quotient;
}
