// HermesHapticService.swift
//
// Provides haptic feedback patterns for different Hermes events.
// Uses the Apple Watch Taptic Engine for precise, crisp feedback.

import Foundation
import SwiftUI

enum HapticPattern {
    case approval      // Sharp, positive click
    case denial        // Short, negative buzz
    case taskReceived  // Double tap pattern
    case notification  // Gentle pulse
    case heartbeat     // Subtle tick
    case success       // Strong positive feedback
    case error         // Error buzz pattern
    case actionRequired // Urgent: approve/reject needed
    
    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .approval: return .light
        case .denial: return .medium
        case .taskReceived: return .medium
        case .notification: return .light
        case .heartbeat: return .light
        case .success: return .heavy
        case .error: return .heavy
        case .actionRequired: return .heavy
        }
    }
    
    var notificationType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .approval, .success: return .success
        case .denial, .error: return .warning
        case .taskReceived, .notification, .heartbeat: return .success
        case .actionRequired: return .warning
        }
    }
}

class HermesHapticService {
    static let shared = HermesHapticService()
    
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    
    private init() {
        impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        notificationGenerator = UINotificationFeedbackGenerator()
        selectionGenerator = UISelectionFeedbackGenerator()
    }
    
    func play(_ pattern: HapticPattern) {
        // Ensure haptics are enabled
        guard UIAccessibility.isHapticFeedbackEnabled else { return }
        
        switch pattern {
        case .taskReceived:
            // Double tap pattern
            playImpact(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.playImpact(.medium)
            }
            
        case .approval, .success:
            // Crisp, positive feedback
            playImpact(pattern.impactStyle)
            playNotification(pattern.notificationType)
            
        case .denial, .error:
            // Stronger, negative feedback
            playImpact(.heavy)
            playNotification(.warning)
            
        case .notification, .heartbeat:
            // Subtle light feedback
            playImpact(.light)
            
        case .actionRequired:
            // Urgent pattern: heavy impact + warning + selection tick
            playImpact(.heavy)
            playNotification(.warning)
            playSelection()
        }
    }
    
    private func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        impactGenerator?.prepare()
        impactGenerator?.impactOccurred()
    }
    
    private func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator?.prepare()
        notificationGenerator?.notificationOccurred(type)
    }
    
    private func playSelection() {
        selectionGenerator?.prepare()
        selectionGenerator?.selectionChanged()
    }
}
