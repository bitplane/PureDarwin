#ifndef _NETWORK_NAT64_H_
#define _NETWORK_NAT64_H_

#include <netinet/in.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/socket.h>

typedef struct nw_nat64_prefix_s {
	uint8_t bytes[16];
} nw_nat64_prefix_t;
typedef void *nw_endpoint_t;
typedef void *nw_path_evaluator_t;
typedef void *nw_path_t;
typedef int nw_path_status_t;

enum {
	nw_path_status_unsatisfied = 0,
};

static inline int32_t
nw_nat64_copy_prefixes(uint32_t *interface_index,
	nw_nat64_prefix_t **prefixes)
{
	(void)interface_index;
	*prefixes = NULL;
	return 0;
}

static inline int
nw_nat64_synthesize_v6(const nw_nat64_prefix_t *prefix,
	const struct in_addr *v4, struct in6_addr *v6)
{
	(void)prefix;
	(void)v4;
	(void)v6;
	return 0;
}

static inline nw_endpoint_t
nw_endpoint_create_address(const struct sockaddr *address)
{
	(void)address;
	return NULL;
}

static inline nw_path_evaluator_t
nw_path_create_evaluator_for_endpoint(nw_endpoint_t endpoint, void *parameters)
{
	(void)endpoint;
	(void)parameters;
	return NULL;
}

static inline nw_path_t
nw_path_evaluator_copy_path(nw_path_evaluator_t evaluator)
{
	(void)evaluator;
	return NULL;
}

static inline nw_path_status_t
nw_path_get_status(nw_path_t path)
{
	(void)path;
	return nw_path_status_unsatisfied;
}

static inline void
network_release(void *object)
{
	(void)object;
}

#endif
