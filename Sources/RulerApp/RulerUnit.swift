import Foundation

enum RulerUnit: String, CaseIterable {
    case mmcm
    case inches
    case both

    var next: RulerUnit {
        let all = Self.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }

    var label: String {
        switch self {
        case .mmcm: return "cm"
        case .inches: return "in"
        case .both: return "cm + in"
        }
    }
}

enum RulerFormat {
    /// Format a length in millimeters for display in the selected unit.
    static func format(mm: CGFloat, unit: RulerUnit) -> String {
        switch unit {
        case .mmcm:
            return String(format: "%.1f mm", mm)
        case .inches:
            return String(format: "%.2f in", mm / 25.4)
        case .both:
            return String(format: "%.1f mm / %.2f in", mm, mm / 25.4)
        }
    }
}
