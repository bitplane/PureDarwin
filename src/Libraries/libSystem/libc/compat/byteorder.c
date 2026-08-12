#include <stdint.h>

uint32_t
ntohl(uint32_t value)
{
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
	return __builtin_bswap32(value);
#else
	return value;
#endif
}

uint32_t
htonl(uint32_t value)
{
	return ntohl(value);
}

uint16_t
ntohs(uint16_t value)
{
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
	return __builtin_bswap16(value);
#else
	return value;
#endif
}

uint16_t
htons(uint16_t value)
{
	return ntohs(value);
}
