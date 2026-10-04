import SwiftUI

/// A horizontally draggable band of pushbuttons — one per station on the current
/// country's frequency range.
///
/// A plain `ScrollView` is deliberately avoided: it swallows clicks inside the
/// scroll area on some macOS versions, so the band is scrolled by hand with an
/// offset and clipped here. That also keeps the row a fixed 52 pt tall.
struct StationSelectorView: View {
    let theme: SkinTheme
    let stations: [Station]
    let selectedID: String?
    let state: RadioState
    let onSelect: (Station) -> Void

    private let buttonWidth: CGFloat = 108
    private let gap: CGFloat = 8
    private let height: CGFloat = 52

    @State private var offset: CGFloat = 0
    @State private var dragAnchor: CGFloat?

    private var contentWidth: CGFloat {
        CGFloat(stations.count) * buttonWidth + CGFloat(max(stations.count - 1, 0)) * gap
    }

    var body: some View {
        GeometryReader { geo in
            let visible = geo.size.width
            let travel = max(0, contentWidth - visible)

            ZStack(alignment: .topLeading) {
                HStack(spacing: gap) {
                    ForEach(stations) { station in
                        PushButton(
                            theme: theme,
                            title: shortTitle(station),
                            subtitle: station.genre,
                            isActive: station.id == selectedID,
                            isLive: station.id == selectedID && state == .playing
                        ) {
                            onSelect(station)
                        }
                        .frame(width: buttonWidth)
                    }
                }
                .offset(x: -min(offset, travel))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            let anchor = dragAnchor ?? offset
                            if dragAnchor == nil { dragAnchor = anchor }
                            offset = min(max(anchor + g.translation.width, 0), travel)
                        }
                        .onEnded { _ in dragAnchor = nil }
                )

                if travel > 1 {
                    // Chevron affordances at both ends of the band.
                    ScrollChevron(theme: theme, pointsRight: false) { scroll(by: -buttonWidth, travel: travel) }
                        .frame(width: 18, height: height)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ScrollChevron(theme: theme, pointsRight: true) { scroll(by: buttonWidth, travel: travel) }
                        .frame(width: 18, height: height)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(height: height)
            .clipShape(Rectangle())
            .onAppear { offset = 0 }
        }
        .frame(height: height)
    }

    private func scroll(by amount: CGFloat, travel: CGFloat) {
        withAnimation(.easeOut(duration: 0.18)) {
            offset = min(max(offset + amount, 0), travel)
        }
    }

    /// Keeps the engraving readable — three words maximum.
    private func shortTitle(_ station: Station) -> String {
        station.name.split(separator: " ").prefix(3).joined(separator: " ").uppercased()
    }
}

/// A single moulded pushbutton with a bevelled face and a lit indicator.
private struct PushButton: View {
    let theme: SkinTheme
    let title: String
    let subtitle: String
    let isActive: Bool
    let isLive: Bool
    let action: () -> Void

    @State private var pressed = false

    private var face: Color { isActive ? theme.buttonFaceActive : theme.buttonFace }
    private var ink: Color { theme.readableOn(face) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isLive ? theme.glow : ink.opacity(0.45))
                        .frame(width: 5, height: 5)
                        .shadow(color: isLive ? theme.glow : .clear, radius: 3)
                    Text(title)
                        .font(theme.labelFont(11))
                        .tracking(0.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(subtitle.uppercased())
                    .font(theme.smallFont(8))
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(0.78)
            }
            .foregroundColor(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .padding(.horizontal, 4)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(LinearGradient(colors: [face, face.opacity(0.78)],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(pressed ? 0.22 : 0.0))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(pressed ? 0.05 : 0.22), lineWidth: 0.8)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(theme.buttonEdge, lineWidth: 1.4)
            )
            .shadow(color: theme.shadowColor, radius: pressed ? 1 : 3, y: pressed ? 1 : 2)
            .offset(y: pressed ? 1 : 0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { down in
            pressed = down
        }, perform: {})
    }
}

/// A small moulded arrow that pages the station band one button at a time.
private struct ScrollChevron: View {
    let theme: SkinTheme
    let pointsRight: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.black.opacity(hovering ? 0.62 : 0.45))
                Image(systemName: pointsRight ? "chevron.right" : "chevron.left")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color.white.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
