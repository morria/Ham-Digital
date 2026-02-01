//
//  ChannelListView.swift
//  DigiModes
//
//  List of all detected channels with navigation to detail
//

import SwiftUI

struct ChannelListView: View {
    @EnvironmentObject var viewModel: ChatViewModel

    var body: some View {
        List {
            ForEach(viewModel.channels) { channel in
                NavigationLink(value: channel) {
                    ChannelRowView(channel: channel)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Channel.self) { channel in
            ChannelDetailView(channel: channel)
        }
    }
}

#Preview {
    NavigationStack {
        ChannelListView()
            .environmentObject(ChatViewModel())
            .navigationTitle("Channels")
    }
}
