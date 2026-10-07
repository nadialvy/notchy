import NotchyKit
import SwiftUI

/// Compact layout used by peek and alert: the ambient ears on top, a short card below.
struct CardView<Card: View>: View {
    @ObservedObject var model: NotchViewModel
    @ViewBuilder var card: Card

    var body: some View {
        VStack(spacing: 0) {
            AmbientView(sessions: model.sessions, notchWidth: model.geometry.notchSize.width)
                .frame(height: model.geometry.notchSize.height)

            VStack(spacing: 6) { card }
                .padding(.horizontal, 10)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: CardHeightKey.self, value: proxy.size.height)
                    }
                )
                .onPreferenceChange(CardHeightKey.self) { height in
                    MainActor.assumeIsolated { model.cardHeight = height }
                }
        }
    }
}

private struct CardHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct AlertLine: View {
    let session: SessionStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.permission)
            Text(session.project)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Text(session.permissionMessage ?? "Needs your permission")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Palette.permission.opacity(0.12))
        )
    }
}

/// Orange outline that keeps pulsing until the permission request is handled.
struct AlertGlow: View {
    let bottomRadius: CGFloat
    @State private var bright = false

    var body: some View {
        NotchShape(topRadius: 6, bottomRadius: bottomRadius)
            .stroke(Palette.permission, lineWidth: 1.5)
            .shadow(color: Palette.permission.opacity(0.8), radius: bright ? 8 : 2)
            .opacity(bright ? 1 : 0.35)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bright)
            .onAppear { bright = true }
            .allowsHitTesting(false)
    }
}
