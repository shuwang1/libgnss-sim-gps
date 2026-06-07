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

/// Represents a point in GPS time.
struct GPSTime: Equatable {
    /// GPS Week number.
    var week: Int
    /// Seconds within the GPS week.
    var sec: Double
    
    /// Subtracts two `GPSTime` instances to get the duration in seconds.
    /// - Parameters:
    ///   - lhs: The later time.
    ///   - rhs: The earlier time.
    /// - Returns: Difference in seconds.
    static func -(lhs: GPSTime, rhs: GPSTime) -> Double {
        var dt = lhs.sec - rhs.sec
        dt += Double(lhs.week - rhs.week) * Constants.SECONDS_IN_WEEK
        return dt
    }
    
    /// Returns a new `GPSTime` incremented by the given duration.
    /// - Parameter seconds: Duration to add.
    /// - Returns: A new `GPSTime` instance.
    func adding(seconds: Double) -> GPSTime {
        var newWeek = self.week
        var newSec = self.sec + seconds
        newSec = floor(newSec * 1000.0 + 0.5) / 1000.0
        
        while newSec >= Constants.SECONDS_IN_WEEK {
            newSec -= Constants.SECONDS_IN_WEEK
            newWeek += 1
        }
        while newSec < 0.0 {
            newSec += Constants.SECONDS_IN_WEEK
            newWeek -= 1
        }
        return GPSTime(week: newWeek, sec: newSec)
    }
}

/// Represents a Gregorian calendar date and time, with conversion to GPS time.
struct DateTime {
    /// Year.
    var y: Int
    /// Month (1-12).
    var m: Int
    /// Day (1-31).
    var d: Int
    /// Hour (0-23).
    var hh: Int
    /// Minute (0-59).
    var mm: Int
    /// Seconds (0-59.999).
    var sec: Double
    
    /// Converts the date and time to `GPSTime`.
    /// - Returns: A `GPSTime` instance representing this date.
    func toGPSTime() -> GPSTime {
        let doy = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        let ye = self.y - 1980
        var lpdays = ye / 4 + 1
        if (ye % 4) == 0 && self.m <= 2 {
            lpdays -= 1
        }
        
        let de = ye * 365 + doy[self.m - 1] + self.d + lpdays - 6
        
        let week = de / 7
        let sec = Double(de % 7) * Constants.SECONDS_IN_DAY + Double(self.hh) * Constants.SECONDS_IN_HOUR + Double(self.mm) * Constants.SECONDS_IN_MINUTE + self.sec
        return GPSTime(week: week, sec: sec)
    }
    
    /// Initializes a new `DateTime` with explicit components.
    init(y: Int, m: Int, d: Int, hh: Int, mm: Int, sec: Double) {
        self.y = y
        self.m = m
        self.d = d
        self.hh = hh
        self.mm = mm
        self.sec = sec
    }
    
    /// Initializes a new `DateTime` from a `GPSTime`.
    /// - Parameter gpsTime: The source GPS time.
    init(gpsTime: GPSTime) {
        // Implementation uses Fliegel and Van Flandern algorithm
        let c_val = Double(7 * gpsTime.week) + floor(gpsTime.sec / 86400.0) + 2444245.0 + 1537.0
        let d_val = floor((c_val - 122.1) / 365.25)
        let e_val = floor(365.0 * d_val + d_val / 4.0)
        let f_val = floor((c_val - e_val) / 30.6001)
        
        self.d = Int(c_val - e_val - floor(30.6001 * f_val))
        self.m = Int(f_val - 1.0 - 12.0 * floor(f_val / 14.0))
        self.y = Int(d_val - 4715.0 - floor((7.0 + Double(self.m)) / 10.0))
        
        self.hh = Int(floor(gpsTime.sec / 3600.0)) % 24
        self.mm = Int(floor(gpsTime.sec / 60.0)) % 60
        self.sec = gpsTime.sec - 60.0 * floor(gpsTime.sec / 60.0)
    }
}
