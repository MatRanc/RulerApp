import AppKit
import SwiftUI

struct AboutView: View {
    /// App Store numeric ID, used to deep-link to the review page.
    private static let appStoreID = "6771221433"
    /// Address feedback is sent to.
    private static let feedbackEmail = "matranc03+ruler@gmail.com"

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "RulerApp"
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 10) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 72, height: 72)
            }

            Text(appName)
                .font(.title2.weight(.semibold))

            Text(version)
                .font(.callout)
                .foregroundColor(.secondary)

            Text("Made in 🇨🇦 with ❤️")
                .font(.callout)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Rate App", action: rateApp)
                Button("Send Feedback", action: sendFeedback)
            }
            .padding(.top, 6)
        }
        .padding(24)
        .frame(width: 300)
    }

    private func rateApp() {
        let urlString = "macappstore://apps.apple.com/app/id\(Self.appStoreID)?action=write-review"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func sendFeedback() {
        let subject = "\(appName) Feedback"
        let allowed = CharacterSet.urlQueryAllowed
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? subject
        if let url = URL(string: "mailto:\(Self.feedbackEmail)?subject=\(encodedSubject)") {
            NSWorkspace.shared.open(url)
        }
    }
}
