# DigiModes - Claude Development Notes

## Project Overview

iOS app for amateur radio digital modes (RTTY, PSK31, Olivia) with an iMessage-style chat interface. Uses external USB soundcard connected between iPhone and radio for audio I/O.

## Build Commands

```bash
# Build Swift Package (DigiModesCore)
cd DigiModes/DigiModesCore && swift build

# Build iOS app (requires Xcode)
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project DigiModes/DigiModes.xcodeproj \
  -scheme DigiModes \
  -destination 'id=5112B080-58D8-4BC7-8AB0-BB34ED2095F6' \
  build

# Run tests (requires Xcode, not just command line tools)
cd DigiModes/DigiModesCore && swift test
```

## Architecture

### Two Codebases
1. **DigiModes/** - iOS app (SwiftUI, requires Xcode)
2. **DigiModesCore/** - Swift Package with core logic (buildable via CLI)

### Key Design Decisions
- iOS 16+ target (uses `ObservableObject`, not `@Observable`)
- Messages-style two-level navigation: Channel List → Channel Detail
- Ham radio conventions: uppercase text, callsigns, RST reports
- Channel = detected signal on a frequency, may have multiple participants

### File Organization

```
DigiModes/
├── DigiModes/                    # iOS App
│   ├── Models/                   # Channel, Message, DigitalMode, Station
│   ├── Views/
│   │   ├── Channels/             # ChannelListView, ChannelDetailView, ChannelRowView
│   │   ├── Chat/                 # MessageBubbleView (deprecated: ChatView, MessageListView, MessageInputView)
│   │   ├── Components/           # ModePickerView
│   │   └── Settings/             # SettingsView with AudioMeterView
│   ├── ViewModels/               # ChatViewModel
│   └── Services/                 # AudioService, ModemService (placeholders)
│
└── DigiModesCore/                # Swift Package
    ├── Sources/DigiModesCore/
    │   ├── Models/               # Same models, with `public` access
    │   └── Codecs/               # BaudotCodec (RTTY)
    └── Tests/
```

## Current State

### Completed
- UI skeleton with channel-based navigation
- Baudot/ITA2 codec with LTRS/FIGS shift handling
- Sample data for development (3 mock channels)
- Swipe-to-reveal timestamps gesture
- Basic transmit simulation

### Next Steps (RTTY Implementation)
1. **Audio capture** - AVAudioEngine setup for external soundcard input
2. **FSK demodulation** - Detect mark/space tones (typically 2125/2295 Hz)
3. **Bit timing** - Sample at correct baud rate (45.45 baud standard)
4. **Baudot decoding** - Use existing BaudotCodec
5. **Channel detection** - Identify distinct signals in passband
6. **FSK modulation** - Generate mark/space tones for transmit

### Technical Notes

**RTTY Parameters (standard)**
- Baud rate: 45.45 baud (22ms per bit)
- Shift: 170 Hz (mark=2125 Hz, space=2295 Hz)
- 5 bits per character (Baudot/ITA2)
- 1 start bit, 1.5 stop bits

**Baudot Codec**
- `BaudotCodec.encode(String) -> [UInt8]` - Text to 5-bit codes
- `BaudotCodec.decode([UInt8]) -> String` - 5-bit codes to text
- Handles LTRS (0x1F) and FIGS (0x1B) shift codes automatically

**iOS Audio Considerations**
- Need `NSMicrophoneUsageDescription` in Info.plist (already added)
- External soundcard appears as standard audio device
- Use AVAudioSession category `.playAndRecord` with `.allowBluetooth` option
- Sample rate: 48000 Hz typical for USB audio

## Conventions

- Ham radio text is UPPERCASE
- Callsigns follow ITU format (e.g., W1AW, K1ABC, N0CALL)
- Common abbreviations: CQ (calling), DE (from), K (over), 73 (best regards)
- RST = Readability, Signal strength, Tone (e.g., 599 = perfect)
