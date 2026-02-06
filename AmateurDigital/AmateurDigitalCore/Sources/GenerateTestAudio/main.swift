//
//  GenerateTestAudio
//  Generates RTTY test audio files for Amateur Digital
//

import Foundation
import AmateurDigitalCore

// MARK: - Audio File Generation

/// Write samples to a WAV file
func writeWAV(samples: [Float], sampleRate: Double, to path: String) throws {
    let url = URL(fileURLWithPath: path)

    // WAV header
    var header = Data()
    let dataSize = UInt32(samples.count * 2)  // 16-bit samples
    let fileSize = dataSize + 36

    // RIFF header
    header.append("RIFF".data(using: .ascii)!)
    header.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
    header.append("WAVE".data(using: .ascii)!)

    // fmt chunk
    header.append("fmt ".data(using: .ascii)!)
    header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })  // chunk size
    header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })   // PCM format
    header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })   // mono
    header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })  // sample rate
    header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Array($0) })  // byte rate
    header.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })   // block align
    header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })  // bits per sample

    // data chunk
    header.append("data".data(using: .ascii)!)
    header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })

    // Convert Float32 to Int16
    var audioData = Data()
    for sample in samples {
        let clamped = max(-1.0, min(1.0, sample))
        let int16 = Int16(clamped * 32767)
        audioData.append(contentsOf: withUnsafeBytes(of: int16.littleEndian) { Array($0) })
    }

    var fileData = header
    fileData.append(audioData)

    try fileData.write(to: url)
}

// MARK: - Single Channel Test

func generateSingleChannelTest() throws {
    print("=== Single Channel RTTY Test ===")

    let config = RTTYConfiguration.standard
    let modem = RTTYModem(configuration: config)

    let message = "RYRYRY CQ CQ CQ DE W1AW W1AW W1AW K"

    print("Configuration: \(config)")
    print("Message: \(message)")

    let samples = modem.encodeWithIdle(
        text: message,
        preambleMs: 500,
        postambleMs: 200
    )

    print("Generated \(samples.count) samples (\(String(format: "%.2f", Double(samples.count) / config.sampleRate)) seconds)")

    let outputPath = "/tmp/rtty_single_channel.wav"
    try writeWAV(samples: samples, sampleRate: config.sampleRate, to: outputPath)
    print("Written to: \(outputPath)")
    print()
}

// MARK: - Multi-Channel Test

func generateMultiChannelTest() throws {
    print("=== Multi-Channel RTTY Test (4 channels) ===")

    // Four different stations at different frequencies
    let channels: [(freq: Double, callsign: String, message: String)] = [
        (1500, "W1AW", "CQ CQ CQ DE W1AW W1AW W1AW K"),
        (1700, "K5ABC", "CQ CONTEST DE K5ABC K5ABC K"),
        (1900, "N0XYZ", "QSO DE N0XYZ N0XYZ PSE K"),
        (2100, "VE3TEST", "CQ DX DE VE3TEST VE3TEST K")
    ]

    let sampleRate = 48000.0
    var maxLength = 0
    var channelSamples: [[Float]] = []

    for (freq, callsign, message) in channels {
        let config = RTTYConfiguration(
            baudRate: 45.45,
            markFrequency: freq,
            shift: 170.0,
            sampleRate: sampleRate
        )
        let modem = RTTYModem(configuration: config)

        // Add some random delay (0-500ms) to make channels start at different times
        let delaySamples = Int(Double.random(in: 0...0.5) * sampleRate)
        var samples = [Float](repeating: 0, count: delaySamples)

        samples.append(contentsOf: modem.encodeWithIdle(
            text: message,
            preambleMs: 200,
            postambleMs: 100
        ))

        print("Channel \(Int(freq)) Hz (\(callsign)): \(samples.count) samples")
        channelSamples.append(samples)
        maxLength = max(maxLength, samples.count)
    }

    // Mix all channels together
    var mixed = [Float](repeating: 0, count: maxLength)
    for channel in channelSamples {
        for (i, sample) in channel.enumerated() {
            mixed[i] += sample * 0.25  // Scale down to prevent clipping
        }
    }

    print("Mixed audio: \(mixed.count) samples (\(String(format: "%.2f", Double(mixed.count) / sampleRate)) seconds)")

    let outputPath = "/tmp/rtty_multi_channel.wav"
    try writeWAV(samples: mixed, sampleRate: sampleRate, to: outputPath)
    print("Written to: \(outputPath)")
    print()
    print("Channels:")
    for (freq, callsign, _) in channels {
        print("  - \(Int(freq)) Hz: \(callsign)")
    }
    print()
}

