import AppKit
import ServiceManagement

/// Small menu bar item for settings and quitting, since Notchy has no Dock icon.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let store: SessionStore

    init(store: SessionStore) {
        self.store = store
        super.init()
        item.button?.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "Notchy")
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let count = store.sessions.count
        let header = NSMenuItem(title: count == 1 ? "1 Claude session" : "\(count) Claude sessions", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        menu.addItem(toggle("Sound for permission requests", on: Settings.soundOnPermission, action: #selector(toggleSoundOnPermission)))
        menu.addItem(toggle("Sound when Claude finishes", on: Settings.soundOnDone, action: #selector(toggleSoundOnDone)))
        menu.addItem(toggle("Launch at Login", on: SMAppService.mainApp.status == .enabled, action: #selector(toggleLaunchAtLogin)))
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Notchy", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private func toggle(_ title: String, on: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    @objc private func toggleSoundOnPermission() {
        Settings.soundOnPermission.toggle()
    }

    @objc private func toggleSoundOnDone() {
        Settings.soundOnDone.toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Couldn't change Launch at Login"
            alert.runModal()
        }
    }
}
