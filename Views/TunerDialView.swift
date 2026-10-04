import SwiftUI
import Combine

/// The large tuning dial: a printed FM scale, a drifting analog needle, and a
/// central readout that shows the station name or the current signal state.
struct TunerDialView: View {
    let theme: SkinTheme
    let station: Station?
    let state: RadioState
    let nowPlaying: String
    let bitrate: String

    /// ±2° of needle life, slow and irregular, applied while the set is
    /// playing. Kept local to the dial: its ~4×/sec updates must only
    /// re-evaluate the dial, never the whole face — a face-wide re-render at
    /// that rate hitched window drags while the set was on.
    @State private var drift: Double = 0

    private var frequency: Double { station?.frequency ?? 88.0 }
    private var range: ClosedRange<Double> { 87.5...108.0 }

    private var needleFraction: Double {
        let f = frequency
        let lo = range.lowerBound, hi = range.upperBound
        return min(max((f - lo) / (hi - lo), 0), 1)
    }

    var body: some View {
        ZStack {
            // Dial face
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [theme.dialFace.opacity(0.98),
                                              theme.dialFace.opacity(0.88)],
                                     startPoint: .top, endPoint: .bottom))

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(theme.dialFaceEdge, lineWidth: 2)

            // Faint warm glow when the valve is lit
            RadialGradient(colors: [theme.dialGlow.opacity(state == .playing ? 0.30 : 0.0),
                                    .clear],
                           center: .center, startRadius: 6, endRadius: 150)
                .blendMode(.plusLighter)

            VStack(spacing: 4) {
                // Readout
                VStack(spacing: 1) {
                    Text(station?.name.uppercased() ?? "NO STATION")
                        .font(theme.font(21))
                        .tracking(1.2)
                        .foregroundColor(state == .off
                                         ? theme.dialText.opacity(0.35)
                                         : theme.dialText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .shadow(color: theme.dialGlow.opacity(state == .playing ? 0.9 : 0.0),
                                radius: 6)

                    HStack(spacing: 8) {
                        Text(state.dialText)
                            .font(theme.smallFont(11))
                            .tracking(2.0)
                        if let city = station?.city {
                            Text("·").foregroundColor(theme.dialSubText)
                            Text(city.uppercased())
                                .font(theme.smallFont(11))
                                .tracking(1.4)
                        }
                        if !bitrate.isEmpty {
                            Text("·").foregroundColor(theme.dialSubText)
                            Text(bitrate)
                                .font(theme.smallFont(11))
                                .tracking(1.2)
                        }
                    }
                    .foregroundColor(theme.dialSubText)
                }
                .padding(.top, 6)

                // Scale + needle
                ZStack(alignment: .topLeading) {
                    DialScaleCanvas(theme: theme,
                                    needleFraction: needleFraction,
                                    state: state)
                        .equatable()

                    // Needle (idle drift of ±2°). It stops at the scale line so
                    // it never overprints the frequency numerals below it.
                    GeometryReader { geo in
                        let left: CGFloat = 26
                        let gutter: CGFloat = 40
                        let span = geo.size.width - 52 - gutter
                        let x = left + span * needleFraction
                        let baseline = geo.size.height - 12
                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(LinearGradient(colors: [theme.needleColor.opacity(0.25),
                                                              theme.needleColor,
                                                              theme.needleColor.opacity(0.35)],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: 2.2)
                            // Pointer arrow riding the scale
                            Path { p in
                                p.move(to: CGPoint(x: -6, y: baseline - 9))
                                p.addLine(to: CGPoint(x: 6, y: baseline - 9))
                                p.addLine(to: CGPoint(x: 0, y: baseline - 18))
                                p.closeSubpath()
                            }
                            .fill(theme.needleColor)
                        }
                        .frame(width: 14, height: baseline)
                        .position(x: x, y: baseline / 2)
                        .rotationEffect(.degrees(state == .playing ? drift : 0))
                        .shadow(color: theme.needleColor.opacity(0.7), radius: 4)
                    }
                }
                .frame(height: 46)
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 4)

            // Glass reflection sheen
            LinearGradient(colors: [.white.opacity(0.16), .clear, .white.opacity(0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .allowsHitTesting(false)
        }
        .frame(height: 146)
        .shadow(color: theme.shadowColor, radius: 4, y: 2)
        .onReceive(tick) { date in
            let t = date.timeIntervalSince1970
            if state == .playing {
                withAnimation(.easeInOut(duration: 0.9)) {
                    drift = sin(t * 0.9) * 2.0 + sin(t * 2.3) * 0.6
                }
            } else {
                withAnimation(.easeInOut(duration: 0.5)) { drift = 0 }
            }
        }
    }

    private var tick: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 0.28, on: .main, in: .common).autoconnect()
    }
}

