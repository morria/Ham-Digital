//
//  ContentView.swift
//  DigiModes
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ChatViewModel

    var body: some View {
        AdaptiveContentView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatViewModel())
}
