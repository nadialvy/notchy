import AppKit
import NotchyKit

/// Brings the Terminal.app tab that runs a session to the front, matched by its tty.
@MainActor
enum TerminalJumper {
    static func jump(to session: SessionStatus) {
        guard let tty = session.tty, isSafeTTY(tty) else {
            activateTerminal()
            return
        }

        let source = """
        tell application "Terminal"
            repeat with w in windows
                repeat with t in tabs of w
                    if tty of t is "\(tty)" then
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
        """

        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if error != nil || result?.booleanValue != true {
            activateTerminal()
        }
    }

    private static func activateTerminal() {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.Terminal")
            .first?
            .activate()
    }

    /// The tty ends up inside AppleScript source, so only accept plain device paths.
    private static func isSafeTTY(_ tty: String) -> Bool {
        tty.range(of: #"^/dev/ttys?[0-9]+$"#, options: .regularExpression) != nil
    }
}
