import SwiftUI

/// A physical control knob. Rotate by dragging vertically; the value maps
/// linearly onto 0…1 over a 270° sweep.
struct KnobView: View {
    let theme: SkinTheme
    let label: String
    @Binding var value: Double
    var accent: Color?
    var showPercentage: Bool = false

    @State private var dragStart: Double?
    /// True while the cap is being turned by hand. The rotation must track the
    /// cursor 1:1 then; the spring is only for programmatic value changes —
    /// mid-drag it makes the cap lag the cursor, then overshoot and wobble.
    @State private var isTurning = false

    private var accentColor: Color { accent ?? theme.accent }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Skirt / mounting plate
                Circle()
                    .fill(RadialGradient(colors: [theme.bezelColor.opacity(0.9),
                                                   theme.shadowColor],
                                         center: .center, startRadius: 4, endRadius: 34))
                    .frame(width: 62, height: 62)
                    .overlay(Circle().strokeBorder(theme.dialFaceEdge.opacity(0.6), lineWidth: 1))

                // Tick marks around the skirt
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let r = size.width / 2 - 2
                    for i in 0...10 {
                        let t = Double(i) / 10.0
                        let a = Angle.degrees(135 + 270 * t)
                        var p = Path()
                        p.move(to: CGPoint(x: c.x + cos(a.radians) * r,
                                           y: c.y + sin(a.radians) * r))
                        p.addLine(to: CGPoint(x: c.x + cos(a.radians) * (r - 4.5),
                                              y: c.y + sin(a.radians) * (r - 4.5)))
                        ctx.stroke(p, with: .color(theme.dialFaceEdge.opacity(0.55)),
                                   lineWidth: i % 5 == 0 ? 1.4 : 0.7)
                    }
                }
                .frame(width: 62, height: 62)

                // The cap in three layers: a static base, the part that turns
                // with the value, and a static lighting/trim overlay on top —
                // the highlight stays at the upper left while the cap rotates,
                // the way a real knob sits under a fixed light source.
                capBase
                    .frame(width: 46, height: 46)
                capRotating
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-135 + 270 * value))
                    .animation(isTurning ? nil : .interactiveSpring(response: 0.16, dampingFraction: 0.8),
                               value: value)
                capLighting
                    .frame(width: 46, height: 46)
                    .allowsHitTesting(false)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        isTurning = true
                        let start = dragStart ?? value
                        if dragStart == nil { dragStart = start }
                        // 150 pt of vertical travel covers the full sweep.
                        let delta = (start - g.translation.height) / 150.0
                        value = min(max(start + delta, 0), 1)
                    }
                    .onEnded { _ in
                        dragStart = nil
                        isTurning = false
                    }
            )

            // Label and readout share one baseline so every knob in the row
            // lines up regardless of whether it shows a percentage.
            HStack(spacing: 4) {
                Text(label.uppercased())
                    .font(theme.smallFont(8))
                    .tracking(1.2)
                    .foregroundColor(panelInk)
                if showPercentage {
                    Text("\(Int((value * 100).rounded()))")
                        .font(theme.smallFont(8))
                        .foregroundColor(accentColor.opacity(0.95))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    /// Knob engraving sits directly on the cabinet, so its colour has to be
    /// derived from the cabinet finish rather than the dial face.
    private var panelInk: Color {
        theme.readableOn(theme.cabinetBottom)
    }

    // Each material is built in three layers so the type-checker stays
    // tractable: a static base, the part that turns with the value, and a
    // static lighting/trim overlay. The specular highlight must not rotate
    // with the cap — doing so makes the knob look like it slides and tilts
    // instead of turning under a fixed light.

    @ViewBuilder
    private var capBase: some View {
        switch theme.knobStyle {
        case .chromeDome:
            Circle().fill(RadialGradient(colors: theme.knobBody,
                                         center: .topLeading,
                                         startRadius: 1,
                                         endRadius: 30))
        case .bakelite:
            Circle().fill(AngularGradient(colors: theme.knobBody + [theme.knobBody[0]],
                                          center: .center))
        case .turnedWood:
            Circle().fill(AngularGradient(colors: theme.knobBody + [theme.knobBody[0]],
                                          center: .center))
        case .lacquerGold:
            ZStack {
                Circle().fill(RadialGradient(colors: theme.knobBody,
                                             center: .topLeading,
                                             startRadius: 1,
                                             endRadius: 28))
                Circle().strokeBorder(theme.knobRim, lineWidth: 3).padding(4)
                Circle().strokeBorder(theme.knobRim.opacity(0.6), lineWidth: 1).padding(8)
            }
        case .clay:
            ZStack {
                Circle().fill(RadialGradient(colors: theme.knobBody,
                                             center: .topLeading,
                                             startRadius: 1,
                                             endRadius: 28))
                Circle().strokeBorder(theme.knobRim, lineWidth: 4).padding(5)
                Circle().strokeBorder(theme.knobRim.opacity(0.5), lineWidth: 1).padding(13)
            }
        }
    }

    @ViewBuilder
    private var capRotating: some View {
        switch theme.knobStyle {
        case .chromeDome, .lacquerGold:
            // Shiny domes carry no milled texture: only the pointer mark moves.
            pointer
        case .bakelite:
            ZStack {
                fluting(count: 24, inset: 2, width: 4, opacity: 0.30, lineWidth: 1.6)
                pointer
            }
        case .turnedWood:
            ZStack {
                latheRings()
                pointer
            }
        case .clay:
            ZStack {
                claySpeckle()
                pointer
            }
        }
    }

    @ViewBuilder
    private var capLighting: some View {
        switch theme.knobStyle {
        case .chromeDome:
            ZStack {
                Circle().fill(AngularGradient(colors: [.white.opacity(0.55), .clear,
                                                      .black.opacity(0.30), .white.opacity(0.35)],
                                              center: .center))
                    .blendMode(.overlay)
                Circle().strokeBorder(theme.knobRim, lineWidth: 1.4)
                Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 0.6)
            }
        case .bakelite:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color.white.opacity(0.16), .clear],
                                             center: .topLeading,
                                             startRadius: 1,
                                             endRadius: 22))
                Circle().strokeBorder(theme.knobRim.opacity(0.85), lineWidth: 1.2)
            }
        case .turnedWood:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color.white.opacity(0.18), .clear],
                                             center: .topLeading,
                                             startRadius: 1,
                                             endRadius: 22))
                Circle().strokeBorder(theme.knobRim, lineWidth: 1.6)
            }
        case .lacquerGold:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color.white.opacity(0.22), .clear],
                                             center: .topLeading,
                                             startRadius: 1,
                                             endRadius: 18))
                Circle().strokeBorder(theme.knobRim, lineWidth: 1.2)
            }
        case .clay:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color.white.opacity(0.14), .clear],
                                             center: .topLeading,
                                             startRadius: 1,
                                             endRadius: 20))
                Circle().strokeBorder(theme.knobRim.opacity(0.7), lineWidth: 0.9)
            }
        }
    }

    /// Radial flutes moulded into the edge of a bakelite knob.
    private func fluting(count: Int, inset: CGFloat, width: CGFloat,
                         opacity: Double, lineWidth: CGFloat) -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = size.width / 2 - inset
            for i in 0..<count {
                let a = Double(i) / Double(count) * .pi * 2
                var p = Path()
                p.move(to: CGPoint(x: c.x + cos(a) * outer, y: c.y + sin(a) * outer))
                p.addLine(to: CGPoint(x: c.x + cos(a) * (outer - width),
                                      y: c.y + sin(a) * (outer - width)))
                ctx.stroke(p, with: .color(Color.black.opacity(opacity)), lineWidth: lineWidth)
            }
        }
    }

    /// Fire specks and inclusions in unglazed clay, fixed positions so the
    /// speckle pattern rotates with the cap like a real thrown knob.
    private func claySpeckle() -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var seed: UInt64 = 0xA1E5_51CA
            for _ in 0..<16 {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let a = Double((seed >> 33) % 3600) / 3600.0 * .pi * 2
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let r = Double((seed >> 33) % 1000) / 1000.0 * (Double(size.width) / 2 - 9)
                let p = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.7, y: p.y - 0.7,
                                                width: 1.4, height: 1.4)),
                         with: .color(.black.opacity(0.12)))
            }
        }
    }

    /// Concentric turning marks left by the lathe.
    private func latheRings() -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 1..<5 {
                let r = size.width / 2 * (0.22 + 0.17 * Double(i))
                let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r,
                                                  width: r * 2, height: r * 2))
                ctx.stroke(ring, with: .color(Color.black.opacity(0.16)), lineWidth: 0.9)
            }
        }
    }

    private var pointer: some View {
        Capsule()
            .fill(theme.knobPointer)
            .frame(width: 3, height: 13)
            .offset(y: -12)
            .shadow(color: theme.knobPointer.opacity(0.8), radius: 2)
    }
}

