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

/// Pseudo-Random Noise (PRN) code generation for GNSS signals.
struct GPSCode {
    /// Standard length of a GPS L1 C/A code epoch (chips).
    static let codeLength = 1023
    /// Maximum supported PRN number.
    static let maxPRN = 210
    
    /// G2 register delay taps for each PRN (from IS-GPS-200).
    private static let g2Delay: [Int16] = [
        5,   6,   7,   8,  17,  18, 139, 140, 141, 251,
        252, 254, 255, 256, 257, 258, 469, 470, 471, 472,
        473, 474, 509, 512, 513, 514, 515, 516, 859, 860,
        861, 862, 863, 950, 947, 948, 950,  67, 103,  91,
        19, 679, 225, 625, 946, 638, 161,1001, 554, 280,
        710, 709, 775, 864, 558, 220, 397,  55, 898, 759,
        367, 299,1018, 729, 695, 780, 801, 788, 732,  34,
        320, 327, 389, 407, 525, 405, 221, 761, 260, 326,
        955, 653, 699, 422, 188, 438, 959, 539, 879, 677,
        586, 153, 792, 814, 446, 264,1015, 278, 536, 819,
        156, 957, 159, 712, 885, 461, 248, 713, 126, 807,
        279, 122, 197, 693, 632, 771, 467, 647, 203, 145,
        175,  52,  21, 237, 235, 886, 657, 634, 762, 355,
        1012, 176, 603, 130, 359, 595,  68, 386, 797, 456,
        499, 883, 307, 127, 211, 121, 118, 163, 628, 853,
        484, 289, 811, 202,1021, 463, 568, 904, 670, 230,
        911, 684, 309, 644, 932,  12, 314, 891, 212, 185,
        675, 503, 150, 395, 345, 846, 798, 992, 357, 995,
        877, 112, 144, 476, 193, 109, 445, 291,  87, 399,
        292, 901, 339, 208, 711, 189, 263, 537, 663, 942,
        173, 900,  30, 500, 935, 556, 373,  85, 652, 310
    ]
    
    /// Generates a packed 32-bit array containing the 1023 bits of a GPS L1 C/A Gold code.
    /// - Parameter prn: Satellite PRN number (1-210).
    /// - Returns: An array of 32 `UInt32` values containing the packed code bits, or `nil` if PRN is invalid.
    static func generateL1CA(prn: Int) -> [UInt32]? {
        guard prn >= 1 && prn <= maxPRN else { return nil }
        
        var code = [UInt32](repeating: 0, count: 32)
        var g1 = [Int8](repeating: 0, count: codeLength)
        var g2 = [Int8](repeating: 0, count: codeLength)
        var r1 = [Int8](repeating: -1, count: 10)
        var r2 = [Int8](repeating: -1, count: 10)
        
        for i in 0..<codeLength {
            g1[i] = r1[9]
            g2[i] = r2[9]
            let c1 = r1[2] * r1[9]
            let c2 = r2[1] * r2[2] * r2[5] * r2[7] * r2[8] * r2[9]
            for j in (1...9).reversed() {
                r1[j] = r1[j-1]
                r2[j] = r2[j-1]
            }
            r1[0] = c1
            r2[0] = c2
        }
        
        let d = Int(g2Delay[prn - 1])
        for i in 0..<codeLength {
            let j = (i + codeLength - d) % codeLength
            if g1[i] * g2[j] > 0 {
                code[i >> 5] |= (1 << (i & 0x1F))
            }
        }
        return code
    }
}
