// Renders RetroWave's app icon at every size the .icns needs, using the same
// procedural vocabulary as the app: a chrome cabinet, a lit dial, a needle and
// a speaker grille. No source images — CoreGraphics draws every pixel.
//
//   swift Tools/MakeIcon.swift && .build/makeicon Resources/AppIcon.iconset
//   iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns

import Foundation
import AppKit
import CoreGraphics
import ImageIO
import CoreText
import UniformTypeIdentifiers

let W = 1024.0

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, a])!
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let S = W / 1024.0   // design units == pixels at 1024

let ctx = CGContext(data: nil, width: Int(W), height: Int(W),
                    bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// ------------------------------------------------------------------ cabinet
let inset = 64.0 * S
let body = CGRect(x: inset, y: inset, width: W - inset * 2, height: W - inset * 2)
let bodyPath = CGPath(roundedRect: body, cornerWidth: 150 * S, cornerHeight: 150 * S,
                      transform: nil)
ctx.saveGState()
ctx.addPath(bodyPath)
ctx.clip()

let shell = CGGradient(colorsSpace: space, colors: [
    rgb(0.90, 0.91, 0.93), rgb(0.55, 0.57, 0.61),
    rgb(0.78, 0.79, 0.82), rgb(0.28, 0.29, 0.33),
] as CFArray, locations: [0.0, 0.34, 0.62, 1.0])!
ctx.drawLinearGradient(shell, start: CGPoint(x: 0, y: W), end: CGPoint(x: 0, y: 0),
                       options: [])

var seed: UInt64 = 12345
func rnd() -> Double {
    seed = seed &* 6364136223846793005 &+ 1442695040888963407
    return Double((seed >> 33) % 10000) / 10000.0
}
ctx.setLineWidth(1.5 * S)
var y = body.minY
while y < body.maxY {
    ctx.setStrokeColor(rgb(1, 1, 1, 0.03 + rnd() * 0.06))
    ctx.move(to: CGPoint(x: body.minX, y: y))
    ctx.addLine(to: CGPoint(x: body.maxX, y: y + (rnd() - 0.5) * 4 * S))
    ctx.strokePath()
    y += 2 * S
}

// Red vinyl record tucked into the bottom-right corner of the cabinet
let discC = CGPoint(x: body.maxX - 40 * S, y: body.minY + 40 * S)
let discR = 150.0 * S
let discGrad = CGGradient(colorsSpace: space, colors: [
    rgb(0.66, 0.09, 0.13), rgb(0.28, 0.02, 0.05)
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(discGrad, startCenter: discC, startRadius: 0,
                       endCenter: discC, endRadius: discR, options: [])
ctx.setStrokeColor(rgb(1, 1, 1, 0.10))
ctx.setLineWidth(1.2 * S)
for i in 1...8 {
    let r = discR * (0.18 + 0.09 * Double(i))
    ctx.addEllipse(in: CGRect(x: discC.x - r, y: discC.y - r, width: r * 2, height: r * 2))
    ctx.strokePath()
}
ctx.setFillColor(rgb(0.88, 0.80, 0.52))
ctx.fillEllipse(in: CGRect(x: discC.x - discR * 0.16, y: discC.y - discR * 0.16,
                           width: discR * 0.32, height: discR * 0.32))

// ------------------------------------------------------------------ dial
let dialRect = CGRect(x: 150 * S, y: 500 * S, width: 560 * S, height: 300 * S)
let dialPath = CGPath(roundedRect: dialRect, cornerWidth: 40 * S, cornerHeight: 40 * S,
                      transform: nil)
ctx.saveGState()
ctx.addPath(dialPath)
ctx.clip()
ctx.setFillColor(rgb(0.07, 0.09, 0.12))
ctx.fill(dialRect)

let glow = CGGradient(colorsSpace: space, colors: [
    rgb(0.20, 0.72, 1.0, 0.45), rgb(0.20, 0.72, 1.0, 0.0)
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 430 * S, y: 650 * S), startRadius: 0,
                       endCenter: CGPoint(x: 430 * S, y: 650 * S), endRadius: 330 * S,
                       options: [])

let baseY = 640 * S
for i in 0...10 {
    let fx = 200 * S + (460 * S) * CGFloat(i) / 10.0
    let h = (i % 5 == 0 ? 46.0 : 26.0) * S
    ctx.setStrokeColor(rgb(0.85, 0.88, 0.92, i % 5 == 0 ? 0.95 : 0.5))
    ctx.setLineWidth((i % 5 == 0 ? 5.0 : 2.5) * S)
    ctx.move(to: CGPoint(x: fx, y: baseY))
    ctx.addLine(to: CGPoint(x: fx, y: baseY - h))
    ctx.strokePath()
}
ctx.setStrokeColor(rgb(0.85, 0.88, 0.92, 0.6))
ctx.setLineWidth(3 * S)
ctx.move(to: CGPoint(x: 190 * S, y: baseY))
ctx.addLine(to: CGPoint(x: 670 * S, y: baseY))
ctx.strokePath()

// Needle parked at 101.7, with a triangular pointer riding the scale
let nx = 200 * S + 460 * S * 0.692
ctx.setFillColor(rgb(1.0, 0.24, 0.26))
ctx.move(to: CGPoint(x: nx, y: baseY - 58 * S))
ctx.addLine(to: CGPoint(x: nx - 15 * S, y: baseY - 34 * S))
ctx.addLine(to: CGPoint(x: nx + 15 * S, y: baseY - 34 * S))
ctx.closePath()
ctx.fillPath()
ctx.setStrokeColor(rgb(1.0, 0.24, 0.26))
ctx.setLineWidth(7 * S)
ctx.move(to: CGPoint(x: nx, y: baseY - 36 * S))
ctx.addLine(to: CGPoint(x: nx, y: baseY + 2 * S))
ctx.strokePath()

func drawText(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
              font: String, color: CGColor, tracking: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: CTFontCreateWithName(font as CFString, size, nil),
        .foregroundColor: color,
        .kern: tracking,
    ]
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: x - bounds.width / 2 - bounds.minX,
                               y: y - bounds.height / 2 - bounds.minY)
    CTLineDraw(line, ctx)
}

drawText("RETROWAVE", x: 430 * S, y: 730 * S, size: 84 * S,
         font: "Futura-CondensedExtraBold", color: rgb(0.42, 0.88, 1.0),
         tracking: 12 * S)
drawText("101.7 FM", x: 430 * S, y: 566 * S, size: 38 * S,
         font: "Menlo-Bold", color: rgb(0.55, 0.62, 0.70), tracking: 8 * S)
ctx.restoreGState()

ctx.setStrokeColor(rgb(0.72, 0.74, 0.78))
ctx.setLineWidth(7 * S)
ctx.addPath(dialPath)
ctx.strokePath()

// ------------------------------------------------------------------ grille
let grille = CGRect(x: 740 * S, y: 480 * S, width: 220 * S, height: 320 * S)
let grillePath = CGPath(roundedRect: grille, cornerWidth: 30 * S, cornerHeight: 30 * S,
                        transform: nil)
ctx.saveGState()
ctx.addPath(grillePath)
ctx.clip()
ctx.setFillColor(rgb(0.16, 0.17, 0.20))
ctx.fill(grille)
var gy = grille.minY + 12 * S
while gy < grille.maxY - 8 * S {
    ctx.setFillColor(rgb(0.05, 0.05, 0.07))
    ctx.fill(CGRect(x: grille.minX + 10 * S, y: gy,
                    width: grille.width - 20 * S, height: 9 * S))
    ctx.setFillColor(rgb(0.70, 0.72, 0.76, 0.30))
    ctx.fill(CGRect(x: grille.minX + 10 * S, y: gy + 9 * S,
                    width: grille.width - 20 * S, height: 2.5 * S))
    gy += 20 * S
}
ctx.restoreGState()
ctx.setStrokeColor(rgb(0.62, 0.64, 0.68))
ctx.setLineWidth(6 * S)
ctx.addPath(grillePath)
ctx.strokePath()

// ------------------------------------------------------------------ knobs
let knobCenters = [CGPoint(x: 190 * S, y: 300 * S),
                   CGPoint(x: 400 * S, y: 300 * S),
                   CGPoint(x: 610 * S, y: 300 * S),
                   CGPoint(x: 820 * S, y: 300 * S)]
for (i, c) in knobCenters.enumerated() {
    let r = 74.0 * S
    ctx.setFillColor(rgb(0.13, 0.14, 0.16))
    ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    let dome = CGGradient(colorsSpace: space, colors: [
        rgb(0.97, 0.98, 1.0), rgb(0.68, 0.70, 0.74), rgb(0.30, 0.31, 0.35)
    ] as CFArray, locations: [0, 0.5, 1.0])!
    ctx.drawRadialGradient(dome,
                           startCenter: CGPoint(x: c.x - r * 0.35, y: c.y + r * 0.35),
                           startRadius: 0,
                           endCenter: CGPoint(x: c.x, y: c.y), endRadius: r,
                           options: [])
    let angle = -CGFloat.pi / 2 + (CGFloat(i) - 1.5) * 0.62
    ctx.setStrokeColor(rgb(1.0, 0.22, 0.24))
    ctx.setLineWidth(9 * S)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: c.x, y: c.y))
    ctx.addLine(to: CGPoint(x: c.x + CoreGraphics.cos(angle) * r * 0.72,
                            y: c.y + CoreGraphics.sin(angle) * r * 0.72))
    ctx.strokePath()
    ctx.setLineCap(.butt)
    ctx.setStrokeColor(rgb(0.85, 0.87, 0.90, 0.8))
    ctx.setLineWidth(4 * S)
    ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    ctx.strokePath()
}