/// The IEC power symbol, drawn as a stroked arc with a gap plus a stem.
private struct PowerGlyph: View {
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2 - 1.6
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            // Arc from just past 12 o'clock, clockwise around to just before it,
            // leaving the gap at the top that the stem fills.
            let start = Angle.degrees(-90 + 38)
            let end = Angle.degrees(270 - 38)
            let ring = Path { p in
                p.addArc(center: c, radius: r, startAngle: start,
                         endAngle: end, clockwise: false)
            }
            ctx.stroke(ring, with: .color(color), lineWidth: 1.8)

            var stem = Path()
            stem.move(to: CGPoint(x: c.x, y: c.y - r * 0.95))
            stem.addLine(to: CGPoint(x: c.x, y: c.y - r * 0.05))
            ctx.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
    }
}

/// The speaker grille: horizontal slats over a cloth ground, drawn in Canvas.
struct SpeakerGrilleView: View {
    let theme: SkinTheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [theme.grilleBase, theme.grilleBase.opacity(0.72)],
                                     startPoint: .top, endPoint: .bottom))

            Canvas { ctx, size in
                let inset: CGFloat = 10
                let slatCount = 15
                let usable = size.height - inset * 2
                let pitch = usable / CGFloat(slatCount)
                for i in 0..<slatCount {
                    let y = inset + pitch * (CGFloat(i) + 0.5)
                    // Slat shadow
                    let dark = Path(roundedRect: CGRect(x: inset, y: y - pitch * 0.30,
                                                        width: size.width - inset * 2,
                                                        height: pitch * 0.44),
                                    cornerRadius: pitch * 0.22)
                    ctx.fill(dark, with: .color(theme.grilleLine.opacity(0.85)))
                    // Highlight on the upper lip
                    let lit = Path(roundedRect: CGRect(x: inset, y: y - pitch * 0.34,
                                                       width: size.width - inset * 2,
                                                       height: pitch * 0.13),
                                   cornerRadius: pitch * 0.06)
                    ctx.fill(lit, with: .color(theme.grilleHighlight.opacity(0.35)))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Woven cloth cross-hatch, very subtle
            Canvas { ctx, size in
                var x: CGFloat = 0
                while x < size.width {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(p, with: .color(theme.grilleHighlight.opacity(0.06)), lineWidth: 1)
                    x += 4
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(theme.bezelColor, lineWidth: 3)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(theme.dialFaceEdge.opacity(0.5), lineWidth: 0.8)

            // Maker's badge on the grille cloth
            VStack(spacing: 1) {
                Text("RETROWAVE")
                    .font(theme.labelFont(11))
                    .tracking(3)
                Text(theme.country.modelName)
                    .font(theme.smallFont(7))
                    .tracking(1.6)
                    .opacity(0.8)
            }
            .foregroundColor(theme.grilleHighlight.opacity(0.75))
        }
        .frame(height: 146)
        .shadow(color: theme.shadowColor, radius: 4, y: 2)
    }
}

/// The power rocker: unlit and dead when off, glowing when on.
struct PowerButtonView: View {
    let theme: SkinTheme
    let isOn: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        VStack(spacing: 3) {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(LinearGradient(colors: isOn
                                             ? [theme.accent.opacity(0.95), theme.accent.opacity(0.55)]
                                             : [theme.buttonFace.opacity(0.85), theme.buttonFace.opacity(0.55)],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(theme.dialFaceEdge.opacity(0.8), lineWidth: 1.4)
                    // Power glyph: a ring with a gap at the top, plus a stem.
                    PowerGlyph(color: isOn ? theme.readableOn(theme.accent) : theme.buttonText)
                        .frame(width: 14, height: 14)
                    if isOn {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(theme.glow, lineWidth: 2)
                            .blur(radius: 4)
                            .opacity(0.85)
                    }
                }
                .frame(width: 44, height: 30)
                .shadow(color: isOn ? theme.glow.opacity(0.8) : .clear, radius: 8)
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }

            Text("POWER")
                .font(theme.smallFont(6.5))
                .tracking(1.2)
                .foregroundColor(theme.readableOn(theme.cabinetBottom))
        }
        .scaleEffect(hovering ? 1.04 : 1.0)
    }
}
