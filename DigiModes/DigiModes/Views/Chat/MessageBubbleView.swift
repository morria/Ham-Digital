//
//  MessageBubbleView.swift
//  DigiModes
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let revealedTimestamp: Bool

    private var isReceived: Bool {
        message.direction == .received
    }

    private var bubbleColor: Color {
        isReceived ? Color(.systemGray5) : Color.blue
    }

    private var textColor: Color {
        isReceived ? Color.primary : Color.white
    }

    var body: some View {
        HStack(spacing: 8) {
            // Timestamp (revealed on swipe)
            if revealedTimestamp {
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }

            if !isReceived && !revealedTimestamp {
                Spacer(minLength: 60)
            }

            // Message bubble
            Text(message.content)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleColor)
                .foregroundColor(textColor)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if isReceived && !revealedTimestamp {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(message: Message.sampleMessages[0], revealedTimestamp: false)
        MessageBubbleView(message: Message.sampleMessages[1], revealedTimestamp: false)

        Divider()
        Text("With timestamps revealed:").font(.caption)

        MessageBubbleView(message: Message.sampleMessages[0], revealedTimestamp: true)
        MessageBubbleView(message: Message.sampleMessages[1], revealedTimestamp: true)
    }
    .padding()
}