/// The printed scale, baseline rule, band caption and lit band.
///
/// This content only changes when the tuned station or the signal state
/// changes, yet the face re-evaluates ~4x a second for the needle drift and
/// would hand the Canvas a fresh closure on every pass — re-rasterising the
/// whole scale each time. Keyed Equatable, so SwiftUI skips it between
/// tuning changes.
private struct DialScaleCanvas: View, Equatable {
    let theme: SkinTheme
    let needleFraction: Double
    let state: RadioState

    static func == (lhs: DialScaleCanvas, rhs: DialScaleCanvas) -> Bool {
        lhs.theme.country == rhs.theme.country
            && lhs.needleFraction == rhs.needleFraction
            && lhs.state == rhs.state
    }

    private static let range: ClosedRange<Double> = 87.5...108.0

    var body: some View {
        Canvas { ctx, size in
            let baseline = size.height - 12
            let left: CGFloat = 26
            // The right-hand gutter reserves space for the band
            // caption so the needle can never overlap it.
            let gutter: CGFloat = 40
            let right = size.width - 26 - gutter
            let span = right - left

            // Minor / major ticks
            var f = Self.range.lowerBound
            while f <= Self.range.upperBound + 0.001 {
                let t = CGFloat((f - Self.range.lowerBound) / (Self.range.upperBound - Self.range.lowerBound))
                let x = left + span * t
                let isMajor = abs(f.rounded() - f) < 0.001
                let h: CGFloat = isMajor ? 13 : 7
                var p = Path()
                p.move(to: CGPoint(x: x, y: baseline - h))
                p.addLine(to: CGPoint(x: x, y: baseline))
                ctx.stroke(p, with: .color(theme.scaleTick.opacity(isMajor ? 0.9 : 0.5)),
                           lineWidth: isMajor ? 1.5 : 0.8)
                if isMajor {
                    let label = "\(Int(f))"
                    let resolved = ctx.resolve(
                        Text(label).font(theme.smallFont(9)).foregroundColor(theme.scaleTick))
                    ctx.draw(resolved, at: CGPoint(x: x, y: baseline + 1), anchor: .top)
                }
                f += 0.5
            }

            // Baseline rule
            var base = Path()
            base.move(to: CGPoint(x: left - 6, y: baseline))
            base.addLine(to: CGPoint(x: right + 6, y: baseline))
            ctx.stroke(base, with: .color(theme.scaleTick.opacity(0.55)), lineWidth: 1)

            // Band caption, parked at the right end of the scale so
            // the needle can never sweep across it.
            let band = ctx.resolve(
                Text(theme.country.dialBandLabel)
                    .font(theme.smallFont(8))
                    .foregroundColor(theme.dialSubText))
            ctx.draw(band, at: CGPoint(x: size.width - 4, y: baseline - 12), anchor: .topTrailing)

            // Faint "lit band" behind the tuned station
            let nx = left + span * needleFraction
            let glow = Path(
                roundedRect: CGRect(x: nx - 16, y: baseline - 20, width: 32, height: 22),
                cornerRadius: 6)
            ctx.fill(glow, with: .color(theme.dialGlow.opacity(state == .playing ? 0.35 : 0.12)))
        }
    }
}
