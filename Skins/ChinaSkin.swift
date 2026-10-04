import SwiftUI

/// 🇨🇳 China — cinnabar lacquer, gilt lattice fretwork, brushstroke labels.
enum ChinaSkin {

    static let theme = SkinTheme(
        country: .cn,
        cabinetTop: Color(red: 0.66, green: 0.11, blue: 0.11),
        cabinetBottom: Color(red: 0.36, green: 0.05, blue: 0.06),
        cabinetEdge: Color(red: 0.18, green: 0.03, blue: 0.03),
        cabinetHighlight: Color(red: 1.00, green: 0.55, blue: 0.45).opacity(0.55),
        cornerRadius: 10,
        bezelColor: Color(red: 0.50, green: 0.08, blue: 0.08),
        trimColor: Color(red: 0.87, green: 0.70, blue: 0.32),  // gilt
        shadowColor: Color.black.opacity(0.6),
        dialFace: Color(red: 0.99, green: 0.96, blue: 0.86),
        dialFaceEdge: Color(red: 0.80, green: 0.62, blue: 0.26),
        dialText: Color(red: 0.44, green: 0.06, blue: 0.07),
        dialSubText: Color(red: 0.52, green: 0.34, blue: 0.20),
        dialGlow: Color(red: 1.00, green: 0.88, blue: 0.58),
        needleColor: Color(red: 0.72, green: 0.10, blue: 0.11),
        scaleTick: Color(red: 0.40, green: 0.24, blue: 0.14),
        grilleBase: Color(red: 0.46, green: 0.07, blue: 0.08),
        grilleLine: Color(red: 0.20, green: 0.03, blue: 0.03),
        grilleHighlight: Color(red: 0.98, green: 0.78, blue: 0.40),
        knobStyle: .lacquerGold,
        knobBody: [Color(red: 0.74, green: 0.13, blue: 0.12),
                   Color(red: 0.48, green: 0.06, blue: 0.06),
                   Color(red: 0.24, green: 0.03, blue: 0.03)],
        knobRim: Color(red: 0.88, green: 0.72, blue: 0.34),
        knobPointer: Color(red: 0.95, green: 0.82, blue: 0.42),
        buttonFace: Color(red: 0.58, green: 0.09, blue: 0.09),
        buttonFaceActive: Color(red: 0.88, green: 0.70, blue: 0.30),
        buttonEdge: Color(red: 0.86, green: 0.68, blue: 0.30),
        buttonText: Color(red: 1.00, green: 0.94, blue: 0.78),
        accent: Color(red: 0.76, green: 0.11, blue: 0.12),   // crimson
        secondaryAccent: Color(red: 0.88, green: 0.71, blue: 0.31), // gold
        glow: Color(red: 1.00, green: 0.76, blue: 0.34),
        displayFontName: FontProbe.firstAvailable([
            "STKaiti-Kai", "Kaiti SC", "Songti SC", "HiraginoSansGB-W6", "PingFangSC-Semibold",
        ]),
        labelFontName: FontProbe.firstAvailable([
            "STKaiti-Kai", "Kaiti SC", "Songti SC", "HiraginoSansGB-W3", "PingFangSC-Regular",
        ]),
        smallFontName: FontProbe.firstAvailable([
            "Songti SC", "PingFangSC-Regular", "STHeiti Light",
        ]),
        texture: .redLacquerAndLattice
    )
}
