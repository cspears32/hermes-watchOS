// HermesTaskService.swift
//
// Manages the task queue for Hermes tasks received from the gateway.
// Provides approve/deny functionality with haptic feedback.

import Foundation
import Combine

class HermesTaskService: ObservableObject {
    @Published var tasks: [HermesTask] = []
    @Published var selectedTask: HermesTask?
    @Published var isProcessing = false
    
    private let webSocketService: HermesWebSocketService
    private var cancellables = Set<AnyCancellable>()
    
    init(webSocketService: HermesWebSocketService = HermesWebSocketService()) {
        self.webSocketService = webSocketService
        setupObservation()
    }
    
    private func setupObservation() {
        // Listen for new/updated tasks via WebSocket
        webSocketService.eventPublisher
            .compactMap { event -> HermesTask? in
                switch event {
                case .taskNew(let task): return task
                case .taskUpdated(let task): return task
                default: return nil
                }
            }
            .sink { [weak self] task in
                self?.handleTaskUpdate(task)
            }
            .store(in: &cancellables)
        
        // Listen for completed tasks
        webSocketService.eventPublisher
            .compactMap { event -> String? in
                if case .taskCompleted(let id) = event { return id }
                return nil
            }
            .sink { [weak self] id in
                self?.removeTask(id)
            }
            .store(in: &cancellables)
    }
    
    private func handleTaskUpdate(_ task: HermesTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }
        
        // Haptic feedback for new tasks
        if task.status == .pending {
            HermesHapticService.shared.play(.taskReceived)
        }
    }
    
    private func removeTask(_ id: String) {
        tasks.removeAll { $0.id == id }
    }
    
    func approveTask(_ task: HermesTask) {
        guard !isProcessing else { return }
        isProcessing = true
        
        webSocketService.sendTaskApprove(taskId: task.id)
        HermesHapticService.shared.play(.approval)
        
        // Optimistic update
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = tasks[index]
            updated.status = .approved
            tasks[index] = updated
        }
        
        Task.detached { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                self?.isProcessing = false
            }
        }
    }
    
    func denyTask(_ task: HermesTask, reason: String = "") {
        guard !isProcessing else { return }
        isProcessing = true
        
        webSocketService.sendTaskDeny(taskId: task.id, reason: reason)
        HermesHapticService.shared.play(.denial)
        
        // Optimistic update
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = tasks[index]
            updated.status = .denied
            tasks[index] = updated
        }
        
        Task.detached { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                self?.isProcessing = false
            }
        }
    }
    
    func refreshTasks() {
        // Could implement a REST endpoint call here if WebSocket isn't available
        // For now, rely on WebSocket events
        print("Refresh requested - WebSocket will handle updates")
    }
}
