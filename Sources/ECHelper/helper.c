#include "include/helper.h"

#include <stdio.h>
#include <stdlib.h>

#include "secp256k1_schnorrsig.h"

const char* toHex(const unsigned char* bytes, int count) {
    int i;
    char *converted = malloc(count + 1);
    for (i = 0; i < 32; i++) {
        sprintf(&converted[i * 2], "%02x", bytes[i]);
    }
    return converted;
}

const char* computeInternalKey(const unsigned char secretKey[32]) {
    // unsigned char sk[32] = "\x41\xf4\x1d\x69\x26\x0d\xf4\xcf\x27\x78\x26\xa9\xb6\x5a\x37\x17\xe4\xee\xdd\xbe\xed\xf6\x37\xf2\x12\xca\x09\x65\x76\x47\x93\x61";
    secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    secp256k1_keypair keypair;
    secp256k1_xonly_pubkey internalKey;
    unsigned char internalKeyBytes[32];
    if (!secp256k1_keypair_create(context, &keypair, secretKey)) { return NULL; };
    if (!secp256k1_keypair_xonly_pub(context, &internalKey, NULL, &keypair)) { return NULL; };
    if (!secp256k1_xonly_pubkey_serialize(context, internalKeyBytes, &internalKey)) { return NULL; }
    return toHex(internalKeyBytes, 32);
}

const char* computeOutputKey(const unsigned char internalKeyBytes[32], unsigned char tweak[32]) {
    secp256k1_context *context = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    secp256k1_xonly_pubkey internalKey;
    secp256k1_pubkey outputKey; // Used for non keypair flow
    secp256k1_xonly_pubkey outputKeyXOnly;
    unsigned char outputKeyBytes[32];
    int keyParity;
    if (!secp256k1_xonly_pubkey_parse(context, &internalKey, internalKeyBytes)) { return NULL; };
    if (!secp256k1_xonly_pubkey_tweak_add(context, &outputKey, &internalKey, tweak)) { return NULL; };
    if (!secp256k1_xonly_pubkey_from_pubkey(context, &outputKeyXOnly, &keyParity, &outputKey)) { return NULL; };
    if (!secp256k1_xonly_pubkey_serialize(context, outputKeyBytes, &outputKeyXOnly)) { return NULL; };
    return toHex(outputKeyBytes, 32);
}
