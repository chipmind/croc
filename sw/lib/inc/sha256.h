// Copyright 2026 Chipmind AG.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#pragma once
#include <stdint.h>
#include "config.h"

// SHA-256 register offsets (byte addresses)
#define SHA256_CTRL_OFFSET      0x20
#define SHA256_STATUS_OFFSET    0x24
#define SHA256_BLOCK_OFFSET     0x40 // BLOCK0..BLOCK15 (16 x 4 bytes)
#define SHA256_DIGEST_OFFSET    0x80 // DIGEST0..DIGEST7 (8 x 4 bytes)

// CTRL register bits
#define SHA256_CTRL_INIT_BIT    0
#define SHA256_CTRL_NEXT_BIT    1
#define SHA256_CTRL_MODE_BIT    2

// STATUS register bits
#define SHA256_STATUS_READY_BIT 0
#define SHA256_STATUS_VALID_BIT 1

// Mode
#define SHA256_MODE_SHA224      0
#define SHA256_MODE_SHA256      1

// Write a 32-bit word to SHA-256 register
static inline void sha256_write(uint32_t offset, uint32_t value) {
    *((volatile uint32_t *)(SHA256_BASE_ADDR + offset)) = value;
}

// Read a 32-bit word from SHA-256 register
static inline uint32_t sha256_read(uint32_t offset) {
    return *((volatile uint32_t *)(SHA256_BASE_ADDR + offset));
}

// Write a 512-bit block (16 x 32-bit words, big-endian)
static inline void sha256_write_block(const uint32_t *block) {
    for (int i = 0; i < 16; i++) {
        sha256_write(SHA256_BLOCK_OFFSET + i * 4, block[i]);
    }
}

// Poll until SHA-256 core is ready
static inline void sha256_wait_ready(void) {
    while (!(sha256_read(SHA256_STATUS_OFFSET) & (1 << SHA256_STATUS_READY_BIT)))
        ;
}

// Trigger INIT (first block)
static inline void sha256_init(int mode) {
    sha256_write(SHA256_CTRL_OFFSET, (1 << SHA256_CTRL_INIT_BIT) | ((mode & 1) << SHA256_CTRL_MODE_BIT));
}

// Trigger NEXT (subsequent blocks)
static inline void sha256_next(int mode) {
    sha256_write(SHA256_CTRL_OFFSET, (1 << SHA256_CTRL_NEXT_BIT) | ((mode & 1) << SHA256_CTRL_MODE_BIT));
}

// Read digest (8 x 32-bit words)
static inline void sha256_read_digest(uint32_t *digest) {
    for (int i = 0; i < 8; i++) {
        digest[i] = sha256_read(SHA256_DIGEST_OFFSET + i * 4);
    }
}
