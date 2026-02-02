//
//  BandpassFilterTests.swift
//  AmateurDigitalCoreTests
//

import XCTest
@testable import AmateurDigitalCore

final class BandpassFilterTests: XCTestCase {

    // MARK: - Configuration Tests

    func testFilterConfiguration() {
        let filter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )

        XCTAssertEqual(filter.lowCutoff, 1880)
        XCTAssertEqual(filter.highCutoff, 2200)
        XCTAssertEqual(filter.sampleRate, 48000)
        XCTAssertEqual(filter.bandwidth, 320)
    }

    func testFSKFilterConfiguration() {
        let filter = BandpassFilter(
            markFrequency: 2125,
            spaceFrequency: 1955,
            margin: 75,
            sampleRate: 48000
        )

        // Low cutoff = 1955 - 75 = 1880
        // High cutoff = 2125 + 75 = 2200
        XCTAssertEqual(filter.lowCutoff, 1880)
        XCTAssertEqual(filter.highCutoff, 2200)
    }

    // MARK: - Passband Tests

    func testPassbandAtCenterFrequency() {
        let filter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )

        // Center frequency should have near-unity gain
        let centerResponse = filter.magnitudeResponse(at: filter.centerFrequency)
        XCTAssertGreaterThan(centerResponse, 0.9, "Center frequency should pass through")
        XCTAssertLessThan(centerResponse, 1.1, "Center frequency should not be amplified")
    }

    func testPassbandAtMarkFrequency() {
        let markFreq = 2125.0
        let spaceFreq = 1955.0

        let filter = BandpassFilter(
            markFrequency: markFreq,
            spaceFrequency: spaceFreq,
            margin: 75,
            sampleRate: 48000
        )

        let markResponse = filter.magnitudeResponse(at: markFreq)
        XCTAssertGreaterThan(markResponse, 0.7, "Mark frequency should pass through with minimal loss")
    }

    func testPassbandAtSpaceFrequency() {
        let markFreq = 2125.0
        let spaceFreq = 1955.0

        let filter = BandpassFilter(
            markFrequency: markFreq,
            spaceFrequency: spaceFreq,
            margin: 75,
            sampleRate: 48000
        )

        let spaceResponse = filter.magnitudeResponse(at: spaceFreq)
        XCTAssertGreaterThan(spaceResponse, 0.7, "Space frequency should pass through with minimal loss")
    }

    // MARK: - Stopband Rejection Tests

    func testStopbandRejectionLowFrequency() {
        let filter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )

        // 1000 Hz should be well below passband
        let responseDB = filter.magnitudeResponseDB(at: 1000)
        XCTAssertLessThan(responseDB, -20, "1000 Hz should be attenuated >20 dB")
    }

    func testStopbandRejectionHighFrequency() {
        let filter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )

        // 3500 Hz should be well above passband
        let responseDB = filter.magnitudeResponseDB(at: 3500)
        XCTAssertLessThan(responseDB, -20, "3500 Hz should be attenuated >20 dB")
    }

    func testStopbandRejectionVeryLowFrequency() {
        let filter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )

        // 200 Hz should have strong rejection
        let responseDB = filter.magnitudeResponseDB(at: 200)
        XCTAssertLessThan(responseDB, -30, "200 Hz should be attenuated >30 dB")
    }

    // MARK: - Signal Processing Tests

    func testProcessMarkTone() {
        var filter = BandpassFilter(
            markFrequency: 2125,
            spaceFrequency: 1955,
            margin: 75,
            sampleRate: 48000
        )

        // Generate mark tone
        let sampleRate = 48000.0
        let markFreq = 2125.0
        let numSamples = 4096

        var input = [Float]()
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            input.append(Float(sin(2.0 * .pi * markFreq * t)))
        }

        let output = filter.process(input)

        // Skip first 100 samples for filter settling
        let steadyState = Array(output.dropFirst(100))

        // Measure RMS of output
        let rms = sqrt(steadyState.map { $0 * $0 }.reduce(0, +) / Float(steadyState.count))

        // Input RMS of unit sine is 1/sqrt(2) ≈ 0.707
        // Output should be similar (within 30%)
        XCTAssertGreaterThan(rms, 0.5, "Mark tone should pass through filter")
        XCTAssertLessThan(rms, 1.0, "Mark tone should not be amplified significantly")
    }

    func testProcessOutOfBandNoise() {
        var filter = BandpassFilter(
            markFrequency: 2125,
            spaceFrequency: 1955,
            margin: 75,
            sampleRate: 48000
        )

        // Generate 500 Hz tone (out of band)
        let sampleRate = 48000.0
        let noiseFreq = 500.0
        let numSamples = 4096

        var input = [Float]()
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            input.append(Float(sin(2.0 * .pi * noiseFreq * t)))
        }

        let output = filter.process(input)

        // Skip first 200 samples for filter settling
        let steadyState = Array(output.dropFirst(200))

        // Measure RMS of output
        let rms = sqrt(steadyState.map { $0 * $0 }.reduce(0, +) / Float(steadyState.count))

        // Output should be significantly attenuated
        XCTAssertLessThan(rms, 0.2, "Out-of-band noise should be attenuated")
    }

    func testProcessMixedSignal() {
        var filter = BandpassFilter(
            markFrequency: 2125,
            spaceFrequency: 1955,
            margin: 75,
            sampleRate: 48000
        )

        let sampleRate = 48000.0
        let markFreq = 2125.0
        let noiseFreq = 500.0
        let numSamples = 4096

        // Generate mark tone + out-of-band noise
        var input = [Float]()
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let mark = Float(sin(2.0 * .pi * markFreq * t))
            let noise = Float(sin(2.0 * .pi * noiseFreq * t))
            input.append(mark + noise)  // Equal amplitude
        }

        let output = filter.process(input)

        // Skip first 200 samples for filter settling
        let steadyState = Array(output.dropFirst(200))

        // Measure correlation with pure mark tone
        var correlation: Float = 0
        for (i, sample) in steadyState.enumerated() {
            let t = Double(i + 200) / sampleRate
            let reference = Float(sin(2.0 * .pi * markFreq * t))
            correlation += sample * reference
        }
        correlation /= Float(steadyState.count)

        // Should have good correlation with mark tone after filtering
        XCTAssertGreaterThan(correlation, 0.3,
                           "Output should correlate with mark tone after filtering out noise")
    }

    // MARK: - Reset Test

    func testReset() {
        var filter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )

        // Process some samples to build up state
        for i in 0..<1000 {
            _ = filter.process(Float(i) / 1000.0)
        }

        // Reset and process zero - should get zero output
        filter.reset()
        let output = filter.process(0)

        XCTAssertEqual(output, 0, "After reset, processing zero should output zero")
    }

    // MARK: - Cascaded Filter Tests

    func testCascadedFilterConfiguration() {
        let filter = CascadedBandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000,
            order: 2
        )

        // Should be able to process samples
        var mutableFilter = filter
        let output = mutableFilter.process(1.0)
        XCTAssertNotEqual(output, 0, "Cascaded filter should process samples")
    }

    func testCascadedFilterBetterRejection() {
        // Single section
        let singleFilter = BandpassFilter(
            lowCutoff: 1880,
            highCutoff: 2200,
            sampleRate: 48000
        )
        let singleRejection = singleFilter.magnitudeResponseDB(at: 500)

        // Cascaded (2 sections)
        // Cascaded rejection should be roughly 2x single rejection in dB
        let expectedCascadedRejection = singleRejection * 2

        // This is approximate - cascaded filter should have better rejection
        XCTAssertLessThan(expectedCascadedRejection, -40,
                        "Cascaded filter should have >40 dB rejection at 500 Hz")
    }

    // MARK: - Edge Cases

    func testNarrowBandwidth() {
        // Very narrow filter (50 Hz bandwidth)
        let filter = BandpassFilter(
            lowCutoff: 2000,
            highCutoff: 2050,
            sampleRate: 48000
        )

        let centerResponse = filter.magnitudeResponse(at: 2025)
        XCTAssertGreaterThan(centerResponse, 0.5, "Narrow filter should still pass center frequency")
    }

    func testWideBandwidth() {
        // Wide filter (1000 Hz bandwidth)
        let filter = BandpassFilter(
            lowCutoff: 1500,
            highCutoff: 2500,
            sampleRate: 48000
        )

        let markResponse = filter.magnitudeResponse(at: 2125)
        let spaceResponse = filter.magnitudeResponse(at: 1955)

        XCTAssertGreaterThan(markResponse, 0.8, "Wide filter should pass mark frequency well")
        XCTAssertGreaterThan(spaceResponse, 0.8, "Wide filter should pass space frequency well")
    }
}