// Power lamp
let lamp = CGPoint(x: 850 * S, y: 770 * S)
let lampGrad = CGGradient(colorsSpace: space, colors: [
    rgb(0.55, 0.95, 1.0, 0.95), rgb(0.20, 0.70, 1.0, 0.0)
] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(lampGrad, startCenter: lamp, startRadius: 0,
                       endCenter: lamp, endRadius: 70 * S, options: [])
ctx.setFillColor(rgb(0.45, 0.92, 1.0))
ctx.fillEllipse(in: CGRect(x: lamp.x - 26 * S, y: lamp.y - 26 * S,
                           width: 52 * S, height: 52 * S))
ctx.restoreGState()

// ------------------------------------------------------------------ frame
ctx.setStrokeColor(rgb(0.14, 0.15, 0.18))
ctx.setLineWidth(14 * S)
ctx.addPath(bodyPath)
ctx.strokePath()

// ------------------------------------------------------------------ output
let full = ctx.makeImage()!
let iconset = URL(fileURLWithPath: CommandLine.arguments.count > 1
                  ? CommandLine.arguments[1] : "AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]
for (px, name) in variants {
    let sub = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8,
                        bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    sub.interpolationQuality = .high
    sub.draw(full, in: CGRect(x: 0, y: 0, width: CGFloat(px), height: CGFloat(px)))
    guard let img = sub.makeImage(),
          let dest = CGImageDestinationCreateWithURL(
              iconset.appendingPathComponent(name) as CFURL,
              UTType.png.identifier as CFString, 1, nil)
    else { continue }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}
print("rendered \(variants.count) icon variants into \(iconset.path)")
