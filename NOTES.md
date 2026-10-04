# RetroWave v1.0 — build notes, caveats, and how to run

A vintage-cabinet internet radio player for macOS 13+, built with SwiftUI and
AVFoundation. Five country skins, 27 stations across 12 cities, every stream
verified live before shipping.

---

## 1. How to run

```bash
# Already built — just launch it
open RetroWave/build/RetroWave.app

# Or drag RetroWave.app into /Applications
cp -R build/RetroWave.app /Applications/
```

Requires macOS 13 Ventura or newer. The build on this machine is **x86_64**
(Intel). For Apple Silicon, re-run `./RetroWave/build.sh` on an arm64 Mac — the
script picks the triple automatically from `uname -m`.

### Rebuilding from source

```bash
cd RetroWave
./build.sh                 # -> ./build/RetroWave.app  (ad-hoc signed)
```

`build.sh` compiles every `*.swift` outside `Tools/` with `swiftc`, assembles
the `.app` `Contents` tree by hand, copies `Models/stations.json` and
`Resources/AppIcon.icns` into `Resources/`, and runs
`codesign --force --deep --sign -`. Pass a directory as `$1` to build
elsewhere.

### Re-verifying the streams

```bash
cd research
bash final_verify.sh       # checks all 25 URLs in parallel -> final_verify_result.txt
python3 build_stations.py  # regenerates RetroWave/Models/stations.json
```

### Regenerating the icon

```bash
cd RetroWave
swiftc -O Tools/MakeIcon.swift -o .build/makeicon
./.build/makeicon Resources/AppIcon.iconset
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
```

### Rendering the skins offscreen (no window server needed)

```bash
cd RetroWave
swiftc -parse-as-library $(find . -name '*.swift' -not -path './Tools/*' \
    -not -name 'RetroWaveApp.swift' -not -path './.build/*') \
    Tools/Preview/Preview.swift -o .build/preview
./.build/preview Models/stations.json .build/preview-out
```

This writes `skin-US.png`, `skin-FR.png`, `skin-ZA.png`, `skin-CN.png`,
`skin-MX.png`.

---

## 2. Blockers and workarounds

### No full Xcode — the bundle is assembled by hand

This machine has the **Xcode Command Line Tools only**; `xcodebuild` refuses to
run (`active developer directory ... is a command line tools instance`). So:

* There is **no `.xcodeproj` and no Xcode build**. `build.sh` calls `swiftc`
  directly and lays out the `.app` by hand.
* **`xcodebuild`, scheme settings, and SwiftUI previews are unavailable.** The
  `Tools/Preview` offscreen renderer exists as a substitute.
* To open this in Xcode later, create a macOS App target, add the sources in
  `Models/`, `Audio/`, `Skins/`, `Views/`, and add `Models/stations.json` to
  "Copy Bundle Resources". Set the deployment target to macOS 13.0.

### No screen recording permission — UI verified offscreen

`screencapture` fails in this environment (`could not create image from display`)
and `osascript`/System Events hangs, so **the running window was never
screenshotted**. The UI was instead verified by rendering the real view
hierarchy through `ImageRenderer` (see `Tools/Preview`). That exercise does
reproduce `Canvas` content, so the previews in `.build/preview-out/` are
faithful for layout, typography, colour, and the procedural textures.

**What this means:** interactive behaviour that needs a real window —
drag-rotating the knobs, the mini-player resize, hover states, live audio
playback — was verified by code review and by launching the app (it runs
without crashing), **not** by clicking through it. Please sanity-check those on
a machine with a desktop session.

### Swift type-checker limits

`RadioFaceView`'s original single-`body` layout took **25 s** to type-check and
failed outright. The cabinet is now split into named small views
(`HeaderBar`, `MiddleRow`, `NowPlayingStrip`, `ControlRow`, `StationBand`,
`CountryRow`, `CabinetPanel`), each cheap to check. `KnobView`'s cap is likewise
split into three small builders per material (static base, turning part,
static lighting).

---

## 3. Stations — what shipped and what did not

