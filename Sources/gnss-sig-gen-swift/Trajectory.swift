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

/// Utilities for reading user motion/trajectory files.
struct Trajectory {
    
    /// Reads ECEF user motion from a CSV file (t, x, y, z).
    /// - Parameter filename: Path to the CSV file.
    /// - Returns: An array of ECEF position vectors, or `nil` if the file could not be read.
    static func readUserMotion(filename: String) -> [Vector3]? {
        guard let content = try? String(contentsOfFile: filename, encoding: .utf8) else {
            Logger.error("Failed to open user motion file: \(filename)")
            return nil
        }
        
        var results = [Vector3]()
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 4 {
                if let x = Double(parts[1]), let y = Double(parts[2]), let z = Double(parts[3]) {
                    results.append(Vector3(x, y, z))
                }
            }
        }
        return results
    }
    
    /// Reads LLH user motion from a CSV file (t, lat, lon, h) and converts to ECEF.
    /// - Parameter filename: Path to the CSV file.
    /// - Returns: An array of ECEF position vectors, or `nil` if the file could not be read.
    static func readUserMotionLLH(filename: String) -> [Vector3]? {
        guard let content = try? String(contentsOfFile: filename, encoding: .utf8) else {
            Logger.error("Failed to open user motion file: \(filename)")
            return nil
        }
        
        var results = [Vector3]()
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 4 {
                if let lat = Double(parts[1]), let lon = Double(parts[2]), let h = Double(parts[3]) {
                    let llh = Vector3(lat * Constants.D2R, lon * Constants.D2R, h)
                    results.append(MathUtils.llh2xyz(llh))
                }
            }
        }
        return results
    }
    
    /// Reads user motion from an NMEA GGA stream/file and converts to ECEF.
    /// - Parameter filename: Path to the NMEA file.
    /// - Returns: An array of ECEF position vectors, or `nil` if the file could not be read.
    static func readNmeaGGA(filename: String) -> [Vector3]? {
        guard let content = try? String(contentsOfFile: filename, encoding: .utf8) else {
            Logger.error("Failed to open NMEA GGA file: \(filename)")
            return nil
        }
        
        var results = [Vector3]()
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count > 0 && parts[0].suffix(3) == "GGA" {
                if parts.count >= 10 {
                    let latStr = parts[2]
                    let lonStr = parts[4]
                    if latStr.count >= 2 && lonStr.count >= 3 {
                        var lat = (Double(latStr.prefix(2)) ?? 0) + (Double(latStr.dropFirst(2)) ?? 0) / 60.0
                        if parts[3] == "S" { lat *= -1.0 }
                        var lon = (Double(lonStr.prefix(3)) ?? 0) + (Double(lonStr.dropFirst(3)) ?? 0) / 60.0
                        if parts[5] == "W" { lon *= -1.0 }
                        
                        var alt = Double(parts[9]) ?? 0.0
                        if parts.count >= 12, let geoid = Double(parts[11]) {
                            alt += geoid
                        }
                        
                        let llh = Vector3(lat * Constants.D2R, lon * Constants.D2R, alt)
                        results.append(MathUtils.llh2xyz(llh))
                    }
                }
            }
        }
        return results
    }
}
