import Foundation
import Observation

@Observable
final class RulerState {
    var unit: RulerUnit = .mmcm
    var showGrid: Bool = false
    var pointsPerMm: CGFloat = 4.33  // overwritten on window mount / screen change
    /// Cursor location in the ruler view's local coordinate system, or nil when not hovering.
    var cursorLocal: CGPoint? = nil
}
