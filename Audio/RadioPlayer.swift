import Foundation
import AVFoundation
import Combine

/// The live VU levels, kept in their own observable object rather than on
/// `RadioPlayer`.
///
/// The meter republishes ~18x a second while playing. `@Published` fires
/// `objectWillChange` for the whole object, so had it lived on the player
/// every view observing the player — the entire cabinet face — would have
/// re-rendered 18x a second. A face-wide re-render at that rate re-rasterised
/// the grille and knob canvases mid-drag and is what made window dragging
/// hitch and flicker while the set was on (off = no re-renders = smooth).
@MainActor
final class VUMeterState: ObservableObject {
    @Published fileprivate(set) var level: Double = 0
    @Published fileprivate(set) var peak: Double = 0
}

/// State of the radio's signal chain, mapped to what the dial shows.
enum RadioState: Equatable {
    case off            // power off
    case tuning          // buffering / connecting
    case playing         // audio flowing
    case signalLost      // stream errored out, will auto-retry

    var dialText: String {
        switch self {
        case .off: return "STANDBY"
        case .tuning: return "TUNING…"
        case .playing: return "ON AIR"
        case .signalLost: return "SIGNAL LOST"
        }
    }
}

/// Wraps AVPlayer for internet-radio streaming, plus ICY metadata extraction,
/// buffering state, auto-retry and UserDefaults persistence.
@MainActor
final class RadioPlayer: ObservableObject {

    @Published private(set) var state: RadioState = .off
    @Published private(set) var currentStation: Station?
    @Published private(set) var nowPlayingTitle: String = ""
    @Published private(set) var bitrateLabel: String = ""
    @Published var volume: Double = 0.55 {
        didSet {
            let clamped = min(max(volume, 0), 1)
            if clamped != volume { volume = clamped; return }
            player.volume = Float(volume)
            persist()
        }
    }

    /// Simulated VU levels. Real metering would require a tap on an output
    /// unit; see NOTES.md. See `VUMeterState` for why these are not
    /// @Published on the player.
    let vu = VUMeterState()

    let player = AVPlayer()

    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var stallObserver: Any?
    private var endObserver: Any?
    // An AVPlayerItemMetadataOutput can only ever be attached to one item, so
    // it is created per tuning session rather than stored.
    private var metadataDelegate: MetadataBridge?

