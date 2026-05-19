import SwiftUI

struct CalibrationPromptView: View {
    let screenCount: Int
    let onCalibrate: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Calibrate for accuracy?")
                .font(.title2.weight(.semibold))

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button("Skip — use detected size", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                Button("Calibrate", action: onCalibrate)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 380)
    }

    private var message: String {
        if screenCount > 1 {
            return "We'll walk you through each of your \(screenCount) displays so the ruler matches real-world sizes."
        } else {
            return "Hold a credit card against the screen and align a line — takes about ten seconds, and the ruler will match real-world sizes after."
        }
    }
}
