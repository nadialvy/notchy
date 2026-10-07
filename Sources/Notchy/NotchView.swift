import NotchyKit
import SwiftUI

struct NotchView: View {
    @ObservedObject var model: NotchViewModel

    var body: some View {
        let size = model.contentSize
        ZStack(alignment: .top) {
            NotchShape(topRadius: 6, bottomRadius: model.mode == .expanded ? 22 : 10)
                .fill(Color.black)
            content
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .clipShape(NotchShape(topRadius: 6, bottomRadius: model.mode == .expanded ? 22 : 10))
        .overlay {
            if model.mode == .alert {
                AlertGlow(bottomRadius: 10)
            }
        }
        .opacity(model.mode == .hidden ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: model.mode)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: size)
    }

    @ViewBuilder
    private var content: some View {
        switch model.mode {
        case .hidden:
            EmptyView()
        case .ambient:
            AmbientView(sessions: model.sessions, notchWidth: model.geometry.notchSize.width)
        case .peek(let id):
            CardView(model: model) {
                if let session = model.sessions.first(where: { $0.id == id }) {
                    SessionRow(session: session)
                }
            }
        case .alert:
            CardView(model: model) {
                ForEach(model.waitingSessions.prefix(2)) { session in
                    AlertLine(session: session)
                }
            }
        case .expanded:
            ExpandedView(model: model)
                .transition(.opacity)
        }
    }
}

/// The dots on the left ear and a short summary on the right ear.
struct AmbientView: View {
    let sessions: [SessionStatus]
    let notchWidth: CGFloat

    private let maxDots = 6

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(sessions.prefix(maxDots)) { session in
                    StateDot(state: session.state)
                }
                if sessions.count > maxDots {
                    Text("+\(sessions.count - maxDots)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: NotchViewModel.earWidth)

            Spacer().frame(width: notchWidth)

            summary
                .frame(width: NotchViewModel.earWidth)
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var summary: some View {
        let waiting = sessions.filter { $0.state == .needsPermission }.count
        let running = sessions.filter { $0.state == .working }.count
        Group {
            if waiting > 0 {
                Label("\(waiting)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.permission)
            } else if running > 0 {
                Text("\(running) running")
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                Label("done", systemImage: "checkmark")
                    .foregroundStyle(Palette.done)
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .labelStyle(.titleAndIcon)
        .lineLimit(1)
    }
}

enum Palette {
    static let working = Color(red: 0.68, green: 0.52, blue: 1.0)
    static let done = Color(red: 0.32, green: 0.86, blue: 0.52)
    static let permission = Color(red: 1.0, green: 0.62, blue: 0.2)

    static func color(for state: SessionState) -> Color {
        switch state {
        case .working: working
        case .done: done
        case .needsPermission: permission
        }
    }
}

struct StateDot: View {
    let state: SessionState
    var size: CGFloat = 7

    @State private var dim = false

    var body: some View {
        Circle()
            .fill(Palette.color(for: state))
            .frame(width: size, height: size)
            .opacity(state == .done ? 1 : (dim ? 0.35 : 1))
            .animation(
                state == .done ? .default : .easeInOut(duration: state == .working ? 0.9 : 0.5).repeatForever(autoreverses: true),
                value: dim
            )
            .onAppear { dim = true }
    }
}

/// Black shape that blends into the hardware notch: flared top corners, rounded bottom corners.
struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY + topRadius),
            control: CGPoint(x: rect.minX + topRadius, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.minX + topRadius, y: rect.maxY - bottomRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius + bottomRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + topRadius, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - topRadius - bottomRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topRadius, y: rect.maxY - bottomRadius),
            control: CGPoint(x: rect.maxX - topRadius, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY + topRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - topRadius, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
