//
//  AmateurDigitalApp.swift
//  Amateur Digital
//
//  Amateur Radio Digital Modes Chat Application
//

import SwiftUI

@main
struct AmateurDigitalApp: App {
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(chatViewModel)
        }
    }
}
