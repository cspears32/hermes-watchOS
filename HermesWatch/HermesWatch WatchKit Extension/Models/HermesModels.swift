// HermesModels.swift
//
// Core data models for Hermes WatchOS integration.
// Defines the types used for tasks, status, and communication.

import Foundation

// MARK: - Task Models

struct HermesTask: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let status: TaskStatus
    let priority: TaskPriority
    let createdAt: Date
    let updatedAt: Date?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, priority
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.status = try container.decode(TaskStatus.self, forKey: .status)
        self.priority = try container.decode(TaskPriority.self, forKey: .priority)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
    }
    
    init(id: String, title: String, description: String, status: TaskStatus, priority: TaskPriority, createdAt: Date, updatedAt: Date? = nil, metadata: [String: String]? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
    
    // Short title for watch display
    var shortTitle: String {
        let maxChars = 30
        if title.count > maxChars {
            return String(title.prefix(maxChars)) + "…"
        }
        return title
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
    case inProgress = "in_progress"
    case completed = "completed"
}

enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
}

// MARK: - Status Models

struct HermesStatus: Codable, Sendable {
    let tasksPending: Int
    let tasksCompleted: Int
    let tasksFailed: Int
    let uptime: TimeInterval
    let version: String
    let connectedDevices: Int
}

struct HeartbeatResponse: Codable, Sendable {
    let status: String
    let uptime: TimeInterval
    let connectedDevices: Int
}

// MARK: - Watch Message Types

enum HermesWatchMessage: Codable, Sendable {
    case taskApprove(String)
    case taskDeny(String, String)
    case heartbeat
    case statusRequest
    
    enum MessageType: String, Codable, Sendable {
        case taskApprove = "task:approve"
        case taskDeny = "task:deny"
        case heartbeat = "hermes:heartbeat"
        case statusRequest = "hermes:status"
    }
    
    var type: MessageType {
        switch self {
        case .taskApprove: return .taskApprove
        case .taskDeny: return .taskDeny
        case .heartbeat: return .heartbeat
        case .statusRequest: return .statusRequest
        }
    }
    
    var taskId: String? {
        switch self {
        case .taskApprove(let id): return id
        case .taskDeny(let id, _): return id
        case .heartbeat, .statusRequest: return nil
        }
    }
    
    var reason: String? {
        switch self {
        case .taskDeny(_, let reason): return reason
        default: return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case taskId
        case reason
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let taskId = taskId {
            try container.encode(taskId, forKey: .taskId)
        }
        if let reason = reason {
            try container.encode(reason, forKey: .reason)
        }
    }
}

// MARK: - WebSocket Events

enum HermesWebSocketEvent: Codable, Sendable {
    case taskNew(HermesTask)
    case taskUpdated(HermesTask)
    case taskCompleted(String)
    case hermesHeartbeat(HeartbeatResponse)
    case hermesStatus(HermesStatus)
    
    enum EventType: String, Codable, Sendable {
        case taskNew = "task:new"
        case taskUpdated = "task:updated"
        case taskCompleted = "task:completed"
        case hermesHeartbeat = "hermes:heartbeat"
        case hermesStatus = "hermes:status"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        
        switch type {
        case .taskNew:
            self = try .taskNew(HermesTask(from: decoder))
        case .taskUpdated:
            self = try .taskUpdated(HermesTask(from: decoder))
        case .taskCompleted:
            let singleContainer = try decoder.singleValueContainer()
            let decoded = try singleContainer.decode([String: String].self)
            self = .taskCompleted(decoded["taskId"] ?? "")
        case .hermesHeartbeat:
            self = try .hermesHeartbeat(HeartbeatResponse(from: decoder))
        case .hermesStatus:
            self = try .hermesStatus(HermesStatus(from: decoder))
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
    }
}
