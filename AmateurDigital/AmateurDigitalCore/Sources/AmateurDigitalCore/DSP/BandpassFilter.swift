//
//  BandpassFilter.swift
//  AmateurDigitalCore
//
//  2nd-order Butterworth biquad IIR bandpass filter
//  Uses Direct Form II transposed for numerical stability
//

import Foundation

/// Biquad IIR bandpass filter for rejecting out-of-band noise
///
/// Implements a 2nd-order Butterworth bandpass filter using
/// Direct Form II transposed structure for stability.
/// Provides ~40 dB out-of-band rejection.
///
/// Usage:
/// ```swift
/// var filter = BandpassFilter(
///     lowCutoff: 1880,   // spaceFreq - 75
///     highCutoff: 2200,  // markFreq + 75
///     sampleRate: 48000
/// )
/// let filtered = filter.process(sample)
/// ```
public struct BandpassFilter {

    // MARK: - Biquad Coefficients

    /// Feedforward coefficients (numerator)
    private let b0: Float
    private let b1: Float
    private let b2: Float

    /// Feedback coefficients (denominator, negated)
    private let a1: Float
    private let a2: Float

    // MARK: - State (Direct Form II Transposed)

    private var z1: Float = 0
    private var z2: Float = 0

    // MARK: - Configuration

    /// Low cutoff frequency in Hz
    public let lowCutoff: Double

    /// High cutoff frequency in Hz
    public let highCutoff: Double

    /// Sample rate in Hz
    public let sampleRate: Double

    /// Center frequency (geometric mean of cutoffs)
    public var centerFrequency: Double {
        sqrt(lowCutoff * highCutoff)
    }

    /// Bandwidth in Hz
    public var bandwidth: Double {
        highCutoff - lowCutoff
    }

    // MARK: - Initialization

    /// Create a bandpass filter
    /// - Parameters:
    ///   - lowCutoff: Low cutoff frequency in Hz
    ///   - highCutoff: High cutoff frequency in Hz
    ///   - sampleRate: Audio sample rate in Hz
    public init(lowCutoff: Double, highCutoff: Double, sampleRate: Double) {
        self.lowCutoff = lowCutoff
        self.highCutoff = highCutoff
        self.sampleRate = sampleRate

        // Calculate Butterworth bandpass coefficients using bilinear transform
        //
        // Center frequency (geometric mean)
        let f0 = sqrt(lowCutoff * highCutoff)

        // Bandwidth
        let bw = highCutoff - lowCutoff

        // Pre-warp frequencies for bilinear transform
        let omega0 = 2.0 * .pi * f0 / sampleRate
        let alpha = sin(omega0) * sinh(log(2.0) / 2.0 * bw / f0 * omega0 / sin(omega0))

        // Bandpass coefficients (constant 0 dB peak gain)
        let cosOmega0 = cos(omega0)

        // Normalize by a0
        let a0 = 1.0 + alpha

        b0 = Float(alpha / a0)
        b1 = Float(0.0)
        b2 = Float(-alpha / a0)
        a1 = Float(-2.0 * cosOmega0 / a0)
        a2 = Float((1.0 - alpha) / a0)
    }

    /// Create a bandpass filter for FSK signals
    /// - Parameters:
    ///   - markFrequency: Mark frequency in Hz
    ///   - spaceFrequency: Space frequency in Hz
    ///   - margin: Extra bandwidth margin in Hz (default 75)
    ///   - sampleRate: Audio sample rate in Hz
    public init(
        markFrequency: Double,
        spaceFrequency: Double,
        margin: Double = 75.0,
        sampleRate: Double
    ) {
        let lowFreq = min(markFrequency, spaceFrequency)
        let highFreq = max(markFrequency, spaceFrequency)

        self.init(
            lowCutoff: lowFreq - margin,
            highCutoff: highFreq + margin,
            sampleRate: sampleRate
        )
    }

    // MARK: - Processing

