import AppKit
import SwiftUI

final class CalibrationFlow {
    private var window: NSWindow?
    private var pending: [NSScreen] = []
    private let onComplete: () -> Void
    private weak var parentWindow: NSWindow?

    init(parentWindow: NSWindow?, onComplete: @escaping () -> Void) {
        self.parentWindow = parentWindow
        self.onComplete = onComplete
    }

    /// Prompt for any displays we haven't offered calibration for yet, then walk through them.
    /// Runs at launch and whenever a new display is connected; already-seen displays
    /// (calibrated or previously skipped) are left alone.
    func startFlowForNewDisplays(screens: [NSScreen]) {
        let newScreens = screens.filter { !CalibrationStore.isKnown($0) }
        guard !newScreens.isEmpty else {
            onComplete()
            return
        }
        showPrompt(targetScreen: newScreens.first ?? NSScreen.main ?? screens[0],
                   uncalibratedCount: newScreens.count) { [weak self] calibrate in
            guard let self else { return }
            if calibrate {
                self.pending = newScreens
                self.advance()
            } else {
                // Remember them so we don't ask again next launch.
                newScreens.forEach(CalibrationStore.markKnown)
                self.finish()
            }
        }
    }

    /// Recalibrate a specific screen (e.g. triggered by the C hotkey).
    func recalibrate(screen: NSScreen) {
        pending = [screen]
        advance()
    }

    // MARK: - Steps

    private func showPrompt(
        targetScreen: NSScreen,
        uncalibratedCount: Int,
        decision: @escaping (Bool) -> Void
    ) {
        let view = CalibrationPromptView(
            screenCount: uncalibratedCount,
            onCalibrate: { [weak self] in
                self?.closeWindow()
                decision(true)
            },
            onSkip: { [weak self] in
                self?.closeWindow()
                decision(false)
            }
        )
        presentSheet(
            rootView: AnyView(view),
            contentSize: CGSize(width: 440, height: 220),
            on: targetScreen,
            title: "Ruler App"
        )
    }

    private func advance() {
        guard let screen = pending.first else {
            finish()
            return
        }
        CalibrationStore.markKnown(screen)
        let label = screenLabel(for: screen, indexHint: pending.count)
        let saved = CalibrationStore.pointsPerMm(for: screen)
        let initial = saved ?? DisplayMetrics.pointsPerMillimeter(for: screen)
        let view = CalibrationView(
            screenLabel: label,
            initialPointsPerMm: initial,
            hasSavedCalibration: saved != nil,
            onSave: { [weak self] value in
                CalibrationStore.save(pointsPerMm: value, for: screen)
                self?.closeWindow()
                self?.pending.removeFirst()
                self?.advance()
            },
            onSkip: { [weak self] in
                self?.closeWindow()
                self?.pending.removeFirst()
                self?.advance()
            },
            onReset: { [weak self] in
                CalibrationStore.clear(for: screen)
                self?.closeWindow()
                self?.pending.removeFirst()
                self?.advance()
            }
        )
        presentSheet(
            rootView: AnyView(view),
            contentSize: CGSize(width: 800, height: 420),
            on: screen,
            title: "Calibrate \(label)"
        )
    }

    private func finish() {
        closeWindow()
        onComplete()
    }

    // MARK: - Window management

    private func presentSheet(
        rootView: AnyView,
        contentSize: CGSize,
        on screen: NSScreen,
        title: String
    ) {
        closeWindow()
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = CGRect(origin: .zero, size: contentSize)

        let win = NSWindow(
            contentRect: hosting.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = title
        win.contentView = hosting
        win.isReleasedWhenClosed = false
        win.level = .floating

        let f = win.frame
        let anchor = parentWindow?.frame ?? screen.frame
        let origin = CGPoint(
            x: anchor.midX - f.width / 2,
            y: anchor.midY - f.height / 2
        )
        win.setFrameOrigin(origin)
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    private func closeWindow() {
        window?.close()
        window = nil
    }

    private func screenLabel(for screen: NSScreen, indexHint: Int) -> String {
        if let name = screen.localizedName as String?, !name.isEmpty {
            return name
        }
        return "Display"
    }
}
