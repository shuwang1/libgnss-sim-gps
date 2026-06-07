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
import ArgumentParser

/// The main entry point for the GNSS Signal Generator CLI application.
@main
struct GNSSSigGen: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gnss-sig-gen-swift",
        abstract: "A modularized GNSS L1 C/A baseband signal generator for SDR hardware.",
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Path to the RINEX navigation file.")
    var ephemeris: String?
    
    @Option(name: .shortAndLong, help: "Path to an ECEF motion CSV file (columns: t,x,y,z).")
    var userMotion: String?
    
    @Option(name: .customLong("llh-motion"), help: "Path to an LLH motion CSV file (columns: t,lat,lon,h).")
    var llhMotion: String?
    
    @Option(name: .customLong("nmea-gga"), help: "Path to an NMEA GGA stream file.")
    var nmeaGga: String?
    
    @Option(name: .shortAndLong, help: "Path for the output binary signal file.")
    var output: String = "gpssim.bin"
    
    @Option(name: .shortAndLong, help: "Sampling frequency in Hz.")
    var sampFreq: Double = 2600000.0
    
    @Option(name: .customLong("elv-mask"), help: "Satellite elevation mask in degrees.")
    var elvMask: Double = 5.0
    
    @Option(name: .shortAndLong, help: "Simulation duration in seconds.")
    var duration: Int = 300
    
    @Option(name: .shortAndLong, help: "I/Q sample format: 1, 8, or 16 bits.")
    var bits: Int = 16
    
    @Flag(name: .shortAndLong, help: "Enable verbose debug logging.")
    var verbose: Bool = false

    /// Executes the CLI command logic.
    mutating func run() throws {
        Logger.minLevel = verbose ? .debug : .info
        
        var config = Simulator.Config()
        config.navFile = ephemeris ?? ""
        config.umFile = userMotion ?? llhMotion ?? nmeaGga ?? ""
        config.outFile = output
        config.sampFreq = sampFreq
        config.elvMask = elvMask
        config.duration = duration
        config.dataFormat = bits
        config.verbose = verbose
        
        if llhMotion != nil { config.umLLH = true }
        if nmeaGga != nil { config.nmeaGGA = true }
        if config.umFile.isEmpty { config.staticMode = true }
        
        guard !config.navFile.isEmpty else {
            Logger.error("RINEX navigation file is required. Use -e to provide one.")
            throw ExitCode.failure
        }
        
        let simulator = Simulator(config: config)
        guard simulator.initialize() else {
            Logger.error("Simulator initialization failed. Please check your RINEX and trajectory files.")
            throw ExitCode.failure
        }
        
        Logger.info("Starting simulation for \(config.duration) seconds...")
        
        guard let fileHandle = FileHandle(forWritingAtPath: config.outFile) ?? 
                (FileManager.default.createFile(atPath: config.outFile, contents: nil) ? FileHandle(forWritingAtPath: config.outFile) : nil) else {
            Logger.error("Failed to open output file \(config.outFile)")
            throw ExitCode.failure
        }
        
        defer { try? fileHandle.close() }
        
        for i in 0..<simulator.numSteps {
            if let samples = simulator.step(stepIdx: i) {
                let data: Data
                if config.dataFormat == 8 {
                    let samples8 = samples.map { Int8(truncatingIfNeeded: $0 / 16) }
                    data = samples8.withUnsafeBufferPointer { ptr in
                        Data(buffer: ptr)
                    }
                } else if config.dataFormat == 1 {
                    let samples8 = samples.map { $0 >= 0 ? Int8(1) : Int8(-1) }
                    data = samples8.withUnsafeBufferPointer { ptr in
                        Data(buffer: ptr)
                    }
                } else {
                    data = samples.withUnsafeBufferPointer { ptr in
                        Data(buffer: ptr)
                    }
                }
                try fileHandle.write(contentsOf: data)
            }
            if i % 100 == 0 {
                let progress = Int(Double(i) / Double(simulator.numSteps) * 100)
                print("Progress: \(progress)%", terminator: "\r")
                try? FileHandle.standardOutput.synchronize()
            }
        }
        Logger.info("\nSimulation completed.")
    }
}
