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

/// Unit tests for GNSS code generation logic.
struct CodeTests {

    /// Verifies the correct generation of GPS L1 C/A Gold codes for specific PRNs.
    @Test func testGPSL1CAGeneration() async throws {
        guard let code = GPSCode.generateL1CA(prn: 1) else {
            Issue.record("PRN 1 should be valid")
            return
        }
        
        #expect(code.count == 32)
        
        // Extract first 10 bits
        var bits = [Int]()
        for i in 0..<10 {
            bits.append(Int((code[0] >> i) & 1))
        }
        
        // C/A code bits in this implementation are inverted for signal synthesis performance.
        // Standard PRN 1 first chips: 1 1 0 0 1 0 0 0 0 0
        // Expected bits (inverted): 0 0 1 1 0 1 1 1 1 1
        #expect(bits == [0, 0, 1, 1, 0, 1, 1, 1, 1, 1])
        
        // PRN 32
        guard let code32 = GPSCode.generateL1CA(prn: 32) else {
            Issue.record("PRN 32 should be valid")
            return
        }
        var bits32 = [Int]()
        for i in 0..<10 {
            bits32.append(Int((code32[0] >> i) & 1))
        }
        // PRN 32 first 10 chips: Expected bits based on implementation (inverted)
        #expect(bits32 == [0, 0, 0, 0, 1, 1, 0, 1, 0, 1])
    }
    
    /// Verifies that invalid PRN numbers are rejected.
    @Test func testInvalidPRN() async throws {
        #expect(GPSCode.generateL1CA(prn: 0) == nil)
        #expect(GPSCode.generateL1CA(prn: 211) == nil)
    }
}
