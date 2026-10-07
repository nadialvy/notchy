import AppKit
import SwiftUI

/// A transparent, click-through panel pinned to the top center of the screen.
/// The SwiftUI content draws the notch shape inside it.
final class NotchPanel: NSPanel {
    static let size = CGSize(width: 640, height: 460)

    init(model: NotchViewModel) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true

        let host = FirstClickHostingView(rootView: NotchView(model: model))
        host.sizingOptions = []
        contentView = host
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func reposition(on screen: NSScreen) {
        let frame = NSRect(
            x: screen.frame.midX - Self.size.width / 2,
            y: screen.frame.maxY - Self.size.height,
            width: Self.size.width,
            height: Self.size.height
        )
        setFrame(frame, display: true)
    }
}

private final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
