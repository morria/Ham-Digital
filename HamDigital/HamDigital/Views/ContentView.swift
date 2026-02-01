//
//  ContentView.swift
//  DigiModes
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ChatViewModel

    var body: some View {
        ModeSelectionView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatViewModel())
}
