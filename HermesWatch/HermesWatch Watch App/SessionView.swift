// SessionView.swift
//
// Full-screen color-coded session status:
//   Green = done / idle
//   Red   = needs approval (approve/deny buttons)
//   Blue  = working

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var sessionService: HermesSessionService

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 12) {
                Text(sessionService.activeSession?.name ?? "No session")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text(statusText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))

                if sessionService.activeSession?.status == .needsApproval {
                    Text("\(sessionService.pendingTasks.count) pending task\(sessionService.pendingTasks.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                if sessionService.activeSession?.status == .needsApproval {
                    HStack(spacing: 20) {
                        denyButton
                        approveButton
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            sessionService.connect()
        }
    }

    private var backgroundColor: Color {
        guard let session = sessionService.activeSession else {
            return Color.green.opacity(0.3)
        }

        switch session.status {
        case .done: return Color.green.opacity(0.3)
        case .needsApproval: return Color.red.opacity(0.3)
        case .working: return Color.blue.opacity(0.3)
        case .idle: return Color.green.opacity(0.3)
        }
    }

    private var statusText: String {
        guard let session = sessionService.activeSession else {
            return "Hermes is idle"
        }

        switch session.status {
        case .done: return "All done"
        case .needsApproval: return "Needs your approval"
        case .working: return "Working..."
        case .idle: return "Hermes is idle"
        }
    }

    private var approveButton: some View {
        Button(action: {
            if let task = sessionService.pendingTasks.first {
                sessionService.approveTask(task)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                Text("Approve")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
        }
    }

    private var denyButton: some View {
        Button(action: {
            if let task = sessionService.pendingTasks.first {
                sessionService.denyTask(task)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                Text("Deny")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
        }
    }
}
