import AppKit

enum Settings {
    private static let defaults = UserDefaults.standard
    private static let soundOnPermissionKey = "soundOnPermission"
    private static let soundOnDoneKey = "soundOnDone"

    static func registerDefaults() {
        defaults.register(defaults: [soundOnPermissionKey: true, soundOnDoneKey: false])
    }

    static var soundOnPermission: Bool {
        get { defaults.bool(forKey: soundOnPermissionKey) }
        set { defaults.set(newValue, forKey: soundOnPermissionKey) }
    }

    static var soundOnDone: Bool {
        get { defaults.bool(forKey: soundOnDoneKey) }
        set { defaults.set(newValue, forKey: soundOnDoneKey) }
    }
}
