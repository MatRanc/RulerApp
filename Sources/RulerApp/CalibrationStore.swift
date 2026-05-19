import AppKit
import CoreGraphics
import Foundation

enum CalibrationStore {
    private static let prefix = "ruler.calibration."

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
}
