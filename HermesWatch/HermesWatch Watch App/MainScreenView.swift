// MainScreenView.swift
//
// Full-screen switch between Pet / Session / Profile via crown rotation.

import SwiftUI

struct MainScreenView: View {
    @EnvironmentObject var sessionService: HermesSessionService
    @EnvironmentObject var profileService: HermesProfileService
    @EnvironmentObject var voiceService: HermesVoiceService
    @EnvironmentObject var taskService: HermesTaskService

    @State private var currentMode: ScreenMode = .pet

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
            VoiceButton()
                .padding()
        }
        .focusable()
        .digitalCrownRotation(
            detent: $crownDetent,
            from: 0, through: 2, by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownDetent) { _, newValue in
            currentMode = ScreenMode(rawValue: Int(newValue.rounded())) ?? .pet
        }
        .onAppear {
            voiceService.onCommand = { command in
                sessionService.sendVoiceCommand(command)
            }
            sessionService.connect()
            profileService.connect()
        }
    }

    @State private var crownDetent: Double = 0
}

// MARK: - Screen Modes

enum ScreenMode: Int {
    case pet = 0
    case session = 1
    case profile = 2
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
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
        }
        .buttonStyle(.plain)
    }
}
