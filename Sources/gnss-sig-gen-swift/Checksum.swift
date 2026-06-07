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

import Foundation

/// Parity bit calculations for GNSS navigation messages according to IS-GPS-200.
struct Checksum {
    /// Counts the number of set bits (1s) in a 32-bit integer.
    /// - Parameter v: Input value.
    /// - Returns: Number of set bits.
    static func countBits(_ v: UInt32) -> UInt32 {
        var c = v
        let S: [UInt32] = [1, 2, 4, 8, 16]
        let B: [UInt32] = [0x55555555, 0x33333333, 0x0F0F0F0F, 0x00FF00FF, 0x0000FFFF]
        for i in 0..<5 {
            c = ((c >> S[i]) & B[i]) + (c & B[i])
        }
        return c
    }
    
    /// Bit masks for parity calculation (GPS L1 C/A).
    private static let bmask: [UInt32] = [
        0x3B1F3480, 0x1D8F9A40, 0x2EC7CD00,
        0x1763E680, 0x2BB1F340, 0x0B7A89C0
    ]
    
    /// Pre-calculated parity XOR masks for calcChecksumV1.
    private static let parities: [UInt8] = [
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13, 0x25,
        0x0B, 0x16, 0x2C, 0x19, 0x32, 0x26, 0x0E, 0x1F,
        0x3E, 0x3D, 0x38, 0x31, 0x23, 0x07, 0x0D, 0x1A,
        0x37, 0x2F, 0x1C, 0x3B, 0x34, 0x2A, 0x16, 0x29
    ]
    
    /// Calculates the 6 parity bits for a 30-bit GPS navigation word.
    /// - Parameters:
    ///   - sbfmWord: The 24-bit navigation data word (with top 2 bits from previous word).
    ///   - nib: Special handling flag for TOW/HOW words.
    /// - Returns: A 30-bit word including 6 parity bits.
    static func calcChecksumV0(_ sbfmWord: UInt32, nib: Int) -> UInt32 {
        var d = sbfmWord & 0x3FFFFFC0
        let b29 = (sbfmWord >> 31) & 0x1
        let b30 = (sbfmWord >> 30) & 0x1
        
        if nib != 0 {
            if (b30 + countBits(bmask[4] & d)) % 2 != 0 { d ^= (0x1 << 6) }
            if (b29 + countBits(bmask[5] & d)) % 2 != 0 { d ^= (0x1 << 7) }
        }
        
        var wordj = d
        if b30 != 0 { wordj ^= 0x3FFFFFC0 }
        
        wordj |= ((b29 + countBits(bmask[0] & d)) % 2) << 5
        wordj |= ((b30 + countBits(bmask[1] & d)) % 2) << 4
        wordj |= ((b29 + countBits(bmask[2] & d)) % 2) << 3
        wordj |= ((b30 + countBits(bmask[3] & d)) % 2) << 2
        wordj |= ((b30 + countBits(bmask[4] & d)) % 2) << 1
        wordj |= ((b29 + countBits(bmask[5] & d)) % 2)
        
        if b30 != 0 { wordj ^= 0x0000003F }
        
        return wordj & 0x3FFFFFFF
    }
    
    /// Alternative implementation of the IS-GPS-200 parity calculation.
    /// - Parameters:
    ///   - sbfmWord: The 24-bit navigation data word (with top 2 bits from previous word).
    ///   - nib: Special handling flag for TOW/HOW words.
    /// - Returns: A 30-bit word including 6 parity bits.
    static func calcChecksumV1(_ sbfmWord: UInt32, nib: Int) -> UInt32 {
        var d = sbfmWord & 0x3FFFFFC0
        let b29 = (sbfmWord >> 31) & 0x1
        let b30 = (sbfmWord >> 30) & 0x1
        
        if nib != 0 {
            if (b30 + countBits(bmask[4] & d)) % 2 != 0 { d ^= (0x1 << 6) }
            if (b29 + countBits(bmask[5] & d)) % 2 != 0 { d ^= (0x1 << 7) }
        }
        
        var wordj = d | (b30 << 30) | (b29 << 31)
        
        for i in 6..<32 {
            if (wordj & (1 << i)) != 0 {
                wordj ^= UInt32(parities[i])
            }
        }
        
        if b30 != 0 { wordj ^= 0x3FFFFFFF }
        
        return wordj & 0x3FFFFFFF
    }
}
