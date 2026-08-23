// HermesWatch Watch App
//
// Main entry point. The watch shows one of three full-screen modes,
// cycled by rotating the Digital Crown:
//   1. Pet/Face — Hermes digital pet + quick status
//   2. Session — color-coded session status (green=done, red=needs approval, blue=working)
//   3. Profile — rotate to select a Hermes profile, press crown to confirm
//
// Primary input: voice (SFSpeechRecognizer).
// Primary output: screen + Taptic Engine haptics.

import SwiftUI

@main
struct HermesWatch_Watch_App: App {
    
    @StateObject private var sessionService = HermesSessionService()
    @StateObject private var profileService = HermesProfileService()
    @StateObject private var voiceService = HermesVoiceService()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainScreenView()
                    .environmentObject(sessionService)
                    .environmentObject(profileService)
                    .environmentObject(voiceService)
            }
        }
    }
}
