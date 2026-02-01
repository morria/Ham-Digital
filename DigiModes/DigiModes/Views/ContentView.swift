//
//  ContentView.swift
//  DigiModes
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ChannelListView()
            .navigationTitle("Channels")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ModePickerView()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatViewModel())
}
