import AppKit
import NotchyKit

/// Brings the Terminal.app or iTerm2 tab that runs a session to the front, matched by its tty.
@MainActor
enum TerminalJumper {
    private struct Terminal: Sendable {
        let bundleID: String
        /// `TERM_PROGRAM` the terminal sets for its shells.
        let termProgram: String
        /// AppleScript that returns true after focusing the tab whose tty is `TTY`.
        let script: String
    }

    private static let terminals = [
        Terminal(bundleID: "com.apple.Terminal", termProgram: "Apple_Terminal", script: """
        tell application id "com.apple.Terminal"
            repeat with w in windows
                repeat with t in tabs of w
                    if tty of t is "TTY" then
                        if miniaturized of w then set miniaturized of w to false
                        set selected of t to true
                        set index of w to 1
                        activate
                        return true
                    end if
                end repeat
            end repeat
        end tell
        return false
        """),
        Terminal(bundleID: "com.googlecode.iterm2", termProgram: "iTerm.app", script: """
        tell application id "com.googlecode.iterm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if tty of s is "TTY" then
                            try
                                if miniaturized of w then set miniaturized of w to false
                            end try
                            select w
                            select t
                            select s
                            activate
                            return true
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        return false
        """),
    ]

    static func jump(to session: SessionStatus) {
        // Only script running terminals: `tell application` would launch a closed one.
        var candidates = terminals.filter { app($0.bundleID) != nil }
        if let known = candidates.first(where: { $0.termProgram == session.terminal }) {
            candidates = [known]
        }
        guard let tty = session.tty, isSafeTTY(tty) else {
            activate(candidates.first)
            return
        }

        // AppleScript blocks until the terminal answers (or the Automation prompt is dismissed),
        // so run it off the main thread to keep the notch responsive.
        Task.detached {
            var fallback = candidates
            for terminal in candidates {
                switch runScript(terminal.script.replacingOccurrences(of: "TTY", with: tty)) {
                case true?: return
                // Clean "no such tty" means the session lives elsewhere. An error (e.g. Automation
                // not allowed) leaves it unknown, so that terminal stays the fallback.
                case false?: fallback.removeAll { $0.bundleID == terminal.bundleID }
                case nil: break
                }
            }
            await activate(fallback.first ?? candidates.first)
        }
    }

    private static func activate(_ terminal: Terminal?) {
        guard let terminal else { return }
        app(terminal.bundleID)?.activate()
    }

    private static func app(_ bundleID: String) -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
    }

    /// Runs AppleScript via osascript: true/false is the script's result, nil means it failed.
    nonisolated private static func runScript(_ source: String) -> Bool? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    /// The tty ends up inside AppleScript source, so only accept plain device paths.
    private static func isSafeTTY(_ tty: String) -> Bool {
        tty.range(of: #"^/dev/ttys?[0-9]+$"#, options: .regularExpression) != nil
    }
}
