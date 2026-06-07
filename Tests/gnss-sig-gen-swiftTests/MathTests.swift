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

/// Unit tests for mathematical utilities and coordinate transformations.
struct MathTests {

    /// Verifies ECEF to LLH conversion at specific reference points.
    @Test func testXYZ2LLH() async throws {
        // Point on the equator at Greenwich meridian
        let origin = Vector3(Constants.WGS84_RADIUS, 0, 0)
        let llh = MathUtils.xyz2llh(origin)
        
        #expect(abs(llh.x) < 1e-9) // Lat 0
        #expect(abs(llh.y) < 1e-9) // Lon 0
        #expect(abs(llh.z) < 1e-3) // H 0
        
        // North Pole calculation
        let n_pole = Constants.WGS84_RADIUS / sqrt(1.0 - pow(Constants.WGS84_ECCENTRICITY, 2))
        let z_pole = n_pole * (1.0 - pow(Constants.WGS84_ECCENTRICITY, 2))
        let northPole = Vector3(0, 0, z_pole)
        let llhPole = MathUtils.xyz2llh(northPole)
        
        #expect(abs(llhPole.x - 90.0 * Constants.D2R) < 1e-9)
        #expect(abs(llhPole.z) < 1e-3)
    }
    
    /// Verifies bidirectional consistency between LLH and ECEF conversions.
    @Test func testLLH2XYZ() async throws {
        let llh = Vector3(52.2 * Constants.D2R, 0.1 * Constants.D2R, 100.0)
        let xyz = MathUtils.llh2xyz(llh)
        let llhBack = MathUtils.xyz2llh(xyz)
        
        #expect(abs(llh.x - llhBack.x) < 1e-9)
        #expect(abs(llh.y - llhBack.y) < 1e-9)
        #expect(abs(llh.z - llhBack.z) < 1e-3)
    }
    
    /// Verifies conversion from NEU vectors to Azimuth and Elevation angles.
    @Test func testNEU2Azel() async throws {
        // Point directly North
        let neuN = Vector3(100, 0, 0)
        let azelN = MathUtils.neu2azel(neuN)
        #expect(abs(azelN.az) < 1e-9)
        #expect(abs(azelN.el) < 1e-9)
        
        // Point directly East
        let neuE = Vector3(0, 100, 0)
        let azelE = MathUtils.neu2azel(neuE)
        #expect(abs(azelE.az - 90.0 * Constants.D2R) < 1e-9)
        #expect(abs(azelE.el) < 1e-9)
        
        // Point directly Up
        let neuU = Vector3(0, 0, 100)
        let azelU = MathUtils.neu2azel(neuU)
        #expect(abs(azelU.el - 90.0 * Constants.D2R) < 1e-9)
    }
}
