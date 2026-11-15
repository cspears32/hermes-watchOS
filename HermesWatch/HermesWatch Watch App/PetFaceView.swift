// PetFaceView.swift
//
// The Hermes digital pet. Breathing animation, tap to peek at session status.

import SwiftUI

struct PetFaceView: View {
    @EnvironmentObject var sessionService: HermesSessionService
    @State private var breathPhase: Double = 0

    private var petMood: PetMood {
        guard let status = sessionService.activeSession?.status else { return .idle }
        switch status {
        case .idle: return .idle
        case .working: return .thinking
        case .needsApproval: return .alert
        case .done: return .happy
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                PetFace(mood: petMood)
                    .scaleEffect(1.0 + breathPhase * 0.08)

                statusLabel
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathPhase = 1
            }
        }
        .onTapGesture {
            guard let status = sessionService.activeSession?.status else { return }
            switch status {
            case .needsApproval: HermesHapticService.shared.play(.denial)
            case .working: HermesHapticService.shared.play(.notification)
            case .done: HermesHapticService.shared.play(.approval)
            case .idle: break
            }
        }
    }

    private var statusLabel: some View {
        Text(sessionService.activeSession?.name ?? "Hermes is idle")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(sessionService.activeSession == nil ? .secondary : .white)
    }
}

// MARK: - Pet Face

struct PetFace: View {
    let mood: PetMood

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [mood.color.opacity(0.9), mood.color.opacity(0.6)],
                        center: .center,
                        startRadius: 30,
                        endRadius: 60
                    )
                )
                .frame(width: 80, height: 80)

            VStack(spacing: 6) {
                HStack(spacing: 16) {
                    PetEye(isBlinking: mood == .sleepy)
                    PetEye(isBlinking: mood == .sleepy)
                }

                Text(mouthGlyph)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
    }

    private var mouthGlyph: String {
        switch mood {
        case .happy, .idle: return "\u{25DC}\u{203F}\u{25DC}"
        case .alert: return "o_o"
        case .sleepy: return "z_z"
        case .thinking: return "\u{25D5}\u{203F}\u{25D5}"
        }
    }
}

// MARK: - Eye

struct PetEye: View {
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
    case idle, happy, alert, sleepy, thinking

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
