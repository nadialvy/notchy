import AppKit
import Combine
import NotchyKit

@MainActor
final class NotchViewModel: ObservableObject {
    enum Mode: Equatable {
        case hidden
        case ambient
        case expanded
    }

    static let earWidth: CGFloat = 78
    static let expandedWidth: CGFloat = 540
    static let maxListHeight: CGFloat = 380

    let store: SessionStore
    @Published var geometry = NotchGeometry.current()
    @Published var isHovering = false
    @Published var listHeight: CGFloat = 60

    private var cancellables: Set<AnyCancellable> = []
    private var collapseWork: DispatchWorkItem?

    init(store: SessionStore) {
        self.store = store
        store.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var sessions: [SessionStatus] { store.sessions }

    var mode: Mode {
        if isHovering { return .expanded }
        return sessions.isEmpty ? .hidden : .ambient
    }

    /// Size of the black notch shape for the current mode.
    var contentSize: CGSize {
        let notch = geometry.notchSize
        switch mode {
        case .hidden:
            return notch
        case .ambient:
            return CGSize(width: notch.width + Self.earWidth * 2, height: notch.height)
        case .expanded:
            return CGSize(width: Self.expandedWidth, height: notch.height + min(listHeight, Self.maxListHeight))
        }
    }

    // MARK: Hover

    /// Called with the global mouse location on every mouse move.
    func mouseMoved(to point: NSPoint) {
        let screen = geometry.screen.frame
        let size = contentSize
        var zone = NSRect(x: screen.midX - size.width / 2, y: screen.maxY - size.height, width: size.width, height: size.height)
        // A little slack so the panel doesn't flicker at its edges.
        zone = zone.insetBy(dx: isHovering ? -16 : -6, dy: isHovering ? -16 : -4)

        if zone.contains(point) {
            collapseWork?.cancel()
            collapseWork = nil
            if !isHovering { isHovering = true }
        } else if isHovering, collapseWork == nil {
            let work = DispatchWorkItem { [weak self] in
                self?.isHovering = false
                self?.collapseWork = nil
            }
            collapseWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        }
    }

    /// Named states rendered by `Notchy --snapshot`.
    var snapshotStates: [(String, () -> Void)] {
        [
            ("ambient", { self.isHovering = false }),
            ("expanded", { self.isHovering = true }),
        ]
    }
}
