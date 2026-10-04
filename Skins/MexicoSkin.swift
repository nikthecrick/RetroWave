import SwiftUI

/// 🇲🇽 Mexico — sun-baked adobe, talavera tile border, papel picado garland,
/// hand-thrown clay knobs.
enum MexicoSkin {

    static let theme = SkinTheme(
        country: .mx,
        cabinetTop: Color(red: 0.76, green: 0.44, blue: 0.22),
        cabinetBottom: Color(red: 0.52, green: 0.27, blue: 0.11),
        cabinetEdge: Color(red: 0.28, green: 0.14, blue: 0.06),
        cabinetHighlight: Color(red: 0.94, green: 0.70, blue: 0.44).opacity(0.7),
        cornerRadius: 14,
        bezelColor: Color(red: 0.34, green: 0.18, blue: 0.08),
        trimColor: Color(red: 0.95, green: 0.77, blue: 0.32), // marigold
        shadowColor: Color.black.opacity(0.5),
        dialFace: Color(red: 1.00, green: 0.97, blue: 0.88),
        dialFaceEdge: Color(red: 0.30, green: 0.15, blue: 0.06),
        dialText: Color(red: 0.24, green: 0.11, blue: 0.04),
        dialSubText: Color(red: 0.48, green: 0.30, blue: 0.14),
        dialGlow: Color(red: 1.00, green: 0.80, blue: 0.40),
        needleColor: Color(red: 0.85, green: 0.16, blue: 0.10), // cochineal
        scaleTick: Color(red: 0.35, green: 0.20, blue: 0.09),
        grilleBase: Color(red: 0.62, green: 0.36, blue: 0.16),
        grilleLine: Color(red: 0.25, green: 0.13, blue: 0.05),
        grilleHighlight: Color(red: 0.95, green: 0.76, blue: 0.48),
        knobStyle: .clay,
        knobBody: [Color(red: 0.82, green: 0.52, blue: 0.30),
                   Color(red: 0.60, green: 0.34, blue: 0.16),
                   Color(red: 0.36, green: 0.19, blue: 0.08)],
        knobRim: Color(red: 0.95, green: 0.77, blue: 0.32), // marigold glaze
        knobPointer: Color(red: 0.13, green: 0.40, blue: 0.66), // talavera cobalt
        buttonFace: Color(red: 0.50, green: 0.28, blue: 0.13),
        buttonFaceActive: Color(red: 0.90, green: 0.30, blue: 0.14), // cempasúchil
        buttonEdge: Color(red: 0.24, green: 0.12, blue: 0.05),
        buttonText: Color(red: 0.99, green: 0.93, blue: 0.82),
        accent: Color(red: 0.91, green: 0.36, blue: 0.12),   // cempasúchil orange
        secondaryAccent: Color(red: 0.16, green: 0.42, blue: 0.70), // talavera cobalt
        glow: Color(red: 1.00, green: 0.74, blue: 0.30),
        displayFontName: FontProbe.firstAvailable([
            "AvenirNextCondensed-Heavy", "AvenirNext-Heavy",
            "GillSans-Bold", "HelveticaNeue-CondensedBold",
        ]),
        labelFontName: FontProbe.firstAvailable([
            "AvenirNextCondensed-Medium", "AvenirNext-Medium",
        ]),
        smallFontName: FontProbe.firstAvailable([
            "CourierNewPS-BoldMT", "Menlo-Bold",
        ]),
        texture: .terracottaAndTalavera
    )
}
