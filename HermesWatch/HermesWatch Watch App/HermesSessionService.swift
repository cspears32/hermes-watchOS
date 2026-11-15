// HermesSessionService.swift
//
// Manages Hermes sessions: connects to gateway, monitors session state,
// and provides approve/deny actions.

import Foundation
import Combine

class HermesSessionService: ObservableObject {
    @Published var activeSession: HermesSession?
    @Published var pendingTasks: [HermesTask] = []
    @Published var isConnected = false
    @Published var lastError: String?

    private var websocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var isListening = false

    private let url: URL

    init(url: URL = URL(string: Config.gatewayURL + "/ws/hermes/watch")!) {
        self.url = url
    }

    func connect() {
        guard websocket == nil else { return }

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
        websocket = nil
        isConnected = false
        isListening = false
    }

    func approveTask(_ task: HermesTask) {
        guard isConnected else { return }

        sendMessage(.taskApprove(task.id))
        HermesHapticService.shared.play(.approval)

        pendingTasks.removeAll { $0.id == task.id }
    }

    func sendVoiceCommand(_ command: String) {
        sendMessage(.voiceCommand(command))
    }

    func denyTask(_ task: HermesTask) {
        guard isConnected else { return }

        sendMessage(HermesWatchMessage.taskDeny(task.id, ""))
        HermesHapticService.shared.play(.denial)

        pendingTasks.removeAll { $0.id == task.id }
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

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: Config.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendMessage(.heartbeat)
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
            case .taskNew(let task):
                if !pendingTasks.contains(where: { $0.id == task.id }) {
                    pendingTasks.append(task)
                    HermesHapticService.shared.play(.actionRequired)
                }
                if var session = activeSession {
                    session.status = .needsApproval
                    activeSession = session
                } else {
                    activeSession = HermesSession(id: "live", name: "Hermes", status: .needsApproval,
                                                  profile: nil, startedAt: Date(), completedAt: nil)
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
                var session = activeSession ?? HermesSession(id: "live", name: "Hermes", status: .idle,
                                                             profile: nil, startedAt: Date(), completedAt: nil)
                session.status = status.tasksPending > 0 ? .working : .done
                activeSession = session
            case .hermesHeartbeat:
                break
            }
        } catch {
            lastError = "WebSocket decode error: \(error)"
        }
    }
}
