/******************************************************************************
 *
 * Aut viam inveniam aut faciam
 *
 * Copyright (c) 2019-2026 Shu Wang. All rights reserved.
 *
 * PROPRIETARY AND CONFIDENTIAL
 *
 * This software and its documentation (the "Software") are the confidential 
 * and proprietary information of Shu Wang. All rights, title, and 
 * interest in and to the Software, including all intellectual property rights, 
 * are and shall remain the exclusive property of Shu Wang.
 *
 * Correspondence regarding this Software should be directed to:
 * Shu Wang <shuwang1@outlook.com>
 ******************************************************************************/

import Testing
import Foundation
@testable import gnss_sig_gen_swift

/// Unit tests for IS-GPS-200 parity and checksum logic.
struct ChecksumTests {

    /// Verifies the software implementation of population count.
    @Test func testCountBits() async throws {
        #expect(Checksum.countBits(0) == 0)
        #expect(Checksum.countBits(0xFFFFFFFF) == 32)
        #expect(Checksum.countBits(0x10101010) == 4)
        #expect(Checksum.countBits(0xAAAAAAAA) == 16)
    }
    
    /// Verifies GPS L1 C/A parity bit generation for navigation words.
    @Test func testChecksumV0() async throws {
        // Standard Preamble (0x8B) word
        let preamble: UInt32 = 0x8B0000 << 6
        let word = Checksum.calcChecksumV0(preamble, nib: 0)
        #expect((word >> 22) == 0x8B)
        // Parity bits (last 6) should be calculated
        #expect((word & 0x3F) != 0)
    }
    
    /// Verifies that calcChecksumV0 and calcChecksumV1 are mathematically equivalent.
    @Test func testChecksumV1Equivalence() async throws {
        let testCases: [UInt32] = [
            0x8B0000 << 6,   // Standard Preamble
            0x3FFFFFC0,      // All ones
            0x00000000,      // All zeros
            0x123456 << 6,   // Random pattern
            (0x1 << 31) | (0x123456 << 6), // Previous word d30* = 1
            (0x1 << 30) | (0x123456 << 6), // Previous word d29* = 1
            (0x3 << 30) | (0x123456 << 6)  // Both previous bits = 1
        ]
        
        for nib in [0, 1] {
            for tc in testCases {
                let resV0 = Checksum.calcChecksumV0(tc, nib: nib)
                let resV1 = Checksum.calcChecksumV1(tc, nib: nib)
                #expect(resV0 == resV1, "Failed for tc: \(String(tc, radix: 16)), nib: \(nib)")
            }
        }
    }
}
