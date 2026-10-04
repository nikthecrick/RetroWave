import Foundation
import AppKit

/// Generates its own sound effects as WAV data at runtime — the app ships no
/// audio files. A click is a short decaying sine burst; the skin-change static
/// is a filtered noise burst.
final class SoundEffects {
    static let shared = SoundEffects()

    private var clickSound: NSSound?
    private var staticSound: NSSound?
    private let queue = DispatchQueue(label: "retrowave.sfx", qos: .userInitiated)

    private init() {
        clickSound = Self.makeSound(samples: Self.clickSamples())
        staticSound = Self.makeSound(samples: Self.staticSamples())
    }

    /// Warm, satisfying pushbutton click: 1.6 kHz sine with a fast attack and
    /// exponential decay, plus a click transient.
    private static func clickSamples() -> [Double] {
        let rate = 44_100.0
        let duration = 0.085
        let n = Int(rate * duration)
        var out = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / rate
            let progress = Double(i) / Double(n)
            let env = exp(-t * 46.0) * (1 - progress)
            let tone = sin(2 * .pi * 1650 * t) * 0.55
            let body = sin(2 * .pi * 420 * t) * 0.30
            let transient = (i < 180 ? Double.random(in: 0.6...1.0) * 0.5 : 0)
            out[i] = max(min((tone + body) * env + transient * exp(-t * 220.0), 1), -1)
        }
        return out
    }

    /// Short radio static crackle for skin changes: band-limited noise with a
    /// sharp attack and a quick decay.
    private static func staticSamples() -> [Double] {
        let rate = 44_100.0
        let duration = 0.19
        let n = Int(rate * duration)
        var out = [Double](repeating: 0, count: n)
        var last: Double = 0
        for i in 0..<n {
            let progress = Double(i) / Double(n)
            let env = (1 - progress) * (1 - progress)
            let noise = Double.random(in: -1...1)
            // One-pole low-pass plus a high-pass difference → hissy crackle.
            last = last * 0.55 + noise * 0.45
            let hp = noise - last
            out[i] = max(min(hp * env * 0.55, 1), -1)
        }
        return out
    }

    /// Packs mono float samples into a 16-bit PCM WAV file in a temp directory.
    private static func makeSound(samples: [Double]) -> NSSound? {
        let rate = 44_100
        var data = Data()
        let byteCount = samples.count * 2
        data.append(contentsOf: Array("RIFF".utf8))
        data.appendLE(UInt32(36 + byteCount))
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        data.appendLE(UInt32(16))          // PCM fmt chunk size
        data.appendLE(UInt16(1))           // format = PCM
        data.appendLE(UInt16(1))           // channels = mono
        data.appendLE(UInt32(rate))        // sample rate
        data.appendLE(UInt32(rate * 2))    // byte rate
        data.appendLE(UInt16(2))           // block align
        data.appendLE(UInt16(16))          // bits per sample
        data.append(contentsOf: Array("data".utf8))
        data.appendLE(UInt32(byteCount))
        for s in samples {
            let clamped = max(min(s, 1), -1)
            data.appendLE(Int16(clamped * 32_000))
        }

        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("retrowave-sfx", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(UUID().uuidString + ".wav")
        do {
            try data.write(to: url)
            return NSSound(contentsOf: url, byReference: false)
        } catch {
            return nil
        }
    }

    func playClick() {
        queue.async { [weak self] in
            guard let s = self?.clickSound else { return }
            s.stop()
            s.play()
        }
    }

    func playStatic() {
        queue.async { [weak self] in
            guard let s = self?.staticSound else { return }
            s.stop()
            s.play()
        }
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
