# libgnss-tx-swift: GNSS Signal Generator

A high-performance, modularized GNSS L1 C/A baseband signal generator implemented in Swift 6. This project is a port of the **Oriental AI** internal C-based GNSS simulator, optimized for modern hardware and SDR (Software Defined Radio) workflows.

**Proprietary and Confidential.** This software is the exclusive property of Shu Wang.

## Project Overview

The core purpose of this library is to synthesize raw I/Q samples that simulate GNSS signals (primarily GPS L1 C/A, with support for GLONASS and BeiDou frequencies) as they would be received by an antenna. These samples can be saved to disk and played back through SDR hardware (e.g., HackRF, USRP) to spoof or test GNSS receivers.

### Key Technologies
- **Language:** Swift 6 (with strict concurrency safety).
- **Architecture:** Modular simulation engine with dedicated components for orbit propagation, signal synthesis, and atmospheric modeling.
- **Math:** Optimized fixed-point arithmetic for signal generation.
- **CLI:** Powered by `swift-argument-parser`.
- **Documentation:** Swift-native DocC integration.
- **Multi-Constellation:** Logic optimized for GPS, GLONASS, and BeiDou frequency planning.

### Core Components
- **`Simulator`**: The central orchestrator that manages time, trajectory, and satellite allocation.
- **`Link` / `Channel`**: Models the signal propagation path from a specific satellite to the receiver, including Doppler shift and range.
- **`GPSEphemeris`**: Parses and processes RINEX (Receiver Independent Exchange Format) navigation files to calculate satellite positions.
- **`GPSSignal` & `GPSCode`**: Generates the C/A codes and synthesizes the final baseband waveform.
- **`Logger`**: A custom, color-coded logging utility for simulation tracking.

## Building and Running

### Prerequisites
- Swift 6.0 or later.
- Compatible with macOS (10.15.4+) and Linux.

### Key Commands
- **Build:**
  ```bash
  swift build -c release
  ```
- **Run:**
  The executable is located at `.build/release/gnss-sig-gen-swift`.
  ```bash
  ./.build/release/gnss-sig-gen-swift -e <path-to-rinex-file> [options]
  ```
- **Test:**
  ```bash
  swift test
  ```
- **Documentation:**
  ```bash
  swift package generate-documentation
  ```

## Development Conventions

### Coding Style
- **Swift 6 Concurrency:** The codebase adheres to strict concurrency checks. Use `async/await` and `Sendable` types where appropriate.
- **Fixed-Point Arithmetic:** Signal synthesis logic often uses performance-optimized math. Refer to `MathUtils.swift` and `LUT.swift`.
- **Logging:** Use the `Logger` class for all console output. Preferred levels are `.info`, `.debug`, and `.error`.

### Testing Practices
- **Swift Testing Framework:** The project uses the modern `Testing` library (introduced in Swift 6) instead of XCTest. Use `@Test` and `#expect`.
- **Verification:** New features or bug fixes should include tests that verify physical accuracy (e.g., range estimation, coordinate transforms).

### Contribution Guidelines
- Ensure all tests pass before submitting changes.
- Maintain DocC-style comments for public interfaces.
- Porting from C: If porting additional features from the original C project, ensure they are idiomatic Swift and thread-safe.
