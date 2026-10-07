import Darwin
import Foundation
import NotchyKit

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [SessionStatus] = []

    /// Fires when a known session changes state, with its previous state.
    var onTransition: ((SessionStatus, SessionState) -> Void)?

    private var source: DispatchSourceFileSystemObject?
    private var timer: Timer?

    func start() {
        try? FileManager.default.createDirectory(at: NotchyPaths.sessions, withIntermediateDirectories: true)

        let fd = open(NotchyPaths.sessions.path, O_EVTONLY)
        if fd >= 0 {
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .rename, .delete],
                queue: .main
            )
            source.setEventHandler { [weak self] in
                MainActor.assumeIsolated { self?.reload() }
            }
            source.setCancelHandler { close(fd) }
            source.resume()
            self.source = source
        }

        // The directory watcher catches every hook write; this also drops sessions whose Claude process died.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
        reload()
    }

    func reload() {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: NotchyPaths.sessions, includingPropertiesForKeys: nil)) ?? []
        let decoder = StatusCoding.decoder()

        var loaded: [SessionStatus] = []
        for url in urls where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let session = try? decoder.decode(SessionStatus.self, from: data)
            else { continue }
            if isGone(session) {
                try? fm.removeItem(at: url)
                continue
            }
            loaded.append(session)
        }
        loaded.sort(by: Self.displayOrder)
        guard loaded != sessions else { return }

        let previous = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0.state) })
        sessions = loaded
        for session in loaded {
            if let old = previous[session.id], old != session.state {
                onTransition?(session, old)
            }
        }
    }

    private func isGone(_ session: SessionStatus) -> Bool {
        if let pid = session.pid {
            return kill(pid, 0) == -1 && errno == ESRCH
        }
        return session.updatedAt < Date().addingTimeInterval(-12 * 3600)
    }

    private static func displayOrder(_ a: SessionStatus, _ b: SessionStatus) -> Bool {
        func rank(_ state: SessionState) -> Int {
            switch state {
            case .needsPermission: 0
            case .working: 1
            case .done: 2
            }
        }
        if rank(a.state) != rank(b.state) { return rank(a.state) < rank(b.state) }
        if a.project != b.project { return a.project.localizedCaseInsensitiveCompare(b.project) == .orderedAscending }
        return a.sessionId < b.sessionId
    }
}
