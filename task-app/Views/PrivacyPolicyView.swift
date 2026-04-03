import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Last updated: April 1, 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    section("Overview") {
                        "DotTasks (\"the App\") is designed with privacy as a core principle. We do not collect, store, or share your personal data with any third parties. Your data stays on your device and, if you choose, in your private iCloud account."
                    }

                    section("Data We Do Not Collect") {
                        """
                        We do not collect:

                        \u{2022} Personal information (name, email, phone number)
                        \u{2022} Usage analytics or tracking data
                        \u{2022} Advertising identifiers
                        \u{2022} Location data
                        \u{2022} Device fingerprints
                        \u{2022} Crash reports or diagnostics

                        The App does not contain any third-party analytics, advertising, or tracking SDKs.
                        """
                    }

                    section("Data Stored on Your Device") {
                        """
                        All task data, timer settings, hydration preferences, and app settings are stored locally on your device using Apple's SwiftData framework. This data never leaves your device unless you explicitly enable iCloud Sync.
                        """
                    }

                    section("iCloud Sync") {
                        """
                        If you enable iCloud Sync (a premium feature), your task data is synced through Apple's CloudKit service to your private iCloud database. This data is:

                        \u{2022} Stored in your personal iCloud account
                        \u{2022} Encrypted in transit and at rest by Apple
                        \u{2022} Not accessible to us or any third party
                        \u{2022} Subject to Apple's iCloud Terms of Service and Privacy Policy

                        You can disable iCloud Sync at any time in the App's settings. Disabling sync does not delete your local data.
                        """
                    }

                    section("Apple Reminders Integration") {
                        """
                        The App offers optional integration with Apple Reminders using the EventKit framework. When enabled:

                        \u{2022} You can manually add individual tasks to Apple Reminders
                        \u{2022} Completion status can be synced to the linked reminder
                        \u{2022} The App only accesses reminders that it has created
                        \u{2022} No existing reminders are read, imported, or modified

                        This feature requires your explicit permission. You can revoke access at any time in your device's Settings.
                        """
                    }

                    section("Notifications") {
                        """
                        The App may send local notifications for hydration reminders. These notifications are:

                        \u{2022} Scheduled entirely on your device
                        \u{2022} Not sent through any external server
                        \u{2022} Only active when you enable the feature and grant permission

                        No push notification tokens are collected or transmitted.
                        """
                    }

                    section("Subscriptions and Purchases") {
                        """
                        Subscriptions and purchases are processed entirely by Apple through the App Store. We do not have access to your payment information, Apple ID, or transaction details beyond what Apple provides through StoreKit for verifying your subscription status on-device.
                        """
                    }

                    section("Children's Privacy") {
                        """
                        The App does not knowingly collect any personal information from children. Since the App does not collect any data from any user, it is safe for use by people of all ages.
                        """
                    }

                    section("Changes to This Policy") {
                        """
                        We may update this Privacy Policy from time to time. Any changes will be reflected in the App with an updated "Last updated" date. Your continued use of the App after changes constitutes acceptance of the updated policy.
                        """
                    }

                    section("Contact") {
                        """
                        If you have any questions about this Privacy Policy, you can contact us at:

                        clkstudiios@gmail.com
                        """
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationBackground(Color.black)
    }

    private func section(_ title: String, content: () -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(content())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
}
