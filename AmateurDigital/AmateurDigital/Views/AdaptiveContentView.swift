//
//  AdaptiveContentView.swift
//  AmateurDigital
//
//  Adaptive root view that switches between iPhone and iPad layouts
//

import SwiftUI

struct AdaptiveContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            // iPhone: existing NavigationStack
            PhoneNavigationView()
        } else {
            // iPad: new NavigationSplitView
            iPadNavigationView()
        }
    }
}

#Preview("iPhone") {
    AdaptiveContentView()
        .environment(\.horizontalSizeClass, .compact)
        .environmentObject(ChatViewModel())
}

#Preview("iPad") {
    AdaptiveContentView()
        .environment(\.horizontalSizeClass, .regular)
        .environmentObject(ChatViewModel())
}
