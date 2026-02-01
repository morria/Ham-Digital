//
//  DigiModesApp.swift
//  DigiModes
//
//  Amateur Radio Digital Modes Chat Application
//

import SwiftUI

@main
struct DigiModesApp: App {
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatViewModel)
        }
    }
}
