// PetdexView.swift
//
// Renders Hermes pet animations on the Apple Watch.
// Displays a simple animated pet with breathing/idle animations.
// Can be extended to decode and render petdex JSON animations.

import SwiftUI

struct PetdexView: View {
    @State private var petState: PetState = .idle
    @State private var animationPhase: Double = 0.0
    @State private var petMood: PetMood = .happy
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 120
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Pet display
            VStack(spacing: 8) {
                PetDisplay(petState: petState, mood: petMood)
                    .scaleEffect(1.0 + animationPhase * 0.05)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationPhase)
                
                Text(petMood.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                // Pet controls
                HStack(spacing: 20) {
                    Button(action: { petMood = .happy }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.pink)
                    }
                    
                    Button(action: { petMood = .playful }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: { petMood = .sleepy }) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .onAppear {
            startPetAnimation()
        }
    }
    
    private func startPetAnimation() {
        // Animate the breathing effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationPhase = 1.0
        }
        
        // Cycle through pet states
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            let states: [PetState] = [.idle, .bored, .excited, .sleepy]
            petState = states.randomElement() ?? .idle
        }
    }
}

// MARK: - Pet Display

struct PetDisplay: View {
    let petState: PetState
    let mood: PetMood
    
    var body: some View {
        ZStack {
            // Pet body (circle)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
            
            // Pet eyes
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Eye(isBlinking: petState == .sleepy)
                    Eye(isBlinking: petState == .sleepy)
                }
                
                // Pet mouth
                mouthView
            }
        }
    }
    
    private var mouthView: some View {
        Group {
            switch petState {
            case .happy, .excited:
                Image(systemName: "smiley.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
            case .sleepy:
                Image(systemName: "zzz")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            case .bored:
                Image(systemName: "minus.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            default:
                Image(systemName: "smiley.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct Eye: View {
    let isBlinking: Bool
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: isBlinking ? 2 : 8)
            .animation(.easeInOut(duration: 0.2), value: isBlinking)
    }
}

// MARK: - Pet State

enum PetState: String {
    case idle
    case happy
    case bored
    case excited
    case sleepy
}

// MARK: - Pet Mood

enum PetMood: String {
    case happy
    case playful
    case sleepy
    
    var displayName: String {
        switch self {
        case .happy: return "Happy"
        case .playful: return "Playful"
        case .sleepy: return "Sleepy"
        }
    }
}

// MARK: - Preview

struct PetdexView_Previews: PreviewProvider {
    static var previews: some View {
        PetdexView()
            .previewDisplayName("Petdex")
    }
}
