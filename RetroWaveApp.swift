import SwiftUI
import AppKit

@main
struct RetroWaveApp: App {
    @StateObject private var player = RadioPlayer()
    @StateObject private var model: AppModel
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    init() {
        let player = RadioPlayer()
        let library = StationLibraryLoader.load()
        _player = StateObject(wrappedValue: player)
        _model = StateObject(wrappedValue: AppModel(player: player, library: library))
        // Rasterise the five cabinet textures offscreen, once, so the live
        // face only composites images — the heavy skins must not re-render
        // their full-size texture on every face update (it made window
        // drags flicker and hitch).
        SkinEngine.SkinTextureCache.prime()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .environmentObject(model)
                .background(WindowAccessor { window in
                    AppState.shared.window = window
                    applySize(window, mini: model.isMiniPlayer)
                })
                .frame(width: model.isMiniPlayer ? 300 : 800,
                       height: model.isMiniPlayer ? 80 : 520)
                .onAppear { delegate.model = model }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // RetroWave menu
            CommandGroup(replacing: .appInfo) {
                Button("About RetroWave") { model.showAbout = true }
            }
            CommandGroup(replacing: .help) {
                Button("RetroWave Help") { NSWorkspace.shared.open(URL(fileURLWithPath: "/")) }
            }
            // File menu
            CommandGroup(after: .newItem) {
                Divider()
                Button("Mini Player") { toggleMini() }
                    .keyboardShortcut("m", modifiers: [.command, .shift])
                Divider()
            }
            CommandMenu("Playback") {
                Button("Power On / Off") { model.togglePower() }
                    .keyboardShortcut("p", modifiers: [.command])
                Button("Next Station") { player.selectNext() }
                    .keyboardShortcut("]", modifiers: .command)
                Button("Previous Station") { player.selectPrevious() }
                    .keyboardShortcut("[", modifiers: .command)
            }
            CommandGroup(replacing: .appTermination) {
                Button("Quit RetroWave") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q", modifiers: .command)
            }
        }
    }

    private func toggleMini() {
        model.isMiniPlayer.toggle()
        if let w = AppState.shared.window {
            applySize(w, mini: model.isMiniPlayer)
        }
    }

    private func applySize(_ window: NSWindow, mini: Bool) {
        let size = mini ? NSSize(width: 300, height: 80) : NSSize(width: 800, height: 520)

        // `WindowAccessor.updateNSView` calls this on every SwiftUI redraw — the
        // needle ticks ~4x a second — so it must be idempotent. Centring on each
        // pass dragged the window back to its launch position and made it feel
        // glued to the screen. It is only done once, the first time it appears.
        // A Window Server drag runs its own modal loop on this thread; touching
        // the frame while it is in flight makes the window fight the drag.
        guard !AppState.shared.isWindowDragging else { return }

        window.styleMask.remove(.resizable)
        if window.frame.size != size {
            window.setContentSize(size)
        }
        if !AppState.shared.hasBeenPositioned {
            window.center()
            AppState.shared.hasBeenPositioned = true
        }
    }
}

/// Minimal delegate so the app has no dock icon gymnastics and quits cleanly.
final class AppDelegate: NSObject, NSApplicationDelegate {
    var model: AppModel?
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// Switches between the full cabinet and the mini player, and hosts About.
struct RootView: View {
    @EnvironmentObject var player: RadioPlayer
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            if model.isMiniPlayer {
                MiniPlayerView(model: model, player: player)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                RadioFaceView()
                    .transition(.opacity)
            }
        }
        .animation(SkinEngine.crossfade, value: model.isMiniPlayer)
        .sheet(isPresented: $model.showAbout) {
            AboutView()
        }
    }
}

struct AboutView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let theme = model.theme
        VStack(spacing: 10) {
            Text("RETROWAVE")
                .font(theme.font(28))
                .tracking(6)
                .foregroundColor(theme.accent)
            Text("v1.0 · Vintage Internet Radio")
                .font(theme.labelFont(12))
                .foregroundColor(theme.dialText)
            Divider().frame(width: 220)
            Text("Five country skins · 12 cities · verified live streams\nBuilt with SwiftUI and AVFoundation.\nStations courtesy of the radio-browser.info open directory.")
                .font(theme.smallFont(10))
                .multilineTextAlignment(.center)
                .foregroundColor(theme.dialSubText)
            Button("Close") { model.showAbout = false }
                .padding(.horizontal, 22)
                .padding(.vertical, 6)
        }
        .padding(28)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [theme.cabinetTop, theme.cabinetBottom],
                                     startPoint: .top, endPoint: .bottom))
        )
    }
}
