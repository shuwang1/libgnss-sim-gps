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

/// Mathematical utility functions for GNSS coordinate transformations.
struct MathUtils {
    
    /// Converts ECEF (Earth-Centered, Earth-Fixed) coordinates to LLH (Latitude, Longitude, Height).
    /// - Parameter xyz: ECEF coordinates [x, y, z] in meters.
    /// - Returns: LLH coordinates [lat (rad), lon (rad), h (m)].
    static func xyz2llh(_ xyz: Vector3) -> Vector3 {
        let a = Constants.WGS84_RADIUS
        let e = Constants.WGS84_ECCENTRICITY
        let eps = 1.0e-3
        let e2 = e * e
        
        let rho2 = xyz.x * xyz.x + xyz.y * xyz.y
        if rho2 + xyz.z * xyz.z < eps * eps {
            return Vector3(0.0, 0.0, -a)
        }
        
        var dz = e2 * xyz.z
        var iter = 0
        while iter < 100 {
            let zdz = xyz.z + dz
            let nh = sqrt(rho2 + zdz * zdz)
            let slat = zdz / nh
            let n = a / sqrt(1.0 - e2 * slat * slat)
            let dzNew = n * e2 * slat
            if abs(dz - dzNew) < eps { break }
            dz = dzNew
            iter += 1
        }
        
        let zdz = xyz.z + dz
        let nh = sqrt(rho2 + zdz * zdz)
        let lat = atan2(zdz, sqrt(rho2))
        let lon = atan2(xyz.y, xyz.x)
        let h = nh - (a / sqrt(1.0 - e2 * (zdz / nh) * (zdz / nh)))
        
        return Vector3(lat, lon, h)
    }
    
    /// Converts LLH (Latitude, Longitude, Height) coordinates to ECEF (Earth-Centered, Earth-Fixed).
    /// - Parameter llh: LLH coordinates [lat (rad), lon (rad), h (m)].
    /// - Returns: ECEF coordinates [x, y, z] in meters.
    static func llh2xyz(_ llh: Vector3) -> Vector3 {
        let a = Constants.WGS84_RADIUS
        let e = Constants.WGS84_ECCENTRICITY
        let e2 = e * e
        let clat = cos(llh[0]), slat = sin(llh[0])
        let clon = cos(llh[1]), slon = sin(llh[1])
        let d = e * slat
        let n = a / sqrt(1.0 - d * d)
        let nph = n + llh[2]
        
        let x = nph * clat * clon
        let y = nph * clat * slon
        let z = ((1.0 - e2) * n + llh[2]) * slat
        return Vector3(x, y, z)
    }
    
    /// Computes the local-tangent-plane transformation matrix (ECEF to NEU).
    /// - Parameter llh: Reference LLH position.
    /// - Returns: A 3x3 transformation matrix as a 2D array.
    static func ltcmat(_ llh: Vector3) -> [[Double]] {
        let slat = sin(llh[0]), clat = cos(llh[0])
        let slon = sin(llh[1]), clon = cos(llh[1])
        
        return [
            [-slat * clon, -slat * slon, clat],
            [-slon,        clon,        0.0],
            [clat * clon,  clat * slon,  slat]
        ]
    }
    
    /// Converts ECEF coordinates to NEU (North-East-Up) relative to a reference frame.
    /// - Parameters:
    ///   - xyz: ECEF vector to transform.
    ///   - t: 3x3 transformation matrix from `ltcmat`.
    /// - Returns: NEU vector.
    static func ecef2neu(_ xyz: Vector3, t: [[Double]]) -> Vector3 {
        let n = t[0][0] * xyz.x + t[0][1] * xyz.y + t[0][2] * xyz.z
        let e = t[1][0] * xyz.x + t[1][1] * xyz.y + t[1][2] * xyz.z
        let u = t[2][0] * xyz.x + t[2][1] * xyz.y + t[2][2] * xyz.z
        return Vector3(n, e, u)
    }
    
    /// Converts NEU (North-East-Up) coordinates to Azimuth and Elevation.
    /// - Parameter neu: Input NEU vector.
    /// - Returns: A tuple containing Azimuth and Elevation in radians.
    static func neu2azel(_ neu: Vector3) -> (az: Double, el: Double) {
        var az = atan2(neu.y, neu.x)
        if az < 0.0 { az += (2.0 * Constants.PI) }
        let ne = sqrt(neu.x * neu.x + neu.y * neu.y)
        let el = atan2(neu.z, ne)
        return (az, el)
    }
}
