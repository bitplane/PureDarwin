#include <limits.h>

int
fls(int value)
{
	if (value == 0)
		return 0;
	return (int)(sizeof(value) * CHAR_BIT - __builtin_clz((unsigned int)value));
}

int
flsl(long value)
{
	if (value == 0)
		return 0;
	return (int)(sizeof(value) * CHAR_BIT - __builtin_clzl((unsigned long)value));
}
