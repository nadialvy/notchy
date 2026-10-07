import Foundation

public enum SessionState: String, Codable, Sendable {
    case working
    case done
    case needsPermission = "needs_permission"
}

public struct TaskItem: Codable, Equatable, Sendable {
    public var id: String
    public var subject: String
    public var activeForm: String?
    public var status: String

    public init(id: String, subject: String, activeForm: String?, status: String) {
        self.id = id
        self.subject = subject
        self.activeForm = activeForm
        self.status = status
    }

    public var isDone: Bool { status == "completed" }
    public var isActive: Bool { status == "in_progress" }
}

public struct SessionStatus: Codable, Equatable, Identifiable, Sendable {
    public var sessionId: String
    public var cwd: String
    public var tty: String?
    public var pid: Int32?
    public var state: SessionState
    public var lastPrompt: String?
    public var activity: String?
    public var permissionMessage: String?
    public var lastMessage: String?
    public var tasks: [TaskItem]
    public var startedAt: Date?
    public var finishedAt: Date?
    public var updatedAt: Date

    public var id: String { sessionId }
    public var project: String { URL(fileURLWithPath: cwd).lastPathComponent }

    public init(sessionId: String, cwd: String) {
        self.sessionId = sessionId
        self.cwd = cwd
        self.state = .done
        self.tasks = []
        self.updatedAt = Date()
    }

    public var visibleTasks: [TaskItem] { tasks.filter { $0.status != "deleted" } }
    public var completedTaskCount: Int { visibleTasks.filter(\.isDone).count }
    public var activeTask: TaskItem? { visibleTasks.first(where: \.isActive) }
}

public enum NotchyPaths {
    public static let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".notchy")
    public static let sessions = root.appendingPathComponent("sessions")
    public static let locks = root.appendingPathComponent("locks")

    public static func statusFile(for sessionId: String) -> URL {
        sessions.appendingPathComponent("\(sessionId).json")
    }
}

public enum StatusCoding {
    public static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    public static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }
}
