import Darwin
import Foundation
import NotchyKit

// Called by Claude Code hooks with the event JSON on stdin.
// It only records status files and must never block or fail Claude, so every path exits 0.

let input = FileHandle.standardInput.readDataToEndOfFile()
guard
    let payload = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any],
    let rawId = payload["session_id"] as? String,
    let event = payload["hook_event_name"] as? String
else { exit(0) }

let sessionId = String(rawId.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" })
guard !sessionId.isEmpty else { exit(0) }

let cwd = payload["cwd"] as? String ?? FileManager.default.currentDirectoryPath
let file = NotchyPaths.statusFile(for: sessionId)
let fm = FileManager.default

if event == "SessionEnd" {
    try? fm.removeItem(at: file)
    exit(0)
}

try? fm.createDirectory(at: NotchyPaths.sessions, withIntermediateDirectories: true)
try? fm.createDirectory(at: NotchyPaths.locks, withIntermediateDirectories: true)

// Parallel tool calls fire hooks at the same time, so serialize read-modify-write per session.
let lockFd = open(NotchyPaths.locks.appendingPathComponent(sessionId).path, O_CREAT | O_RDWR, 0o644)
if lockFd >= 0 { flock(lockFd, LOCK_EX) }
defer { if lockFd >= 0 { close(lockFd) } }

var status = (try? Data(contentsOf: file)).flatMap { try? StatusCoding.decoder().decode(SessionStatus.self, from: $0) }
    ?? SessionStatus(sessionId: sessionId, cwd: cwd)
status.cwd = cwd

if status.pid == nil || status.tty == nil {
    let owner = ClaudeProcess.find()
    status.pid = owner?.pid
    status.tty = owner?.tty
}

let toolName = payload["tool_name"] as? String ?? ""
let toolInput = payload["tool_input"] as? [String: Any] ?? [:]
let blockingTools: Set<String> = ["AskUserQuestion", "ExitPlanMode"]

switch event {
case "SessionStart":
    break

case "UserPromptSubmit":
    status.state = .working
    status.lastPrompt = (payload["prompt"] as? String).map { Text.oneLine($0, limit: 200) }
    status.activity = nil
    status.permissionMessage = nil
    status.lastMessage = nil
    status.startedAt = Date()
    status.finishedAt = nil
    if status.visibleTasks.allSatisfy(\.isDone) { status.tasks = [] }

case "PreToolUse":
    status.state = .working
    status.activity = ToolDescription.describe(toolName, toolInput, cwd: cwd)
    status.permissionMessage = nil
    if blockingTools.contains(toolName) {
        status.state = .needsPermission
        status.permissionMessage = ToolDescription.describe(toolName, toolInput, cwd: cwd)
    }

case "PostToolUse":
    status.state = .working
    status.permissionMessage = nil
    Tasks.apply(toolName, toolInput, payload["tool_response"], to: &status.tasks)

case "PermissionRequest":
    status.state = .needsPermission
    status.permissionMessage = ToolDescription.describe(toolName, toolInput, cwd: cwd)

case "Notification":
    let message = payload["message"] as? String ?? ""
    if message.localizedCaseInsensitiveContains("permission") {
        status.state = .needsPermission
        if status.permissionMessage == nil {
            status.permissionMessage = status.activity ?? Text.oneLine(message, limit: 160)
        }
    }

case "Stop":
    status.state = .done
    status.finishedAt = Date()
    status.activity = nil
    status.permissionMessage = nil
    let inline = payload["last_assistant_message"] as? String
    let fromTranscript = (payload["transcript_path"] as? String).flatMap(Transcript.lastAssistantText)
    status.lastMessage = (inline ?? fromTranscript).map { Text.oneLine($0, limit: 300) }

default:
    exit(0)
}

status.updatedAt = Date()
if let data = try? StatusCoding.encoder().encode(status) {
    try? data.write(to: file, options: .atomic)
}
exit(0)
