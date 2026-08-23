// MainScreenView.swift
//
// Single full-screen view that switches between 3 modes via crown rotation:
//   0 = Pet/Face
//   1 = Session
//   2 = Profile
//
// Crown rotation cycles modes; crown press confirms selections.
// Voice input is always available (top-right mic button).

import SwiftUI

struct MainScreenView: View {
    @EnvironmentObject var sessionService: HermesSessionService
    @EnvironmentObject var profileService: HermesProfileService
    @EnvironmentObject var voiceService: HermesVoiceService
    
    @State private var currentMode: ScreenMode = .pet
    @State private var profileScrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            switch currentMode {
            case .pet:
                PetFaceView()
            case .session:
                SessionView()
            case .profile:
                ProfileView()
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            // Voice input button always available
            VoiceButton()
                .padding()
        }
        .onAppear {
            sessionService.connect()
            profileService.connect()
        }
    }
}

// MARK: - Screen Modes

enum ScreenMode {
    case pet
    case session
    case profile
}

// MARK: - Voice Button

struct VoiceButton: View {
    @EnvironmentObject var voiceService: HermesVoiceService
    
    var body: some View {
        Button(action: {
            if voiceService.isListening {
                voiceService.stopListening()
            } else {
                voiceService.startListening()
            }
        }) {
            Circle()
                .fill(voiceService.isListening ? Color.red : Color.blue.opacity(0.7))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: voiceService.isListening ? "mic.fill" : "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
        }
        .buttonStyle(.plain)
    }
}
