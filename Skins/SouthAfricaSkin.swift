import SwiftUI

/// 🇿🇦 South Africa — warm hardwood, turned wooden knobs, Ndebele border.
enum SouthAfricaSkin {

    static let theme = SkinTheme(
        country: .za,
        cabinetTop: Color(red: 0.62, green: 0.40, blue: 0.20),
        cabinetBottom: Color(red: 0.38, green: 0.22, blue: 0.10),
        cabinetEdge: Color(red: 0.22, green: 0.12, blue: 0.05),
        cabinetHighlight: Color(red: 0.86, green: 0.66, blue: 0.40).opacity(0.7),
        cornerRadius: 14,
        bezelColor: Color(red: 0.30, green: 0.18, blue: 0.08),
        trimColor: Color(red: 0.90, green: 0.70, blue: 0.20),
        shadowColor: Color.black.opacity(0.5),
        dialFace: Color(red: 0.99, green: 0.97, blue: 0.90),
        dialFaceEdge: Color(red: 0.22, green: 0.12, blue: 0.05),
        dialText: Color(red: 0.20, green: 0.11, blue: 0.04),
        dialSubText: Color(red: 0.45, green: 0.28, blue: 0.14),
        dialGlow: Color(red: 1.00, green: 0.82, blue: 0.45),
        needleColor: Color(red: 0.80, green: 0.42, blue: 0.10),
        scaleTick: Color(red: 0.32, green: 0.20, blue: 0.10),
        grilleBase: Color(red: 0.50, green: 0.31, blue: 0.15),
        grilleLine: Color(red: 0.20, green: 0.11, blue: 0.04),
        grilleHighlight: Color(red: 0.92, green: 0.74, blue: 0.46),
        knobStyle: .turnedWood,
        knobBody: [Color(red: 0.80, green: 0.58, blue: 0.32),
                   Color(red: 0.56, green: 0.36, blue: 0.17),
                   Color(red: 0.32, green: 0.19, blue: 0.08)],
        knobRim: Color(red: 0.88, green: 0.68, blue: 0.36),
        knobPointer: Color(red: 0.16, green: 0.52, blue: 0.78), // cobalt
        buttonFace: Color(red: 0.45, green: 0.28, blue: 0.13),
        buttonFaceActive: Color(red: 0.84, green: 0.42, blue: 0.12), // burnt orange
        buttonEdge: Color(red: 0.20, green: 0.11, blue: 0.04),
        buttonText: Color(red: 0.99, green: 0.94, blue: 0.84),
        accent: Color(red: 0.86, green: 0.43, blue: 0.11),   // burnt orange
        secondaryAccent: Color(red: 0.16, green: 0.44, blue: 0.74), // cobalt
        glow: Color(red: 0.98, green: 0.70, blue: 0.28),
        displayFontName: FontProbe.firstAvailable([
            "Futura-CondensedExtraBold", "AvenirNextCondensed-Heavy",
            "GillSans-Bold", "HelveticaNeue-CondensedBold",
        ]),
        labelFontName: FontProbe.firstAvailable([
            "Futura-Medium", "AvenirNextCondensed-Medium", "AvenirNext-Medium",
        ]),
        smallFontName: FontProbe.firstAvailable([
            "Menlo-Bold", "CourierNewPS-BoldMT",
        ]),
        texture: .woodGrainAndNdebele
    )
}
