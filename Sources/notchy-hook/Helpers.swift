import Darwin
import Foundation
import NotchyKit

enum Text {
    static func oneLine(_ text: String, limit: Int) -> String {
        let collapsed = text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return collapsed.count > limit ? String(collapsed.prefix(limit - 1)) + "…" : collapsed
    }
}

enum ToolDescription {
    static func describe(_ tool: String, _ input: [String: Any], cwd: String) -> String {
        func str(_ key: String) -> String? { input[key] as? String }
        func path(_ key: String) -> String? {
            guard let p = str(key) else { return nil }
            return p.hasPrefix(cwd + "/") ? String(p.dropFirst(cwd.count + 1)) : p
        }

        let detail: String?
        switch tool {
        case "Bash": detail = str("command")
        case "Read", "Write", "Edit", "MultiEdit": detail = path("file_path")
        case "NotebookEdit": detail = path("notebook_path")
        case "Grep", "Glob": detail = str("pattern")
        case "WebFetch": detail = str("url").flatMap { URL(string: $0)?.host }
        case "WebSearch": detail = str("query")
        case "Task", "Agent": detail = str("description")
        case "AskUserQuestion":
            let questions = input["questions"] as? [[String: Any]]
            detail = questions?.first?["question"] as? String
        case "ExitPlanMode": detail = "Plan ready for review"
        default: detail = nil
        }

        var name = tool
        if tool.hasPrefix("mcp__") {
            name = "MCP " + (tool.components(separatedBy: "__").last ?? tool)
        }
        guard let detail, !detail.isEmpty else { return name }
        return Text.oneLine("\(name): \(detail)", limit: 160)
    }
}

enum Tasks {
    static func apply(_ tool: String, _ input: [String: Any], _ response: Any?, to tasks: inout [TaskItem]) {
        switch tool {
        case "TaskCreate":
            let result = response as? [String: Any]
            let task = result?["task"] as? [String: Any]
            let id = (task?["id"] as? String) ?? String(tasks.count + 1)
            let subject = input["subject"] as? String ?? task?["subject"] as? String ?? "Task \(id)"
            tasks.removeAll { $0.id == id }
            tasks.append(TaskItem(id: id, subject: subject, activeForm: input["activeForm"] as? String, status: "pending"))

        case "TaskUpdate":
            guard let id = input["taskId"] as? String, let index = tasks.firstIndex(where: { $0.id == id }) else { return }
            if let status = input["status"] as? String { tasks[index].status = status }
            if let subject = input["subject"] as? String { tasks[index].subject = subject }
            if let activeForm = input["activeForm"] as? String { tasks[index].activeForm = activeForm }

        case "TodoWrite":
            let todos = input["todos"] as? [[String: Any]] ?? []
            tasks = todos.enumerated().map { index, todo in
                TaskItem(
                    id: String(index + 1),
                    subject: todo["content"] as? String ?? "",
                    activeForm: todo["activeForm"] as? String,
                    status: todo["status"] as? String ?? "pending"
                )
            }

        default:
            break
        }
    }
}

enum Transcript {
    /// Reads the tail of the transcript and returns the newest assistant text block.
    static func lastAssistantText(_ path: String) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let window: UInt64 = 512 * 1024
        try? handle.seek(toOffset: size > window ? size - window : 0)
        guard let data = try? handle.readToEnd(), let text = String(data: data, encoding: .utf8) else { return nil }

        for line in text.split(separator: "\n").reversed() {
            guard
                let entry = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any],
                entry["type"] as? String == "assistant",
                let message = entry["message"] as? [String: Any],
                let content = message["content"] as? [[String: Any]]
            else { continue }
            let texts = content.compactMap { $0["type"] as? String == "text" ? $0["text"] as? String : nil }
            let joined = texts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { return joined }
        }
        return nil
    }
}

enum ClaudeProcess {
    struct Owner {
        let pid: Int32
        let tty: String?
    }

    private static let shells: Set<String> = ["sh", "bash", "zsh", "dash", "fish", "env"]

    /// Walks up from the hook process, skipping shells, to the Claude process that spawned it.
    static func find() -> Owner? {
        var pid = getppid()
        for _ in 0..<12 {
            guard pid > 1, let info = info(for: pid) else { return nil }
            if !shells.contains(name(of: info)) {
                return Owner(pid: pid, tty: tty(of: info))
            }
            pid = info.kp_eproc.e_ppid
        }
        return nil
    }

    private static func info(for pid: pid_t) -> kinfo_proc? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info
    }

    private static func name(of info: kinfo_proc) -> String {
        var comm = info.kp_proc.p_comm
        return withUnsafeBytes(of: &comm) { raw in
            String(decoding: raw.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }

    private static func tty(of info: kinfo_proc) -> String? {
        let device = info.kp_eproc.e_tdev
        guard device != -1, let name = devname(device, S_IFCHR) else { return nil }
        return "/dev/" + String(cString: name)
    }
}
