// TaskQueueView.swift
//
// Pending Hermes tasks with approve/deny actions.

import SwiftUI

struct TaskQueueView: View {
    @EnvironmentObject var taskService: HermesTaskService
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingDenyAlert = false
    @State private var selectedTask: HermesTask?
    @State private var denyReason = ""

    var body: some View {
        Group {
            if taskService.isProcessing {
                ProgressView("Processing...")
            } else if taskService.tasks.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(taskService.tasks) { task in
                            TaskCardView(task: task)
                                .onTapGesture {
                                    taskService.approveTask(task)
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 50)
                                        .onEnded { value in
                                            if value.translation.width < -50 {
                                                showDenyAlert(for: task)
                                            }
                                        }
                                )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            if scenePhase == .active {
                taskService.refreshTasks()
            }
        }
        .alert("Deny Task?", isPresented: $showingDenyAlert) {
            TextField("Reason (optional)", text: $denyReason)
            Button("Cancel", role: .cancel) {}
            Button("Deny", role: .destructive) {
                if let task = selectedTask {
                    taskService.denyTask(task, reason: denyReason)
                }
            }
        } message: {
            Text("Why are you denying this?")
        }
    }

    private func showDenyAlert(for task: HermesTask) {
        selectedTask = task
        showingDenyAlert = true
    }
}

// MARK: - Task Card

struct TaskCardView: View {
    let task: HermesTask
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                priorityDot
                Text(task.shortTitle)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                Spacer()
                Text(task.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if task.description.count > 40 {
                Text(String(task.description.prefix(40)) + "...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
        )
    }

    private var priorityDot: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 6, height: 6)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("All caught up!")
                .font(.system(size: 16, weight: .semibold))

            Text("No pending tasks")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}