// MARK: - PSK31 Single Channel Test

func generatePSK31SingleChannelTest() throws {
    print("=== Single Channel PSK31 Test ===")

    let config = PSK31Configuration.standard
    var modulator = PSK31Modulator(configuration: config)

    let message = "cq cq cq de W1AW W1AW W1AW pse k"

    print("Configuration: \(config)")
    print("Message: \(message)")

    let samples = modulator.modulateTextWithEnvelope(
        message,
        preambleMs: 500,
        postambleMs: 200
    )

    print("Generated \(samples.count) samples (\(String(format: "%.2f", Double(samples.count) / config.sampleRate)) seconds)")

    let outputPath = "/tmp/psk31_single_channel.wav"
    try writeWAV(samples: samples, sampleRate: config.sampleRate, to: outputPath)
    print("Written to: \(outputPath)")
    print()
}

// MARK: - PSK31 Multi-Channel Test

func generatePSK31MultiChannelTest() throws {
    print("=== Multi-Channel PSK31 Test (4 channels) ===")

    // Four different stations at different frequencies (50 Hz spacing for PSK31)
    let channels: [(freq: Double, callsign: String, message: String)] = [
        (900, "W1AW", "cq cq cq de W1AW W1AW W1AW k"),
        (1000, "K5ABC", "cq contest de K5ABC K5ABC k"),
        (1100, "N0XYZ", "qso de N0XYZ N0XYZ pse k"),
        (1200, "VE3TEST", "cq dx de VE3TEST VE3TEST k")
    ]

    let sampleRate = 48000.0
    var maxLength = 0
    var channelSamples: [[Float]] = []

    for (freq, callsign, message) in channels {
        let config = PSK31Configuration(
            centerFrequency: freq,
            sampleRate: sampleRate
        )
        var modulator = PSK31Modulator(configuration: config)

        // Add some random delay (0-500ms) to make channels start at different times
        let delaySamples = Int(Double.random(in: 0...0.5) * sampleRate)
        var samples = [Float](repeating: 0, count: delaySamples)

        samples.append(contentsOf: modulator.modulateTextWithEnvelope(
            message,
            preambleMs: 200,
            postambleMs: 100
        ))

        print("Channel \(Int(freq)) Hz (\(callsign)): \(samples.count) samples")
        channelSamples.append(samples)
        maxLength = max(maxLength, samples.count)
    }

    // Mix all channels together
    var mixed = [Float](repeating: 0, count: maxLength)
    for channel in channelSamples {
        for (i, sample) in channel.enumerated() {
            mixed[i] += sample * 0.25  // Scale down to prevent clipping
        }
    }

    print("Mixed audio: \(mixed.count) samples (\(String(format: "%.2f", Double(mixed.count) / sampleRate)) seconds)")

    let outputPath = "/tmp/psk31_multi_channel.wav"
    try writeWAV(samples: mixed, sampleRate: sampleRate, to: outputPath)
    print("Written to: \(outputPath)")
    print()
    print("Channels:")
    for (freq, callsign, _) in channels {
        print("  - \(Int(freq)) Hz: \(callsign)")
    }
    print()
}

// MARK: - Drifting RTTY Test (for AFC testing)

