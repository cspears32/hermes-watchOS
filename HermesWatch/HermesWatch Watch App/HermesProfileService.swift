// HermesProfileService.swift
//
// Manages Hermes profiles. Select via crown/tap, then activate.

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
    private var isListening = false

    private let url: URL

    init(url: URL = URL(string: Config.gatewayURL + "/ws/hermes/watch")!) {
        self.url = url
    }

    func connect() {
        guard websocket == nil else { return }

        session = URLSession(configuration: .default)
        websocket = session?.webSocketTask(with: url)
        websocket?.resume()

        isConnected = true
        listenForMessages()
    }

    func disconnect() {
        reconnectTimer?.invalidate()
        websocket?.cancel(with: .normalClosure, reason: nil)
        websocket = nil
        isConnected = false
        isListening = false
    }

    func activateProfile(_ profile: HermesProfile) {
        guard isConnected else { return }

        sendMessage(.profileActivate(profile.id))
        selectedProfile = profile
        HermesHapticService.shared.play(.success)
    }

    private func sendMessage(_ message: HermesWatchMessage) {
        guard let task = websocket else { return }

        do {
            guard let json = String(data: try JSONEncoder().encode(message), encoding: .utf8) else { return }
            task.send(.string(json)) { [weak self] error in
                if let error = error {
                    self?.lastError = error.localizedDescription
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func attemptReconnect() {
        websocket = nil
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: Config.reconnectDelay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }

    private func listenForMessages() {
        guard let task = websocket, !isListening else { return }
        isListening = true

        task.receive { [weak self] result in
            guard let self = self else { return }
            self.isListening = false

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
            case .hermesStatus, .hermesHeartbeat, .taskNew, .taskUpdated, .taskCompleted:
                break
            }
        } catch {
            lastError = "Profile decode error: \(error)"
        }
    }
}
