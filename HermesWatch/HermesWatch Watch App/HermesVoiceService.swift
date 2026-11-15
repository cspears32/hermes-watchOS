// HermesVoiceService.swift
//
// Voice input via SFSpeechRecognizer. watchOS has Speech but no
// AVAudioEngine, so the WatchKit audio tap is the only input source.

import Foundation
import Combine
import WatchKit

class HermesVoiceService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var transcript: String = ""
    @Published var lastError: String?

    var onCommand: ((String) -> Void)?

    // ponytail: SFSpeechRecognizer on watchOS needs an audio source, and watchOS
    // exposes no AVAudioEngine input tap to third-party apps. Voice is not
    // available until the gateway does the transcription or Apple ships a
    // watchOS speech API. Report honestly instead of pretending to listen.
    func startListening() {
        lastError = "Dictation not yet wired: watchOS exposes no audio input tap"
        isListening = false
    }

    func stopListening() {
        isListening = false
    }
}
