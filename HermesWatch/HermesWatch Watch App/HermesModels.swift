// HermesModels.swift
//
// Core data models for Hermes WatchOS integration.

import Foundation

// MARK: - Session

struct HermesSession: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    var status: SessionStatus
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
    var status: TaskStatus
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
            return String(title.prefix(maxChars)) + "\u{2026}"
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

    enum CodingKeys: String, CodingKey {
        case id, name, description, isActive, settings
    }

    init(id: String, name: String, description: String, isActive: Bool, settings: [String: String]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.isActive = isActive
        self.settings = settings
    }
}

// MARK: - WebSocket Events

enum HermesWebSocketEvent: Codable, Hashable {
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

    enum CodingKeys: String, CodingKey {
        case type, taskId, payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)

        switch type {
        case .taskNew:
            self = .taskNew(try HermesTask(from: decoder))
        case .taskUpdated:
            self = .taskUpdated(try HermesTask(from: decoder))
        case .taskCompleted:
            // Server may send {"type":"task:completed","taskId":"..."} or nest it under payload.
            let single = try decoder.singleValueContainer()
            let flat = try? single.decode([String: String].self)
            let id = try container.decodeIfPresent(String.self, forKey: .taskId)
                ?? (try container.decodeIfPresent([String: String].self, forKey: .payload))?["taskId"]
                ?? flat?["taskId"]
            self = .taskCompleted(id ?? "")
        case .hermesHeartbeat:
            self = .hermesHeartbeat(try HeartbeatResponse(from: decoder))
        case .hermesStatus:
            self = .hermesStatus(try StatusResponse(from: decoder))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .taskNew(let task), .taskUpdated(let task):
            try task.encode(to: encoder)
            try container.encode(Self.EventType.taskNew.rawValue == "" ? "" : "", forKey: .payload)
        case .taskCompleted(let id):
            try container.encode(Self.EventType.taskCompleted, forKey: .type)
            try container.encode(id, forKey: .taskId)
        case .hermesHeartbeat(let hb):
            try container.encode(Self.EventType.hermesHeartbeat, forKey: .type)
            try hb.encode(to: encoder)
        case .hermesStatus(let st):
            try container.encode(Self.EventType.hermesStatus, forKey: .type)
            try st.encode(to: encoder)
        }
    }
}

struct HeartbeatResponse: Codable, Hashable {
    let status: String
    let uptime: TimeInterval
    let connectedDevices: Int

    enum CodingKeys: String, CodingKey {
        case status, uptime
        case connectedDevices = "connected_devices"
    }

    var deviceCount: Int { connectedDevices }
}

struct StatusResponse: Codable, Hashable {
    let tasksPending: Int
    let tasksCompleted: Int
    let tasksFailed: Int
    let uptime: TimeInterval
    let version: String
    let connectedDevices: Int

    enum CodingKeys: String, CodingKey {
        case uptime, version
        case tasksPending = "tasks_pending"
        case tasksCompleted = "tasks_completed"
        case tasksFailed = "tasks_failed"
        case connectedDevices = "connected_devices"
    }
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
        case type, payload, reason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)
        let payload = try container.decodeIfPresent(String.self, forKey: .payload) ?? ""
        let reason = try container.decodeIfPresent(String.self, forKey: .reason) ?? ""

        switch type {
        case .taskApprove: self = .taskApprove(payload)
        case .taskDeny: self = .taskDeny(payload, reason)
        case .heartbeat: self = .heartbeat
        case .profileActivate: self = .profileActivate(payload)
        case .voiceCommand: self = .voiceCommand(payload)
        }
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
