// Config.swift
//
// Gateway endpoint and timing constants. The URL is read from Info.plist so it
// can be changed per build; a real Apple Watch cannot reach "localhost" on the
// Mac, so set it to the Mac's LAN IP (e.g. ws://192.168.0.5:9377).

import Foundation

struct Config {
    static let gatewayURL: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "HermesGatewayURL") as? String,
              !raw.isEmpty else {
            return "ws://127.0.0.1:9377"
        }
        return raw
    }()

    static let heartbeatInterval: TimeInterval = 30
    static let reconnectDelay: TimeInterval = 5
    static let hapticsEnabled = true
}
