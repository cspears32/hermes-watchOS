// HermesWebSocketService.swift
//
// WebSocket client for connecting to Hermes Gateway.
// Handles reconnection, heartbeat, and event routing.
// Uses URLSession WebSocket on watchOS.

import Foundation
import Combine

class HermesWebSocketService: ObservableObject {
    @Published var isConnected = false
    @Published var lastError: String?
    @Published var heartbeatCount = 0
    
    private var sessionWebSocketTask: URLSessionWebSocketTask?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var session: URLSession?
    
    private let url: URL
    private let reconnectDelay: TimeInterval = 5
    
    var eventPublisher: AnyPublisher<HermesWebSocketEvent, Never> {
        _eventPublisher.eraseToAnyPublisher()
    }
    private let _eventPublisher = PassthroughSubject<HermesWebSocketEvent, Never>()
    
    init(url: URL = URL(string: Config.gatewayURL + "/ws/hermes/watch")!) {
        self.url = url
    }
    
    func connect() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        session = URLSession(configuration: config)
        sessionWebSocketTask = session?.webSocketTask(with: url)
        sessionWebSocketTask?.resume()
        
        isConnected = true
        startHeartbeat()
        listenForMessages()
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        heartbeatTimer?.invalidate()
        sessionWebSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
    
    func sendTaskApprove(taskId: String) {
        sendMessage(.taskApprove(taskId))
    }
    
    func sendTaskDeny(taskId: String, reason: String) {
        sendMessage(.taskDeny(taskId, reason))
    }
    
    private func sendMessage(_ message: HermesWatchMessage) {
        guard let task = sessionWebSocketTask else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            task.send(data) { [weak self] error in
                if let error = error {
                    print("Failed to send message: \(error)")
                    self?.lastError = error.localizedDescription
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
            lastError = error.localizedDescription
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: Config.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.heartbeatCount += 1
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        let message = HermesWatchMessage.heartbeat
        sendMessage(message)
    }
    
    private func attemptReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("Reconnecting to Hermes Gateway...")
            self.connect()
        }
    }
    
    private func listenForMessages() {
        guard let task = sessionWebSocketTask else { return }
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleWebSocketMessage(message)
                // Continue listening
                self.listenForMessages()
            case .failure(let error):
                self.isConnected = false
                self.lastError = error.localizedDescription
                self.attemptReconnect()
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            handleDataMessage(data)
        case .string(let string):
            if let data = string.data(using: .utf8) {
                handleDataMessage(data)
            }
        @unknown default:
            break
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        do {
            let event = try JSONDecoder().decode(HermesWebSocketEvent.self, from: data)
            _eventPublisher.send(event)
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
}
