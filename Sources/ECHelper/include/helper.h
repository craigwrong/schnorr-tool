#ifndef helper_h
#define helper_h

const char* computeInternalKey(const unsigned char secretKey[32]);
const char* computeOutputKey(const unsigned char internalKeyBytes[32], unsigned char tweak[32]);

#endif /* helper_h */
