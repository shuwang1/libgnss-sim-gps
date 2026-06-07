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

/// Supported GNSS constellations.
enum GNSSSystem {
    case gps, glo, gal, bds
}

/// Supported signal modulation types.
enum GNSSModulation {
    case bpsk, boc11, boc10_5
}

/// Represents the state of a single satellite tracking/simulation link.
struct Link {
    /// Constellation system.
    var sys: GNSSSystem = .gps
    /// Modulation type.
    var mod: GNSSModulation = .bpsk
    /// Satellite PRN number.
    var prn: Int = 0
    /// Packed C/A code bits.
    var ca: [UInt32] = [UInt32](repeating: 0, count: 128)
    /// Code epoch length in chips.
    var codeLength: Int = 1023
    /// Navigation subframe data (24-bit words).
    var sbf: [[UInt]] = [[UInt]](repeating: [UInt](repeating: 0, count: 10), count: 5)
    /// Formatted navigation words (30-bit words with parity).
    var dwrd: [UInt32] = [UInt32](repeating: 0, count: 60)
    /// Index of current word in navigation message.
    var iword: Int = 0
    /// Index of current bit in word.
    var ibit: Int = 0
    /// Index of current code epoch in bit (0-19 for L1CA).
    var icode: Int = 0
    /// Current navigation data bit value (1 or -1).
    var dataBit: Int = 1
    /// Current C/A code chip value (1 or -1).
    var codeCA: Int = 1
    /// Sub-chip code phase.
    var codePhase: Double = 0
    /// Reference GPS time for navigation message.
    var g0: GPSTime = GPSTime(week: 0, sec: 0)
    /// Range parameters at start of step.
    var rho0: Range = Range()
    /// Instantaneous carrier frequency (Hz).
    var fCarr: Double = 0
    /// Instantaneous code frequency (Hz).
    var fCode: Double = 0
    /// Step size for code phase accumulator.
    var codePhaseStep: UInt64 = 0
    /// Fixed-point code phase accumulator.
    var codePhaseFixed: UInt64 = 0
    /// GLONASS frequency channel index.
    var gloFreqK: Int = 0
    /// Azimuth and elevation (radians).
    var azel: (az: Double, el: Double) = (0, 0)
    /// Carrier phase accumulator.
    var carrPhase: UInt32 = 0
    /// Step size for carrier phase accumulator.
    var carrPhaseStep: Int = 0
    
    // Binary scaling constants for navigation data encoding
    static let POW2_M5  = 0.03125
    static let POW2_M19 = 1.907348632812500e-6
    static let POW2_M29 = 1.862645149230957e-9
    static let POW2_M31 = 4.656612873077393e-10
    static let POW2_M33 = 1.164153218269348e-10
    static let POW2_M43 = 1.136868377216160e-13
    static let POW2_M55 = 2.775557561562891e-17
    static let POW2_M50 = 8.881784197001252e-016
    static let POW2_M30 = 9.313225746154785e-010
    static let POW2_M27 = 7.450580596923828e-009
    static let POW2_M24 = 5.960464477539063e-008

    /// Generates the binary navigation message words from the subframe data.
    /// - Parameters:
    ///   - g: Current GPS time.
    ///   - initFlag: If true, performs a cold start of the message generator.
    mutating func generateNavMsg(g: GPSTime, initFlag: Bool) {
        let g0 = GPSTime(week: g.week, sec: floor((g.sec + 0.5) / 30.0) * 30.0)
        self.g0 = g0
        
        let wn = UInt32(g0.week % 1024)
        var tow = UInt32(g0.sec) / 6
        
        var prevwrd: UInt32 = 0
        if initFlag {
            prevwrd = 0
            for iwrd in 0..<10 {
                var sbfmWord = UInt32(self.sbf[4][iwrd])
                if iwrd == 1 { sbfmWord |= ((tow & 0x1FFFF) << 13) }
                sbfmWord |= (prevwrd << 30)
                let nib = (iwrd == 1 || iwrd == 9) ? 1 : 0
                self.dwrd[iwrd] = Checksum.calcChecksumV0(sbfmWord, nib: nib)
                prevwrd = self.dwrd[iwrd]
            }
        } else {
            for iwrd in 0..<10 {
                self.dwrd[iwrd] = self.dwrd[50 + iwrd]
                prevwrd = self.dwrd[iwrd]
            }
        }
        
        for isbf in 0..<5 {
            tow += 1
            for iwrd in 0..<10 {
                var sbfmWord = UInt32(self.sbf[isbf][iwrd])
                if isbf == 0 && iwrd == 2 { sbfmWord |= (wn & 0x3FF) << 20 }
                if iwrd == 1 { sbfmWord |= ((tow & 0x1FFFF) << 13) }
                sbfmWord |= (prevwrd << 30)
                let nib = (iwrd == 1 || iwrd == 9) ? 1 : 0
                self.dwrd[(isbf + 1) * 10 + iwrd] = Checksum.calcChecksumV0(sbfmWord, nib: nib)
                prevwrd = self.dwrd[(isbf + 1) * 10 + iwrd]
            }
        }
    }
    
