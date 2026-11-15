// HermesTaskService.swift
//
// Task queue fed by the session service's WebSocket stream.

import Foundation
import Combine

class HermesTaskService: ObservableObject {
    @Published var tasks: [HermesTask] = []
    @Published var selectedTask: HermesTask?
    @Published var isProcessing = false

    private let sessionService: HermesSessionService
    private var cancellables = Set<AnyCancellable>()

    init(sessionService: HermesSessionService) {
        self.sessionService = sessionService

        sessionService.$pendingTasks
            .assign(to: &$tasks)
    }

    func approveTask(_ task: HermesTask) {
        guard !isProcessing else { return }
        isProcessing = true

        sessionService.approveTask(task)
        updateLocal(task, status: .approved)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            isProcessing = false
        }
    }

    func denyTask(_ task: HermesTask, reason: String = "") {
        guard !isProcessing else { return }
        isProcessing = true

        sessionService.denyTask(task)
        updateLocal(task, status: .denied)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            isProcessing = false
        }
    }

    func refreshTasks() {
        // ponytail: WebSocket push only; add a REST poll if the gateway drops events.
        sessionService.connect()
    }

    private func updateLocal(_ task: HermesTask, status: TaskStatus) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = status
    }
}
