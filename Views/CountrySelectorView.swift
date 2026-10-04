import SwiftUI

/// The bottom row: a globe badge plus one selector per country skin.
struct CountrySelectorView: View {
    let theme: SkinTheme
    let selected: Country
    let onSelect: (Country) -> Void

    var body: some View {
        HStack(spacing: 8) {
            GlobeBadge(theme: theme)
                .frame(width: 46, height: 46)
            ForEach(Country.allCases) { country in
                let isActive = country == selected
                Button {
                    guard !isActive else { return }
                    onSelect(country)
                } label: {
                    let face: Color = isActive ? theme.accent : Color.black.opacity(0.34)
                    HStack(spacing: 6) {
                        Text(country.flag)
                            .font(.system(size: 17))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(country.displayName)
                                .font(theme.labelFont(11))
                                .tracking(0.8)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(country.subtitle)
                                .font(theme.smallFont(7.5))
                                .tracking(0.4)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .opacity(0.82)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(isActive ? theme.readableOn(theme.accent) : theme.buttonText)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(face)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isActive ? theme.glow : theme.buttonEdge.opacity(0.7),
                                          lineWidth: isActive ? 1.8 : 1.0)
                    )
                    .shadow(color: isActive ? theme.glow.opacity(0.55) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A slowly rotating wire-frame globe drawn with Canvas — the "WORLD" band knob.
private struct GlobeBadge: View {
    let theme: SkinTheme

    @State private var spin: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [theme.bezelColor, theme.bezelColor.opacity(0.35)],
                                     center: .center, startRadius: 2, endRadius: 26))
            Canvas { ctx, size in
                let r = size.width / 2 - 3
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r,
                                                   width: r * 2, height: r * 2)),
                           with: .color(theme.trimColor.opacity(0.9)), lineWidth: 1.2)
                // Meridians squeezed horizontally to fake rotation
                for k in [-0.62, -0.3, 0.0, 0.3, 0.62] {
                    let w = r * 2 * abs(1 - k * k)
                    let offset = CGFloat(sin(spin)) * r * 0.8 * (k == 0 ? 0 : 1)
                    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - w / 2 + offset * 0,
                                                      y: c.y - r, width: w, height: r * 2)),
                               with: .color(theme.trimColor.opacity(0.55)), lineWidth: 0.8)
                }
                // Parallels
                for f in [-0.55, 0.0, 0.55] {
                    let yy = c.y + r * CGFloat(f)
                    let hh = r * 0.30 * (1 - abs(f) * 0.7)
                    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: yy - hh / 2,
                                                      width: r * 2, height: hh)),
                               with: .color(theme.trimColor.opacity(0.45)), lineWidth: 0.8)
                }
            }
            Text("WORLD")
                .font(theme.smallFont(6))
                .tracking(1)
                .foregroundColor(theme.trimColor)
                .offset(y: 0)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                spin = .pi * 2
            }
        }
    }
}