/// Generate RTTY audio with linear frequency drift
/// - Parameters:
///   - text: Text to transmit
///   - startOffset: Frequency offset at start in Hz
///   - endOffset: Frequency offset at end in Hz
///   - configuration: Base RTTY configuration
/// - Returns: Audio samples with drifting frequency
func generateDriftingRTTY(
    text: String,
    startOffset: Double,
    endOffset: Double,
    configuration: RTTYConfiguration
) -> [Float] {
    let codec = BaudotCodec()
    let codes = codec.encodeWithPreamble(text)

    // Calculate total samples
    let samplesPerChar = Int(7.5 * Double(configuration.samplesPerBit))
    let preambleSamples = Int(0.2 * configuration.sampleRate)  // 200ms preamble
    let postambleSamples = Int(0.1 * configuration.sampleRate)  // 100ms postamble
    let messageSamples = codes.count * samplesPerChar
    let totalSamples = preambleSamples + messageSamples + postambleSamples

    var samples = [Float]()
    samples.reserveCapacity(totalSamples)

    var phase: Double = 0
    let sampleRate = configuration.sampleRate
    let samplesPerBit = configuration.samplesPerBit

    // Helper to generate a tone with drifting frequency
    func generateTone(isMarkTone: Bool, count: Int, currentIndex: Int) -> [Float] {
        var toneSamples = [Float]()
        toneSamples.reserveCapacity(count)

        for i in 0..<count {
            let sampleIndex = currentIndex + i
            let progress = Double(sampleIndex) / Double(totalSamples)
            let currentOffset = startOffset + (endOffset - startOffset) * progress

            let baseFreq = isMarkTone ? configuration.markFrequency : configuration.spaceFrequency
            let freq = baseFreq + currentOffset

            phase += 2.0 * .pi * freq / sampleRate
            if phase > 2.0 * .pi {
                phase -= 2.0 * .pi
            }

            toneSamples.append(Float(sin(phase)))
        }
        return toneSamples
    }

    var currentIndex = 0

    // Preamble (mark tone)
    samples.append(contentsOf: generateTone(isMarkTone: true, count: preambleSamples, currentIndex: currentIndex))
    currentIndex += preambleSamples

    // Message
    for code in codes {
        // Start bit (space)
        samples.append(contentsOf: generateTone(isMarkTone: false, count: samplesPerBit, currentIndex: currentIndex))
        currentIndex += samplesPerBit

        // 5 data bits, LSB first
        for bitIndex in 0..<5 {
            let bit = (code >> bitIndex) & 0x01
            let isMarkBit = bit == 1
            samples.append(contentsOf: generateTone(isMarkTone: isMarkBit, count: samplesPerBit, currentIndex: currentIndex))
            currentIndex += samplesPerBit
        }

        // Stop bits (1.5 bits of mark)
        let stopSamples = Int(1.5 * Double(samplesPerBit))
        samples.append(contentsOf: generateTone(isMarkTone: true, count: stopSamples, currentIndex: currentIndex))
        currentIndex += stopSamples
    }

    // Postamble (mark tone)
    samples.append(contentsOf: generateTone(isMarkTone: true, count: postambleSamples, currentIndex: currentIndex))

    return samples
}

