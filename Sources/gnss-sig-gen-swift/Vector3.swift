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

/// A simple 3D vector implementation for GNSS calculations.
/// 
/// Used for ECEF (Earth-Centered, Earth-Fixed) positions and LLH (Latitude, Longitude, Height) coordinates.
struct Vector3: Equatable {
    /// The X component (or Latitude in radians).
    var x: Double
    /// The Y component (or Longitude in radians).
    var y: Double
    /// The Z component (or Height in meters).
    var z: Double
    
    /// Initializes a new vector with the given components.
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Adds two vectors.
    static func +(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    /// Subtracts the second vector from the first.
    static func -(lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    /// Multiplies a vector by a scalar.
    static func *(lhs: Vector3, rhs: Double) -> Vector3 {
        return Vector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    /// Multiplies a vector by a scalar.
    static func *(lhs: Double, rhs: Vector3) -> Vector3 {
        return rhs * lhs
    }
    
    /// Divides a vector by a scalar.
    static func /(lhs: Vector3, rhs: Double) -> Vector3 {
        return Vector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    /// Adds the second vector to the first in-place.
    static func +=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs + rhs
    }
    
    /// Subtracts the second vector from the first in-place.
    static func -=(lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs - rhs
    }
    
    /// Accesses the vector components by index (0: x, 1: y, 2: z).
    subscript(index: Int) -> Double {
        get {
            switch index {
            case 0: return x
            case 1: return y
            case 2: return z
            default: fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0: x = newValue
            case 1: y = newValue
            case 2: z = newValue
            default: fatalError("Index out of range")
            }
        }
    }
}

/// Computes the Euclidean norm (length) of a 3D vector.
/// - Parameter v: The input vector.
/// - Returns: The magnitude of the vector.
func length(_ v: Vector3) -> Double {
    return sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
}

/// Computes the dot product of two 3D vectors.
/// - Parameters:
///   - v1: The first vector.
///   - v2: The second vector.
/// - Returns: The scalar dot product.
func dot(_ v1: Vector3, _ v2: Vector3) -> Double {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
}
