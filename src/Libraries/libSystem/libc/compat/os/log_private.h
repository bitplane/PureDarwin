/*
 * The Libc source release uses this libtrace-private ABI from assumes.c, but
 * Apple did not include the corresponding private SDK header.  Keep the ABI
 * description local to the Linux build rather than substituting the unrelated
 * XNU kernel header of the same name.
 */

#ifndef PUREDARWIN_OS_LOG_PRIVATE_H
#define PUREDARWIN_OS_LOG_PRIVATE_H

#include <stdint.h>
#include <time.h>

typedef struct os_log_pack_s {
	uint64_t olp_continuous_time;
	struct timespec olp_wall_time;
	const void *olp_mh;
	const void *olp_pc;
	const char *olp_format;
	uint8_t olp_data[];
} os_log_pack_s, *os_log_pack_t;

#endif
