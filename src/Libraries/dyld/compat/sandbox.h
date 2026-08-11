#pragma once

#include <sys/types.h>

enum sandbox_filter_type {
    SANDBOX_FILTER_NONE,
    SANDBOX_FILTER_PATH,
};

#define SANDBOX_CHECK_NO_REPORT ((enum sandbox_filter_type)0x100)

static inline int
sandbox_check(pid_t pid, const char *operation, enum sandbox_filter_type type, ...)
{
    (void)pid;
    (void)operation;
    (void)type;
    return 1;
}
