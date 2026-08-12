/* Initializers supplied by system libraries outside the qemount runtime. */

void __keymgr_initializer(void) {}
void _libxpc_initializer(void) {}
void _libtrace_init(void) {}
void _libsecinit_initializer(void) {}

void xpc_atfork_prepare(void) {}
void xpc_atfork_parent(void) {}
void xpc_atfork_child(void) {}
void _libtrace_fork_child(void) {}
void _libSC_info_fork_prepare(void) {}
void _libSC_info_fork_parent(void) {}
void _libSC_info_fork_child(void) {}
