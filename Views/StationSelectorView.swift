import SwiftUI

/// One row of moulded pushbuttons — one per station on the current country's
/// dial. The buttons flex to fill the cabinet width, so every station is
/// visible at once: no scrolling, no clipping. Crowded sets (nine or more)
/// switch to a tighter engraving so the text stays readable at narrow widths.
struct StationSelectorView: View {
    let theme: SkinTheme
    let stations: [Station]
    let selectedID: String?
    let state: RadioState
    let onSelect: (Station) -> Void

    private let gap: CGFloat = 8
    private let height: CGFloat = 52

    var body: some View {
        let compact = stations.count >= 9
        HStack(spacing: gap) {
            ForEach(stations) { station in
                PushButton(
                    theme: theme,
                    title: shortTitle(station),
                    subtitle: station.genre,
                    isActive: station.id == selectedID,
                    isLive: station.id == selectedID && state == .playing,
                    compact: compact
                ) {
                    onSelect(station)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
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
    /// Crowded bands engrave smaller so twelve stations stay legible.
    var compact: Bool = false
    let action: () -> Void

    @State private var pressed = false

    private var face: Color { isActive ? theme.buttonFaceActive : theme.buttonFace }
    private var ink: Color { theme.readableOn(face) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: compact ? 3 : 4) {
                    if !compact {
                        Circle()
                            .fill(isLive ? theme.glow : ink.opacity(0.45))
                            .frame(width: 5, height: 5)
                            .shadow(color: isLive ? theme.glow : .clear, radius: 3)
                    } else {
                        Circle()
                            .fill(isLive ? theme.glow : ink.opacity(0.45))
                            .frame(width: 3.5, height: 3.5)
                            .shadow(color: isLive ? theme.glow : .clear, radius: 2)
                    }
                    Text(title)
                        .font(theme.labelFont(compact ? 9 : 11))
                        .tracking(compact ? 0.4 : 0.6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Text(subtitle.uppercased())
                    .font(theme.smallFont(compact ? 6.5 : 8))
                    .tracking(compact ? 0.4 : 0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
