import SwiftUI
import Combine

/// Owns the selected skin, the station list for that skin, and the persisted
/// state. Everything the cabinet renders flows from here.
@MainActor
final class AppModel: ObservableObject {

    @Published var country: Country {
        didSet {
            guard country != oldValue else { return }
            persistCountry()
            SoundEffects.shared.playStatic()
            restoreStationForCountry()
        }
    }

    @Published var station: Station? {
        didSet {
            persistSelection()
            guard !suppressPlay else { return }
            player.play(station ?? currentFallback)
        }
    }

    /// Set while the model is seeding itself, so restoring the last session
    /// primes the dial instead of powering the set on.
    private var suppressPlay = true

    // Cosmetic tone controls — they drive the knob visuals only.
    @Published var bass: Double = 0.5
    @Published var treble: Double = 0.5
    @Published var tone: Double = 0.5

    @Published var isMiniPlayer = false
    @Published var showAbout = false

    let player: RadioPlayer
    private let library: [Country: [Station]]

    init(player: RadioPlayer, library: [Country: [Station]]) {
        self.player = player
        self.library = library
        self.country = AppModel.restoreCountry(from: player)
        self.station = nil
        // Prime the player with a station but keep the set in standby.
        if let first = AppModel.restoreStation(from: player, in: library, country: country) {
            self.station = first
        } else {
            self.station = library[country]?.first
        }
        player.stationsForSelection = stations
        player.prime(station ?? stations.first ?? StationLibrary.placeholder)
        suppressPlay = false
    }

    private func persistSelection() {
        guard !suppressPlay else { return }
        UserDefaults.standard.set(station?.id, forKey: "retrowave.station")
    }

    // MARK: Derived

    var theme: SkinTheme { SkinEngine.theme(for: country) }
    var stations: [Station] { library[country] ?? [] }

    private var currentFallback: Station {
        station ?? stations.first ?? StationLibrary.placeholder
    }

    // MARK: Actions

    func select(_ station: Station) {
        guard self.station?.id != station.id else {
            // Tapping the live station again toggles the power.
            togglePower()
            return
        }
        SoundEffects.shared.playClick()
        self.station = station
        player.play(station)
    }

    func selectCountry(_ country: Country) {
        guard country != self.country else { return }
        SoundEffects.shared.playClick()
        withAnimation(SkinEngine.crossfade) {
            self.country = country
        }
    }

    func togglePower() {
        if player.state == .off {
            player.play(currentFallback)
        } else {
            player.stop()
        }
    }

    // MARK: Persistence

    private func persistCountry() {
        UserDefaults.standard.set(country.rawValue, forKey: "retrowave.country")
    }

    private func restoreStationForCountry() {
        let list = stations
        // Keep the same station if it belongs to the new country, else take the
        // first one and remember it.
        if let current = station, current.countryCode == country.rawValue {
            player.stationsForSelection = list
            return
        }
        let next = list.first
        station = next
        player.stationsForSelection = list
        if let next { player.prime(next) }
    }

    private static func restoreCountry(from player: RadioPlayer) -> Country {
        guard let code = player.savedCountryCode, let c = Country(rawValue: code) else { return .us }
        return c
    }

    private static func restoreStation(from player: RadioPlayer,
                                       in library: [Country: [Station]],
                                       country: Country) -> Station? {
        guard let id = player.savedStationID else { return library[country]?.first }
        for list in library.values {
            if let hit = list.first(where: { $0.id == id }) { return hit }
        }
        return library[country]?.first
    }
}

extension StationLibrary {
    /// Used only if `stations.json` is missing from the bundle, so the UI still
    /// renders instead of crashing.
    static let placeholder = Station(
        id: "placeholder", name: "RETROWAVE", city: "—", region: "",
        countryCode: "US", genre: "off air", bitrateKbps: 0,
        streamURL: "https://ice1.somafm.com/groovesalad-128-mp3", frequency: 98.7
    )
}
