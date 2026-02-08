//
//  ChannelListView.swift
//  DigiModes
//
//  List of all detected channels with navigation to detail
//

import SwiftUI

struct ChannelListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var channelForSettings: Channel?

    var body: some View {
        let visibleChannels = viewModel.channels.filter { $0.hasContent }
        Group {
            if visibleChannels.isEmpty {
                VStack(spacing: 16) {
                    if viewModel.isListening {
                        // Actively listening
                        Image(systemName: viewModel.selectedMode.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(viewModel.selectedMode.color)
                        Text("Listening...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("No signals decoded yet. Monitoring for \(viewModel.selectedMode.displayName) transmissions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else if let error = viewModel.audioError {
                        // Audio error
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Audio Error")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("Retry") {
                            Task {
                                await viewModel.startAudioService()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    } else {
                        // Not listening yet
                        Image(systemName: viewModel.selectedMode.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(viewModel.selectedMode.color.opacity(0.5))
                        Text("Starting...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Initializing \(viewModel.selectedMode.displayName) decoder...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(visibleChannels.sorted { $0.frequency < $1.frequency }) { channel in
                        NavigationLink(value: channel) {
                            ChannelRowView(channel: channel)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteChannel(channel)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                channelForSettings = channel
                            } label: {
                                Label("Settings", systemImage: "slider.horizontal.3")
                            }
                            .tint(.gray)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(item: $channelForSettings) { channel in
            ChannelSettingsSheet(channel: channel, viewModel: viewModel)
                .id(channel.id) // Force recreation to ensure onAppear fires
        }
    }
}

// MARK: - Channel Settings Sheet

struct ChannelSettingsSheet: View {
    let channelID: UUID
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var squelch: Double = 0
    @State private var baudRate: Double = 45.45
    @State private var polarityInverted: Bool = false
    @State private var frequencyOffset: Double = 0

    /// Look up current channel from viewModel to get live data
    private var channel: Channel? {
        viewModel.channels.first { $0.id == channelID }
    }

    /// Whether to show RTTY-specific settings
    private var isRTTY: Bool {
        viewModel.selectedMode == .rtty
    }

    init(channel: Channel, viewModel: ChatViewModel) {
        self.channelID = channel.id
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            if let channel = channel {
                Form {
                    Section {
                        HStack {
                            Text("Frequency")
                            Spacer()
                            Text(channel.frequencyOffsetDisplay)
                                .foregroundColor(.secondary)
                        }

                        if let callsign = channel.callsign {
                            HStack {
                                Text("Callsign")
                                Spacer()
                                Text(callsign)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section {
                        Picker("Squelch", selection: Binding(
                            get: { SquelchLevel.closest(to: squelch / 100.0) },
                            set: { level in
                                squelch = level.rawValue * 100.0
                                saveSquelch(Int(level.rawValue * 100.0))
                            }
                        )) {
                            ForEach(SquelchLevel.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Signal Threshold")
                    } footer: {
                        Text("Higher values require stronger signals before decoding. Off decodes all signals.")
                    }

                    if isRTTY {
                        Section {
                            Picker("Baud Rate", selection: $baudRate) {
                                Text("45.45").tag(45.45)
                                Text("50").tag(50.0)
                                Text("75").tag(75.0)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: baudRate) { _, newValue in
                                viewModel.setChannelBaudRate(newValue, for: channelID)
                            }
                        } header: {
                            Text("Baud Rate")
                        } footer: {
                            Text("45.45 is standard amateur RTTY. 50 baud is common in Europe.")
                        }

                        Section {
                            Toggle("Invert Polarity", isOn: $polarityInverted)
                                .onChange(of: polarityInverted) { _, newValue in
                                    viewModel.setChannelPolarity(inverted: newValue, for: channelID)
                                }
                        } header: {
                            Text("Polarity")
                        } footer: {
                            Text("Swap mark and space tones. Try this if you see garbled text from a station.")
                        }

                        Section {
                            HStack {
                                Text("\(Int(frequencyOffset)) Hz")
                                    .monospacedDigit()
                                    .frame(width: 56, alignment: .trailing)
                                Slider(value: $frequencyOffset, in: -50...50, step: 1)
                                    .onChange(of: frequencyOffset) { _, newValue in
                                        viewModel.setChannelFrequencyOffset(Int(newValue), for: channelID)
                                    }
                                Button("Reset") {
                                    frequencyOffset = 0
                                    viewModel.setChannelFrequencyOffset(0, for: channelID)
                                }
                                .buttonStyle(.borderless)
                                .disabled(frequencyOffset == 0)
                            }
                        } header: {
                            Text("Frequency Offset")
                        } footer: {
                            Text("Fine-tune the receive frequency to improve decoding. AFC handles small drifts automatically.")
                        }
                    }
                }
                .navigationTitle("Channel Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            } else {
                ContentUnavailableView("Channel Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .presentationDetents([isRTTY ? .large : .medium])
        .onAppear {
            // Load current values when sheet appears
            if let channel = channel {
                squelch = Double(channel.squelch)
                baudRate = channel.rttyBaudRate
                polarityInverted = channel.polarityInverted
                frequencyOffset = Double(channel.frequencyOffset)
                print("[ChannelSettings] Loaded settings for channel \(channelID)")
            }
        }
    }

    private func saveSquelch(_ value: Int) {
        if let index = viewModel.channels.firstIndex(where: { $0.id == channelID }) {
            viewModel.channels[index].squelch = value
        }
    }
}

#Preview {
    NavigationStack {
        ChannelListView()
            .environmentObject(ChatViewModel())
    }
}