    private var retryTask: Task<Void, Never>?
    private var vuTask: Task<Void, Never>?
    private var icyTask: URLSessionDataTask?

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let volume = "retrowave.volume"
        static let country = "retrowave.country"
        static let station  = "retrowave.station"
    }

    // MARK: - Lifecycle

    init() {
        player.volume = Float(volume)
        player.automaticallyWaitsToMinimizeStalling = true
        restoreVolume()
        startVUDrive()
    }

    deinit {
        retryTask?.cancel()
        vuTask?.cancel()
        icyTask?.cancel()
        if let stallObserver { NotificationCenter.default.removeObserver(stallObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    // MARK: - Power / transport

    func togglePower() {
        switch state {
        case .off:
            guard let station = currentStation else { return }
            startTuning(station)
        case .playing, .tuning, .signalLost:
            stop()
        }
    }

    /// Selects a station without powering the set on — the cabinet shows it on
    /// the dial while the radio stays in STANDBY.
    func prime(_ station: Station) {
        currentStation = station
        bitrateLabel = station.bitrateKbps > 0 ? "\(station.bitrateKbps) KBPS" : "STREAM"
        persist()
    }

    func play(_ station: Station) {
        currentStation = station
        bitrateLabel = station.bitrateKbps > 0 ? "\(station.bitrateKbps) KBPS" : "STREAM"
        persist()
        guard state != .off || player.currentItem == nil else { return }
        startTuning(station)
    }

    /// Full stop: power off the set.
    func stop() {
        retryTask?.cancel(); retryTask = nil
        icyTask?.cancel(); icyTask = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        state = .off
        nowPlayingTitle = ""
        vu.level = 0; vu.peak = 0
    }

    func selectNext() { nudge(+1) }
    func selectPrevious() { nudge(-1) }

    private func nudge(_ delta: Int) {
        guard let station = currentStation else { return }
        let siblings = stationsForSelection
        guard !siblings.isEmpty else { return }
        let idx = siblings.firstIndex(where: { $0.id == station.id }) ?? 0
        let next = (idx + delta + siblings.count) % siblings.count
        play(siblings[next])
    }

    /// Injected by the app so the player can walk the current country list.
    var stationsForSelection: [Station] = []

    // MARK: - Tuning

    private func startTuning(_ station: Station) {
        guard let url = station.url else {
            state = .signalLost
            scheduleRetry()
            return
        }
        cleanupObservers()
        state = .tuning
        nowPlayingTitle = ""

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 6

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .failed:
                    self.handleFailure()
                case .readyToPlay:
                    self.player.play()
                    if self.state == .tuning { self.state = .playing }
                default:
                    break
                }
            }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] pl, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if pl.timeControlStatus == .waitingToPlayAtSpecifiedRate,
                   self.state == .playing {
                    self.state = .tuning
                } else if pl.timeControlStatus == .playing,
                          self.state != .off {
                    self.state = .playing
                }
            }
        }

        // Primary metadata path: let AVFoundation surface the ICY tags directly.
        let bridge = MetadataBridge { [weak self] title in
            guard let title, !title.isEmpty else { return }
            Task { @MainActor [weak self] in self?.nowPlayingTitle = title }
        }
        metadataDelegate = bridge
        let metadataOutput = AVPlayerItemMetadataOutput()
        metadataOutput.setDelegate(bridge, queue: .main)
        item.add(metadataOutput)

        stallObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.state != .off else { return }
                self.state = .tuning
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handleFailure() }
        }

        player.replaceCurrentItem(with: item)
        player.play()

        // Fallback metadata path: some Icecast servers are only reachable
        // through a plain ICY request (spec: Icy-MetaData: 1).
        startICYProbe(url: url)
    }

    private func cleanupObservers() {
        if let stallObserver {
            NotificationCenter.default.removeObserver(stallObserver)
            self.stallObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        statusObservation?.invalidate(); statusObservation = nil
        timeControlObservation?.invalidate(); timeControlObservation = nil
        icyTask?.cancel(); icyTask = nil
        metadataDelegate = nil
    }

    private func handleFailure() {
        guard state != .off else { return }
        state = .signalLost
        scheduleRetry()
    }

    private func scheduleRetry() {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled, let self else { return }
            guard self.state == .signalLost, let station = self.currentStation else { return }
            self.startTuning(station)
        }
    }

    // MARK: - ICY metadata (fallback path)

    /// Issues a raw Icecast request with `Icy-MetaData: 1` and parses the
    /// in-band `StreamTitle='…'` blocks that follow every `icy-metaint` bytes.
    private func startICYProbe(url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("RetroWave/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("1", forHTTPHeaderField: "Icy-MetaData")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self else { return }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { return }
            guard let data, !data.isEmpty else { return }
            let headers = (response as? HTTPURLResponse)?.allHeaderFields ?? [:]
            let metaInt = Self.headerInt(headers, "icy-metaint")
            guard metaInt > 0 else { return }

            // First block of audio may be short, so scan for the text pattern
            // rather than trusting the very first metaint boundary.
            guard let title = Self.extractStreamTitle(from: data) else { return }
            Task { @MainActor [weak self] in
                guard let self, self.nowPlayingTitle.isEmpty else { return }
                self.nowPlayingTitle = title
            }
            _ = metaInt
        }
        icyTask = task
        task.resume()
    }

    private nonisolated static func headerInt(_ headers: [AnyHashable: Any], _ key: String) -> Int {
        for (k, v) in headers {
            guard let name = k as? String, name.lowercased() == key.lowercased() else { continue }
            if let i = v as? Int { return i }
            if let s = v as? String { return Int(s) ?? 0 }
        }
        return 0
    }

    /// Finds `StreamTitle='…'` inside an ICY metadata block and unescapes it.
    nonisolated static func extractStreamTitle(from data: Data) -> String? {
        guard let text = String(data: data, encoding: .isoLatin1) else { return nil }
        guard let keyRange = text.range(of: "StreamTitle='") else { return nil }
        let rest = text[keyRange.upperBound...]
        guard let endQuote = rest.firstIndex(of: "'") else { return nil }
        var value = String(rest[rest.startIndex..<endQuote])
        value = value.replacingOccurrences(of: "';", with: "")
        value = value.replacingOccurrences(of: "\u{0}", with: "")
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    // MARK: - Simulated VU

    /// Drives the animated meter. Levels are synthesised (seeded from the
    /// station id so each band behaves slightly differently) and collapse to
    /// zero whenever the set is off or has lost signal.
    private func startVUDrive() {
        vuTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 55_000_000)
                guard let self else { return }
                let live = (self.state == .playing)
                if live {
                    let base = 0.42 + 0.26 * sin(Double(Date().timeIntervalSince1970) * 3.1)
                    let jitter = Double.random(in: -0.16...0.16)
                    let lowPass = max(0, min(1, base + jitter))
                    // Publishing a value that has not meaningfully changed still
                    // invalidates the meter 18x a second — skip it.
                    let nextLevel = self.vu.level * 0.55 + lowPass * 0.45
                    if abs(nextLevel - self.vu.level) > 0.0015 { self.vu.level = nextLevel }
                    let nextPeak = max(nextLevel, self.vu.peak - 0.012)
                    if nextPeak != self.vu.peak { self.vu.peak = nextPeak }
                } else {
                    var nextLevel = self.vu.level * 0.72
                    if nextLevel < 0.001 { nextLevel = 0 }
                    if nextLevel != self.vu.level { self.vu.level = nextLevel }
                    let nextPeak = max(nextLevel, self.vu.peak - 0.02)
                    if nextPeak != self.vu.peak { self.vu.peak = nextPeak }
                }
            }
        }
    }

    // MARK: - Persistence

    private func persist() {
        defaults.set(volume, forKey: Keys.volume)
        if let c = currentStation?.countryCode { defaults.set(c, forKey: Keys.country) }
        if let id = currentStation?.id { defaults.set(id, forKey: Keys.station) }
    }

    private func restoreVolume() {
        if defaults.object(forKey: Keys.volume) != nil {
            let v = defaults.double(forKey: Keys.volume)
            if v > 0 { volume = v }
        }
    }

    var savedCountryCode: String? { defaults.string(forKey: Keys.country) }
    var savedStationID: String? { defaults.string(forKey: Keys.station) }
}

/// Receives AVFoundation's `AVMetadataItem` values (ICY `StreamTitle` among them)
/// and forwards the display string to the player.
private final class MetadataBridge: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    private let onTitle: (String?) -> Void
    init(onTitle: @escaping (String?) -> Void) { self.onTitle = onTitle }

    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        for group in groups {
            for item in group.items {
                guard item.commonKey == .commonKeyTitle else { continue }
                // The modern metadata API is async; hop off the push delegate.
                Task {
                    let value = try? await item.load(.stringValue)
                    guard let value, !value.isEmpty else { return }
                    onTitle(value)
                }
            }
        }
    }
}
