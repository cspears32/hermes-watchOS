// Config.swift
//
// Configuration constants for Hermes WatchOS app.
// Update gatewayURL to match your Hermes Gateway endpoint.

import Foundation

struct Config {
    // Hermes Gateway WebSocket endpoint
    static let gatewayURL = "ws://localhost:9377"
    
    // WebSocket heartbeat interval (seconds)
    static let heartbeatInterval: TimeInterval = 30
    
    // Reconnection delay after connection loss (seconds)
    static let reconnectDelay: TimeInterval = 5
    
    // Maximum reconnection attempts (nil = infinite)
    static let maxReconnectAttempts: Int? = nil
    
    // Task refresh interval (seconds) - fallback if WebSocket fails
    static let taskRefreshInterval: TimeInterval = 60
    
    // Petdex animation settings
    static let petdexAnimationDuration: TimeInterval = 2.0
    static let petdexFrameRate: Int = 10
    
    // Haptic feedback enabled
    static let hapticsEnabled = true
    
    // Enable debug logging
    static let debugMode = false
}
