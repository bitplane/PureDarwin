#include <CommonCrypto/CommonDigest.h>
#include <corecrypto/ccdigest.h>
#include <corecrypto/ccsha1.h>
#include <corecrypto/ccsha2.h>

unsigned char *
CC_SHA1(const void *data, CC_LONG length, unsigned char *digest)
{
    ccdigest(ccsha1_di(), length, data, digest);
    return digest;
}

unsigned char *
CC_SHA256(const void *data, CC_LONG length, unsigned char *digest)
{
    ccdigest(ccsha256_di(), length, data, digest);
    return digest;
}
