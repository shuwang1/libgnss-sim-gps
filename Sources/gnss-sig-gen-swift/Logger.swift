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

/// Severity levels for the logging system.
enum LogLevel: Int, Comparable {
    /// Highly detailed information, typically only useful for debugging.
    case debug = 0
    /// Informational messages that highlight the progress of the application.
    case info = 1
    /// Potentially harmful situations that should be monitored.
    case warn = 2
    /// Error events that might still allow the application to continue running.
    case error = 3
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    /// Short string label for the log level.
    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info:  return "INFO "
        case .warn:  return "WARN "
        case .error: return "ERROR"
        }
    }
    
    /// ANSI color escape sequence for the terminal.
    var color: String {
        switch self {
        case .debug: return "\u{001B}[90m" // Gray
        case .info:  return "\u{001B}[32m" // Green
        case .warn:  return "\u{001B}[33m" // Yellow
        case .error: return "\u{001B}[31m" // Red
        }
    }
}

/// A thread-safe, context-aware logging utility.
struct Logger {
    /// The minimum log level to output. Messages below this level are ignored.
    nonisolated(unsafe) static var minLevel: LogLevel = .info
    /// Current simulation time to be included in the log prefix.
    nonisolated(unsafe) static var simTime: Double?
    /// ANSI escape sequence to reset colors.
    static let resetColor = "\u{001B}[0m"
    
    /// Logs a message with the specified level and source context.
    /// - Parameters:
    ///   - level: Severity level.
    ///   - message: The message string.
    ///   - file: Source file name (automatically populated).
    ///   - line: Source line number (automatically populated).
    ///   - function: Source function name (automatically populated).
    static func log(_ level: LogLevel, _ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        guard level >= minLevel else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss.SSS a"
        let timestamp = formatter.string(from: Date())
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        var prefix = ""
        if let st = simTime {
            prefix += String(format: "[T+%06.1fs] ", st)
        }
        
        let header = "\(level.color)\(prefix)[\(timestamp)] [\(level.label)] [\(fileName):\(line):\(function)]"
        let output = "\(header) \(message)\(resetColor)\n"
        
        if level == .error {
            if let data = output.data(using: .utf8) {
                try? FileHandle.standardError.write(contentsOf: data)
            }
        } else {
            print(output, terminator: "")
        }
    }
    
    /// Logs a debug message.
    static func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.debug, message, file: file, line: line, function: function)
    }
    
    /// Logs an informational message.
    static func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.info, message, file: file, line: line, function: function)
    }
    
    /// Logs a warning message.
    static func warn(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.warn, message, file: file, line: line, function: function)
    }
    
    /// Logs an error message.
    static func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.error, message, file: file, line: line, function: function)
    }
    
    /// Produces a formatted hexadecimal and ASCII dump of binary data.
    /// - Parameters:
    ///   - level: Severity level for the dump.
    ///   - label: Title for the dump.
    ///   - data: Raw binary data.
    ///   - file: Source file name (automatically populated).
    ///   - line: Source line number (automatically populated).
    ///   - function: Source function name (automatically populated).
    static func hexDump(_ level: LogLevel, label: String, data: Data, file: String = #file, line: Int = #line, function: String = #function) {
        guard level >= minLevel else { return }
        log(level, "\(label) (\(data.count) bytes):", file: file, line: line, function: function)
        
        var output = ""
        for i in stride(from: 0, to: data.count, by: 16) {
            let chunk = data.subdata(in: i..<min(i + 16, data.count))
            let hex = chunk.map { String(format: "%02X ", $0) }.joined()
            let padding = String(repeating: " ", count: (16 - chunk.count) * 3)
            let ascii = chunk.map { $0 >= 32 && $0 <= 126 ? Character(UnicodeScalar($0)) : "." }.map { String($0) }.joined()
            output += String(format: "    %04X  %@%@ |%@|\n", i, hex, padding, ascii)
        }
        print("\(level.color)\(output)\(resetColor)", terminator: "")
    }
}
