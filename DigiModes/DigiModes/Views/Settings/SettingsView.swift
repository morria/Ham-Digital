//
//  SettingsView.swift
//  DigiModes
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var myCallsign = Station.myStation.callsign
    @State private var myName = Station.myStation.name
    @State private var myQTH = Station.myStation.qth
    @State private var myGrid = Station.myStation.grid

    var body: some View {
        NavigationStack {
            Form {
                Section("My Station") {
                    TextField("Callsign", text: $myCallsign)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Name", text: $myName)
                    TextField("QTH (City, State)", text: $myQTH)
                    TextField("Grid Square", text: $myGrid)
                        .textInputAutocapitalization(.characters)
                }

                Section("Audio") {
                    NavigationLink {
                        AudioMeterView()
                    } label: {
                        Label("Input Level Meter", systemImage: "waveform")
                    }
                }

                Section("Digital Modes") {
                    NavigationLink {
                        RTTYSettingsView()
                    } label: {
                        Label("RTTY Settings", systemImage: "dot.radiowaves.left.and.right")
                    }

                    NavigationLink {
                        Text("PSK31 Settings - Coming Soon")
                            .foregroundColor(.secondary)
                    } label: {
                        Label("PSK31 Settings", systemImage: "waveform.path")
                    }

                    NavigationLink {
                        Text("Olivia Settings - Coming Soon")
                            .foregroundColor(.secondary)
                    } label: {
                        Label("Olivia Settings", systemImage: "waveform.circle")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Skeleton)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Audio Meter View

struct AudioMeterView: View {
    @StateObject private var audioMeter = AudioMeterModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("Input Level")
                .font(.headline)

            // Level meter bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    // Level indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(meterColor)
                        .frame(width: geometry.size.width * audioMeter.normalizedLevel)

                    // Peak indicator
                    if audioMeter.peakLevel > 0.01 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2)
                            .offset(x: geometry.size.width * audioMeter.peakLevel - 1)
                    }
                }
            }
            .frame(height: 32)
            .padding(.horizontal)

            // dB scale
            HStack {
                Text("-60")
                Spacer()
                Text("-40")
                Spacer()
                Text("-20")
                Spacer()
                Text("-10")
                Spacer()
                Text("0 dB")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal)

            // Current level display
            Text(String(format: "%.1f dB", audioMeter.decibelLevel))
                .font(.system(.title, design: .monospaced))
                .foregroundColor(audioMeter.decibelLevel > -6 ? .red : .primary)

            Spacer()

            // Instructions
            VStack(spacing: 8) {
                Text("Adjust your radio's audio output")
                    .font(.subheadline)
                Text("Aim for peaks around -12 to -6 dB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Input Level")
        .onAppear {
            audioMeter.startMonitoring()
        }
        .onDisappear {
            audioMeter.stopMonitoring()
        }
    }

    private var meterColor: Color {
        if audioMeter.decibelLevel > -3 {
            return .red
        } else if audioMeter.decibelLevel > -10 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Audio Meter Model

@MainActor
class AudioMeterModel: ObservableObject {
    @Published var normalizedLevel: CGFloat = 0
    @Published var peakLevel: CGFloat = 0
    @Published var decibelLevel: Double = -60

    private var isMonitoring = false
    private var simulationTask: Task<Void, Never>?

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // TODO: Replace with real AVAudioEngine input metering
        // For now, simulate audio levels for UI development
        simulationTask = Task {
            while isMonitoring {
                // Simulate varying audio levels
                let baseLevel = Double.random(in: 0.1...0.4)
                let noise = Double.random(in: -0.1...0.1)
                let level = min(1.0, max(0.0, baseLevel + noise))

                normalizedLevel = CGFloat(level)
                decibelLevel = 20 * log10(max(level, 0.001))

                // Update peak with decay
                if CGFloat(level) > peakLevel {
                    peakLevel = CGFloat(level)
                } else {
                    peakLevel = max(0, peakLevel - 0.01)
                }

                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        simulationTask?.cancel()
        simulationTask = nil
    }
}

// MARK: - RTTY Settings View

struct RTTYSettingsView: View {
    @State private var baudRate = 45.45
    @State private var markFreq = 2125.0
    @State private var shift = 170.0

    var body: some View {
        Form {
            Section("Baud Rate") {
                Picker("Baud Rate", selection: $baudRate) {
                    Text("45.45 Baud").tag(45.45)
                    Text("50 Baud").tag(50.0)
                    Text("75 Baud").tag(75.0)
                }
            }

            Section("Frequencies") {
                HStack {
                    Text("Mark Frequency")
                    Spacer()
                    Text("\(Int(markFreq)) Hz")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Shift")
                    Spacer()
                    Text("\(Int(shift)) Hz")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Space Frequency")
                    Spacer()
                    Text("\(Int(markFreq - shift)) Hz")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("RTTY Settings")
    }
}

#Preview {
    SettingsView()
}

#Preview("Audio Meter") {
    NavigationStack {
        AudioMeterView()
    }
}
