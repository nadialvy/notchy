import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SessionStore()
    private lazy var model = NotchViewModel(store: store)
    private var panel: NotchPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.start()

        let panel = NotchPanel(model: model)
        panel.reposition(on: model.geometry.screen)
        panel.orderFrontRegardless()
        self.panel = panel

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        }
    }

    private func screensChanged() {
        model.geometry = .current()
        panel?.reposition(on: model.geometry.screen)
    }
}
