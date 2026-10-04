import SwiftUI

/// The five visual identities RetroWave can wear. The raw value matches the
/// `code` field used in `stations.json`.
enum Country: String, CaseIterable, Codable, Identifiable, Hashable {
    case us = "US"
    case fr = "FR"
    case za = "ZA"
    case cn = "CN"
    case mx = "MX"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .us: return "UNITED STATES"
        case .fr: return "FRANCE"
        case .za: return "SOUTH AFRICA"
        case .cn: return "CHINA"
        case .mx: return "MEXICO"
        }
    }

    /// Short label used on the compact country buttons.
    var shortName: String {
        switch self {
        case .us: return "USA"
        case .fr: return "FR"
        case .za: return "ZA"
        case .cn: return "CN"
        case .mx: return "MX"
        }
    }

    var flag: String {
        switch self {
        case .us: return "🇺🇸"
        case .fr: return "🇫🇷"
        case .za: return "🇿🇦"
        case .cn: return "🇨🇳"
        case .mx: return "🇲🇽"
        }
    }

    var subtitle: String {
        switch self {
        case .us: return "Chrome & Neon Diner"
        case .fr: return "Art Déco Café"
        case .za: return "Ndebele Earth"
        case .cn: return "Lacquer & Gold"
        case .mx: return "Talavera & Tierra"
        }
    }

    /// Capital shown on the frequency scale, per local broadcast convention.
    var dialBandLabel: String {
        switch self {
        case .us, .za, .mx: return "FM MHz"
        case .fr: return "MHz"
        case .cn: return "FM kHz"
        }
    }

    /// Text shown etched on the cabinet badge.
    var modelName: String {
        switch self {
        case .us: return "RETROWAVE DELUXE"
        case .fr: return "RETROWAVE ART DÉCO"
        case .za: return "RETROWAVE KWA-NDEBELE"
        case .cn: return "RETROWAVE HONGQI"
        case .mx: return "RETROWAVE TALAVARA"
        }
    }
}
