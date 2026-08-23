// StatusView.swift
//
// Displays Hermes system status: heartbeat, connected devices, queue depth.
// Shows connection state and last update time.

import SwiftUI

struct StatusView: View {
    @EnvironmentObject var webSocketService: HermesWebSocketService
    @State private var status: HermesStatus?
    @State private var lastUpdate: Date?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Connection status
                ConnectionStatusView(isConnected: webSocketService.isConnected)
                
                // System stats
                if let status = status {
                    StatsGrid(status: status)
                } else {
                    ProgressView("Loading status...")
                }
                
                // Uptime
                if let uptime = status?.uptime {
                    UptimeView(seconds: uptime)
                }
                
                // Version info
                if let version = status?.version {
                    VersionRow(version: version)
                }
                
                // Last update
                if let lastUpdate = lastUpdate {
                    Text("Last update: " + formattedTime(lastUpdate))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .onReceive(webSocketService.eventPublisher) { event in
            if case .hermesStatus(let s) = event {
                status = s
                lastUpdate = Date()
                HermesHapticService.shared.play(.notification)
            }
            if case .hermesHeartbeat = event {
                // Heartbeat received - could update something
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Connection Status

struct ConnectionStatusView: View {
    let isConnected: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isConnected ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let status: HermesStatus
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                StatCard(title: "Pending", value: "\(status.tasksPending)", color: .orange)
                StatCard(title: "Done", value: "\(status.tasksCompleted)", color: .green)
            }
            HStack {
                StatCard(title: "Failed", value: "\(status.tasksFailed)", color: .red)
                StatCard(title: "Devices", value: "\(status.connectedDevices)", color: .blue)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Uptime View

struct UptimeView: View {
    let seconds: TimeInterval
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Uptime")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(formattedUptime(seconds))
                .font(.system(size: 14, weight: .medium))
        }
    }
    
    private func formattedUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        
        return parts.joined(separator: " ")
    }
}

// MARK: - Version Row

struct VersionRow: View {
    let version: String
    
    var body: some View {
        HStack {
            Text("Version")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(version)
                .font(.system(size: 10, weight: .medium))
        }
    }
}

// MARK: - Preview

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
            .environmentObject(HermesWebSocketService())
            .previewDisplayName("Status")
    }
}
