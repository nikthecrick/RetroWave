# RetroWave — roadmap / next steps

## 1. iOS (iPhone + iPad) port

Status: **planned, not started.** Assessment from 2026-10-04.

The app is small (~2.5k lines) and ~80 % platform-neutral; the macOS-specific
parts are mostly *removed*, not ported.

### What ports almost for free
- All five skins, `SkinEngine`, knobs, dial, VU, station/country bands —
  pure SwiftUI + `Canvas` (iOS 15+)
- `Country` / `Station` / `stations.json`, `AppModel`, `RadioPlayer`
  (AVPlayer + ICY + retry) — Foundation/AVFoundation, unchanged
- The macOS window-drag machinery (`WindowDragHandle`, `DragZones`,
  `MouseDownCapture`, `WindowDragHandoff` in `Views/MiniPlayerView.swift`)
  is **deleted**, not ported — iOS has no hidden-title-bar problem

### What needs replacing
| macOS piece | iOS replacement |
|---|---|
| `NSImage` / `NSScreen` in `SkinEngine.SkinTextureCache` | `UIImage` / `UIScreen` (`ImageRenderer.nsImage` → `.uiImage`) |
| `SoundEffects` via `NSSound` | `AVAudioPlayer` |
| `@main` + `NSApplicationDelegateAdaptor` + menu commands | iOS scene; menu actions (power, next/prev) need a home in the UI — most already have buttons |
| `Info.plist` | same `NSAllowsArbitraryLoads` (HTTP streams) **plus** `UIBackgroundModes = audio` |

### The real iOS work
1. **Audio session** — `AVAudioSession` category `.playback`, interruption
   handling (incoming calls), and lock-screen controls via
   `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter`. Without lock-screen
   play/pause/next the app feels broken on iOS.
2. **Layout** — the 800×520 face fits an iPad landscape almost as-is; on
   iPhone it needs a reflow. The main casualty is `MiddleRow`
   (dial + grille side by side is too wide for ~390 pt).
3. **App Store friction** — plain-HTTP community streams need the
   `NSAllowsArbitraryLoads` exception justified in review; iHeart stations
   are geo-restricted and will show SIGNAL LOST outside the US. Third-party
   stream redistribution terms should be sanity-checked per station.

### Suggested sequence
1. Split shared code into a shared target/folder (models, skins, player,
   face views) — the macOS app consumes it unchanged.
2. Ship **iPad first** (existing layout nearly works, scales to 1024×768).
3. iPhone variant with the reflowed layout.
4. Audio session + remote commands, interruption tests, ATS justification
   blurb for the App Store review notes.

Realistic effort: a few days, not weeks.

---

## 2. Candidate follow-ups (uncommitted)

- Universal macOS binary (compile arm64 + x86_64, `lipo -create`) — decided
  against for now: native-to-machine builds are acceptable.
- A few plain-HTTP community streams could be swapped for HTTPS variants to
  soften the ATS exception.
