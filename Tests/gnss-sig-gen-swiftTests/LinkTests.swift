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

/// Unit tests for satellite link state and navigation data encoding.
struct LinkTests {

    /// Verifies the encoding of ephemeris parameters into raw navigation subframe bits.
    @Test func testEph2SBF() async throws {
        var eph = Ephemeris()
        eph.vflg = true
        eph.toe = GPSTime(week: 2000, sec: 0.0)
        eph.toc = eph.toe
        eph.af[0] = 0.0001
        
        let ionoutc = IonUTC()
        let sbf = Link.eph2sbf(eph: eph, ionoutc: ionoutc)
        
        #expect(sbf.count == 5)
        #expect(sbf[0].count == 10)
        
        // Verify preamble (0x8B) in the first word
        #expect((sbf[0][0] >> 22) == 0x8B)
        
        // Verify subframe ID in the second word
        #expect((sbf[0][1] >> 8) == 1)
    }
}