func generateDriftingRTTYTests() throws {
    print("=== Drifting RTTY Tests (for AFC) ===")
    print()

    let config = RTTYConfiguration.standard
    let text = "CQ CQ CQ DE W1AW W1AW W1AW K"

    // Test 1: 50 Hz drift (within AFC range)
    print("Test 1: RTTY with +50 Hz drift (0 to +50 Hz)")
    let samples50Hz = generateDriftingRTTY(
        text: text,
        startOffset: 0,
        endOffset: 50,
        configuration: config
    )
    let path50Hz = "/tmp/rtty_drift_50hz.wav"
    try writeWAV(samples: samples50Hz, sampleRate: config.sampleRate, to: path50Hz)
    print("  Written to: \(path50Hz)")
    print()

    // Test 2: 25 Hz drift (moderate)
    print("Test 2: RTTY with ±25 Hz drift (-25 to +25 Hz)")
    let samples25Hz = generateDriftingRTTY(
        text: text,
        startOffset: -25,
        endOffset: 25,
        configuration: config
    )
    let path25Hz = "/tmp/rtty_drift_25hz.wav"
    try writeWAV(samples: samples25Hz, sampleRate: config.sampleRate, to: path25Hz)
    print("  Written to: \(path25Hz)")
    print()

    // Test 3: 100 Hz drift (beyond AFC range - should fail)
    print("Test 3: RTTY with +100 Hz drift (0 to +100 Hz) - beyond AFC range")
    let samples100Hz = generateDriftingRTTY(
        text: text,
        startOffset: 0,
        endOffset: 100,
        configuration: config
    )
    let path100Hz = "/tmp/rtty_drift_100hz.wav"
    try writeWAV(samples: samples100Hz, sampleRate: config.sampleRate, to: path100Hz)
    print("  Written to: \(path100Hz)")
    print()

    // Test 4: Negative drift
    print("Test 4: RTTY with -40 Hz drift (0 to -40 Hz)")
    let samplesNeg = generateDriftingRTTY(
        text: text,
        startOffset: 0,
        endOffset: -40,
        configuration: config
    )
    let pathNeg = "/tmp/rtty_drift_neg40hz.wav"
    try writeWAV(samples: samplesNeg, sampleRate: config.sampleRate, to: pathNeg)
    print("  Written to: \(pathNeg)")
    print()
}

// MARK: - Difficulty Level Tests

func generateDifficultyTests() throws {
    print("=== Difficulty Level Tests ===")
    print()

    let sampleRate = 48000.0

    // Level 8: Out-of-band interference
    print("Level 8: RTTY with out-of-band interference (500 Hz tone)")
    let config = RTTYConfiguration.standard
    let modem = RTTYModem(configuration: config)
    let text = "CQ CQ DE W1AW"

    var samples = modem.encodeWithIdle(text: text, preambleMs: 200, postambleMs: 200)

    // Add strong 500 Hz interference (well below RTTY passband at 1955-2125 Hz)
    for i in 0..<samples.count {
        let t = Double(i) / sampleRate
        let interference = Float(sin(2.0 * .pi * 500.0 * t)) * 1.5
        samples[i] += interference
    }

    let level8Path = "/tmp/rtty_level8_interference.wav"
    try writeWAV(samples: samples, sampleRate: sampleRate, to: level8Path)
    print("  Written to: \(level8Path)")
    print()

    // Level 5: Very heavy noise (10 dB SNR)
    print("Level 5: RTTY with 10 dB SNR noise")
    var cleanSamples = modem.encodeWithIdle(text: text, preambleMs: 200, postambleMs: 200)

    // Calculate signal RMS
    let signalPower = cleanSamples.map { $0 * $0 }.reduce(0, +) / Float(cleanSamples.count)
    let signalRMS = sqrt(signalPower)
    let noiseRMS = signalRMS / pow(10.0, 10.0 / 20.0)  // 10 dB SNR

    // Add noise with simple LCG random
    var seed: UInt64 = 42
    for i in 0..<cleanSamples.count {
        seed ^= seed >> 12
        seed ^= seed << 25
        seed ^= seed >> 27
        let u1 = max(Double(seed &* 0x2545F4914F6CDD1D) / Double(UInt64.max), 0.0001)
        seed ^= seed >> 12
        seed ^= seed << 25
        seed ^= seed >> 27
        let u2 = Double(seed &* 0x2545F4914F6CDD1D) / Double(UInt64.max)
        let noise = noiseRMS * Float(sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2))
        cleanSamples[i] += noise
    }

    let level5Path = "/tmp/rtty_level5_noisy.wav"
    try writeWAV(samples: cleanSamples, sampleRate: sampleRate, to: level5Path)
    print("  Written to: \(level5Path)")
    print()

    // Level 7: Slow fading
    print("Level 7: RTTY with slow fading (0.5 Hz)")
    var fadingSamples = modem.encodeWithIdle(text: "TEST DE W1AW", preambleMs: 200, postambleMs: 200)
    for i in 0..<fadingSamples.count {
        let t = Double(i) / sampleRate
        let fade = Float((1.0 + cos(2.0 * .pi * 0.5 * t)) / 2.0)  // 0.5 Hz fade
        let amplitude = 0.3 + 0.7 * fade  // Fade between 30% and 100%
        fadingSamples[i] *= amplitude
    }

    let level7Path = "/tmp/rtty_level7_fading.wav"
    try writeWAV(samples: fadingSamples, sampleRate: sampleRate, to: level7Path)
    print("  Written to: \(level7Path)")
    print()

    // PSK31 with noise
    print("Level 4: PSK31 with 15 dB SNR noise")
    let pskConfig = PSK31Configuration.standard
    var pskMod = PSK31Modulator(configuration: pskConfig)
    var pskSamples = pskMod.modulateTextWithEnvelope("cq de w1aw", preambleMs: 300, postambleMs: 200)

    let pskPower = pskSamples.map { $0 * $0 }.reduce(0, +) / Float(pskSamples.count)
    let pskRMS = sqrt(pskPower)
    let pskNoiseRMS = pskRMS / pow(10.0, 15.0 / 20.0)  // 15 dB SNR

    seed = 123
    for i in 0..<pskSamples.count {
        seed ^= seed >> 12
        seed ^= seed << 25
        seed ^= seed >> 27
        let u1 = max(Double(seed &* 0x2545F4914F6CDD1D) / Double(UInt64.max), 0.0001)
        seed ^= seed >> 12
        seed ^= seed << 25
        seed ^= seed >> 27
        let u2 = Double(seed &* 0x2545F4914F6CDD1D) / Double(UInt64.max)
        let noise = pskNoiseRMS * Float(sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2))
        pskSamples[i] += noise
    }

    let pskNoisyPath = "/tmp/psk31_level4_noisy.wav"
    try writeWAV(samples: pskSamples, sampleRate: pskConfig.sampleRate, to: pskNoisyPath)
    print("  Written to: \(pskNoisyPath)")
    print()
}

