// Offscreen renderer used to smoke-test the cabinet without a window-server
// capture. Builds the real view hierarchy for each country skin and writes a
// PNG per skin.
//
//   swiftc -parse-as-library <app sources except RetroWaveApp.swift> \
//          Tools/Preview/Preview.swift -o .build/preview
//   .build/preview Models/stations.json .build/preview-out
//
// NOTE: ImageRenderer does not rasterise `Canvas` content, so procedural
// textures and the drawn dial/grille come out blank here. This still catches
// layout, typography, colour and data-plumbing regressions.

import SwiftUI
import AppKit

@main
struct PreviewTool {
    @MainActor
    static func main() {
        let args = CommandLine.arguments
        guard args.count >= 3 else {
            print("usage: preview <stations.json> <out-dir>")
            exit(2)
        }
        let json = URL(fileURLWithPath: args[1])
        let outDir = URL(fileURLWithPath: args[2])
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let library = StationLibraryLoader.load(override: json)
        print("loaded \(library.values.reduce(0) { $0 + $1.count }) stations "
              + "from \(json.lastPathComponent)")
        for (country, list) in library.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            print("  \(country.rawValue) \(country.displayName): \(list.count) "
                  + "[\(list.map { $0.dialLabel }.joined(separator: " "))]")
        }
        guard !library.isEmpty else {
            print("!! no stations decoded - aborting")
            exit(1)
        }

        for country in Country.allCases {
            let model = AppModel(player: RadioPlayer(), library: library)
            model.country = country
            if let first = library[country]?.first { model.station = first }

            let view = RadioFaceView()
                .environmentObject(model.player)
                .environmentObject(model)
                .frame(width: 800, height: 520)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2.0
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:])
            else {
                print("!! failed to render \(country.rawValue)")
                continue
            }
            let url = outDir.appendingPathComponent("skin-\(country.rawValue).png")
            try? png.write(to: url)
            print("rendered \(url.lastPathComponent) (\(rep.pixelsWide)x\(rep.pixelsHigh))")
        }
        print("done")
    }
}
