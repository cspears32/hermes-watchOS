// PetFaceView.swift
//
// The Hermes digital pet / face.
// Simple breathing animation with a small status indicator.
// Tap to peek at session info; voice input always available via top button.

import SwiftUI

struct PetFaceView: View {
    @EnvironmentObject var sessionService: HermesSessionService
    @State private var breathPhase: Double = 0
    @State private var petMood: PetMood = .idle
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Pet face
                PetFace(mood: petMood, breathPhase: breathPhase)
                    .scaleEffect(1.0 + breathPhase * 0.08)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathPhase)
                
                // Status indicator
                statusLabel
            }
        }
        .onAppear {
            startBreathing()
        }
        .onTapGesture {
            // Quick peek: flash current session status
            if let session = sessionService.activeSession {
                switch session.status {
                case .needsApproval:
                    HermesHapticService.shared.play(.denial)
                case .working:
                    HermesHapticService.shared.play(.notification)
                case .done:
                    HermesHapticService.shared.play(.approval)
                }
            }
        }
    }
    
    private var statusLabel: some View {
        Group {
            if let session = sessionService.activeSession {
                Text(session.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Text("Hermes is idle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func startBreathing() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathPhase = 1
        }
    }
}

// MARK: - Pet Face

struct PetFace: View {
    let mood: PetMood
    let breathPhase: Double
    
    var body: some View {
        ZStack {
            // Head (circle)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            mood.color.opacity(0.9),
                            mood.color.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 60
                    )
                )
                .frame(width: 80, height: 80)
            
            // Eyes
            VStack(spacing: 6) {
                HStack(spacing: 16) {
                    Eye(isBlinking: mood == .sleepy)
                    Eye(isBlinking: mood == .sleepy)
                }
                
                // Mouth
                mouthView
            }
        }
    }
    
    private var mouthView: some View {
        Group {
            switch mood {
            case .happy, .idle:
                Text("◠‿◠")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            case .alert:
                Text("⊙_⊙")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            case .sleepy:
                Text("≋")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            case .thinking:
                Text("◕‿◕")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Eye

struct Eye: View {
    let isBlinking: Bool
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 10, height: isBlinking ? 2 : 10)
            .animation(.easeInOut(duration: 0.15), value: isBlinking)
    }
}

// MARK: - Pet Mood

enum PetMood: String {
    case idle
    case happy
    case alert
    case sleepy
    case thinking
    
    var color: Color {
        switch self {
        case .idle: return Color.blue.opacity(0.8)
        case .happy: return Color.green.opacity(0.8)
        case .alert: return Color.orange.opacity(0.8)
        case .sleepy: return Color.purple.opacity(0.6)
        case .thinking: return Color.pink.opacity(0.7)
        }
    }
}

// MARK: - Preview

struct PetFaceView_Previews: PreviewProvider {
    static var previews: some View {
        PetFaceView()
            .environmentObject(HermesSessionService())
            .previewDisplayName("Pet Face")
    }
}
