// HermesVoiceService.swift
//
// Voice input service using SFSpeechRecognizer.
// Primary input method for Hermes interactions.
// Transcribed text is sent to the gateway as a voice command.

import Foundation
import Combine
#if canImport(Speech)
import Speech
#endif

class HermesVoiceService: ObservableObject {
    @Published var isListening = false
    @Published var transcript: String = ""
    @Published var lastError: String?
    
    #if canImport(Speech)
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        speechRecognizer = SFSpeechRecognizer()
    }
    
    func startListening() {
        guard speechRecognizer?.isAvailable ?? false else {
            lastError = "Speech recognition not available"
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { _ in }
        
        guard let recognizer = speechRecognizer else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        do {
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self.sendCommand(self.transcript)
                        self.transcript = ""
                        self.stopListening()
                    }
                }
                
                if error != nil {
                    self.stopListening()
                }
            }
            
            isListening = true
            HermesHapticService.shared.play(.notification)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    private func sendCommand(_ command: String) {
        let message = HermesWatchMessage.voiceCommand(command)
        // Send via WebSocket (would need access to WebSocket service)
        print("Voice command: \(command)")
    }
    #else
    // Speech framework not available on watchOS
    func startListening() {
        lastError = "Speech recognition not available on this device"
    }
    
    func stopListening() {}
    #endif
}
