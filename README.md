# Hermes WatchOS

A companion app for [Hermes Agent](https://hermes-agent.nousresearch.com) that runs on Apple Watch (watchOS). Provides quick access to task approvals, status monitoring, and petdex animations from your wrist.

## Features

- **Task Queue** — View pending Hermes tasks with approve/deny actions
- **Petdex Viewer** — Watch Hermes pet animations on your watch
- **Quick Responses** — Swipe to send canned replies
- **Status Screen** — Hermes heartbeat, connected devices, queue depth
- **Haptic Feedback** — Custom patterns for approvals, denials, notifications

## Architecture

```
┌─────────────────────────────────────────┐
│           Apple Watch (watchOS)          │
│                                          │
│  ┌──────────┐  ┌────────────────────┐   │
│  │ SwiftUI  │  │ Hermes Watch App   │   │
│  │ UI Layer │  │ - Approve/Deny UI  │   │
│  │ - Petdex │  │ - Notification UI  │   │
│  │ - Status │  │ - Quick responses  │   │
│  └────┬─────┘  └────────┬───────────┘   │
│       │                 │               │
│  ┌────▼─────────────────▼───────────┐   │
│  │        WebSocket Client          │   │
│  │  (connects to Hermes Gateway)    │   │
│  └────────────────┬─────────────────┘   │
│                   │                     │
│  ┌────────────────▼─────────────────┐   │
│  │     Taptic Engine (Haptics)      │   │
│  │     Haptic feedback patterns     │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
                │ WiFi / BLE
                ▼
┌─────────────────────────────────────────┐
│           Hermes Gateway (9377)          │
│  WebSocket endpoint for device events   │
└─────────────────────────────────────────┘
```

## Getting Started

### Requirements

- macOS 14+ (Sonoma) with Xcode 15+
- An Apple Watch (Series 4 or later recommended)
- Paired iPhone running iOS 17+
- Hermes Agent running locally with WebSocket support

### Setup

1. Open `HermesWatch.xcodeproj` in Xcode
2. Set your development team (signing) in project settings
3. Update the WebSocket endpoint URL in `HermesWebSocketService.swift`
4. Build and run on your Apple Watch

### Configuration

Edit `Config.swift` to set:

```swift
struct Config {
    static let gatewayURL = "ws://localhost:9377"
    static let heartbeatInterval: TimeInterval = 30
    static let reconnectDelay: TimeInterval = 5
}
```

## Project Structure

```
HermesWatch/
├── HermesWatch Watch App/          # WatchOS app (main entry point)
│   ├── HermesWatchApp.swift        # App entry point
│   └── ContentView.swift           # Root view
├── HermesWatch WatchKit Extension/ # Extension with logic
│   ├── HermesWebSocketService.swift  # WebSocket client
│   ├── HermesTaskService.swift       # Task management
│   ├── HermesHapticService.swift     # Haptic feedback
│   └── HermesModels.swift            # Data models
├── HermesWatch WatchExtension/       # Glance/Complication
└── HermesWatch WatchApp/             # Standalone watch app (if needed)
```

## Hermes Gateway Integration

The watch connects to Hermes via WebSocket. Expected endpoints:

```
ws://<gateway-host>:9377/ws/hermes/watch
```

### Events

- **`task:new`** — New task received
- **`task:updated`** — Task status changed
- **`task:completed`** — Task finished
- **`hermes:heartbeat`** — Gateway health check
- **`hermes:status`** — System status update

### Actions

The watch sends:

```json
{
  "type": "task:approve",
  "taskId": "task-123"
}
```

```json
{
  "type": "task:deny",
  "taskId": "task-123",
  "reason": "User declined"
}
```

## Development

### Building

```bash
# Open in Xcode
open HermesWatch.xcodeproj

# Or build from command line
xcodebuild -project HermesWatch.xcodeproj \
  -scheme HermesWatch\ Watch\ App \
  -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 2 (49mm),OS=latest' \
  build
```

### Testing

- Use Apple Watch Simulator for UI testing
- Test WebSocket connections with a local Hermes instance
- Verify haptic feedback on real device

## License

MIT
