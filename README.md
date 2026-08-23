# Hermes WatchOS

Apple Watch companion app for [Hermes Agent](https://hermes-agent.nousresearch.com).

## Design

**Voice input, status output interface.** Three full-screen modes cycled by rotating the Digital Crown:

1. **Pet/Face** — Hermes digital pet with breathing animation + current session name
2. **Session** — Color-coded session status:
   - 🟢 Green background = done / idle
   - 🔴 Red background = needs approval (shows approve/deny buttons)
   - 🔵 Blue background = working / in progress
3. **Profile** — Scrollable list of Hermes profiles; rotate crown to scroll, press crown to select

### Input

- **Primary:** Voice input (top-right mic button, always available)
- **Secondary:** Digital Crown (scroll modes, scroll profiles, select by pressing)
- **Tertiary:** Tap screen (peek at session info on pet face)

### Output

- Full-screen color-coded backgrounds
- Haptic feedback via Taptic Engine (approval buzz, denial tap, notification pulse)
- Digital pet animation (breathing, mood changes)

## Architecture

```
┌─────────────────────────────────────┐
│         Apple Watch (watchOS)        │
│                                      │
│  ┌─────────┐  ┌──────────────────┐  │
│  │ Voice   │  │ Digital Crown    │  │
│  │ Input   │  │ (cycle modes)    │  │
│  │         │  │ (press = confirm)│  │
│  └────┬────┘  └────────┬─────────┘  │
│       │                 │            │
│  ┌────▼─────────────────▼──────────┐│
│  │       WebSocket Client          ││
│  │  ws://localhost:9377/ws/hermes  ││
│  └────────────────┬────────────────┘│
│                   │                  │
│  ┌────────────────▼────────────────┐│
│  │   Taptic Engine (Haptics)      ││
│  └─────────────────────────────────┘│
└─────────────────────┬───────────────┘
                      │ WiFi
                      ▼
┌─────────────────────────────────────┐
│       Hermes Gateway (9377)         │
│  WebSocket endpoint for watch events│
└─────────────────────────────────────┘
```

## Project Structure

```
HermesWatch/
├── HermesWatch Watch App/
│   ├── HermesWatchApp.swift      # Main entry point
│   └── Info.plist
└── HermesWatch WatchKit Extension/
    ├── ExtensionDelegate.swift
    ├── Models/
    │   ├── HermesModels.swift     # Task, Session, Profile, WebSocket events
    │   └── Config.swift
    ├── Services/
    │   ├── HermesWebSocketService.swift  # WebSocket client
    │   ├── HermesSessionService.swift    # Session state management
    │   ├── HermesProfileService.swift    # Profile selection/activation
    │   ├── HermesVoiceService.swift      # SFSpeechRecognizer voice input
    │   └── HermesHapticService.swift     # Taptic Engine wrapper
    └── Views/
        ├── MainScreenView.swift    # Mode router (pet/session/profile)
        ├── PetFaceView.swift       # Digital pet with breathing animation
        ├── SessionView.swift       # Color-coded session status
        └── ProfileView.swift       # Profile selector
```

## Setup

1. Open `HermesWatch.xcodeproj` in Xcode
2. Set your bundle identifier and signing team
3. Update `Config.gatewayURL` to your Hermes Gateway address
4. Build and run on your Apple Watch

## WebSocket Protocol

### Messages from Watch → Gateway

```json
{ "type": "task:approve", "payload": "<task_id>" }
{ "type": "task:deny", "payload": "<task_id>", "reason": "<optional>" }
{ "type": "profile:activate", "payload": "<profile_id>" }
{ "type": "voice:command", "payload": "<transcribed_text>" }
{ "type": "hermes:heartbeat" }
```

### Messages from Gateway → Watch

```json
{ "type": "task:new", ... }
{ "type": "task:updated", ... }
{ "type": "task:completed", "payload": "<task_id>" }
{ "type": "hermes:heartbeat", ... }
{ "type": "hermes:status", ... }
```

## License

MIT
