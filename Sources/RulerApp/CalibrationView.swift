import SwiftUI

struct CalibrationView: View {
    /// Standard credit card long-edge length.
    static let referenceMm: CGFloat = 85.6

    let screenLabel: String
    let initialPointsPerMm: CGFloat
    let onSave: (CGFloat) -> Void
    let onSkip: () -> Void

    @State private var pointsPerMm: CGFloat

    init(
        screenLabel: String,
        initialPointsPerMm: CGFloat,
        onSave: @escaping (CGFloat) -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.screenLabel = screenLabel
        self.initialPointsPerMm = initialPointsPerMm
        self.onSave = onSave
        self.onSkip = onSkip
        _pointsPerMm = State(initialValue: initialPointsPerMm)
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Calibrate \(screenLabel)")
                    .font(.title2.weight(.semibold))
                Text("Hold a credit card flush against the screen and drag the slider until the line matches its long edge (\(String(format: "%.1f", Self.referenceMm)) mm).")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ZStack {
                referenceLine
            }
            .frame(height: 80)

            VStack(spacing: 8) {
                Slider(value: $pointsPerMm, in: 2.0...8.0)
                    .frame(width: 320)
                Text(String(format: "%.3f points / mm  ·  ≈ %.0f DPI", pointsPerMm, pointsPerMm * 25.4))
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button("Skip", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave(pointsPerMm) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(minWidth: 520)
    }

    private var referenceLine: some View {
        let length = Self.referenceMm * pointsPerMm
        return ZStack {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: length, height: 4)
            HStack {
                endcap
                Spacer()
                endcap
            }
            .frame(width: length)
        }
    }

    private var endcap: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 4, height: 28)
    }
}
