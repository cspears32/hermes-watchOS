// HermesModels.swift
//
// Core data models for Hermes WatchOS integration.

import Foundation

// MARK: - Session

struct HermesSession: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let status: SessionStatus
    let profile: String?
    let startedAt: Date?
    let completedAt: Date?
}

enum SessionStatus: String, Codable, Hashable {
    case idle
    case working
    case needsApproval = "needs_approval"
    case done
}

// MARK: - Task

struct HermesTask: Identifiable, Codable, Hashable {
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
    
    var shortTitle: String {
        let maxChars = 30
        if title.count > maxChars {
            return String(title.prefix(maxChars)) + "…"
        }
        return title
    }
}

enum TaskStatus: String, Codable, Hashable {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
    case inProgress = "in_progress"
    case completed = "completed"
}

enum TaskPriority: String, Codable, Hashable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
}

// MARK: - Profile

struct HermesProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let isActive: Bool
    let settings: [String: String]?
}

// MARK: - WebSocket Events

enum HermesWebSocketEvent: Codable {
    case taskNew(HermesTask)
    case taskUpdated(HermesTask)
    case taskCompleted(String)
    case hermesHeartbeat(HeartbeatResponse)
    case hermesStatus(StatusResponse)
    
    enum EventType: String, Codable {
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
            let single = try decoder.singleValueContainer()
            let decoded = try single.decode([String: String].self)
            self = .taskCompleted(decoded["taskId"] ?? "")
        case .hermesHeartbeat:
            self = try .hermesHeartbeat(HeartbeatResponse(from: decoder))
        case .hermesStatus:
            self = try .hermesStatus(StatusResponse(from: decoder))
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
    }
}

struct HeartbeatResponse: Codable {
    let status: String
    let uptime: TimeInterval
    let connectedDevices: Int
}

struct StatusResponse: Codable {
    let tasksPending: Int
    let tasksCompleted: Int
    let tasksFailed: Int
    let uptime: TimeInterval
    let version: String
}

// MARK: - Watch Messages

enum HermesWatchMessage: Codable {
    case taskApprove(String)
    case taskDeny(String, String)
    case heartbeat
    case profileActivate(String)
    case voiceCommand(String)
    
    enum MessageType: String, Codable {
        case taskApprove = "task:approve"
        case taskDeny = "task:deny"
        case heartbeat = "hermes:heartbeat"
        case profileActivate = "profile:activate"
        case voiceCommand = "voice:command"
    }
    
    var type: MessageType {
        switch self {
        case .taskApprove: return .taskApprove
        case .taskDeny: return .taskDeny
        case .heartbeat: return .heartbeat
        case .profileActivate: return .profileActivate
        case .voiceCommand: return .voiceCommand
        }
    }
    
    var payload: String? {
        switch self {
        case .taskApprove(let id): return id
        case .taskDeny(let id, _): return id
        case .profileActivate(let id): return id
        case .voiceCommand(let cmd): return cmd
        case .heartbeat: return nil
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
        case payload
        case reason
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        if let payload = payload {
            try container.encode(payload, forKey: .payload)
        }
        if let reason = reason {
            try container.encode(reason, forKey: .reason)
        }
    }
}
