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

/// Unit tests for GPS time and date conversions.
struct TimeTests {

    /// Verifies subtraction logic for GPSTime, including week rollovers.
    @Test func testGPSTimeArithmetic() async throws {
        let t1 = GPSTime(week: 2000, sec: 100.0)
        let t2 = GPSTime(week: 2000, sec: 50.0)
        #expect(t1 - t2 == 50.0)
        
        let t3 = GPSTime(week: 2001, sec: 0.0)
        #expect(t3 - t1 == Constants.SECONDS_IN_WEEK - 100.0)
    }
    
    /// Verifies addition of seconds to GPSTime with week overflow handling.
    @Test func testGPSTimeAdding() async throws {
        let t1 = GPSTime(week: 2000, sec: Constants.SECONDS_IN_WEEK - 10.0)
        let t2 = t1.adding(seconds: 20.0)
        #expect(t2.week == 2001)
        #expect(t2.sec == 10.0)
        
        let t3 = GPSTime(week: 2000, sec: 10.0)
        let t4 = t3.adding(seconds: -20.0)
        #expect(t4.week == 1999)
        #expect(t4.sec == Constants.SECONDS_IN_WEEK - 10.0)
    }
    
    /// Verifies conversion between Gregorian dates and GPS time formats.
    @Test func testDateTimeConversion() async throws {
        // GPS Epoch: 1980-01-06 00:00:00
        let dtEpoch = DateTime(y: 1980, m: 1, d: 6, hh: 0, mm: 0, sec: 0)
        let gpsEpoch = dtEpoch.toGPSTime()
        #expect(gpsEpoch.week == 0)
        #expect(gpsEpoch.sec == 0)
        
        let dtBack = DateTime(gpsTime: gpsEpoch)
        #expect(dtBack.y == 1980)
        #expect(dtBack.m == 1)
        #expect(dtBack.d == 6)
        
        // Random date check
        let dt = DateTime(y: 2023, m: 5, d: 15, hh: 12, mm: 30, sec: 45.5)
        let gps = dt.toGPSTime()
        let dtBack2 = DateTime(gpsTime: gps)
        #expect(dtBack2.y == 2023)
        #expect(dtBack2.m == 5)
        #expect(dtBack2.d == 15)
        #expect(dtBack2.hh == 12)
        #expect(dtBack2.mm == 30)
        #expect(abs(dtBack2.sec - 45.5) < 1e-3)
    }
}
