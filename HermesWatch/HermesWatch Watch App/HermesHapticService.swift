// HermesHapticService.swift
//
// Haptic feedback patterns via the WatchKit Taptic Engine.
// UIImpactFeedbackGenerator does not exist on watchOS, so WKInterfaceDevice
// haptic types are the correct primitive here.

import Foundation
import WatchKit

enum HapticPattern {
    case approval
    case denial
    case taskReceived
    case notification
    case heartbeat
    case success
    case error
    case actionRequired
}

class HermesHapticService {
    static let shared = HermesHapticService()

    private let device = WKInterfaceDevice.current()

    private init() {}

    func play(_ pattern: HapticPattern) {
        guard Config.hapticsEnabled else { return }

        switch pattern {
        case .taskReceived:
            device.play(.click)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [device] in
                device.play(.click)
            }
        case .approval:
            device.play(.success)
        case .success:
            device.play(.success)
            device.play(.click)
        case .denial, .error:
            device.play(.failure)
        case .notification:
            device.play(.directionDown)
        case .heartbeat:
            device.play(.click)
        case .actionRequired:
            device.play(.failure)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [device] in
                device.play(.failure)
            }
        }
    }
}