**All 27 shipped URLs were verified live** — the original 25 during
selection and again as a final sweep on 2026-09-26 (`LIVE` for 25/25), and the
eight Mexican streams on 2026-10-04 (ranged GET, HTTP 200/206, audio sync
bytes received). Six verified stations were later trimmed (KUSC 91.9,
Chilltrax, Deep Space One and Miami Beach Radio in the US; La Ke Buena 92.9
in MX) to keep every country's band at eight stations or fewer, so all
buttons fit the cabinet width with readable engraving.

Source: the **radio-browser.info** open directory (`de1.api.radio-browser.info`),
which aggregates community Icecast/Shoutcast listings. Stream URLs in
`stations.json` are the *resolved* URLs from that directory.

| Country | Locations | Stations |
|---|---|---|
| 🇺🇸 US | New York (2), Los Angeles (2), Miami (2), San Francisco (2) | 8 |
| 🇫🇷 FR | Paris (3), Marseille (3) | 6 |
| 🇿🇦 ZA | Johannesburg / Cape Town (3) | 3 |
| 🇨🇳 CN | Beijing & Shanghai (3) | 3 |
| 🇲🇽 MX | Mexico City (4), Guadalajara (1), Monterrey (1), Hermosillo (1) | 7 |

### Candidates that were rejected

Roughly a dozen candidate endpoints turned out to be dead or unusable and were
**replaced**, not skipped — no city was dropped:

| Candidate | Problem | Replaced with |
|---|---|---|
| `kusc.streamguys1.com/kusc-mp3` | DNS failure (guessed path) | KUSC 91.9 via `18443.live.streamtheworld.com` |
| `kcrw.streamguys1.com/kcrw_192k_mp3_e24` | DNS failure | KCRW 88.9 via `streams.kcrw.com` |
| `kqed.streamguys1.com/…`, `kcalx.streamguys1.com/…`, `bagnews.streamguys1.com` | DNS failure | KQED `streams.kqed.org`, KALX `stream.kalx.berkeley.edu` |
| `server1.chilltrax.com:9000` | Connection refused | `streamssl.chilltrax.com` |
| `icecast.radiofrance.fr/fip-hifi.mp3` (and `-inter-`, `-culture-`) | **HTTP 404** — Radio France publishes AAC, not MP3, on those paths | `.aac` variants (live) |
| `classic1027.streamguys1.com/mp3-128` | DNS failure | Kaya FM / Amapiano FM |
| `stream.krypton.co.za:8040` (Radio 786) | DNS failure | Hot 102.7 FM, Amapiano FM |
| `华语金曲500首` (lhttp.qtfm.cn/live/3412131) | **HTTP 404** | 北京音乐广播 FM97.4 |

### Caveats about these streams

* **Several US stations are iHeart properties** (Q104.3, Mega 96.3, Z 92). They
  resolve and serve audio, but iHeart geo-restricts some content outside the US.
  If one goes silent, the app shows `SIGNAL LOST` and retries every 5 s.
* **CMA/Chinese streams** (`lhttp.qtfm.cn`, `lhttp.qingting.fm`) are
  mainland-reachable and were verified from an Asia-Pacific network. They may be
  slow or blocked from other regions.
* **South Africa's directory coverage is genuinely thin** — radio-browser
  listed only ~40 ZA stations, most AAC-only, and few are individually famous.
  Ukhozi FM, Kaya FM and Amapiano FM were chosen as the most recognisable
  afrobeats / world / amapiano voices available. This is the weakest of the
  five station sets.
* **Frequencies are fictional.** Real FM frequencies in the 88–108 MHz band
  would clash with licensed broadcasters, so each station is given a plausible
  in-band position purely to drive the dial needle. `frequency` in
  `stations.json` is presentation data, not the real broadcast frequency.
  The Mexican set mixes real FM numbers where the station holds an FM license
  (W Radio 96.9, Radio Centro 97.7, La Mejor 98.5) with in-band positions for
  AM-only transmitters — the same convention already used for the
  internet-only US stations.
* Verified responses are `HTTP 200`/`206` with an audio body — the check proves
  the endpoint serves audio, not that the licence is cleared for redistribution.
  The app plays streams from their original servers and hosts no audio itself.

---

## 4. Skin elements simplified from the spec

