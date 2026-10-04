import SwiftUI

/// 🇺🇸 United States — Route 66 chrome, red vinyl, and a neon diner glow.
enum USSkin {

    static let theme = SkinTheme(
        country: .us,
        cabinetTop: Color(red: 0.86, green: 0.87, blue: 0.89),
        cabinetBottom: Color(red: 0.42, green: 0.44, blue: 0.48),
        cabinetEdge: Color(red: 0.16, green: 0.17, blue: 0.20),
        cabinetHighlight: Color.white.opacity(0.75),
        cornerRadius: 18,
        bezelColor: Color(red: 0.20, green: 0.21, blue: 0.24),
        trimColor: Color(red: 0.90, green: 0.91, blue: 0.93),
        shadowColor: Color.black.opacity(0.55),
        dialFace: Color(red: 0.09, green: 0.11, blue: 0.14),
        dialFaceEdge: Color(red: 0.55, green: 0.57, blue: 0.60),
        dialText: Color(red: 0.36, green: 0.86, blue: 1.00),
        dialSubText: Color(red: 0.78, green: 0.82, blue: 0.86),
        dialGlow: Color(red: 0.20, green: 0.70, blue: 1.00),
        needleColor: Color(red: 1.00, green: 0.22, blue: 0.24),
        scaleTick: Color(red: 0.85, green: 0.87, blue: 0.90),
        grilleBase: Color(red: 0.24, green: 0.25, blue: 0.28),
        grilleLine: Color(red: 0.08, green: 0.09, blue: 0.11),
        grilleHighlight: Color(red: 0.72, green: 0.74, blue: 0.78),
        knobStyle: .chromeDome,
        knobBody: [Color(red: 0.94, green: 0.95, blue: 0.97),
                   Color(red: 0.70, green: 0.72, blue: 0.76),
                   Color(red: 0.38, green: 0.40, blue: 0.44)],
        knobRim: Color(red: 0.22, green: 0.23, blue: 0.26),
        knobPointer: Color(red: 1.00, green: 0.20, blue: 0.22),
        buttonFace: Color(red: 0.30, green: 0.31, blue: 0.34),
        buttonFaceActive: Color(red: 0.16, green: 0.62, blue: 1.00),
        buttonEdge: Color(red: 0.10, green: 0.11, blue: 0.13),
        buttonText: Color(red: 0.92, green: 0.94, blue: 0.97),
        accent: Color(red: 0.20, green: 0.66, blue: 1.00),   // electric blue
        secondaryAccent: Color(red: 0.98, green: 0.20, blue: 0.22), // diner red
        glow: Color(red: 0.35, green: 0.80, blue: 1.00),
        displayFontName: FontProbe.firstAvailable([
            "BebasNeue-Regular", "Futura-CondensedExtraBold",
            "AvenirNextCondensed-Heavy", "Oswald-Regular",
        ]),
        labelFontName: FontProbe.firstAvailable([
            "Futura-Medium", "AvenirNextCondensed-Medium", "AvenirNext-Medium",
        ]),
        smallFontName: FontProbe.firstAvailable([
            "Menlo-Regular", "CourierNewPSMT",
        ]),
        texture: .brushedChromeAndVinyl
    )
}
