import SwiftUI

/// Twin animated VU bars plus a peak-hold pip. Levels come from
/// `VUMeterState` (simulated — see NOTES.md); observing it here, rather than
/// taking plain values, keeps its ~18×/sec updates scoped to this view.
struct VUMeterView: View {
    let theme: SkinTheme
    @ObservedObject var vu: VUMeterState
    let state: RadioState

    private var lit: Bool { state == .playing }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text("VU")
                    .font(theme.smallFont(8))
                    .tracking(2)
                    .foregroundColor(Color.white.opacity(0.75))
                Spacer()
                // Power lamp
                Circle()
                    .fill(lit ? theme.glow : Color.white.opacity(0.22))
                    .frame(width: 7, height: 7)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.6))
                    .shadow(color: lit ? theme.glow.opacity(0.9) : .clear, radius: 4)
                Spacer()
                Text("L")
                    .font(theme.smallFont(7))
                    .foregroundColor(Color.white.opacity(0.5))
            }

            HStack(alignment: .bottom, spacing: 4) {
                bar
                bar
            }
            .frame(height: 34)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(theme.dialFace)
                // A permanent dark wash keeps the coloured bars legible on the
                // ivory dial faces used by the France and South Africa skins.
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.black.opacity(0.72))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(theme.dialFaceEdge.opacity(0.8), lineWidth: 1)
        )
    }

    private var bar: some View {
        GeometryReader { geo in
            let segments = 14
            let filled = Int((vu.level * Double(segments)).rounded())
            let peakSeg = Int((vu.peak * Double(segments)).rounded())
            VStack(spacing: 1.4) {
                ForEach(0..<segments, id: \.self) { i in
                    let isOn = i < filled
                    let isPeak = i == peakSeg - 1 && vu.peak > 0.04
                    RoundedRectangle(cornerRadius: 1)
                        .fill(segmentColor(index: i, segments: segments)
                            .opacity(isOn || isPeak ? 1 : 0.14))
                        .frame(height: geo.size.height / CGFloat(segments) - 1.4)
                }
            }
        }
    }

    /// Green up to 60%, amber to 82%, red beyond — the classic VU ramp.
    private func segmentColor(index: Int, segments: Int) -> Color {
        let ratio = Double(index) / Double(segments - 1)
        if ratio < 0.58 { return Color(red: 0.30, green: 0.80, blue: 0.42) }
        if ratio < 0.80 { return Color(red: 0.96, green: 0.78, blue: 0.20) }
        return Color(red: 0.94, green: 0.26, blue: 0.22)
    }
}
