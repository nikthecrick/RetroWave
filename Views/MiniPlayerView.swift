import SwiftUI
import AppKit

/// 300×80 compact bar: station name, transport, and a volume slider.
struct MiniPlayerView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var player: RadioPlayer

    private var theme: SkinTheme { model.theme }

    var body: some View {
        let station = model.station

        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [theme.cabinetTop, theme.cabinetBottom],
                                     startPoint: .top, endPoint: .bottom))
            SkinEngine.textureView(for: theme)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(theme.trimColor.opacity(0.8), lineWidth: 1.2)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(theme.cabinetEdge, lineWidth: 2.5)
                .padding(1)

            HStack(spacing: 8) {
                // Transport
                Button {
                    SoundEffects.shared.playClick()
                    model.togglePower()
                } label: {
                    ZStack {
                        Circle()
                            .fill(player.state == .off
                                  ? theme.buttonFace
                                  : theme.accent)
                            .frame(width: 30, height: 30)
                        Circle()
                            .strokeBorder(theme.dialFaceEdge, lineWidth: 1.2)
                        Image(systemName: player.state == .off ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(player.state == .off ? theme.buttonText : theme.dialFace)
                    }
                }
                .buttonStyle(.plain)

                // Station name
                VStack(alignment: .leading, spacing: 0) {
                    Text(station?.name.uppercased() ?? "RETROWAVE")
                        .font(theme.font(13))
                        .tracking(0.8)
                        .foregroundColor(theme.dialText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(player.state == .off
                         ? (station?.city ?? "")
                         : (player.nowPlayingTitle.isEmpty ? player.state.dialText
                                                            : player.nowPlayingTitle))
                        .font(theme.smallFont(8.5))
                        .foregroundColor(theme.dialSubText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .windowDraggable()

                // Volume
                HStack(spacing: 4) {
                    Image(systemName: player.volume < 0.02 ? "speaker.slash.fill" : "speaker.wave.1.fill")
                        .font(.system(size: 9))
                        .foregroundColor(theme.dialSubText)
                    Slider(value: $player.volume, in: 0...1)
                        .controlSize(.mini)
                        .tint(theme.accent)
                        .frame(width: 66)
                }

                // Expand back to the full cabinet — the inverse of the header
                // paddle switch, kept quiet so it reads as chrome, not a button.
                ExpandButton(theme: theme) {
                    SoundEffects.shared.playClick()
                    model.isMiniPlayer = false
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(width: 300, height: 80)
        // Thin grab strip along the very top, like the full cabinet's.
        .overlay(alignment: .top) { WindowDragHandle(height: 8) }
    }
}

/// The mini bar's way back to the full cabinet: a small expand glyph in the
/// same muted style as the volume icon, brightening on hover.
private struct ExpandButton: View {
    let theme: SkinTheme
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(theme.bezelColor.opacity(0.5))
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(theme.dialFaceEdge.opacity(0.7), lineWidth: 0.8)
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(hovering ? theme.accent : theme.dialSubText)
            }
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

/// Holds the live window reference so menu actions can reach it, and guards
/// `applySize` while a Window Server drag is in flight. Lives here (rather
/// than in the App file) because the offscreen preview tool compiles every
/// view file without the App entry point.
final class AppState {
    static let shared = AppState()
    var window: NSWindow?
    /// Guards the one-time `center()` so redraws do not re-centre the window.
    var hasBeenPositioned = false
    /// True while a Window Server window drag is in flight. Guards `applySize`
    /// so a SwiftUI redraw cannot resize or move the window mid-drag.
    private(set) var isWindowDragging = false

    func beginWindowDrag() { isWindowDragging = true }
    func endWindowDrag() { isWindowDragging = false }
}

/// Window-content-space frames of the views that should behave like a title
/// bar. SwiftUI's `.global` space is the content view with y growing down;
/// AppKit event locations are window-based with y growing up, so the flip
/// happens at hit-test time, when the content height is known.
final class DragZones {
    static let shared = DragZones()

    private var zones: [UUID: CGRect] = [:]

    func register(_ id: UUID, frame: CGRect) { zones[id] = frame }
    func unregister(_ id: UUID) { zones.removeValue(forKey: id) }

    /// Starts a Window Server drag when the mouse-down landed in a registered
    /// zone. Returns true when the handoff happened.
    func tryBeginWindowDrag(for event: NSEvent) -> Bool {
        guard let window = event.window,
              let contentHeight = window.contentView?.frame.height,
              contains(event.locationInWindow, contentHeight: contentHeight) else {
            return false
        }
        return WindowDragHandoff.begin(window: window, with: event)
    }

    private func contains(_ windowPoint: NSPoint, contentHeight: CGFloat) -> Bool {
        let p = NSPoint(x: windowPoint.x, y: contentHeight - windowPoint.y)
        return zones.values.contains { $0.contains(p) }
    }
}

/// Hands a mouse-down to the Window Server so the window follows the cursor
/// exactly the way a real title bar would. The call blocks on the main thread
/// until the mouse is released, so the whole span is guarded by
/// `AppState.isWindowDragging` against mid-drag frame changes.
enum WindowDragHandoff {
    static let selector = NSSelectorFromString("performWindowDragWithEvent:")

    static func begin(window: NSWindow, with down: NSEvent) -> Bool {
        guard window.responds(to: selector) else { return false }
        AppState.shared.beginWindowDrag()
        defer { AppState.shared.endWindowDrag() }
        window.perform(selector, with: down)
        return true
    }
}

/// Watches every left mouse-down in the app.
///
/// `performWindowDragWithEvent:` insists on the *original* mouse-down event and
/// a SwiftUI `DragGesture` only ever reports movement — waiting for the first
/// move made grabs feel dead and rubbery. So the Window Server is asked to take
/// over the drag on the down itself, whenever the point lands in a registered
/// zone. The most recent unclaimed down is kept for the gesture fallback.
/// Letting an `NSViewRepresentable` grab its own `mouseDown` does not work:
/// under the SwiftUI hosting view that override is never called.
final class MouseDownCapture {
    static let shared = MouseDownCapture()

    /// Most recent down that did not start a drag, kept for the fallback path.
    private var lastDown: NSEvent?

    private init() {
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.note(event)
            return event
        }
    }

    private func note(_ event: NSEvent) {
        if !DragZones.shared.tryBeginWindowDrag(for: event) {
            lastDown = event
        }
    }

    /// Returns a recent, same-window mouse-down once, for the fallback handoff.
    func takeFresh(window: NSWindow, maxAge: TimeInterval = 1.0) -> NSEvent? {
        guard let down = lastDown else { return nil }
        lastDown = nil
        let age = ProcessInfo.processInfo.systemUptime - down.timestamp
        guard age >= 0, age <= maxAge,
              down.window?.windowNumber == window.windowNumber else { return nil }
        return down
    }
}

/// Makes a region of the window draggable.
///
/// `.windowStyle(.hiddenTitleBar)` leaves no title bar to grab, and the cabinet
/// art covers the whole window, so AppKit's built-in title-bar drag never fires.
/// The region's frame is registered with `DragZones`, so a mouse-down inside it
/// is handed to the Window Server on the down itself. The gesture is a safety
/// net for downs the monitor did not claim (e.g. stale zone geometry): it hands
/// off the most recent original down, or falls back to moving the window by
/// hand with `setFrameOrigin` if none is available.
private struct WindowDragModifier: ViewModifier {
    /// Token for this view's registered zone, so it can be removed on disappear.
    private let zoneID = UUID()
    /// True while this view's gesture thinks a drag is in flight. Reset on
    /// end so the next grab — even from the exact same spot — starts fresh.
    @State private var isDragging = false

    /// The window being moved, with fallbacks in case the accessor has not run.
    private var target: NSWindow? {
        AppState.shared.window ?? NSApp.keyWindow ?? NSApp.mainWindow
    }

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        guard !isDragging else { return }
                        isDragging = true
                        startDrag(value)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .background(
                GeometryReader { geo in
                    Color.clear
                        .allowsHitTesting(false)
                        .onAppear {
                            DragZones.shared.register(zoneID, frame: geo.frame(in: .global))
                        }
                        .onDisappear {
                            DragZones.shared.unregister(zoneID)
                        }
                }
            )
    }

    private func startDrag(_ value: DragGesture.Value) {
        guard let window = target else { return }
        if let down = MouseDownCapture.shared.takeFresh(window: window) {
            _ = WindowDragHandoff.begin(window: window, with: down)
        } else if !AppState.shared.isWindowDragging {
            // No original down available: keep the window moving by hand so the
            // gesture is not dead. SwiftUI's global space grows downwards,
            // AppKit's frame origin grows upwards, hence the flipped y.
            let origin = window.frame.origin
            window.setFrameOrigin(CGPoint(x: origin.x + value.translation.width,
                                          y: origin.y - value.translation.height))
        }
    }
}

extension View {
    /// Attaches the hidden-title-bar drag workaround. Apply to inert chrome —
    /// never on top of a knob, button or slider.
    func windowDraggable() -> some View {
        modifier(WindowDragModifier())
    }
}

/// An invisible strip whose only job is to be grabbed and dragged.
struct WindowDragHandle: View {
    var height: CGFloat = 16

    var body: some View {
        Color.clear
            .frame(height: height)
            .windowDraggable()
    }
}

/// Bridges SwiftUI to the hosting `NSWindow` so the app can resize itself for
/// the mini player and lock the normal size.
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window { onWindow(window) }
        }
    }
}
