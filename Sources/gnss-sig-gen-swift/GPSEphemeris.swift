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

/// Ionospheric and UTC parameters parsed from RINEX navigation messages.
struct IonUTC {
    /// Flag indicating if valid parameters are available.
    var vflg: Bool = false
    /// Flag to enable/disable ionospheric correction in simulation.
    var enable: Bool = true
    /// Ionospheric alpha parameters.
    var alpha0: Double = 0, alpha1: Double = 0, alpha2: Double = 0, alpha3: Double = 0
    /// Ionospheric beta parameters.
    var beta0: Double = 0, beta1: Double = 0, beta2: Double = 0, beta3: Double = 0
    /// UTC delta-time parameters.
    var A0: Double = 0, A1: Double = 0
    /// UTC reference time (seconds), reference week, and leap seconds.
    var tot: Int = 0, wnt: Int = 0, dtls: Int = 0
}

/// Satellite ephemeris data used for orbital calculations.
struct Ephemeris {
    /// Flag indicating if the ephemeris is valid.
    var vflg: Bool = false
    /// Creation time of the navigation message.
    var t: DateTime = DateTime(y: 0, m: 0, d: 0, hh: 0, mm: 0, sec: 0)
    /// Time of Clock (TOC).
    var toc: GPSTime = GPSTime(week: 0, sec: 0)
    /// Time of Ephemeris (TOE).
    var toe: GPSTime = GPSTime(week: 0, sec: 0)
    /// Issue of Data, Clock.
    var iodc: Int = 0
    /// Issue of Data, Ephemeris.
    var iode: Int = 0
    /// Mean motion difference from computed value.
    var deltan: Double = 0
    /// Amplitude of cosine/sine harmonic correction to argument of latitude.
    var cuc: Double = 0, cus: Double = 0
    /// Amplitude of cosine/sine harmonic correction to inclination.
    var cic: Double = 0, cis: Double = 0
    /// Amplitude of cosine/sine harmonic correction to orbit radius.
    var crc: Double = 0, crs: Double = 0
    /// Eccentricity.
    var ecc: Double = 0
    /// Square root of semi-major axis.
    var sqrtA: Double = 0
    /// Mean anomaly at reference time.
    var M0: Double = 0
    /// Longitude of ascending node at weekly epoch.
    var OMG0: Double = 0
    /// Inclination angle at reference time.
    var inc0: Double = 0
    /// Argument of perigee.
    var aop: Double = 0
    /// Rate of right ascension.
    var OMGd: Double = 0
    /// Rate of inclination angle.
    var idot: Double = 0
    /// Satellite clock correction parameters (af0, af1, af2).
    var af: [Double] = [0, 0, 0]
    /// Total Group Delay.
    var tgd: [Double] = [0, 0, 0, 0]
    /// Satellite health status.
    var svhlth: Int = 0
    /// L2 P data flag.
    var codeL2: Int = 0
    
    // Derived values
    /// Corrected mean motion.
    var n: Double = 0
    /// sqrt(1 - ecc^2).
    var sq1e2: Double = 0
    /// Semi-major axis.
    var A: Double = 0
    /// Corrected rate of right ascension (omgdot - OMEGA_EARTH).
    var omgkdot: Double = 0
    
    /// Updates derived parameters from the raw orbital elements.
    mutating func updateDerived() {
        self.A = self.sqrtA * self.sqrtA
        self.n = sqrt(Constants.GM_EARTH / (self.A * self.A * self.A)) + self.deltan
        self.sq1e2 = sqrt(1.0 - self.ecc * self.ecc)
        self.omgkdot = self.OMGd - Constants.OMEGA_EARTH
    }
}

/// Parser for RINEX (Receiver Independent Exchange Format) navigation files.
class GPSEphemeris {
    /// Loads GPS ephemeris data from a RINEX navigation file.
    /// - Parameter fname: Path to the RINEX file.
    /// - Returns: A tuple containing the parsed epochs and Ionospheric/UTC parameters, or `nil` on error.
    static func loadGPSEphemeris(fname: String) -> (epochs: [[Ephemeris]], ionUTC: IonUTC)? {
        guard let content = try? String(contentsOfFile: fname, encoding: .utf8) else {
            return nil
        }
        
        let lines = content.components(separatedBy: .newlines)
        guard let firstLine = lines.first else { return nil }
        
        var version = 2.0
        if firstLine.count >= 60 && firstLine.contains("RINEX VERSION / TYPE") {
            let verStr = firstLine.prefix(9).trimmingCharacters(in: .whitespaces)
            version = Double(verStr) ?? 2.0
        }
        
        if version >= 3.0 {
            Logger.info("Detected RINEX \(version), using 3.x parser")
            return parseRINEX3(lines: lines)
        } else {
            Logger.info("Detected RINEX \(version), using 2.x parser")
            return parseRINEX2(lines: lines)
        }
    }
    