| Spec | What shipped | Why |
|---|---|---|
| `Assets.xcassets/` with knob/texture images | **No asset catalog.** Every texture is procedural (`Canvas` / `Path` / gradients), and `AppIcon.icns` is generated by `Tools/MakeIcon.swift` and placed in `Contents/Resources/`. | The spec also said textures must be generated procedurally with no image files, which makes an asset catalog redundant. |
| Bebas Neue (US), Didot (FR), simulated brushstroke (CN) | System fonts only, chosen at runtime by `FontProbe` with graceful fallback. US/ZA → `Futura-CondensedExtraBold`; FR → `Didot-Bold`; CN → `STKaiti-Kai` (Kaiti); MX → `AvenirNextCondensed-Heavy`. | Avoids shipping and licensing font binaries. Bebas Neue is not a macOS system font; **Didot and Kaiti are**, so the intended French and Chinese looks are authentic. If Bebas Neue is installed it is used. |
| Real audio metering for the VU meter | **Simulated.** A timer drives a smoothed envelope with peak-hold, gated on playback state, collapsing to zero when off or `SIGNAL LOST`. | Genuine RMS metering needs an `AVAudioEngine` tap on an output unit, which cannot measure what `AVPlayer` sends to the system output. The spec explicitly permitted a fake tied to play/pause. The VU is labelled `VU` with a power lamp so it is not presented as a real meter. |
| Real MP3/AAC DSP for the Bass / Treble / Tone knobs | Cosmetic only — the knobs rotate and hold state but do not alter audio. | `AVPlayer` exposes no EQ. Wiring real filters would mean replacing it with `AVAudioEngine` + `AVPlayerItemOutput`, a much larger change. **Volume is real** and drives `AVPlayer.volume`. |
| `NSSound` click from "a short sine-wave burst generated in code" | As specified — `SoundEffects` synthesises both effects as 16-bit PCM WAV in a temp dir, then plays them via `NSSound`. The click is a 1.65 kHz sine + 420 Hz body with a fast exponential decay; the skin-change static is high-passed noise. | Matches the spec. |
| Window "fixed size 800×520, non-resizable" | `800×520` and `300×80` for the mini player. Non-resizable via `styleMask.remove(.resizable)` and `.windowResizability(.contentSize)`. **Movable via a hand-rolled drag**, see below. | Matches. |
| Crossfade 0.6 s ease-in-out on skin change | `SkinEngine.crossfade = .easeInOut(duration: 0.6)`, applied to the country selection. | Matches. |
| Needle idle drift ±2° | Implemented, `sin(t·0.9)·2.0 + sin(t·2.3)·0.6`. | Matches. |

### Other judgement calls

* **The station band fills the cabinet — no scrolling.** Buttons are
  flex-width and stretch to fill the row, so every station is visible at
  once: no chevrons, no drag-scroll, no clipping. Crowded sets (nine or more
  stations — currently the US set with twelve) switch to a compact engraving
  (9 pt title / 6.5 pt genre, smaller indicator dot) so they stay legible at
  narrow button widths; long titles truncate with an ellipsis rather than
  overflow. The earlier hand-rolled scroll band (offset + chevron paging) was
  removed: a `ScrollView` was rejected because it swallows clicks on some
  macOS versions, and the scrolling itself was dropped in favour of
  everything-visible.
* **Contrast-aware ink.** Several skins invert (ivory cabinets, crimson
  lacquer), so engraved text colour is derived at runtime by WCAG contrast
  ratio (`Color.bestInk`) instead of being hard-coded per country. The first
  pass hard-coded colours and was unreadable on three of the four skins.
* **Knob lighting is static.** Each cap is drawn as a static base + the part
  that turns with the value + a static specular/trim overlay, so the highlight
  stays at the upper left while the cap rotates — rotating the sheen with the
  cap made the knobs look like they slid and tilted rather than turning under
  a fixed light. The rotation also tracks the cursor 1:1 while being turned
  by hand (`isTurning` disables the spring mid-drag); the spring is kept only
  for programmatic value changes, so the cap no longer lags or overshoots the
  cursor.
