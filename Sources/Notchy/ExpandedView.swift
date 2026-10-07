import NotchyKit
import SwiftUI

struct ExpandedView: View {
    @ObservedObject var model: NotchViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: model.geometry.notchSize.height)

            if model.listHeight > NotchViewModel.maxListHeight {
                ScrollView(.vertical, showsIndicators: false) { list }
            } else {
                list
            }
        }
    }

    private var list: some View {
        VStack(spacing: 6) {
            if model.sessions.isEmpty {
                Text("No Claude sessions running")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            ForEach(model.sessions) { session in
                SessionRow(session: session)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ListHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(ListHeightKey.self) { height in
            MainActor.assumeIsolated { model.listHeight = height }
        }
    }

    private var header: some View {
        let notchWidth = model.geometry.notchSize.width
        return HStack(spacing: 0) {
            Text("Claude")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer().frame(width: notchWidth)
            Text(summary)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 22)
    }

    private var summary: String {
        let sessions = model.sessions
        let running = sessions.filter { $0.state == .working }.count
        let waiting = sessions.filter { $0.state == .needsPermission }.count
        var parts: [String] = []
        if running > 0 { parts.append("\(running) running") }
        if waiting > 0 { parts.append("\(waiting) waiting") }
        if parts.isEmpty { parts.append("\(sessions.count) idle") }
        return parts.joined(separator: " · ")
    }
}

private struct ListHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct SessionRow: View {
    let session: SessionStatus
    var onTap: () -> Void = {}

    @State private var hovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StateDot(state: session.state, size: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.project)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    ElapsedText(session: session)
                }

                if let prompt = session.lastPrompt {
                    Text(prompt)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }

                detail
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(hovered ? 0.1 : 0.05))
        )
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var detail: some View {
        switch session.state {
        case .working:
            Text(session.activity ?? "Thinking…")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
            TaskProgress(session: session)

        case .needsPermission:
            Text(session.permissionMessage?.hasPrefix("AskUserQuestion") == true ? "Has a question for you" : "Needs your permission")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.permission)
            if let message = session.permissionMessage {
                Text(message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

        case .done:
            if let message = session.lastMessage {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
            } else {
                Text(session.startedAt == nil ? "Ready" : "Done")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.done)
            }
        }
    }
}

private struct TaskProgress: View {
    let session: SessionStatus

    var body: some View {
        let total = session.visibleTasks.count
        if total > 0 {
            let done = session.completedTaskCount
            HStack(spacing: 8) {
                ProgressBar(fraction: Double(done) / Double(total))
                    .frame(width: 80, height: 4)
                Text("\(done)/\(total)")
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
                if let active = session.activeTask {
                    Text(active.activeForm ?? active.subject)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(.top, 2)
        }
    }
}

private struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule().fill(Palette.working)
                    .frame(width: proxy.size.width * fraction)
            }
        }
    }
}

private struct ElapsedText: View {
    let session: SessionStatus

    var body: some View {
        if let start = session.startedAt {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let end = session.finishedAt ?? context.date
                Text(Self.format(end.timeIntervalSince(start)))
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m \(String(format: "%02d", seconds % 60))s" }
        return "\(seconds / 3600)h \(String(format: "%02d", seconds % 3600 / 60))m"
    }
}
