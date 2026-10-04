import Foundation

/// A single internet radio station, loaded from `stations.json`.
struct Station: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let city: String
    let region: String
    let countryCode: String
    let genre: String
    let bitrateKbps: Int
    let streamURL: String
    /// Fictional "FM/AM dial position" in MHz, used by the analog tuning needle.
    let frequency: Double

    var url: URL? { URL(string: streamURL) }

    /// Two-decimal dial label, e.g. 101.7
    var dialLabel: String { String(format: "%.1f", frequency) }
}

/// Root object of `stations.json`.
struct StationLibrary: Codable {
    let version: Int
    let generated: String
    let source: String
    let countries: [CountryEntry]
}

struct CountryEntry: Codable {
    let code: String
    let name: String
    let locations: [LocationEntry]
}

struct LocationEntry: Codable {
    let city: String
    let country: String
    let stations: [Station]
}

/// Loads and decodes the bundled, verified `stations.json`.
enum StationLibraryLoader {
    /// - Parameter override: an explicit file to read instead of the one inside
    ///   the app bundle. Used by the offscreen preview tool.
    static func load(override: URL? = nil) -> [Country: [Station]] {
        let url = override ?? Bundle.main.url(forResource: "stations", withExtension: "json")
        guard let url else {
            #if DEBUG
            print("[RetroWave] stations.json not found in bundle")
            #endif
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let lib = try JSONDecoder().decode(StationLibrary.self, from: data)
            var out: [Country: [Station]] = [:]
            for entry in lib.countries {
                guard let country = Country(rawValue: entry.code) else { continue }
                out[country] = entry.locations.flatMap { $0.stations }
            }
            return out
        } catch {
            print("[RetroWave] stations.json decode failed: \(error)")
            return [:]
        }
    }
}
