import SwiftUI

/// 🇫🇷 France — Art Déco lacquer, gold filigree, and a Parisian café warmth.
enum FranceSkin {

    static let theme = SkinTheme(
        country: .fr,
        cabinetTop: Color(red: 0.97, green: 0.94, blue: 0.86),
        cabinetBottom: Color(red: 0.86, green: 0.79, blue: 0.66),
        cabinetEdge: Color(red: 0.36, green: 0.16, blue: 0.18),
        cabinetHighlight: Color.white.opacity(0.8),
        cornerRadius: 8,
        bezelColor: Color(red: 0.93, green: 0.89, blue: 0.79),
        trimColor: Color(red: 0.83, green: 0.66, blue: 0.33),
        shadowColor: Color(red: 0.25, green: 0.10, blue: 0.11).opacity(0.45),
        dialFace: Color(red: 0.99, green: 0.97, blue: 0.90),
        dialFaceEdge: Color(red: 0.83, green: 0.66, blue: 0.33),
        dialText: Color(red: 0.40, green: 0.12, blue: 0.15),
        dialSubText: Color(red: 0.46, green: 0.35, blue: 0.24),
        dialGlow: Color(red: 1.00, green: 0.86, blue: 0.55),
        needleColor: Color(red: 0.48, green: 0.14, blue: 0.17),
        scaleTick: Color(red: 0.44, green: 0.30, blue: 0.20),
        grilleBase: Color(red: 0.62, green: 0.45, blue: 0.26),
        grilleLine: Color(red: 0.34, green: 0.22, blue: 0.12),
        grilleHighlight: Color(red: 0.90, green: 0.78, blue: 0.56),
        knobStyle: .bakelite,
        knobBody: [Color(red: 0.44, green: 0.28, blue: 0.16),
                   Color(red: 0.28, green: 0.16, blue: 0.09),
                   Color(red: 0.16, green: 0.09, blue: 0.05)],
        knobRim: Color(red: 0.72, green: 0.56, blue: 0.30),
        knobPointer: Color(red: 0.98, green: 0.90, blue: 0.70),
        buttonFace: Color(red: 0.88, green: 0.83, blue: 0.72),
        buttonFaceActive: Color(red: 0.42, green: 0.13, blue: 0.16),
        buttonEdge: Color(red: 0.83, green: 0.66, blue: 0.33),
        buttonText: Color(red: 0.36, green: 0.12, blue: 0.14),
        accent: Color(red: 0.83, green: 0.66, blue: 0.33),   // gold
        secondaryAccent: Color(red: 0.42, green: 0.13, blue: 0.16), // burgundy
        glow: Color(red: 1.00, green: 0.84, blue: 0.48),
        displayFontName: FontProbe.firstAvailable([
            "Didot-Bold", "Didot-Regular", "PlayfairDisplay-Bold", "TimesNewRomanPS-BoldMT",
        ]),
        labelFontName: FontProbe.firstAvailable([
            "Didot-Italic", "Didot-Regular", "Baskerville-Italic", "TimesNewRomanPS-ItalicMT",
        ]),
        smallFontName: FontProbe.firstAvailable([
            "Baskerville-Regular", "TimesNewRomanPSMT",
        ]),
        texture: .ivoryLacquerAndGoldTrim
    )
}
