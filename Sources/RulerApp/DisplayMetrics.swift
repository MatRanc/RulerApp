import AppKit
import CoreGraphics

enum DisplayMetrics {
    static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return screen.deviceDescription[key] as? CGDirectDisplayID
    }

    /// Points per millimeter derived from the OS-reported physical display size.
    /// May be inaccurate on external displays — user calibration can override this.
    static func pointsPerMillimeter(for screen: NSScreen) -> CGFloat {
        guard let id = displayID(for: screen) else { return fallbackPointsPerMm }
        let physical = CGDisplayScreenSize(id) // millimeters
        guard physical.width > 0 else { return fallbackPointsPerMm }
        return screen.frame.width / physical.width
    }

    /// Calibrated value if present, otherwise the OS-derived value.
    static func effectivePointsPerMm(for screen: NSScreen) -> CGFloat {
        CalibrationStore.pointsPerMm(for: screen) ?? pointsPerMillimeter(for: screen)
    }

    /// Roughly a typical 110 DPI display: ~4.33 points per mm.
    private static let fallbackPointsPerMm: CGFloat = 4.33
}
