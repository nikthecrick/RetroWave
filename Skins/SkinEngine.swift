import SwiftUI
import AppKit

/// How a control knob is rendered. Each country gets a different material.
enum KnobStyle {
    case chromeDome      // USA — polished chrome with a pointer skirt
    case bakelite        // France — moulded brown phenolic, fluted edge
    case turnedWood      // South Africa — lathe-turned hardwood
    case lacquerGold     // China — red lacquer cap with a gilt collar
    case clay            // Mexico — hand-thrown terracotta with a glaze band
}

/// Which procedural texture is painted behind the cabinet.
enum TextureKind {
    case brushedChromeAndVinyl
    case ivoryLacquerAndGoldTrim
    case woodGrainAndNdebele
    case redLacquerAndLattice
    case terracottaAndTalavera
}

/// The complete set of visual tokens one country skin contributes.
struct SkinTheme {
    let country: Country

    // Cabinet
    let cabinetTop: Color
    let cabinetBottom: Color
    let cabinetEdge: Color
    let cabinetHighlight: Color
    let cornerRadius: CGFloat

    // Trim / bezel
    let bezelColor: Color
    let trimColor: Color
    let shadowColor: Color

    // Dial
    let dialFace: Color
    let dialFaceEdge: Color
    let dialText: Color
    let dialSubText: Color
    let dialGlow: Color
    let needleColor: Color
    let scaleTick: Color

    // Grille
    let grilleBase: Color
    let grilleLine: Color
    let grilleHighlight: Color

    // Controls
    let knobStyle: KnobStyle
    let knobBody: [Color]
    let knobRim: Color
    let knobPointer: Color
    let buttonFace: Color
    let buttonFaceActive: Color
    let buttonEdge: Color
    let buttonText: Color

    // Accents
    let accent: Color
    let secondaryAccent: Color
    let glow: Color

    // Typography (resolved names, already availability-checked)
    let displayFontName: String
    let labelFontName: String
    let smallFontName: String

    // Texture
    let texture: TextureKind

    func font(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        displayFontName.isEmpty
            ? .system(size: size, weight: weight, design: .rounded)
            : .custom(displayFontName, size: size)
    }

    func labelFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        labelFontName.isEmpty
            ? .system(size: size, weight: weight)
            : .custom(labelFontName, size: size)
    }

    func smallFont(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        smallFontName.isEmpty
            ? .system(size: size, weight: weight, design: .monospaced)
            : .custom(smallFontName, size: size)
    }

    /// Black or white, whichever gives the better WCAG contrast against
    /// `background`. Several skins invert (ivory cabinets, crimson lacquer), so
    /// engraving colour has to be derived rather than hard-coded per country.
    func readableOn(_ background: Color) -> Color {
        background.bestInk == .black ? .black : .white
    }
}

extension Color {
    /// Perceptual luminance in 0...1, via AppKit's calibrated RGB.
    var relativeLuminance: Double {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        func lin(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(ns.redComponent)
             + 0.7152 * lin(ns.greenComponent)
             + 0.0722 * lin(ns.blueComponent)
    }

    /// Picks black or white, whichever contrasts more (WCAG 2.x ratio).
    var bestInk: Color {
        let l = relativeLuminance
        let onWhite = 1.05 / (l + 0.05)      // contrast against white
        let onBlack = (l + 0.05) / 0.05       // contrast against black
        return onBlack > onWhite ? .black : .white
    }
}

/// Resolves a font by name, falling back gracefully when it is not installed.
enum FontProbe {
    /// A font counts as available only if AppKit can instantiate it, so a
    /// missing display face degrades to the system font instead of tofu.
    static func firstAvailable(_ candidates: [String]) -> String {
        for c in candidates where NSFont(name: c, size: 12) != nil { return c }
        return ""
    }
}

/// The skin switcher: maps a `Country` to its theme and drives the crossfade.
enum SkinEngine {

    static func theme(for country: Country) -> SkinTheme {
        switch country {
        case .us: return USSkin.theme
        case .fr: return FranceSkin.theme
        case .za: return SouthAfricaSkin.theme
        case .cn: return ChinaSkin.theme
        case .mx: return MexicoSkin.theme
        }
    }

    /// The spec'd 0.6 s ease-in-out used when one skin dissolves into another.
    static let crossfade = Animation.easeInOut(duration: 0.6)

