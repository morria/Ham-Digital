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
        .navigationDestination(for: Channel.self) { channel in
            ChannelDetailView(channel: channel)
        }
        .sheet(item: $channelForSettings) { channel in
            ChannelSettingsSheet(channel: channel, viewModel: viewModel)
        }
    }
}

// MARK: - Channel Settings Sheet

struct ChannelSettingsSheet: View {
    let channel: Channel
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var squelch: Double

    init(channel: Channel, viewModel: ChatViewModel) {
        self.channel = channel
        self.viewModel = viewModel
        self._squelch = State(initialValue: Double(channel.squelch))
    }

    var body: some View {
        NavigationStack {
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Squelch")
                            Spacer()
                            Text("\(Int(squelch))")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $squelch, in: 0...100, step: 1)
                    }
                } header: {
                    Text("Signal Threshold")
                } footer: {
                    Text("Higher values require stronger signals before decoding. Set to 0 to decode all signals.")
                }
            }
            .navigationTitle("Channel Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveSettings() {
        if let index = viewModel.channels.firstIndex(where: { $0.id == channel.id }) {
            viewModel.channels[index].squelch = Int(squelch)
        }
    }
}

#Preview {
    NavigationStack {
        ChannelListView()
            .environmentObject(ChatViewModel())
    }
}
