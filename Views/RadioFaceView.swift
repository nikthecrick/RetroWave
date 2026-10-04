import SwiftUI
import Combine

/// The radio cabinet's face — the single screen that assembles every control.
///
/// Layout lives in a handful of small named views rather than one big `body`:
/// nested opaque return types make the Swift type-checker explode, and named
/// structs keep each `body` cheap to check.
struct RadioFaceView: View {
    @EnvironmentObject var player: RadioPlayer
    @EnvironmentObject var model: AppModel

    private var theme: SkinTheme { model.theme }

    var body: some View {
        CabinetPanel(theme: theme) {
            VStack(spacing: 8) {
                HeaderBar(theme: theme,
                          country: model.country,
                          isOn: player.state != .off,
                          isMini: model.isMiniPlayer,
                          onPower: {
                            SoundEffects.shared.playClick()
                            model.togglePower()
                          },
                          onToggleMini: {
                            SoundEffects.shared.playClick()
                            model.isMiniPlayer = true
                          })
                MiddleRow(theme: theme,
                          station: model.station,
                          state: player.state,
                          nowPlaying: player.nowPlayingTitle,
                          bitrate: player.bitrateLabel)
                NowPlayingStrip(theme: theme,
                                state: player.state,
                                title: player.nowPlayingTitle,
                                station: model.station,
                                band: model.country.dialBandLabel)
                ControlRow(theme: theme,
                           volume: $player.volume,
                           bass: $model.bass,
                           treble: $model.treble,
                           tone: $model.tone,
                           vu: player.vu,
                           state: player.state)
                Spacer(minLength: 0)
                StationBand(theme: theme,
                            stations: model.stations,
                            selectedID: model.station?.id,
                            state: player.state,
                            onSelect: { model.select($0) })
                Spacer(minLength: 6)
                CountryRow(theme: theme,
                           selected: model.country,
                           onSelect: { model.selectCountry($0) })
            }
            .padding(.horizontal, 14)
            // The extra bottom inset keeps the panel clear of the Ndebele and
            // fretwork borders that several skins paint along the cabinet edge.
            .padding(.top, 16)
            .padding(.bottom, 26)
            // Grab strip: the hidden title bar leaves nothing else to drag with.
            .overlay(alignment: .top) {
                WindowDragHandle()
            }
        }
        .frame(width: 800, height: 520)
    }
}

// MARK: - Cabinet

/// The outer shell: gradient body, procedural texture, trim and edge.
private struct CabinetPanel<Content: View>: View {
    let theme: SkinTheme
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .fill(LinearGradient(colors: [theme.cabinetTop, theme.cabinetBottom],
                                             startPoint: .top, endPoint: .bottom))

                    SkinEngine.textureView(for: theme)
                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius,
                                                   style: .continuous))

                    LinearGradient(colors: [theme.cabinetHighlight.opacity(0.55), .clear],
                                   startPoint: .top, endPoint: .center)
                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius,
                                                   style: .continuous))

                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .strokeBorder(theme.trimColor.opacity(0.75), lineWidth: 1.2)
                    RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                        .strokeBorder(theme.cabinetEdge, lineWidth: 3)
                        .padding(1.5)

                    RoundedRectangle(cornerRadius: max(theme.cornerRadius - 4, 2),
                                     style: .continuous)
                        .strokeBorder(Color.black.opacity(0.35), lineWidth: 6)
                        .blur(radius: 4)
                        .padding(6)
                        .allowsHitTesting(false)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
    }
}

// MARK: - Header

private struct HeaderBar: View {
    let theme: SkinTheme
    let country: Country
    let isOn: Bool
    let isMini: Bool
    let onPower: () -> Void
    let onToggleMini: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            BrandPlate(theme: theme)
            Spacer()
            MiniSwitch(theme: theme, isOn: isMini, action: onToggleMini)
            CountryPlate(theme: theme, country: country)
            PowerButtonView(theme: theme, isOn: isOn, action: onPower)
        }
        .frame(height: 42)
    }
}

/// A small vintage paddle switch: slides right to drop the cabinet into the
/// 300×80 mini bar. Deliberately quieter than the power rocker — brass knob
/// on a shadowed track, no glow, caption set like the other header labels.
private struct MiniSwitch: View {
    let theme: SkinTheme
    let isOn: Bool
    let action: () -> Void

    @State private var pressing = false

    private var slide: Bool { pressing || isOn }

    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                pressing = false
                action()
            }) {
                ZStack {
                    Capsule()
                        .fill(theme.bezelColor.opacity(0.55))
                        .shadow(color: .black.opacity(0.45), radius: 0.8, y: 0.8)
                    Capsule()
                        .strokeBorder(theme.dialFaceEdge.opacity(0.9), lineWidth: 1.1)
                    Circle()
                        .fill(LinearGradient(colors: [theme.knobRim, theme.knobRim.opacity(0.65)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().strokeBorder(theme.dialFaceEdge.opacity(0.7), lineWidth: 0.7))
                        .frame(width: 13, height: 13)
                        .offset(x: slide ? 11 : -11)
                        .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                        .animation(.easeInOut(duration: 0.14), value: slide)
                }
                .frame(width: 40, height: 18)
            }
            .buttonStyle(.plain)
            .onHover { pressing = $0 }

            Text("MINI")
                .font(theme.smallFont(6.5))
                .tracking(1.2)
                .foregroundColor(theme.readableOn(theme.cabinetBottom))
        }
    }
}

