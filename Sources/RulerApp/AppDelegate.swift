import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let state = RulerState()
    private var window: NSWindow?
    private var keyMonitor: Any?
    private var calibrationFlow: CalibrationFlow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        buildMainWindow()
        installKeyMonitor()
        hideUnusedAppMenuItems()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidChangeScreen),
            name: NSWindow.didChangeScreenNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        promptForNewDisplays()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Window

    private func buildMainWindow() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "RulerApp"
        win.minSize = NSSize(width: 240, height: 180)
        win.collectionBehavior.insert(.fullScreenPrimary)
        win.isReleasedWhenClosed = false
        win.setFrameAutosaveName("RulerApp.MainWindow")
        win.center()

        let root = RulerView(state: state) { [weak self] in
            self?.triggerRecalibration()
        }
        win.contentView = NSHostingView(rootView: root)

        // Initial ppm from the screen the window lands on.
        if let screen = win.screen ?? NSScreen.main {
            state.pointsPerMm = DisplayMetrics.effectivePointsPerMm(for: screen)
        }

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    @objc private func windowDidChangeScreen(_ note: Notification) {
        guard let win = note.object as? NSWindow, win === window else { return }
        guard let screen = win.screen else { return }
        state.pointsPerMm = DisplayMetrics.effectivePointsPerMm(for: screen)
    }

    /// Fires on display connect/disconnect and resolution changes. Refresh the current
    /// scale and offer calibration for any display we haven't seen before.
    @objc private func screenParametersChanged(_ note: Notification) {
        if let screen = window?.screen ?? NSScreen.main {
            state.pointsPerMm = DisplayMetrics.effectivePointsPerMm(for: screen)
        }
        promptForNewDisplays()
    }

    // MARK: - Calibration

    /// Prompt for calibration on first run or whenever a new display appears.
    /// No-op while a calibration flow is already on screen.
    private func promptForNewDisplays() {
        guard calibrationFlow == nil else { return }
        let flow = CalibrationFlow(parentWindow: window) { [weak self] in
            guard let self else { return }
            if let screen = self.window?.screen ?? NSScreen.main {
                self.state.pointsPerMm = DisplayMetrics.effectivePointsPerMm(for: screen)
            }
            self.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.calibrationFlow = nil
        }
        calibrationFlow = flow
        flow.startFlowForNewDisplays(screens: NSScreen.screens)
    }

    /// SwiftUI's `Settings { ... }` scene always adds a "Settings…" item to the app menu,
    /// but Ruler App has no settings. Hide it so users don't open an empty window.
    private func hideUnusedAppMenuItems() {
        guard let appMenu = NSApp.mainMenu?.item(at: 0)?.submenu else { return }
        for item in appMenu.items
        where item.title.localizedStandardContains("Settings")
            || item.title.localizedStandardContains("Preferences") {
            item.isHidden = true
        }
    }

    // MARK: - Hotkeys

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Don't swallow keys while a text field has focus (none today, but safe).
            if let responder = event.window?.firstResponder, responder is NSText {
                return event
            }
            return self.handle(event: event) ? nil : event
        }
    }

    private func handle(event: NSEvent) -> Bool {
        switch event.keyCode {
        case 32: // U
            state.unit = state.unit.next
            return true
        case 5: // G
            state.gridMode = state.gridMode.next
            return true
        case 8: // C
            triggerRecalibration()
            return true
        default:
            return false
        }
    }

    // MARK: - Recalibration

    private func triggerRecalibration() {
        guard calibrationFlow == nil else { return }
        guard let screen = window?.screen ?? NSScreen.main else { return }
        let flow = CalibrationFlow(parentWindow: window) { [weak self] in
            guard let self else { return }
            self.state.pointsPerMm = DisplayMetrics.effectivePointsPerMm(for: screen)
            self.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.calibrationFlow = nil
        }
        calibrationFlow = flow
        flow.recalibrate(screen: screen)
    }
}