    // MARK: Procedural texture painters
    //
    // Everything is drawn with SwiftUI Canvas / Path / gradients — the app
    // ships no bitmap textures.

    /// Brushed chrome with a red vinyl record arc (USA).
    static func paintBrushedChrome(_ ctx: inout GraphicsContext, size: CGSize, theme: SkinTheme) {
        let w = size.width, h = size.height

        // Brushed metal: many faint horizontal streaks of varying opacity.
        var y: CGFloat = 0
        var seed: UInt64 = 0x5EED_1234
        while y < h {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let r = Double((seed >> 33) % 1000) / 1000.0
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let r2 = Double((seed >> 33) % 1000) / 1000.0
            let band = 0.5 + r * 2.0
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: w, y: y + (r2 - 0.5) * 1.2))
            }
            ctx.stroke(path, with: .color(.white.opacity(0.035 + 0.05 * r)),
                      lineWidth: band)
            y += band
        }

        // Vinyl record corner — red disc with grooves, bottom-right.
        let radius = min(w, h) * 0.46
        let center = CGPoint(x: w * 0.94, y: h * 0.86)
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius * 2, height: radius * 2))
        ctx.fill(disc, with: .radialGradient(
            Gradient(colors: [Color(red: 0.62, green: 0.08, blue: 0.12),
                              Color(red: 0.30, green: 0.02, blue: 0.05)]),
            center: center, startRadius: 0, endRadius: radius))

        for i in 1...9 {
            let rr = radius * (0.16 + 0.09 * Double(i))
            let g = Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr,
                                           width: rr * 2, height: rr * 2))
            ctx.stroke(g, with: .color(.white.opacity(0.10)), lineWidth: 0.7)
        }
        let label = Path(ellipseIn: CGRect(x: center.x - radius * 0.15,
                                           y: center.y - radius * 0.15,
                                           width: radius * 0.3, height: radius * 0.3))
        ctx.fill(label, with: .color(Color(red: 0.85, green: 0.78, blue: 0.5)))
    }

    /// Warm ivory lacquer with gold Art Déco sunburst (France).
    static func paintIvoryLacquer(_ ctx: inout GraphicsContext, size: CGSize, theme: SkinTheme) {
        let w = size.width, h = size.height
        let origin = CGPoint(x: w * 0.5, y: h * 1.35)

        // Sunburst rays fanning up from below the cabinet.
        for i in 0..<26 {
            let spread: CGFloat = 1.55
            let a = -CGFloat.pi / 2 + (CGFloat(i) - 12.5) / 12.5 * spread / 2
            let len = h * 1.9
            var p = Path()
            p.move(to: origin)
            let half: CGFloat = 0.012 + 0.014 * abs(CGFloat(i) - 12.5) / 12.5
            p.addLine(to: CGPoint(x: origin.x + cos(a - half) * len,
                                  y: origin.y + sin(a - half) * len))
            p.addLine(to: CGPoint(x: origin.x + cos(a + half) * len,
                                  y: origin.y + sin(a + half) * len))
            p.closeSubpath()
            ctx.fill(p, with: .color(theme.secondaryAccent.opacity(i % 2 == 0 ? 0.055 : 0.022)))
        }

        // Fine hairline rules, like a lacquered French cabinet.
        for i in 0..<5 {
            let yy = h * (0.18 + 0.16 * CGFloat(i))
            var p = Path()
            p.move(to: CGPoint(x: w * 0.06, y: yy))
            p.addLine(to: CGPoint(x: w * 0.94, y: yy))
            ctx.stroke(p, with: .color(theme.trimColor.opacity(0.10)), lineWidth: 0.6)
        }
    }

    /// Warm wood grain plus a Ndebele geometric border (South Africa).
    static func paintWoodAndNdebele(_ ctx: inout GraphicsContext, size: CGSize, theme: SkinTheme) {
        let w = size.width, h = size.height

        // Wood grain: long low-frequency sine ribbons.
        for i in 0..<26 {
            let baseY = h * CGFloat(i) / 26.0
            let amp: CGFloat = 2.0 + 3.4 * CGFloat(i % 4)
            var p = Path()
            var x: CGFloat = -10
            p.move(to: CGPoint(x: x, y: baseY))
            while x <= w + 10 {
                let y = baseY + sin(x / 34.0 + CGFloat(i) * 0.7) * amp
                p.addLine(to: CGPoint(x: x, y: y))
                x += 8
            }
            ctx.stroke(p, with: .color(Color.black.opacity(0.10 - 0.002 * Double(i % 5))),
                      lineWidth: 0.9)
        }
        // Occasional lighter grain highlight.
        for i in stride(from: 2, to: 26, by: 5) {
            let baseY = h * CGFloat(i) / 26.0
            var p = Path()
            var x: CGFloat = -10
            p.move(to: CGPoint(x: x, y: baseY))
            while x <= w + 10 {
                p.addLine(to: CGPoint(x: x, y: baseY + sin(x / 34.0 + CGFloat(i) * 0.7) * 3.2))
                x += 8
            }
            ctx.stroke(p, with: .color(Color.white.opacity(0.05)), lineWidth: 0.7)
        }

        // Ndebele border hugging the top and bottom edges of the cabinet. The
        // panel's bottom inset (see RadioFaceView) keeps it clear of controls.
        let palette: [Color] = [
            Color(red: 0.78, green: 0.20, blue: 0.18),  // red
            Color(red: 0.90, green: 0.70, blue: 0.20),  // gold
            Color(red: 0.29, green: 0.58, blue: 0.76),  // sky blue
            Color(red: 0.36, green: 0.55, blue: 0.31),  // green
        ]
        let step: CGFloat = 34
        for bandY in [CGFloat(3), h - 18] {
            var sx: CGFloat = 0
            var k = 0
            while sx < w {
                let c = palette[k % palette.count]
                // Filled diamond
                var d = Path()
                let cx = sx + step / 2, cy = bandY + 7
                d.move(to: CGPoint(x: cx, y: cy - 6.5))
                d.addLine(to: CGPoint(x: cx + 8, y: cy))
                d.addLine(to: CGPoint(x: cx, y: cy + 6.5))
                d.addLine(to: CGPoint(x: cx - 8, y: cy))
                d.closeSubpath()
                ctx.fill(d, with: .color(c))
                ctx.stroke(d, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
                // Connector bar
                var bar = Path()
                bar.move(to: CGPoint(x: sx, y: cy + 5.5))
                bar.addLine(to: CGPoint(x: cx - 8, y: cy + 5.5))
                bar.move(to: CGPoint(x: cx + 8, y: cy + 5.5))
                bar.addLine(to: CGPoint(x: sx + step, y: cy + 5.5))
                ctx.stroke(bar, with: .color(palette[(k + 1) % palette.count].opacity(0.85)),
                           lineWidth: 3.2)
                sx += step
                k += 1
            }
        }
    }

    /// Red lacquer panel with a gold Chinese lattice (China).
    static func paintRedLacquerAndLattice(_ ctx: inout GraphicsContext, size: CGSize, theme: SkinTheme) {
        let w = size.width, h = size.height

        // Lacquer depth: broad diagonal sheen bands.
        for i in 0..<9 {
            let x = w * CGFloat(i) / 9.0
            var p = Path()
            p.move(to: CGPoint(x: x - w * 0.15, y: 0))
            p.addLine(to: CGPoint(x: x + w * 0.30, y: 0))
            p.addLine(to: CGPoint(x: x + w * 0.16, y: h))
            p.addLine(to: CGPoint(x: x - w * 0.29, y: h))
            p.closeSubpath()
            ctx.fill(p, with: .color(Color.white.opacity(i % 2 == 0 ? 0.035 : 0.012)))
        }

        // Ink-wash bloom in the lower-left, as if brushed onto the lacquer.
        let ink = CGPoint(x: w * 0.14, y: h * 0.78)
        for i in stride(from: 5, through: 1, by: -1) {
            let r = min(w, h) * 0.10 * CGFloat(i)
            let blob = Path(ellipseIn: CGRect(x: ink.x - r, y: ink.y - r * 0.62,
                                              width: r * 2, height: r * 1.24))
            ctx.fill(blob, with: .color(Color.black.opacity(0.035 * Double(i))))
        }

        // Gold "ice-crack" lattice: interlocking 回 fretwork along the edges.
        let cell: CGFloat = 26
        for bandY in [CGFloat(3), h - 20] {
            var x: CGFloat = 0
            while x < w {
                var p = Path()
                let o = x, y0 = bandY, s = cell * 0.62
                p.move(to: CGPoint(x: o + s * 0.1, y: y0 + s * 0.9))
                p.addLine(to: CGPoint(x: o + s * 0.1, y: y0 + s * 0.1))
                p.addLine(to: CGPoint(x: o + s * 0.9, y: y0 + s * 0.1))
                p.addLine(to: CGPoint(x: o + s * 0.9, y: y0 + s * 0.55))
                p.addLine(to: CGPoint(x: o + s * 0.45, y: y0 + s * 0.55))
                p.addLine(to: CGPoint(x: o + s * 0.45, y: y0 + s * 0.32))
                ctx.stroke(p, with: .color(theme.trimColor.opacity(0.55)), lineWidth: 1.3)
                x += cell
            }
        }
    }

    /// Sun-baked adobe with a papel picado garland and a talavera tile row
    /// (Mexico).
    static func paintTerracottaAndTalavera(_ ctx: inout GraphicsContext, size: CGSize, theme: SkinTheme) {
        let w = size.width, h = size.height

        // Stucco mottling: broad soft blotches of light and shadow.
        var seed: UInt64 = 0x5ADE_51DE
        func rnd() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double((seed >> 33) % 1000) / 1000.0
        }
        for _ in 0..<18 {
            let r = min(w, h) * (0.10 + 0.22 * rnd())
            let x = rnd() * w
            let y = rnd() * h
            let light = rnd() > 0.5
            let blob = Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.7,
                                              width: r * 2, height: r * 1.4))
            ctx.fill(blob, with: .color((light ? Color.white : Color.black)
                .opacity(0.02 + 0.025 * rnd())))
        }
        // Plaster hairlines, like a skim coat laid with a float.
        for _ in 0..<14 {
            let y = rnd() * h
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: w, y: y + (rnd() - 0.5) * 3))
            ctx.stroke(p, with: .color(Color.black.opacity(0.02 + 0.02 * rnd())),
                      lineWidth: 0.8)
        }

        // Papel picado: cut-paper flags strung across the top, each with a
        // V-cut hem and a punched hole.
        let flagW: CGFloat = 26
        let flagH: CGFloat = 22
        let palette: [Color] = [
            Color(red: 0.93, green: 0.65, blue: 0.13),  // marigold
            Color(red: 0.15, green: 0.42, blue: 0.72),  // cobalt
            Color(red: 0.30, green: 0.58, blue: 0.33),  // leaf green
            Color(red: 0.94, green: 0.90, blue: 0.80),  // paper white
            Color(red: 0.78, green: 0.18, blue: 0.15),  // cochineal red
        ]
        var fx: CGFloat = -3
        var k = 0
        while fx < w + flagW {
            let c = palette[k % palette.count]
            let rect = CGRect(x: fx, y: 2, width: flagW, height: flagH)
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 4))
            p.closeSubpath()
            ctx.fill(p, with: .color(c.opacity(0.92)))
            ctx.stroke(p, with: .color(Color.black.opacity(0.25)), lineWidth: 0.6)
            // The picado: punched holes showing through to the cabinet.
            let holes: [(CGFloat, CGFloat)] = [(9, 2.4), (15, 1.4)]
            for (dy, hr) in holes {
                let hole = Path(ellipseIn: CGRect(x: rect.midX - hr, y: 2 + dy - hr,
                                                  width: hr * 2, height: hr * 2))
                ctx.fill(hole, with: .color(Color.black.opacity(0.35)))
            }
            fx += flagW
            k += 1
        }
        // The cord the flags hang from.
        var cord = Path()
        cord.move(to: CGPoint(x: 0, y: 1.5))
        cord.addQuadCurve(to: CGPoint(x: w, y: 1.5),
                          control: CGPoint(x: w / 2, y: 5))
        ctx.stroke(cord, with: .color(Color(red: 0.20, green: 0.10, blue: 0.04).opacity(0.6)),
                   lineWidth: 1)

        // Talavera: a row of glazed tiles with a painted flower motif, hugging
        // the bottom edge like the other skins' border bands.
        let tile: CGFloat = 26
        var tx: CGFloat = 0
        var i = 0
        while tx < w {
            let rect = CGRect(x: tx + 1.5, y: h - 25.5, width: tile - 3, height: tile - 3)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 2),
                     with: .linearGradient(
                        Gradient(colors: [Color(red: 0.99, green: 0.96, blue: 0.88),
                                          Color(red: 0.93, green: 0.87, blue: 0.72)]),
                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                        endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
            ctx.stroke(Path(roundedRect: rect, cornerRadius: 2),
                       with: .color(Color(red: 0.15, green: 0.38, blue: 0.68).opacity(0.8)),
                       lineWidth: 1)
            let cx = rect.midX, cy = rect.midY
            let motif = i % 2 == 0
                ? Color(red: 0.15, green: 0.38, blue: 0.68)   // cobalt
                : Color(red: 0.85, green: 0.55, blue: 0.15)   // raw sienna
            for q in 0..<4 {
                let a = CGFloat(q) * .pi / 2 + .pi / 4
                var petal = Path(ellipseIn: CGRect(x: -3.4, y: -2.2, width: 6.8, height: 4.4))
                petal = petal.applying(CGAffineTransform(rotationAngle: a))
                petal = petal.applying(CGAffineTransform(translationX: cx + cos(a) * 5.5,
                                                        y: cy + sin(a) * 5.5))
                ctx.fill(petal, with: .color(motif.opacity(0.85)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 1.8, y: cy - 1.8, width: 3.6, height: 3.6)),
                     with: .color(Color(red: 0.78, green: 0.18, blue: 0.15)))
            tx += tile
            i += 1
        }
    }

    /// The cabinet texture for a theme.
    ///
    /// At the full 800×520 face size, composites the pre-rasterised image
    /// from `SkinTextureCache` instead of a live `Canvas`. A live full-size
    /// Canvas would be re-rasterised on every face re-evaluation — the needle
    /// ticks ~4x a second, the VU publishes ~18x a second while playing — and
    /// that showed up as flicker and hitches while dragging the window: fine
    /// on the light US texture, visibly broken on the heavier skins (wood
    /// grain + Ndebele, red lattice, sunburst). At other sizes (the mini
    /// player's 300×80) the live Canvas is used: it is cheap there, and the
    /// cached image must not be stretched, or the art would be distorted.
    static func textureView(for theme: SkinTheme) -> some View {
        GeometryReader { geo in
            let matchesCache = abs(geo.size.width - SkinTextureCache.size.width) < 0.5
                && abs(geo.size.height - SkinTextureCache.size.height) < 0.5
            ZStack {
                if matchesCache, let image = SkinTextureCache.image(for: theme.country) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                } else {
                    SkinTextureCanvas(theme: theme)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// The cabinet texture as a raw Canvas.
    struct SkinTextureCanvas: View {
        let theme: SkinTheme

        var body: some View {
            Canvas(opaque: false, rendersAsynchronously: false) { ctx, size in
                switch theme.texture {
                case .brushedChromeAndVinyl:   paintBrushedChrome(&ctx, size: size, theme: theme)
                case .ivoryLacquerAndGoldTrim:  paintIvoryLacquer(&ctx, size: size, theme: theme)
                case .woodGrainAndNdebele:      paintWoodAndNdebele(&ctx, size: size, theme: theme)
                case .redLacquerAndLattice:     paintRedLacquerAndLattice(&ctx, size: size, theme: theme)
                case .terracottaAndTalavera:    paintTerracottaAndTalavera(&ctx, size: size, theme: theme)
                }
            }
        }
    }

    /// Pre-rasterised cabinet textures, one per skin, rendered offscreen at
    /// launch so the live face only ever composites a ready-made image.
    /// All access happens on the main thread (app launch + view bodies);
    /// only the rasterisation itself needs the main actor.
    enum SkinTextureCache {
        /// The face the texture spans; the mini player resamples it down.
        static let size = CGSize(width: 800, height: 520)

        private static var images: [Country: NSImage] = [:]

        /// Rasterises all five skins once, before the first frame.
        @MainActor
        static func prime() {
            guard images.isEmpty else { return }
            let scale = NSScreen.main?.backingScaleFactor ?? 2
            for country in Country.allCases {
                if let image = rasterize(theme(for: country), scale: scale) {
                    images[country] = image
                }
            }
        }

        static func image(for country: Country) -> NSImage? {
            images[country]
        }

        @MainActor
        private static func rasterize(_ theme: SkinTheme, scale: CGFloat) -> NSImage? {
            let renderer = ImageRenderer(
                content: SkinTextureCanvas(theme: theme)
                    .frame(width: size.width, height: size.height))
            renderer.scale = scale
            return renderer.nsImage
        }
    }
}
