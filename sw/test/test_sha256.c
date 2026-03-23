// Copyright 2026 Chipmind AG.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include <stdint.h>
#include "sha256.h"
#include "uart.h"
#include "util.h"

// Pre-padded NIST test vectors (512-bit blocks, big-endian 32-bit words)

// Test 1: SHA-256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
static const uint32_t empty_block[16]   = {0x80000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                           0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                           0x00000000, 0x00000000, 0x00000000, 0x00000000};
static const uint32_t empty_expected[8] = {0xe3b0c442, 0x98fc1c14, 0x9afbf4c8, 0x996fb924,
                                           0x27ae41e4, 0x649b934c, 0xa495991b, 0x7852b855};

// Test 2: SHA-256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
static const uint32_t abc_block[16]     = {0x61626380, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                           0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                           0x00000000, 0x00000000, 0x00000000, 0x00000018};
static const uint32_t abc_expected[8]   = {0xba7816bf, 0x8f01cfea, 0x414140de, 0x5dae2223,
                                           0xb00361a3, 0x96177a9c, 0xb410ff61, 0xf20015ad};

// Test 3: SHA-256("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
// = 248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1
// Two blocks required (56-byte message)
static const uint32_t long_block1[16]   = {0x61626364, 0x62636465, 0x63646566, 0x64656667, 0x65666768, 0x66676869,
                                           0x6768696a, 0x68696a6b, 0x696a6b6c, 0x6a6b6c6d, 0x6b6c6d6e, 0x6c6d6e6f,
                                           0x6d6e6f70, 0x6e6f7071, 0x80000000, 0x00000000};
static const uint32_t long_block2[16]   = {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                           0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000,
                                           0x00000000, 0x00000000, 0x00000000, 0x000001c0};
static const uint32_t long_expected[8]  = {0x248d6a61, 0xd20638b8, 0xe5c02693, 0x0c3e6039,
                                           0xa33ce459, 0x64ff2167, 0xf6ecedd4, 0x19db06c1};

// Compute SHA-256 for a single block and check result
static int sha256_test_single(const uint32_t *block, const uint32_t *expected, int test_id) {
    uint32_t digest[8];

    sha256_wait_ready();
    sha256_write_block(block);
    sha256_init(SHA256_MODE_SHA256);
    sha256_wait_ready();
    sha256_read_digest(digest);

    for (int i = 0; i < 8; i++) {
        if (digest[i] != expected[i]) return test_id * 10 + i + 1;
    }
    return 0;
}

// Compute SHA-256 for two blocks and check result
static int sha256_test_two_blocks(const uint32_t *block1, const uint32_t *block2, const uint32_t *expected,
                                  int test_id) {
    uint32_t digest[8];

    sha256_wait_ready();
    sha256_write_block(block1);
    sha256_init(SHA256_MODE_SHA256);
    sha256_wait_ready();

    sha256_write_block(block2);
    sha256_next(SHA256_MODE_SHA256);
    sha256_wait_ready();
    sha256_read_digest(digest);

    for (int i = 0; i < 8; i++) {
        if (digest[i] != expected[i]) return test_id * 10 + i + 1;
    }
    return 0;
}

int main(void) {
    int err = 0;

    err     = sha256_test_single(empty_block, empty_expected, 1);
    if (err) return err;

    err = sha256_test_single(abc_block, abc_expected, 2);
    if (err) return err;

    err = sha256_test_two_blocks(long_block1, long_block2, long_expected, 3);
    if (err) return err;

    return 0;
}
