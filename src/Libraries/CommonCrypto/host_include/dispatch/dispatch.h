#ifndef PUREDARWIN_HOST_DISPATCH_H
#define PUREDARWIN_HOST_DISPATCH_H

#include <sched.h>
#include <stdatomic.h>

typedef atomic_int dispatch_once_t;
typedef void (*dispatch_function_t)(void *);

static inline void
dispatch_once_f(dispatch_once_t *predicate, void *context,
    dispatch_function_t function)
{
    int pending = 0;

    if (atomic_compare_exchange_strong_explicit(predicate, &pending, 1,
            memory_order_acquire, memory_order_acquire)) {
        function(context);
        atomic_store_explicit(predicate, 2, memory_order_release);
        return;
    }

    while (atomic_load_explicit(predicate, memory_order_acquire) != 2)
        sched_yield();
}

#endif
