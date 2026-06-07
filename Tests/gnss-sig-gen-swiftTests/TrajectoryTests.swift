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

/// Unit tests for trajectory and user motion file parsing.
struct TrajectoryTests {

    /// Verifies parsing of ECEF CSV trajectory files and robustness to whitespace.
    @Test func testReadUserMotion() async throws {
        let csvContent = "0.0, 1000.0, 2000.0, 3000.0\n0.1, 1001.0, 2001.0, 3001.0"
        let tempFile = "/tmp/test_motion.csv"
        try csvContent.write(toFile: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tempFile) }
        
        guard let trajectory = Trajectory.readUserMotion(filename: tempFile) else {
            Issue.record("Failed to read trajectory")
            return
        }
        
        guard trajectory.count == 2 else {
            Issue.record("Expected 2 trajectory points, got \(trajectory.count)")
            return
        }
        #expect(trajectory[0] == Vector3(1000.0, 2000.0, 3000.0))
        #expect(trajectory[1] == Vector3(1001.0, 2001.0, 3001.0))
    }
}