    /// Converts a satellite ephemeris to the raw 24-bit navigation subframe words.
    /// - Parameters:
    ///   - eph: The input ephemeris.
    ///   - ionoutc: Ionospheric and UTC parameters.
    /// - Returns: A 5x10 array of raw navigation words.
    static func eph2sbf(eph: Ephemeris, ionoutc: IonUTC) -> [[UInt]] {
        var sbf = [[UInt]](repeating: [UInt](repeating: 0, count: 10), count: 5)
        
        let toe = UInt32(eph.toe.sec / 16.0)
        let toc = UInt32(eph.toc.sec / 16.0)
        let iode = UInt32(eph.iode)
        let iodc = UInt32(eph.iodc)
        let deltan = Int32(eph.deltan / POW2_M43 / Constants.PI)
        let cuc = Int32(eph.cuc / POW2_M29)
        let cus = Int32(eph.cus / POW2_M29)
        let cic = Int32(eph.cic / POW2_M29)
        let cis = Int32(eph.cis / POW2_M29)
        let crc = Int32(eph.crc / POW2_M5)
        let crs = Int32(eph.crs / POW2_M5)
        let ecc = UInt32(eph.ecc / POW2_M33)
        let sqrtA = UInt32(eph.sqrtA / POW2_M19)
        let M0 = Int32(eph.M0 / POW2_M31 / Constants.PI)
        let omg0 = Int32(eph.OMG0 / POW2_M31 / Constants.PI)
        let inc0 = Int32(eph.inc0 / POW2_M31 / Constants.PI)
        let aop = Int32(eph.aop / POW2_M31 / Constants.PI)
        let omgdot = Int32(eph.OMGd / POW2_M43 / Constants.PI)
        let idot = Int32(eph.idot / POW2_M43 / Constants.PI)
        let af0 = Int32(eph.af[0] / POW2_M31)
        let af1 = Int32(eph.af[1] / POW2_M43)
        let af2 = Int32(eph.af[2] / POW2_M55)
        let tgd = Int32(eph.tgd[0] / POW2_M31)
        let svhlth = UInt32(eph.svhlth)
        let codeL2 = UInt32(eph.codeL2)
        
        let alpha0 = Int32(round(ionoutc.alpha0 / POW2_M30))
        let alpha1 = Int32(round(ionoutc.alpha1 / POW2_M27))
        let alpha2 = Int32(round(ionoutc.alpha2 / POW2_M24))
        let alpha3 = Int32(round(ionoutc.alpha3 / POW2_M24))
        let beta0 = Int32(round(ionoutc.beta0 / 2048.0))
        let beta1 = Int32(round(ionoutc.beta1 / 16384.0))
        let beta2 = Int32(round(ionoutc.beta2 / 65536.0))
        let beta3 = Int32(round(ionoutc.beta3 / 65536.0))
        let A0 = Int32(round(ionoutc.A0 / POW2_M30))
        let A1 = Int32(round(ionoutc.A1 / POW2_M50))
        let dtls = Int32(ionoutc.dtls)
        let tot = UInt32(ionoutc.tot / 4096)
        let wnt = UInt32(ionoutc.wnt % 256)
        
        // Subframe 1
        sbf[0][0] = 0x8B0000 << 6
        sbf[0][1] = 0x1 << 8
        sbf[0][2] = UInt((codeL2 & 0x3) << 18 | (svhlth & 0x3F) << 8 | ((iodc >> 8) & 0x3) << 6)
        sbf[0][6] = UInt((tgd & 0xFF) << 6)
        sbf[0][7] = UInt((iodc & 0xFF) << 22 | (toc & 0xFFFF) << 6)
        sbf[0][8] = UInt((af2 & 0xFF) << 22 | (af1 & 0xFFFF) << 6)
        sbf[0][9] = UInt((af0 & 0x3FFFFF) << 8)
        
        // Subframe 2
        sbf[1][0] = 0x8B0000 << 6
        sbf[1][1] = 0x2 << 8
        sbf[1][2] = UInt((iode & 0xFF) << 22 | UInt32(crs & 0xFFFF) << 6)
        sbf[1][3] = UInt(UInt32(deltan & 0xFFFF) << 14 | UInt32((M0 >> 24) & 0xFF) << 6)
        sbf[1][4] = UInt(UInt32(M0 & 0xFFFFFF) << 6)
        sbf[1][5] = UInt(UInt32(cuc & 0xFFFF) << 14 | (ecc >> 24) << 6)
        sbf[1][6] = UInt((ecc & 0xFFFFFF) << 6)
        sbf[1][7] = UInt(UInt32(cus & 0xFFFF) << 14 | (sqrtA >> 24) << 6)
        sbf[1][8] = UInt((sqrtA & 0xFFFFFF) << 6)
        sbf[1][9] = UInt((toe & 0xFFFF) << 14)
        
        // Subframe 3
        sbf[2][0] = 0x8B0000 << 6
        sbf[2][1] = 0x3 << 8
        sbf[2][2] = UInt(UInt32(cic & 0xFFFF) << 14 | UInt32((omg0 >> 24) & 0xFF) << 6)
        sbf[2][3] = UInt(UInt32(omg0 & 0xFFFFFF) << 6)
        sbf[2][4] = UInt(UInt32(cis & 0xFFFF) << 14 | UInt32((inc0 >> 24) & 0xFF) << 6)
        sbf[2][5] = UInt(UInt32(inc0 & 0xFFFFFF) << 6)
        sbf[2][6] = UInt(UInt32(crc & 0xFFFF) << 14 | UInt32((aop >> 24) & 0xFF) << 6)
        sbf[2][7] = UInt(UInt32(aop & 0xFFFFFF) << 6)
        sbf[2][8] = UInt(UInt32(omgdot & 0xFFFFFF) << 6)
        sbf[2][9] = UInt((iode & 0xFF) << 22 | UInt32(idot & 0x3FFF) << 8)
        
        if ionoutc.vflg {
            sbf[3][0] = 0x8B0000 << 6
            sbf[3][1] = 0x4 << 8
            sbf[3][2] = UInt(1 << 28 | 56 << 22 | UInt32(alpha0 & 0xFF) << 14 | UInt32(alpha1 & 0xFF) << 6)
            sbf[3][3] = UInt(UInt32(alpha2 & 0xFF) << 22 | UInt32(alpha3 & 0xFF) << 14 | UInt32(beta0 & 0xFF) << 6)
            sbf[3][4] = UInt(UInt32(beta1 & 0xFF) << 22 | UInt32(beta2 & 0xFF) << 14 | UInt32(beta3 & 0xFF) << 6)
            sbf[3][5] = UInt(UInt32(A1 & 0xFFFFFF) << 6)
            sbf[3][6] = UInt(UInt32((A0 >> 8) & 0xFFFFFF) << 6)
            sbf[3][7] = UInt(UInt32(A0 & 0xFF) << 22 | (tot & 0xFF) << 14 | (wnt & 0xFF) << 6)
            sbf[3][8] = UInt(UInt32(dtls & 0xFF) << 22 | (1929 % 256) << 14 | 7 << 6)
            sbf[3][9] = UInt(18 << 22)
        } else {
            sbf[3][0] = 0x8B0000 << 6
            sbf[3][1] = 0x4 << 8
            sbf[3][2] = UInt(1 << 28 | 63 << 22)
        }
        
        sbf[4][0] = 0x8B0000 << 6
        sbf[4][1] = 0x5 << 8
        sbf[4][2] = UInt(1 << 28 | 51 << 22)
        
        return sbf
    }
}
