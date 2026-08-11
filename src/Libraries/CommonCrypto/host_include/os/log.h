#ifndef PUREDARWIN_HOST_OS_LOG_H
#define PUREDARWIN_HOST_OS_LOG_H

typedef void *os_log_t;

#define OS_LOG_DEFAULT ((os_log_t)0)
#define os_log_fault(log, format, ...) ((void)0)

#endif
