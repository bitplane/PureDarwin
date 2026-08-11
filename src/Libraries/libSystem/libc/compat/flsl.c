#include <limits.h>

int
flsl(long value)
{
	if (value == 0)
		return 0;
	return (int)(sizeof(value) * CHAR_BIT - __builtin_clzl((unsigned long)value));
}