// MARK: - Main

do {
    // RTTY tests
    try generateSingleChannelTest()
    try generateMultiChannelTest()

    // PSK31 tests
    try generatePSK31SingleChannelTest()
    try generatePSK31MultiChannelTest()

    // Difficulty level tests
    try generateDifficultyTests()

    // AFC drift tests
    try generateDriftingRTTYTests()

    print("=== Playback Instructions ===")
    print()
    print("RTTY:")
    print("  Play single channel:  afplay /tmp/rtty_single_channel.wav")
    print("  Play multi-channel:   afplay /tmp/rtty_multi_channel.wav")
    print()
    print("PSK31:")
    print("  Play single channel:  afplay /tmp/psk31_single_channel.wav")
    print("  Play multi-channel:   afplay /tmp/psk31_multi_channel.wav")
    print()
    print("Difficulty Levels:")
    print("  Level 5 (10dB noise):  afplay /tmp/rtty_level5_noisy.wav")
    print("  Level 7 (fading):      afplay /tmp/rtty_level7_fading.wav")
    print("  Level 8 (interference): afplay /tmp/rtty_level8_interference.wav")
    print("  PSK31 Level 4 (15dB):  afplay /tmp/psk31_level4_noisy.wav")
    print()
    print("AFC Drift Tests:")
    print("  +50 Hz drift:  afplay /tmp/rtty_drift_50hz.wav")
    print("  ±25 Hz drift:  afplay /tmp/rtty_drift_25hz.wav")
    print("  +100 Hz drift: afplay /tmp/rtty_drift_100hz.wav (beyond AFC range)")
    print("  -40 Hz drift:  afplay /tmp/rtty_drift_neg40hz.wav")
    print()
    print("To test with your phone:")
    print("1. Play the WAV file on your computer")
    print("2. Hold your phone near the speaker")
    print("3. The app should decode the signal")
} catch {
    print("Error: \(error)")
    exit(1)
}
