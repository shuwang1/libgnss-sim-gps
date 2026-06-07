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

/// A collection of mathematical and physical constants used in GNSS simulations.
enum Constants {
    /// Mathematical constant Pi.
    static let PI = 3.1415926535898
    /// Conversion factor from Radians to Degrees.
    static let R2D = 57.2957795131
    /// Conversion factor from Degrees to Radians.
    static let D2R = PI / 180.0
    
    /// Speed of light in vacuum (m/s).
    static let SPEED_OF_LIGHT = 2.99792458e8
    /// Wavelength of the GPS L1 signal (meters).
    static let LAMBDA_L1 = 0.190293672798365
    
    /// Fundamental frequency of GPS L1 carrier (Hz).
    static let FREQ_GPS_L1 = 1575.42e6
    /// Fundamental frequency of GLONASS L1 carrier (Hz).
    static let FREQ_GLO_L1 = 1602.0e6
    /// Frequency step for GLONASS L1 channel offsets (Hz).
    static let FREQ_GLO_L1_STEP = 0.5625e6
    /// Fundamental frequency of Galileo E1 carrier (Hz).
    static let FREQ_GAL_E1 = 1575.42e6
    /// Fundamental frequency of BeiDou B1I carrier (Hz).
    static let FREQ_BDS_B1I = 1561.098e6
    /// Fundamental frequency of BeiDou B1C carrier (Hz).
    static let FREQ_BDS_B1C = 1575.42e6
    /// Standard GPS C/A code chipping rate (chips/s).
    static let CODE_FREQ = 1.023e6
    /// Ratio of carrier frequency to code frequency.
    static let CARR_TO_CODE = 1.0 / 1540.0
    
    /// Earth's gravitational parameter (m^3/s^2).
    static let GM_EARTH = 3.986005e14
    /// WGS84 semi-major axis of the Earth (meters).
    static let WGS84_RADIUS = 6378137.0
    /// WGS84 first eccentricity of the Earth.
    static let WGS84_ECCENTRICITY = 0.0818191908426
    
    /// Maximum number of GPS satellites in the constellation.
    static let MAX_SAT = 32
    /// Maximum number of hardware channels simulated.
    static let MAX_CHAN = 16
    
    /// Default simulation time step (seconds).
    static let TIME_STEP = 0.1
    /// Earth's rotation rate (rad/s).
    static let OMEGA_EARTH = 7.2921151467e-5
    /// Size of the ephemeris history array.
    static let EPHEM_ARRAY_SIZE = 15
    
    /// Number of seconds in a GPS week.
    static let SECONDS_IN_WEEK = 604800.0
    /// Number of seconds in half a GPS week.
    static let SECONDS_IN_HALF_WEEK = 302400.0
    /// Number of seconds in a day.
    static let SECONDS_IN_DAY = 86400.0
    /// Number of seconds in an hour.
    static let SECONDS_IN_HOUR = 3600.0
    /// Number of seconds in a minute.
    static let SECONDS_IN_MINUTE = 60.0
}
