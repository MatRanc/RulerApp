import AppKit
import SwiftUI

final class CalibrationFlow {
    private var window: NSWindow?
    private var pending: [NSScreen] = []
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    /// Start the launch-time flow: prompt the user, then walk through any uncalibrated screens.
    func startLaunchFlow(screens: [NSScreen]) {
        let uncalibrated = screens.filter { CalibrationStore.pointsPerMm(for: $0) == nil }
        guard !uncalibrated.isEmpty else {
            onComplete()
            return
        }
        showPrompt(targetScreen: uncalibrated.first ?? NSScreen.main ?? screens[0],
                   uncalibratedCount: uncalibrated.count) { [weak self] calibrate in
            guard let self else { return }
            if calibrate {
                self.pending = uncalibrated
                self.advance()
            } else {
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
        presentSheet(rootView: AnyView(view), on: targetScreen, title: "RulerApp")
    }

    private func advance() {
        guard let screen = pending.first else {
            finish()
            return
        }
        let label = screenLabel(for: screen, indexHint: pending.count)
        let initial = CalibrationStore.pointsPerMm(for: screen)
            ?? DisplayMetrics.pointsPerMillimeter(for: screen)
        let view = CalibrationView(
            screenLabel: label,
            initialPointsPerMm: initial,
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
            }
        )
        presentSheet(rootView: AnyView(view), on: screen, title: "Calibrate \(label)")
    }

    private func finish() {
        closeWindow()
        onComplete()
    }

    // MARK: - Window management

    private func presentSheet(rootView: AnyView, on screen: NSScreen, title: String) {
        closeWindow()
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = CGRect(x: 0, y: 0, width: 600, height: 360)

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
        win.center()
        // Reposition onto the target screen.
        let f = win.frame
        let sf = screen.frame
        let origin = CGPoint(
            x: sf.midX - f.width / 2,
            y: sf.midY - f.height / 2
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