* **High-frequency updates are scoped to their own views.** While the set is
  on, the VU republishes ~18×/sec and the needle drift retargets ~4×/sec.
  Both used to live on views that pulled the whole face down with them: the
  VU levels were `@Published` on `RadioPlayer` (and `@Published` invalidates
  the whole object, not one property), and the drift `@State` sat on
  `RadioFaceView` — so the entire cabinet re-rendered 18×/sec, re-rasterising
  the grille and knob canvases mid-drag and making window drags flicker and
  hitch while playing (with the set off, the face went static and drags were
  smooth). The levels now live in `VUMeterState`, observed by `VUMeterView`
  only, and the drift timer lives in `TunerDialView`, so playing re-renders
  only the meter (tiny) and the dial (scale is `Equatable`-keyed, needle is
  cheap shapes).
* **Skin textures are pre-rasterised.** The face re-evaluates several times a
  second (needle drift ~4x, VU ~18x while playing) and a live full-size
  `Canvas` is re-rasterised on every re-evaluation — at 800×520 that made
  dragging the window flicker and hitch on the heavier skins (France
  sunburst, SA wood grain + Ndebele, CN lattice) while the light US texture
  kept up. `SkinEngine.SkinTextureCache.prime()` therefore renders all four
  textures offscreen with `ImageRenderer` at launch, and the face composites
  the cached `NSImage` instead of the live `Canvas` (which remains only as a
  fallback for the cache-less offscreen preview tool). `DialScaleCanvas` is
  likewise keyed Equatable (skin + tuned station + state) so the needle
  ticks do not re-rasterise the printed scale.
* **Extra 26 pt bottom inset** on the panel so the Ndebele and Chinese fretwork
  borders, which are painted along the cabinet edge, do not sit under the
  country buttons.
* **The window backdrop follows the skin.** With `.windowStyle(.hiddenTitleBar)`
  the cabinet fills the whole window, but the AppKit backdrop still shows
  through at the cabinet's 14 pt rounded corners and in the ring around its
  drop shadow — default grey, which clashed with every skin. The
  `WindowAccessor` closure therefore sets
  `window.backgroundColor = NSColor(theme.cabinetBottom)` on every update, so
  the edges read as the cabinet finish instead of a grey plate.
* **Dual ICY metadata path.** The primary path is
  `AVPlayerItemMetadataOutput`, which surfaces ICY tags natively without a
  second connection. A fallback issues a raw `URLSession` request with
  `Icy-MetaData: 1` and parses `StreamTitle='…'` for servers that only expose it
  that way — this is the path the spec described.

---

## 5. Controls