    /// Process a single sample through the filter
    /// - Parameter sample: Input sample
    /// - Returns: Filtered output sample
    public mutating func process(_ sample: Float) -> Float {
        // Direct Form II Transposed:
        // y[n] = b0*x[n] + z1
        // z1   = b1*x[n] - a1*y[n] + z2
        // z2   = b2*x[n] - a2*y[n]

        let output = b0 * sample + z1
        z1 = b1 * sample - a1 * output + z2
        z2 = b2 * sample - a2 * output

        return output
    }

    /// Process multiple samples through the filter
    /// - Parameter samples: Input samples
    /// - Returns: Filtered output samples
    public mutating func process(_ samples: [Float]) -> [Float] {
        var output = [Float]()
        output.reserveCapacity(samples.count)

        for sample in samples {
            output.append(process(sample))
        }

        return output
    }

    /// Reset the filter state
    public mutating func reset() {
        z1 = 0
        z2 = 0
    }

    // MARK: - Frequency Response

    /// Calculate the magnitude response at a given frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Magnitude response (linear scale)
    public func magnitudeResponse(at frequency: Double) -> Float {
        // Evaluate H(z) at z = e^(j*omega) where omega = 2*pi*f/fs
        let omega = 2.0 * .pi * frequency / sampleRate

        // H(z) = (b0 + b1*z^-1 + b2*z^-2) / (1 + a1*z^-1 + a2*z^-2)
        // At z = e^(j*omega):
        // z^-1 = e^(-j*omega) = cos(omega) - j*sin(omega)
        // z^-2 = e^(-j*2*omega) = cos(2*omega) - j*sin(2*omega)

        let cosW = Float(cos(omega))
        let sinW = Float(sin(omega))
        let cos2W = Float(cos(2.0 * omega))
        let sin2W = Float(sin(2.0 * omega))

        // Numerator: b0 + b1*(cos - j*sin) + b2*(cos2 - j*sin2)
        let numReal = b0 + b1 * cosW + b2 * cos2W
        let numImag = -b1 * sinW - b2 * sin2W

        // Denominator: 1 + a1*(cos - j*sin) + a2*(cos2 - j*sin2)
        let denReal = 1.0 + a1 * cosW + a2 * cos2W
        let denImag = -a1 * sinW - a2 * sin2W

        // |H| = |num| / |den|
        let numMag = sqrt(numReal * numReal + numImag * numImag)
        let denMag = sqrt(denReal * denReal + denImag * denImag)

        guard denMag > 0 else { return 0 }
        return numMag / denMag
    }

    /// Calculate the magnitude response in dB at a given frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Magnitude response in dB
    public func magnitudeResponseDB(at frequency: Double) -> Float {
        let magnitude = magnitudeResponse(at: frequency)
        guard magnitude > 0 else { return -100 }
        return 20.0 * log10(magnitude)
    }
}

// MARK: - Cascaded Filter for Steeper Rolloff

/// Cascaded bandpass filter for steeper rolloff
///
/// Cascades multiple 2nd-order sections for higher-order response.
/// Each section adds ~40 dB/decade rolloff.
public struct CascadedBandpassFilter {

    private var sections: [BandpassFilter]

    /// Create a cascaded bandpass filter
    /// - Parameters:
    ///   - lowCutoff: Low cutoff frequency in Hz
    ///   - highCutoff: High cutoff frequency in Hz
    ///   - sampleRate: Audio sample rate in Hz
    ///   - order: Number of cascaded sections (default 2 = 4th order)
    public init(
        lowCutoff: Double,
        highCutoff: Double,
        sampleRate: Double,
        order: Int = 2
    ) {
        sections = (0..<order).map { _ in
            BandpassFilter(
                lowCutoff: lowCutoff,
                highCutoff: highCutoff,
                sampleRate: sampleRate
            )
        }
    }

    /// Process a single sample through all cascaded sections
    public mutating func process(_ sample: Float) -> Float {
        var output = sample
        for i in 0..<sections.count {
            output = sections[i].process(output)
        }
        return output
    }

    /// Process multiple samples
    public mutating func process(_ samples: [Float]) -> [Float] {
        var output = [Float]()
        output.reserveCapacity(samples.count)

        for sample in samples {
            output.append(process(sample))
        }

        return output
    }

    /// Reset all sections
    public mutating func reset() {
        for i in 0..<sections.count {
            sections[i].reset()
        }
    }
}
