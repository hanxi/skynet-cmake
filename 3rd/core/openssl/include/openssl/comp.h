#ifndef OPENSSL_COMP_H
#define OPENSSL_COMP_H
#pragma once

#include <openssl/macros.h>
#ifndef OPENSSL_NO_DEPRECATED_3_0
#define HEADER_COMP_H
#endif

#include <openssl/opensslconf.h>

#include <openssl/comperr.h>
#include <openssl/crypto.h>
#ifdef __cplusplus
extern "C" {
#endif

#ifndef OPENSSL_NO_COMP

COMP_CTX *COMP_CTX_new(COMP_METHOD *meth);
const COMP_METHOD *COMP_CTX_get_method(const COMP_CTX *ctx);
int COMP_CTX_get_type(const COMP_CTX *comp);
int COMP_get_type(const COMP_METHOD *meth);
const char *COMP_get_name(const COMP_METHOD *meth);
void COMP_CTX_free(COMP_CTX *ctx);

int COMP_compress_block(COMP_CTX *ctx, unsigned char *out, int olen,
                        unsigned char *in, int ilen);
int COMP_expand_block(COMP_CTX *ctx, unsigned char *out, int olen,
                      unsigned char *in, int ilen);

COMP_METHOD *COMP_zlib(void);
COMP_METHOD *COMP_zlib_oneshot(void);
COMP_METHOD *COMP_brotli(void);
COMP_METHOD *COMP_brotli_oneshot(void);
COMP_METHOD *COMP_zstd(void);
COMP_METHOD *COMP_zstd_oneshot(void);

#ifndef OPENSSL_NO_DEPRECATED_1_1_0
#define COMP_zlib_cleanup()                                                    \
  while (0)                                                                    \
  continue
#endif

#ifdef OPENSSL_BIO_H
const BIO_METHOD *BIO_f_zlib(void);
const BIO_METHOD *BIO_f_brotli(void);
const BIO_METHOD *BIO_f_zstd(void);
#endif

#endif

typedef struct ssl_comp_st SSL_COMP;

#ifdef __cplusplus
}
#endif
#endif
