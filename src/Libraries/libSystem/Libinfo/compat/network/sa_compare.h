#ifndef _NETWORK_SA_COMPARE_H_
#define _NETWORK_SA_COMPARE_H_

#include <sys/socket.h>

static inline int
sa_dst_compare(const struct sockaddr *left, const struct sockaddr *right,
    int flags)
{
    (void)left;
    (void)right;
    (void)flags;
    return 0;
}

#endif