| Control | Action |
|---|---|
| POWER | Toggles the set on/off. Lit when on. |
| Volume knob | Drag vertically, 0–100, mapped linearly to `AVPlayer.volume`. |
| Bass / Treble / Tone knobs | Drag vertically. Cosmetic (see above). |
| Station pushbuttons | Click to tune. Click the already-live station to toggle power. The row flexes to fit the cabinet, so all stations are visible at once. |
| Country buttons | Switch skin. Crossfades over 0.6 s, plays a static crackle. |
| Globe badge | Decorative; drifts as a wire-frame globe. |
| MINI paddle switch (header) | Slides the cabinet into the 300×80 mini bar (same as ⇧⌘M). The mini bar's small expand glyph brings the cabinet back — without it the only way out of mini mode would have been the menu. |
| ⌘P | Power on/off |
| ⌘] / ⌘[ | Next / previous station |
| ⇧⌘M | Toggle the 300×80 mini player |
| ⌘Q | Quit |

Last country, station, and volume persist in `UserDefaults`
(`retrowave.country`, `retrowave.station`, `retrowave.volume`). The set always
starts in **STANDBY** — restoring a session primes the dial without powering on.

## 6. Project layout

```
RetroWave/
├── RetroWaveApp.swift          # @main App, menu commands, About, window sizing
├── build.sh                    # swiftc build + bundle + ad-hoc codesign
├── Models/
│   ├── Station.swift           # Station, StationLibrary, JSON loader
│   ├── Country.swift           # Country enum + display metadata
│   ├── AppModel.swift          # selected skin/station, UserDefaults persistence
│   └── stations.json           # 27 verified streams
├── Audio/
│   ├── RadioPlayer.swift       # AVPlayer, buffering, ICY, retry, persistence
│   └── SoundEffects.swift      # runtime-synthesised WAV click + static
├── Skins/
│   ├── SkinEngine.swift        # SkinTheme, FontProbe, 5 procedural textures
│   ├── USSkin.swift
│   ├── FranceSkin.swift
│   ├── SouthAfricaSkin.swift
│   ├── ChinaSkin.swift
│   └── MexicoSkin.swift
├── Views/
│   ├── RadioFaceView.swift     # cabinet + layout sections
│   ├── TunerDialView.swift     # scale, needle, drift, readout
│   ├── StationSelectorView.swift# drag-scrollable pushbutton band
│   ├── VUMeterView.swift       # twin bars + peak hold
│   ├── CountrySelectorView.swift
│   ├── KnobView.swift          # KnobView, PowerGlyph, SpeakerGrilleView, PowerButtonView
│   └── MiniPlayerView.swift    # 300×80 bar + WindowAccessor
├── Resources/
│   ├── Info.plist
│   └── AppIcon.icns            # generated by Tools/MakeIcon.swift
└── Tools/
    ├── MakeIcon.swift          # procedural icon renderer
    └── Preview/Preview.swift   # offscreen per-skin PNG renderer
```

Design references consulted for the skins: collectorsweekly/vam.ac.uk/radiomuseum
for Bakelite and 1940s–60s cabinet forms; `artdeco.org`, the V&A and the Met for
the 1925 Paris exposition palette (ivory `#F5F0E8`, gold `#D4A853`, burgundy);
Wikipedia/Britannica on Ndebele mural painting for the five-colour geometric
vocabulary (red, gold, sky blue, green, black outline) and its chevron/diamond
motifs; Met and Britannica on Chinese lacquerwork for the red-and-gold palette
and 回 fretwork lattice; Wikipedia on talavera poblano tileware (cobalt/sienna
on cream glaze, painted flower motifs) and papel picado cut-paper banners for
the Mexican skin; ceramics references on thick-walled terracotta (barro)
for the clay knob material.

## 7. Known issues

* The `Info.plist` sets `NSAllowsArbitraryLoads` because many listed directories
  still serve plain HTTP Icecast endpoints. Fine for a local build; a
  Mac App Store submission would need every URL moved to HTTPS.
* Signed ad-hoc (`-`), so Gatekeeper will quarantine the app on first launch.
  Right-click → **Open**, or:
  `xattr -dr com.apple.quarantine /Applications/RetroWave.app`
* **The window had to be made draggable by hand.** `.windowStyle(.hiddenTitleBar)`
  plus full-bleed cabinet art means AppKit's title-bar drag region never
  receives a mouse event, so the window could not be moved at all. The drag
  strips (top of the cabinet, top of the mini player), the brand nameplate,
  and the mini player's station label register their frames with `DragZones`.
  A local `NSEvent` monitor (`MouseDownCapture`) sees the original mouse-down
  and, when it lands in a registered zone, hands it to
  `performWindowDragWithEvent:` immediately, so the Window Server drives the
  drag from the down itself — no gesture latency, and Space switching still
  works. A `DragGesture` on the same regions remains as a safety net (it hands
  off the most recent original down, or falls back to `setFrameOrigin` if
  none is available), and `applySize` is locked while a Window Server drag is
  in flight so SwiftUI redraws cannot fight the drag. Two earlier attempts
  failed and should not be retried: an `NSViewRepresentable` calling the same
  selector never receives `mouseDown` under the SwiftUI hosting view, and
  moving the window by hand with `setFrameOrigin` on each drag update felt
  laggy and rubbery.
* **The window used to snap back to centre on every redraw.** `applySize` called
  `window.center()`, and `WindowAccessor.updateNSView` re-invokes it on every
  SwiftUI update (the needle ticks ~4x a second), so any drag was undone
  immediately — the "glued to the screen" feeling. It now resizes only when the
  size actually differs and centres exactly once, when the window first appears.
* The globe badge's meridian animation is decorative and not geographically
  meaningful.
