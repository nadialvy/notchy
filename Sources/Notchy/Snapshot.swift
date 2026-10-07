import AppKit
import SwiftUI

/// Development helper: `Notchy --snapshot <dir>` renders the notch for the current
/// session files into PNGs, since there are no Xcode previews in a SwiftPM app.
@MainActor
enum Snapshot {
    static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "--snapshot"), index + 1 < args.count else { return false }
        let dir = URL(fileURLWithPath: args[index + 1])
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let store = SessionStore()
        store.reload()
        let model = NotchViewModel(store: store)
        for (name, configure) in model.snapshotStates {
            configure()
            write(model, to: dir.appendingPathComponent("\(name).png"))
        }
        return true
    }

    private static func write(_ model: NotchViewModel, to url: URL) {
        let view = NotchView(model: model)
            .frame(width: NotchPanel.size.width, height: NotchPanel.size.height)
            .background(Color(white: 0.85))
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { return }
        let rep = NSBitmapImageRep(cgImage: image)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
        print("wrote \(url.path)")
    }
}
