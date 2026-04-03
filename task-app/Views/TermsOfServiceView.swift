import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Last updated: April 1, 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    section("Acceptance of Terms") {
                        """
                        By downloading, installing, or using DotTasks ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
                        """
                    }

                    section("Description of Service") {
                        """
                        DotTasks is a personal task management and focus timer application. The App provides:

                        \u{2022} Task creation and management
                        \u{2022} Focus timer (Pomodoro-style)
                        \u{2022} Optional iCloud sync (premium)
                        \u{2022} Optional Apple Reminders integration
                        \u{2022} Optional hydration reminders (premium)
                        \u{2022} Home screen widgets (premium)

                        The App is provided "as is" and is intended for personal, non-commercial use.
                        """
                    }

                    section("Subscriptions and Payments") {
                        """
                        The App offers optional premium features through auto-renewable subscriptions and a one-time lifetime purchase, processed entirely by Apple.

                        \u{2022} Payment is charged to your Apple ID account upon confirmation of purchase
                        \u{2022} Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period
                        \u{2022} Your account will be charged for renewal within 24 hours prior to the end of the current period
                        \u{2022} You can manage or cancel subscriptions in your device's Settings > Apple ID > Subscriptions
                        \u{2022} Any unused portion of a free trial period is forfeited when you purchase a subscription
                        \u{2022} Refunds are handled by Apple according to their refund policies
                        """
                    }

                    section("Free Trial") {
                        """
                        The App may offer a 7-day free trial for premium features. During the trial period, you have access to all premium features at no cost. After the trial expires, premium features require an active subscription or lifetime purchase.
                        """
                    }

                    section("User Data and Responsibility") {
                        """
                        You are solely responsible for the data you create within the App. We do not have access to your data and cannot recover lost data. We recommend enabling iCloud Sync for backup purposes.

                        You agree not to use the App for any unlawful purpose or in any way that could damage, disable, or impair the App.
                        """
                    }

                    section("Intellectual Property") {
                        """
                        The App, including its design, code, icons, and content, is the intellectual property of Yunus Celik. You are granted a limited, non-exclusive, non-transferable license to use the App for personal purposes, subject to these Terms and the Apple Licensed Application End User License Agreement (EULA).
                        """
                    }

                    section("Apple's Standard EULA") {
                        """
                        This App is licensed to you under Apple's Standard Licensed Application End User License Agreement (EULA), available at:

                        https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

                        In the event of any conflict between these Terms and Apple's Standard EULA, Apple's Standard EULA shall prevail.
                        """
                    }

                    section("Third-Party Services") {
                        """
                        The App integrates with Apple services (iCloud, Reminders, Notifications, StoreKit). Your use of these services is subject to Apple's own terms of service and privacy policies. We are not responsible for the availability, security, or functionality of Apple's services.
                        """
                    }

                    section("Disclaimer of Warranties") {
                        """
                        The App is provided on an "as is" and "as available" basis without warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, or non-infringement.

                        We do not warrant that the App will be uninterrupted, error-free, or free of harmful components.
                        """
                    }

                    section("Limitation of Liability") {
                        """
                        To the maximum extent permitted by applicable law, in no event shall the developer be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, profits, or revenue, whether incurred directly or indirectly, arising out of your use of or inability to use the App.
                        """
                    }

                    section("Termination") {
                        """
                        We reserve the right to terminate or restrict your access to the App at any time, without notice, for any reason. Upon termination, your right to use the App ceases immediately. Provisions that by their nature should survive termination shall survive.
                        """
                    }

                    section("Changes to These Terms") {
                        """
                        We may update these Terms from time to time. Any changes will be reflected in the App with an updated "Last updated" date. Your continued use of the App after changes constitutes acceptance of the updated Terms.
                        """
                    }

                    section("Governing Law") {
                        """
                        These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which the developer resides, without regard to its conflict of law provisions.
                        """
                    }

                    section("Contact") {
                        """
                        If you have any questions about these Terms, you can contact us at:

                        clkstudiios@gmail.com
                        """
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.black)
            .navigationTitle("Terms of Service")
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
