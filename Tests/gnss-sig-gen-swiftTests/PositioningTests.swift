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

/// Unit tests for satellite orbit and clock bias calculations.
struct PositioningTests {

    /// Verifies satellite ECEF position calculation from a test ephemeris.
    @Test func testSatPosCalculation() async throws {
        // Create a dummy ephemeris
        var eph = Ephemeris()
        eph.vflg = true
        eph.sqrtA = 5153.5
        eph.ecc = 0.005
        eph.M0 = 0.0
        eph.OMG0 = 0.0
        eph.inc0 = 0.95 // radians
        eph.aop = 0.0
        eph.OMGd = 0.0
        eph.idot = 0.0
        eph.deltan = 0.0
        eph.toe = GPSTime(week: 2000, sec: 0.0)
        eph.toc = eph.toe
        eph.updateDerived()
        
        let t = GPSTime(week: 2000, sec: 0.0)
        let result = Positioning.calculateSatPos(eph: eph, g: t)
        
        // Verify geometric consistency
        let A = eph.sqrtA * eph.sqrtA
        #expect(abs(length(result.pos) - A * (1.0 - eph.ecc)) < 1.0)
    }
}
