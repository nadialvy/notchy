import AppKit
import Combine
import NotchyKit

@MainActor
final class NotchViewModel: ObservableObject {
    enum Mode: Equatable {
        case hidden
        case ambient
    }

    static let earWidth: CGFloat = 78

    let store: SessionStore
    @Published var geometry = NotchGeometry.current()

    private var cancellables: Set<AnyCancellable> = []

    init(store: SessionStore) {
        self.store = store
        store.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var sessions: [SessionStatus] { store.sessions }

    var mode: Mode {
        sessions.isEmpty ? .hidden : .ambient
    }

    /// Size of the black notch shape for the current mode.
    var contentSize: CGSize {
        let notch = geometry.notchSize
        switch mode {
        case .hidden:
            return notch
        case .ambient:
            return CGSize(width: notch.width + Self.earWidth * 2, height: notch.height)
        }
    }

    /// Named states rendered by `Notchy --snapshot`.
    var snapshotStates: [(String, () -> Void)] {
        [("ambient", {})]
    }
}
