import SwiftUI

struct CalibrationView: View {
    /// Standard credit card long-edge length.
    static let referenceMm: CGFloat = 85.6

    let screenLabel: String
    let initialPointsPerMm: CGFloat
    let hasSavedCalibration: Bool
    let onSave: (CGFloat) -> Void
    let onSkip: () -> Void
    let onReset: () -> Void

    @State private var pointsPerMm: CGFloat
    @State private var showDetectedInfo = false

    init(
        screenLabel: String,
        initialPointsPerMm: CGFloat,
        hasSavedCalibration: Bool,
        onSave: @escaping (CGFloat) -> Void,
        onSkip: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.screenLabel = screenLabel
        self.initialPointsPerMm = initialPointsPerMm
        self.hasSavedCalibration = hasSavedCalibration
        self.onSave = onSave
        self.onSkip = onSkip
        self.onReset = onReset
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

            HStack(spacing: 6) {
                Button("Use detected size", action: onReset)
                    .disabled(!hasSavedCalibration)
                    .help(hasSavedCalibration
                          ? "Discard the saved calibration and fall back to what macOS reports for this display."
                          : "Already using the detected size — there's no saved calibration to clear.")
                Button {
                    showDetectedInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                .help("How is the detected size determined?")
                .popover(isPresented: $showDetectedInfo, arrowEdge: .bottom) {
                    detectedSizeInfo
                }

                Spacer()
                Button("Skip", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave(pointsPerMm) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(minWidth: 760)
    }

    private var detectedSizeInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How the detected size works")
                .font(.headline)
            Text("Ruler App asks macOS for this display's physical width (in millimeters) via the system API, then divides by the screen's resolution in points to get a points-per-millimeter value.")
            Text("This is usually accurate on built-in Apple displays. External monitors often report the wrong physical size — sometimes off by a centimeter or more — which is why manual calibration exists.")
                .foregroundColor(.secondary)
        }
        .font(.callout)
        .frame(width: 340)
        .padding(16)
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
