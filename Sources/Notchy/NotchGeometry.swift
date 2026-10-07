import AppKit

struct NotchGeometry {
    let screen: NSScreen
    let notchSize: CGSize

    /// Prefers the built-in display with a notch, falling back to a fake notch on the main screen.
    static func current() -> NotchGeometry {
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens[0]
        if screen.safeAreaInsets.top > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let width = screen.frame.width - left.width - right.width
            return NotchGeometry(screen: screen, notchSize: CGSize(width: width, height: screen.safeAreaInsets.top))
        }
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        return NotchGeometry(screen: screen, notchSize: CGSize(width: 180, height: max(menuBarHeight, 24)))
    }
}
