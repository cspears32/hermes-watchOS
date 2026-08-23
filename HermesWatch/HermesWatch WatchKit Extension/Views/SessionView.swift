// SessionView.swift
//
// Shows the current Hermes session with a full-screen color-coded background:
//   Green = done / idle
//   Red   = needs approval (with approve/deny buttons)
//   Blue  = working / in progress
//
// Tap to approve, swipe left to deny.

import SwiftUI

struct SessionView: View {
    @EnvironmentObject var sessionService: HermesSessionService
    
    var body: some View {
        ZStack {
            // Full-screen background with session color
            backgroundColor.ignoresSafeArea()
            
            // Content overlay
            VStack(spacing: 12) {
                // Session name
                Text(sessionService.activeSession?.name ?? "No session")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                // Status text
                Text(statusText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 2)
                
                // Task count if pending
                if sessionService.activeSession?.status == .needsApproval {
                    Text("\(sessionService.pendingTasks.count) pending task\(sessionService.pendingTasks.count != 1 ? "s" : "")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(radius: 2)
                }
                
                Spacer()
                
                // Action buttons (only when needs approval)
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
            return Color.green // default to green when idle
        }
        
        switch session.status {
        case .done:
            return Color.green.opacity(0.3)
        case .needsApproval:
            return Color.red.opacity(0.3)
        case .working:
            return Color.blue.opacity(0.3)
        }
    }
    
    private var statusText: String {
        guard let session = sessionService.activeSession else {
            return "Hermes is idle"
        }
        
        switch session.status {
        case .done:
            return "All done ✓"
        case .needsApproval:
            return "Needs your approval"
        case .working:
            return "Working..."
        }
    }
    
    private var approveButton: some View {
        Button(action: {
            if let session = sessionService.activeSession,
               let task = sessionService.pendingTasks.first {
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
            .shadow(radius: 2)
        }
    }
    
    private var denyButton: some View {
        Button(action: {
            if let session = sessionService.activeSession,
               let task = sessionService.pendingTasks.first {
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
            .shadow(radius: 2)
        }
    }
}

// MARK: - Preview

struct SessionView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
            .environmentObject(HermesSessionService())
            .previewDisplayName("Session")
    }
}
