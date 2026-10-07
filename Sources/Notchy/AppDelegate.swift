import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SessionStore()
    private lazy var model = NotchViewModel(store: store)
    private var panel: NotchPanel?
    private var menuBar: MenuBarController?
    private var mouseMonitors: [Any] = []
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.registerDefaults()
        store.start()
        menuBar = MenuBarController(store: store)

        let panel = NotchPanel(model: model)
        panel.reposition(on: model.geometry.screen)
        panel.orderFrontRegardless()
        self.panel = panel

        // The panel only takes clicks while expanded; otherwise clicks pass through to the menu bar.
        model.$isHovering
            .sink { [weak panel] hovering in panel?.ignoresMouseEvents = !hovering }
            .store(in: &cancellables)
        startMouseTracking()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        }
    }

    private func startMouseTracking() {
        let handler: (NSEvent) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.model.mouseMoved(to: NSEvent.mouseLocation) }
        }
        let events: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: events, handler: handler) {
            mouseMonitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: events, handler: { event in
            handler(event)
            return event
        }) {
            mouseMonitors.append(local)
        }
    }

    private func screensChanged() {
        model.geometry = .current()
        panel?.reposition(on: model.geometry.screen)
    }
}
