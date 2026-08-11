#ifndef _APPLEKEYSTORE_FILESYSTEM_KEY_SERVICES_H
#define _APPLEKEYSTORE_FILESYSTEM_KEY_SERVICES_H

#include <sys/cprotect.h>
#include <uuid/uuid.h>

typedef struct {
    void *key;
    unsigned key_len;
    void *iv_key;
    unsigned iv_key_len;
    uint32_t flags;
} *aks_raw_key_t;

typedef struct {
    void *key;
    unsigned key_len;
    cp_key_class_t dp_class;
} *aks_wrapped_key_t;

typedef struct {
    union {
        ino64_t inode;
        cp_crypto_id_t crypto_id;
    };
    pid_t pid;
    uid_t uid;
    uuid_t volume_uuid;
    cp_key_revision_t key_revision;
} *aks_cred_t;

typedef struct {
    int (*unwrap_key)(aks_cred_t, const aks_wrapped_key_t, aks_raw_key_t);
    int (*rewrap_key)(aks_cred_t, cp_key_class_t,
        const aks_wrapped_key_t, aks_wrapped_key_t);
    int (*new_key)(aks_cred_t, cp_key_class_t,
        aks_raw_key_t, aks_wrapped_key_t);
    int (*backup_key)(aks_cred_t,
        const aks_wrapped_key_t, aks_wrapped_key_t);
} aks_file_system_key_services_t;

#define kAKSFileSystemKeyServices "AppleKeyStoreFSServices"
#define AKS_RAW_KEY_WRAPPEDKEY CP_RAW_KEY_WRAPPEDKEY

#endif