private struct BrandPlate: View {
    let theme: SkinTheme

    var body: some View {
        VStack(alignment: .leading, spacing: -1) {
            Text("RETROWAVE")
                .font(theme.font(24))
                .tracking(5)
                .foregroundColor(theme.accent)
            Text("SOLID STATE · FOUR BAND · EST. 1954")
                .font(theme.smallFont(8))
                .tracking(2.2)
                .foregroundColor(theme.dialSubText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(theme.dialFace)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(theme.trimColor.opacity(0.8), lineWidth: 1.0)
        )
        // The nameplate doubles as the title bar: with the real one hidden,
        // grabbing the cabinet by its badge is what moves the window.
        .contentShape(Rectangle())
        .windowDraggable()
    }
}

private struct CountryPlate: View {
    let theme: SkinTheme
    let country: Country

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("\(country.flag)  \(country.displayName)")
                .font(theme.labelFont(12))
                .tracking(2)
                .foregroundColor(theme.dialText)
            Text(country.subtitle.uppercased())
                .font(theme.smallFont(8))
                .tracking(1.6)
                .foregroundColor(theme.dialSubText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(theme.dialFace)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(theme.trimColor.opacity(0.8), lineWidth: 1.0)
        )
    }
}

// MARK: - Dial + grille

private struct MiddleRow: View {
    let theme: SkinTheme
    let station: Station?
    let state: RadioState
    let nowPlaying: String
    let bitrate: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TunerDialView(theme: theme,
                          station: station,
                          state: state,
                          nowPlaying: nowPlaying,
                          bitrate: bitrate)
                .frame(maxWidth: .infinity)
            SpeakerGrilleView(theme: theme)
                .frame(width: 268)
        }
    }
}

// MARK: - Now playing

private struct NowPlayingStrip: View {
    let theme: SkinTheme
    let state: RadioState
    let title: String
    let station: Station?
    let band: String

    private var headline: String {
        if title.isEmpty {
            return state == .off ? "SET STANDBY — PRESS POWER" : "NO ICY METADATA"
        }
        return title
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: state == .playing ? "waveform" : "speaker.slash")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(state == .playing ? theme.accent : theme.dialSubText)
            VStack(alignment: .leading, spacing: 0) {
                Text(headline)
                    .font(theme.labelFont(12))
                    .foregroundColor(theme.dialText)
                    .lineLimit(1)
                detail
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(theme.dialFace)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(theme.trimColor.opacity(0.8), lineWidth: 0.9)
        )
    }

    @ViewBuilder
    private var detail: some View {
        if let station {
            Text("\(station.city) · \(station.genre) · \(station.dialLabel) \(band)")
                .font(theme.smallFont(8.5))
                .tracking(0.8)
                .foregroundColor(theme.dialSubText)
                .lineLimit(1)
        }
    }
}

// MARK: - Knobs + VU

private struct ControlRow: View {
    let theme: SkinTheme
    @Binding var volume: Double
    @Binding var bass: Double
    @Binding var treble: Double
    @Binding var tone: Double
    /// The meter observes `VUMeterState` itself, so its ~18×/sec updates only
    /// re-render the meter — not this row, not the face.
    let vu: VUMeterState
    let state: RadioState

    var body: some View {
        HStack(spacing: 0) {
            KnobView(theme: theme, label: "Volume",
                     value: $volume, accent: theme.accent, showPercentage: true)
                .frame(maxWidth: .infinity)
            KnobView(theme: theme, label: "Bass", value: $bass)
                .frame(maxWidth: .infinity)
            KnobView(theme: theme, label: "Treble", value: $treble)
                .frame(maxWidth: .infinity)
            KnobView(theme: theme, label: "Tone", value: $tone,
                     accent: theme.secondaryAccent)
                .frame(maxWidth: .infinity)
            VUMeterView(theme: theme, vu: vu, state: state)
                .frame(width: 112)
        }
        .frame(height: 84)
    }
}

// MARK: - Station + country bands

private struct StationBand: View {
    let theme: SkinTheme
    let stations: [Station]
    let selectedID: String?
    let state: RadioState
    let onSelect: (Station) -> Void

    var body: some View {
        StationSelectorView(theme: theme,
                            stations: stations,
                            selectedID: selectedID,
                            state: state,
                            onSelect: onSelect)
    }
}

private struct CountryRow: View {
    let theme: SkinTheme
    let selected: Country
    let onSelect: (Country) -> Void

    var body: some View {
        CountrySelectorView(theme: theme, selected: selected, onSelect: onSelect)
    }
}
