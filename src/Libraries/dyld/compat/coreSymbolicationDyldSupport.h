#pragma once

#include <mach-o/loader.h>
#include <stdint.h>

static inline void
coresymbolication_load_notifier(void *connection, uint64_t timestamp,
    const char *path, const struct mach_header *header)
{
    (void)connection;
    (void)timestamp;
    (void)path;
    (void)header;
}

static inline void
coresymbolication_unload_notifier(void *connection, uint64_t timestamp,
    const char *path, const struct mach_header *header)
{
    (void)connection;
    (void)timestamp;
    (void)path;
    (void)header;
}
