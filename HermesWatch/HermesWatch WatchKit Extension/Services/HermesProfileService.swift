// HermesProfileService.swift
//
// Manages Hermes profiles. Fetches available profiles from the gateway,
// allows the user to select one via crown rotation, and activates it.

import Foundation
import Combine

class HermesProfileService: ObservableObject {
    @Published var profiles: [HermesProfile] = []
    @Published var selectedProfile: HermesProfile?
    @Published var isConnected = false
    @Published var lastError: String?
    
    private var websocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectTimer: Timer?
    
    private let url: URL
    
    init(url: URL = URL(string: Config.gatewayURL + "/ws/hermes/watch")!) {
        self.url = url
    }
    
    func connect() {
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
        websocket = session?.webSocketTask(with: url)
        websocket?.resume()
        
        isConnected = true
        listenForMessages()
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        websocket?.cancel(with: .normalClosure, reason: nil)
    }
    
    func activateProfile(_ profile: HermesProfile) {
        guard isConnected else { return }
        
        let message = HermesWatchMessage.profileActivate(profile.id)
        sendMessage(message)
        selectedProfile = profile
        HermesHapticService.shared.play(.success)
    }
    
    private func sendMessage(_ message: HermesWatchMessage) {
        guard let task = websocket else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            task.send(data) { _ in }
        } catch {
            print("Failed to send: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    private func attemptReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: Config.reconnectDelay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func listenForMessages() {
        guard let task = websocket else { return }
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.listenForMessages()
            case .failure(let error):
                self.isConnected = false
                self.lastError = error.localizedDescription
                self.attemptReconnect()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            handleData(data)
        case .string(let string):
            if let data = string.data(using: .utf8) {
                handleData(data)
            }
        @unknown default: break
        }
    }
    
    private func handleData(_ data: Data) {
        do {
            let event = try JSONDecoder().decode(HermesWebSocketEvent.self, from: data)
            switch event {
            case .hermesStatus(let status):
                // Could update profiles from status
                break
            case .hermesHeartbeat:
                break
            case .taskNew, .taskUpdated, .taskCompleted:
                // Not profile-related
                break
            }
        } catch {
            print("Profile decode error: \(error)")
        }
    }
}