    /// Internal parser for RINEX version 2.x files.
    private static func parseRINEX2(lines: [String]) -> (epochs: [[Ephemeris]], ionUTC: IonUTC)? {
        var ionUTC = IonUTC()
        var epochs = [[Ephemeris]](repeating: [Ephemeris](repeating: Ephemeris(), count: Constants.MAX_SAT), count: Constants.EPHEM_ARRAY_SIZE)
        
        var lineIdx = 0
        var flags = 0
        
        while lineIdx < lines.count {
            let line = lines[lineIdx]
            lineIdx += 1
            if line.count >= 60 && line.contains("END OF HEADER") {
                break
            }
            
            if line.count >= 60 {
                let label = line.suffix(from: line.index(line.startIndex, offsetBy: 60))
                if label.contains("ION ALPHA") {
                    let parts = parseFixed(line, widths: [2, 12, 12, 12, 12])
                    if parts.count >= 5 {
                        ionUTC.alpha0 = Double(parts[1].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.alpha1 = Double(parts[2].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.alpha2 = Double(parts[3].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.alpha3 = Double(parts[4].replacingOccurrences(of: "D", with: "E")) ?? 0
                    }
                    flags |= 0x1
                } else if label.contains("ION BETA") {
                    let parts = parseFixed(line, widths: [2, 12, 12, 12, 12])
                    if parts.count >= 5 {
                        ionUTC.beta0 = Double(parts[1].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.beta1 = Double(parts[2].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.beta2 = Double(parts[3].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.beta3 = Double(parts[4].replacingOccurrences(of: "D", with: "E")) ?? 0
                    }
                    flags |= 0x2
                } else if label.contains("DELTA-UTC") {
                    let parts = parseFixed(line, widths: [3, 19, 19, 9, 9])
                    if parts.count >= 5 {
                        ionUTC.A0 = Double(parts[1].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.A1 = Double(parts[2].replacingOccurrences(of: "D", with: "E")) ?? 0
                        ionUTC.tot = Int(parts[3].trimmingCharacters(in: .whitespaces)) ?? 0
                        ionUTC.wnt = Int(parts[4].trimmingCharacters(in: .whitespaces)) ?? 0
                    }
                    if ionUTC.tot % 4096 == 0 { flags |= 0x4 }
                } else if label.contains("LEAP SECONDS") {
                    let parts = parseFixed(line, widths: [6])
                    ionUTC.dtls = Int(parts[0].trimmingCharacters(in: .whitespaces)) ?? 0
                    flags |= 0x8
                }
            }
        }
        ionUTC.vflg = (flags == 0xF)
        
        var g0: GPSTime?
        var ieph = 0
        
        while lineIdx < lines.count {
            let line = lines[lineIdx]
            lineIdx += 1
            if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            if line.count < 22 { continue }
            
            let parts0 = parseFixed(line, widths: [2, 3, 3, 3, 3, 3, 5, 19, 19, 19])
            if parts0.count < 10 { continue }
            
            let sv = (Int(parts0[0].trimmingCharacters(in: .whitespaces)) ?? 0) - 1
            if sv < 0 || sv >= Constants.MAX_SAT {
                Logger.warn("Invalid satellite number \(sv + 1) at line \(lineIdx)")
                continue
            }
            
            var yy = Int(parts0[1].trimmingCharacters(in: .whitespaces)) ?? 0
            let m = Int(parts0[2].trimmingCharacters(in: .whitespaces)) ?? 0
            let d = Int(parts0[3].trimmingCharacters(in: .whitespaces)) ?? 0
            let hh = Int(parts0[4].trimmingCharacters(in: .whitespaces)) ?? 0
            let mm = Int(parts0[5].trimmingCharacters(in: .whitespaces)) ?? 0
            let sec = Double(parts0[6].trimmingCharacters(in: .whitespaces)) ?? 0
            
            yy = (yy >= 80) ? 1900 + yy : 2000 + yy
            let t = DateTime(y: yy, m: m, d: d, hh: hh, mm: mm, sec: sec)
            let g = t.toGPSTime()
            
            if g0 == nil { g0 = g }
            if let g0Val = g0, g - g0Val > Constants.SECONDS_IN_HOUR {
                g0 = g
                ieph += 1
                if ieph >= Constants.EPHEM_ARRAY_SIZE { break }
            }
            
            var eph = Ephemeris()
            eph.t = t
            eph.toc = g
            eph.af[0] = Double(parts0[7].replacingOccurrences(of: "D", with: "E")) ?? 0
            eph.af[1] = Double(parts0[8].replacingOccurrences(of: "D", with: "E")) ?? 0
            eph.af[2] = Double(parts0[9].replacingOccurrences(of: "D", with: "E")) ?? 0
            
            // Read 6 more orbit lines
            for i in 1...6 {
                if lineIdx >= lines.count { break }
                let oline = lines[lineIdx]
                lineIdx += 1
                let oparts = parseFixed(oline, widths: [3, 19, 19, 19, 19])
                for j in 0..<4 {
                    if j + 1 >= oparts.count { break }
                    let rawVal = oparts[j+1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "D", with: "E")
                    let val = Double(rawVal) ?? 0
                    if i == 1 {
                        if j == 0 { eph.iode = Int(val) }
                        else if j == 1 { eph.crs = val }
                        else if j == 2 { eph.deltan = val }
                        else if j == 3 { eph.M0 = val }
                    } else if i == 2 {
                        if j == 0 { eph.cuc = val }
                        else if j == 1 { eph.ecc = val }
                        else if j == 2 { eph.cus = val }
                        else if j == 3 { eph.sqrtA = val }
                    } else if i == 3 {
                        if j == 0 { eph.toe.sec = val }
                        else if j == 1 { eph.cic = val }
                        else if j == 2 { eph.OMG0 = val }
                        else if j == 3 { eph.cis = val }
                    } else if i == 4 {
                        if j == 0 { eph.inc0 = val }
                        else if j == 1 { eph.crc = val }
                        else if j == 2 { eph.aop = val }
                        else if j == 3 { eph.OMGd = val }
                    } else if i == 5 {
                        if j == 0 { eph.idot = val }
                        else if j == 1 { eph.codeL2 = Int(val) }
                        else if j == 2 { eph.toe.week = Int(val) }
                    } else if i == 6 {
                        if j == 1 { 
                            eph.svhlth = Int(val)
                            if eph.svhlth > 0 && eph.svhlth < 32 { eph.svhlth += 32 }
                        } else if j == 2 { eph.tgd[0] = val }
                        else if j == 3 { eph.iodc = Int(val) }
                    }
                }
            }
            // Skip 7th line if present (often it is)
            if lineIdx < lines.count {
                lineIdx += 1
            }
            
            eph.vflg = true
            eph.updateDerived()
            epochs[ieph][sv] = eph
        }
        
        return (epochs, ionUTC)
    }
    
    /// Internal parser for RINEX version 3.x files.
    private static func parseRINEX3(lines: [String]) -> (epochs: [[Ephemeris]], ionUTC: IonUTC)? {
        var ionUTC = IonUTC()
        var epochs = [[Ephemeris]](repeating: [Ephemeris](repeating: Ephemeris(), count: Constants.MAX_SAT), count: Constants.EPHEM_ARRAY_SIZE)
        
        var lineIdx = 0
        var flags = 0
        
        while lineIdx < lines.count {
            let line = lines[lineIdx]
            lineIdx += 1
            if line.count >= 60 && line.contains("END OF HEADER") {
                break
            }
            
            if line.count >= 60 {
                let label = line.suffix(from: line.index(line.startIndex, offsetBy: 60))
                if label.contains("IONOSPHERIC CORR") {
                    if line.hasPrefix("GPSA") {
                        let parts = parseFixed(line, widths: [5, 12, 12, 12, 12])
                        if parts.count >= 5 {
                            ionUTC.alpha0 = Double(parts[1].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.alpha1 = Double(parts[2].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.alpha2 = Double(parts[3].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.alpha3 = Double(parts[4].replacingOccurrences(of: "D", with: "E")) ?? 0
                        }
                        flags |= 0x1
                    } else if line.hasPrefix("GPSB") {
                        let parts = parseFixed(line, widths: [5, 12, 12, 12, 12])
                        if parts.count >= 5 {
                            ionUTC.beta0 = Double(parts[1].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.beta1 = Double(parts[2].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.beta2 = Double(parts[3].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.beta3 = Double(parts[4].replacingOccurrences(of: "D", with: "E")) ?? 0
                        }
                        flags |= 0x2
                    }
                } else if label.contains("TIME SYSTEM CORR") {
                    if line.hasPrefix("GPUT") {
                        let parts = parseFixed(line, widths: [5, 17, 16, 7, 5])
                        if parts.count >= 5 {
                            ionUTC.A0 = Double(parts[1].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.A1 = Double(parts[2].replacingOccurrences(of: "D", with: "E")) ?? 0
                            ionUTC.tot = Int(parts[3].trimmingCharacters(in: .whitespaces)) ?? 0
                            ionUTC.wnt = Int(parts[4].trimmingCharacters(in: .whitespaces)) ?? 0
                        }
                        if ionUTC.tot % 4096 == 0 { flags |= 0x4 }
                    }
                } else if label.contains("LEAP SECONDS") {
                    let parts = parseFixed(line, widths: [6])
                    ionUTC.dtls = Int(parts[0].trimmingCharacters(in: .whitespaces)) ?? 0
                    flags |= 0x8
                }
            }
        }
        ionUTC.vflg = (flags == 0xF)
        
        var g0: GPSTime?
        var ieph = 0
        
        while lineIdx < lines.count {
            let line = lines[lineIdx]
            lineIdx += 1
            if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            if !line.hasPrefix("G") {
                // Skip non-GPS constellations
                for _ in 1...7 { if lineIdx < lines.count { lineIdx += 1 } }
                continue
            }
            
            let parts0 = parseFixed(line, widths: [3, 5, 3, 3, 3, 3, 3, 19, 19, 19])
            if parts0.count < 10 { continue }
            
            let svStr = parts0[0].suffix(2).trimmingCharacters(in: .whitespaces)
            let sv = (Int(svStr) ?? 0) - 1
            if sv < 0 || sv >= Constants.MAX_SAT {
                for _ in 1...7 { if lineIdx < lines.count { lineIdx += 1 } }
                continue
            }
            
            let yy = Int(parts0[1].trimmingCharacters(in: .whitespaces)) ?? 0
            let m = Int(parts0[2].trimmingCharacters(in: .whitespaces)) ?? 0
            let d = Int(parts0[3].trimmingCharacters(in: .whitespaces)) ?? 0
            let hh = Int(parts0[4].trimmingCharacters(in: .whitespaces)) ?? 0
            let mm = Int(parts0[5].trimmingCharacters(in: .whitespaces)) ?? 0
            let sec = Double(parts0[6].trimmingCharacters(in: .whitespaces)) ?? 0
            
            let t = DateTime(y: yy, m: m, d: d, hh: hh, mm: mm, sec: sec)
            let g = t.toGPSTime()
            
            if g0 == nil { g0 = g }
            if let g0Val = g0, g - g0Val > Constants.SECONDS_IN_HOUR {
                g0 = g
                ieph += 1
                if ieph >= Constants.EPHEM_ARRAY_SIZE { break }
            }
            
            var eph = Ephemeris()
            eph.t = t
            eph.toc = g
            eph.af[0] = Double(parts0[7].replacingOccurrences(of: "D", with: "E")) ?? 0
            eph.af[1] = Double(parts0[8].replacingOccurrences(of: "D", with: "E")) ?? 0
            eph.af[2] = Double(parts0[9].replacingOccurrences(of: "D", with: "E")) ?? 0
            
            for i in 1...7 {
                if lineIdx >= lines.count { break }
                let oline = lines[lineIdx]
                lineIdx += 1
                let oparts = parseFixed(oline, widths: [4, 19, 19, 19, 19])
                for j in 0..<4 {
                    if j + 1 >= oparts.count { break }
                    let rawVal = oparts[j+1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "D", with: "E")
                    let val = Double(rawVal) ?? 0
                    if i == 1 {
                        if j == 0 { eph.iode = Int(val) }
                        else if j == 1 { eph.crs = val }
                        else if j == 2 { eph.deltan = val }
                        else if j == 3 { eph.M0 = val }
                    } else if i == 2 {
                        if j == 0 { eph.cuc = val }
                        else if j == 1 { eph.ecc = val }
                        else if j == 2 { eph.cus = val }
                        else if j == 3 { eph.sqrtA = val }
                    } else if i == 3 {
                        if j == 0 { eph.toe.sec = val }
                        else if j == 1 { eph.cic = val }
                        else if j == 2 { eph.OMG0 = val }
                        else if j == 3 { eph.cis = val }
                    } else if i == 4 {
                        if j == 0 { eph.inc0 = val }
                        else if j == 1 { eph.crc = val }
                        else if j == 2 { eph.aop = val }
                        else if j == 3 { eph.OMGd = val }
                    } else if i == 5 {
                        if j == 0 { eph.idot = val }
                        else if j == 1 { eph.codeL2 = Int(val) }
                        else if j == 2 { eph.toe.week = Int(val) }
                    } else if i == 6 {
                        if j == 1 { 
                            eph.svhlth = Int(val)
                            if eph.svhlth > 0 && eph.svhlth < 32 { eph.svhlth += 32 }
                        } else if j == 2 { eph.tgd[0] = val }
                        else if j == 3 { eph.iodc = Int(val) }
                    }
                }
            }
            
            eph.vflg = true
            eph.updateDerived()
            epochs[ieph][sv] = eph
        }
        
        return (epochs, ionUTC)
    }
    
    /// Parses a fixed-width line into components.
    private static func parseFixed(_ line: String, widths: [Int]) -> [String] {
        var results = [String]()
        var current = line.startIndex
        for w in widths {
            if current >= line.endIndex { break }
            let next = line.index(current, offsetBy: w, limitedBy: line.endIndex) ?? line.endIndex
            results.append(String(line[current..<next]))
            current = next
        }
        return results
    }
}
