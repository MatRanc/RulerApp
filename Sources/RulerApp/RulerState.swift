import Foundation
import Observation

enum RulerGridMode {
    case off
    case major
    case majorAndMinor

    var next: RulerGridMode {
        switch self {
        case .off: return .major
        case .major: return .majorAndMinor
        case .majorAndMinor: return .off
        }
    }

    var showsMajor: Bool { self != .off }
    var showsMinor: Bool { self == .majorAndMinor }
}

@Observable
final class RulerState {
    var unit: RulerUnit = .mmcm
    var gridMode: RulerGridMode = .majorAndMinor
    var pointsPerMm: CGFloat = 4.33  // overwritten on window mount / screen change
    /// Cursor location in the ruler view's local coordinate system, or nil when not hovering.
    var cursorLocal: CGPoint? = nil
}
