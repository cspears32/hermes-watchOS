// HermesSessionService.swift
//
// Manages Hermes sessions: connects to gateway, monitors session state,
// and provides approve/deny actions.
//
// Session states:
//   - idle: Hermes is waiting
//   - working: Hermes is processing
//   - needsApproval: needs user decision (shows red screen)
//   - done: all tasks completed (shows green screen)

import Foundation
import Combine

enum SessionStatus: String, Codable {
    case idle
    case working
    case needsApproval = "needs_approval"
    case done
}

class HermesSessionService: ObservableObject {
    @Published var activeSession: HermesSession?
    @Published var pendingTasks: [HermesTask] = []
    @Published var isConnected = false
    @Published var lastError: String?
    
    private var websocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    
    private let url: URL
    
    init(url: URL = URL(string: Config.gatewayURL + "/ws/hermes/watch")!) {
        self.url = url
    }
    
    func connect() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        
        session = URLSession(configuration: config)
        websocket = session?.webSocketTask(with: url)
        websocket?.resume()
        
        isConnected = true
        startHeartbeat()
        listenForMessages()
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        heartbeatTimer?.invalidate()
        websocket?.cancel(with: .normalClosure, reason: nil)
    }
    
    func approveTask(_ task: HermesTask) {
        guard isConnected else { return }
        
        let message = HermesWatchMessage.taskApprove(task.id)
        sendMessage(message)
        HermesHapticService.shared.play(.approval)
        
        // Optimistic update
        if let index = pendingTasks.firstIndex(where: { $0.id == task.id }) {
            pendingTasks.remove(at: index)
        }
    }
    
    func denyTask(_ task: HermesTask) {
        guard isConnected else { return }
        
        let message = HermesWatchMessage.taskDeny(task.id, "")
        sendMessage(message)
        HermesHapticService.shared.play(.denial)
        
        if let index = pendingTasks.firstIndex(where: { $0.id == task.id }) {
            pendingTasks.remove(at: index)
        }
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
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: Config.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendMessage(.heartbeat)
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
            // Try as WebSocket event
            let event = try JSONDecoder().decode(HermesWebSocketEvent.self, from: data)
            switch event {
            case .taskNew(let task):
                if !pendingTasks.contains(where: { $0.id == task.id }) {
                    pendingTasks.append(task)
                    HermesHapticService.shared.play(.taskReceived)
                }
                // Update active session if it has pending tasks
                if var session = activeSession {
                    session.status = .needsApproval
                    activeSession = session
                }
            case .taskUpdated(let task):
                if let index = pendingTasks.firstIndex(where: { $0.id == task.id }) {
                    pendingTasks[index] = task
                }
            case .taskCompleted(let id):
                pendingTasks.removeAll { $0.id == id }
                if var session = activeSession {
                    session.status = .done
                    activeSession = session
                }
            case .hermesStatus(let status):
                // Could update session from status
                break
            case .hermesHeartbeat:
                break
            }
        } catch {
            print("WebSocket decode error: \(error)")
        }
    }
}
