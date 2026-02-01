//
//  ChatViewModel.swift
//  DigiModes
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var channels: [Channel] = []
    @Published var selectedMode: DigitalMode = .rtty
    @Published var isTransmitting: Bool = false

    // MARK: - Services (Placeholders)
    private var audioService: AudioService?
    private var modemService: ModemService?

    // MARK: - Initialization
    init() {
        #if DEBUG
        loadSampleChannels()
        #endif
    }

    // MARK: - Public Methods

    func sendMessage(_ content: String, toChannel channel: Channel) {
        guard let index = channels.firstIndex(where: { $0.id == channel.id }) else { return }

        let message = Message(
            content: content.uppercased(),
            direction: .sent,
            mode: selectedMode,
            callsign: Station.myStation.callsign
        )

        channels[index].messages.append(message)
        channels[index].lastActivity = Date()

        simulateTransmission(forChannelAt: index)
    }

    func clearChannel(_ channel: Channel) {
        guard let index = channels.firstIndex(where: { $0.id == channel.id }) else { return }
        channels[index].messages.removeAll()
    }

    // MARK: - Private Methods (Simulation for Development)

    private func loadSampleChannels() {
        channels = Channel.sampleChannels
    }

    private func simulateTransmission(forChannelAt index: Int) {
        isTransmitting = true

        let duration = Double(channels[index].messages.last?.content.count ?? 10) * 0.05

        Task {
            try? await Task.sleep(for: .seconds(max(duration, 1.0)))
            isTransmitting = false

            simulateReceivedMessage(forChannelAt: index)
        }
    }

    private func simulateReceivedMessage(forChannelAt index: Int) {
        Task {
            try? await Task.sleep(for: .seconds(2))

            guard index < channels.count else { return }

            let callsign = channels[index].callsign ?? "W1AW"
            let responses = [
                "R R TU 73 DE \(callsign) K",
                "QSL QSL 73 GL",
                "FB FB CUL 73",
                "R TU FER QSO 73 DE \(callsign) K"
            ]

            let randomResponse = responses.randomElement() ?? "73"
            let message = Message(
                content: randomResponse,
                direction: .received,
                mode: selectedMode,
                callsign: callsign
            )

            channels[index].messages.append(message)
            channels[index].lastActivity = Date()
        }
    }
}
