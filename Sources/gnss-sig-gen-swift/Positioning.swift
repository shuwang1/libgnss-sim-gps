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

/// Satellite positioning and clock bias calculations.
struct Positioning {
    
    /// Calculates a satellite's position, velocity, and clock corrections.
    /// - Parameters:
    ///   - eph: The satellite's ephemeris data.
    ///   - g: The target GPS time for calculation.
    /// - Returns: A tuple containing position (ECEF), velocity (ECEF), and clock (bias and drift).
    static func calculateSatPos(eph: Ephemeris, g: GPSTime) -> (pos: Vector3, vel: Vector3, clk: (bias: Double, drift: Double)) {
        var tk = g - eph.toe
        
        let mk = eph.M0 + eph.n * tk
        var ek = mk
        var ekold = ek + 1.0
        var oneMinusEcosE = 1.0
        
        // Solve Kepler's equation for Eccentric Anomaly (Ek)
        while abs(ek - ekold) > 1.0e-14 {
            ekold = ek
            oneMinusEcosE = 1.0 - eph.ecc * cos(ekold)
            ek = ek + (mk - ekold + eph.ecc * sin(ekold)) / oneMinusEcosE
        }
        
        let sek = sin(ek), cek = cos(ek)
        let ekdot = eph.n / oneMinusEcosE
        let relativistic = -4.442807633e-10 * eph.ecc * eph.sqrtA * sek
        
        let pk = atan2(eph.sq1e2 * sek, cek - eph.ecc) + eph.aop
        let pkdot = eph.sq1e2 * ekdot / oneMinusEcosE
        let s2pk = sin(2.0 * pk), c2pk = cos(2.0 * pk)
        
        let uk = pk + eph.cus * s2pk + eph.cuc * c2pk
        let suk = sin(uk), cuk = cos(uk)
        let ukdot = pkdot * (1.0 + 2.0 * (eph.cus * c2pk - eph.cuc * s2pk))
        
        let rk = eph.A * oneMinusEcosE + eph.crc * c2pk + eph.crs * s2pk
        let rkdot = eph.A * eph.ecc * sek * ekdot + 2.0 * pkdot * (eph.crs * c2pk - eph.crc * s2pk)
        
        let ik = eph.inc0 + eph.idot * tk + eph.cic * c2pk + eph.cis * s2pk
        let sik = sin(ik), cik = cos(ik)
        let ikdot = eph.idot + 2.0 * pkdot * (eph.cis * c2pk - eph.cic * s2pk)
        
        let xpk = rk * cuk, ypk = rk * suk
        let xpkdot = rkdot * cuk - ypk * ukdot, ypkdot = rkdot * suk + xpk * ukdot
        
        let ok = eph.OMG0 + tk * eph.omgkdot - Constants.OMEGA_EARTH * eph.toe.sec
        let sok = sin(ok), cok = cos(ok)
        
        let px = xpk * cok - ypk * cik * sok
        let py = xpk * sok + ypk * cik * cok
        let pz = ypk * sik
        let pos = Vector3(px, py, pz)
        
        if px.isNaN || py.isNaN || pz.isNaN {
            Logger.error("NaN Satellite Position detected for PRN with sqrtA: \(eph.sqrtA), ecc: \(eph.ecc), M0: \(eph.M0)")
        }
        
        let tmp = ypkdot * cik - ypk * sik * ikdot
        let vx = -eph.omgkdot * py + xpkdot * cok - tmp * sok
        let vy = eph.omgkdot * px + xpkdot * sok + tmp * cok
        let vz = ypk * cik * ikdot + ypkdot * sik
        let vel = Vector3(vx, vy, vz)
        
        tk = g - eph.toc
        let clkBias = eph.af[0] + tk * (eph.af[1] + tk * eph.af[2]) + relativistic - eph.tgd[0]
        let clkDrift = eph.af[1] + 2.0 * tk * eph.af[2]
        
        return (pos, vel, (clkBias, clkDrift))
    }
}
