// HermesWatch Watch App
//
// Three full-screen modes cycled by the Digital Crown:
//   1. Pet/Face  2. Session  3. Profile
// Primary input: voice. Primary output: screen + Taptic Engine.

import SwiftUI

@main
struct HermesWatch_Watch_App: App {

    @StateObject private var sessionService = HermesSessionService()
    @StateObject private var profileService = HermesProfileService()
    @StateObject private var voiceService = HermesVoiceService()
    @StateObject private var taskService: HermesTaskService

    init() {
        let session = HermesSessionService()
        _sessionService = StateObject(wrappedValue: session)
        _taskService = StateObject(wrappedValue: HermesTaskService(sessionService: session))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainScreenView()
                    .environmentObject(sessionService)
                    .environmentObject(profileService)
                    .environmentObject(voiceService)
                    .environmentObject(taskService)
            }
        }
    }
}
