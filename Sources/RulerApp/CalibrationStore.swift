import AppKit
import CoreGraphics
import Foundation

enum CalibrationStore {
    private static let prefix = "ruler.calibration."
    private static let knownDisplaysKey = "ruler.knownDisplays"

    static func uuid(for screen: NSScreen) -> String? {
        guard let displayID = DisplayMetrics.displayID(for: screen) else { return nil }
        guard let uuidRef = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }
        return CFUUIDCreateString(nil, uuidRef) as String?
    }

    static func pointsPerMm(for screen: NSScreen) -> CGFloat? {
        guard let id = uuid(for: screen) else { return nil }
        let v = UserDefaults.standard.double(forKey: prefix + id)
        return v > 0 ? CGFloat(v) : nil
    }

    static func save(pointsPerMm value: CGFloat, for screen: NSScreen) {
        guard let id = uuid(for: screen) else { return }
        UserDefaults.standard.set(Double(value), forKey: prefix + id)
    }

    static func clear(for screen: NSScreen) {
        guard let id = uuid(for: screen) else { return }
        UserDefaults.standard.removeObject(forKey: prefix + id)
    }

    // MARK: - Known displays

    /// Whether we've already offered calibration for this display (calibrated *or* skipped).
    /// Drives "ask only on first run or when a new display appears" — a skipped display
    /// stays known so we don't re-prompt on every launch.
    ///
    /// A display whose UUID can't be resolved is treated as known: we can't persist
    /// anything for it, so prompting would only nag.
    static func isKnown(_ screen: NSScreen) -> Bool {
        guard let id = uuid(for: screen) else { return true }
        return knownDisplayIDs().contains(id)
    }

    static func markKnown(_ screen: NSScreen) {
        guard let id = uuid(for: screen) else { return }
        var ids = knownDisplayIDs()
        guard ids.insert(id).inserted else { return }
        UserDefaults.standard.set(Array(ids), forKey: knownDisplaysKey)
    }

    private static func knownDisplayIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: knownDisplaysKey) ?? [])
    }
}
