import KikiCommerceCore
import KikiCommercePresentation
import SwiftUI

struct ClipDropPaywallSheetView: View {
    @ObservedObject var accessManager: KikiAccessManager
    let context: KikiAccessPaywallContext
    let config: ClipDropAppConfig
    let onFinish: () -> Void

    var body: some View {
        KikiAccessPaywallSheet(
            manager: accessManager,
            context: context,
            copy: KikiAccessPaywallCopy(
                title: "Clipboard Drop Pro",
                proSubtitle: "Send copied text and links via AirDrop whenever you need them.",
                trialSubtitle: "Your free trial is active. Unlock Pro for life whenever you're ready.",
                expiredSubtitle: "Your 2-day trial has ended. Unlock Pro for life to keep sending.",
                notStartedSubtitle: "Try Pro free for 2 days. No subscription or automatic charge.",
                features: [
                    "Send copied text and links with AirDrop",
                    "Resend recent clipboard items from the menu bar",
                    "No receiver app, account, or cloud sync"
                ],
                purchaseActionTitle: "Unlock Pro for Life",
                trialActionTitle: "Start Free 2-Day Trial",
                restoreActionTitle: "Restore Purchases"
            ),
            footerLinks: footerLinks,
            tint: ClipDropDesignToken.Colors.brand,
            onFinish: onFinish
        )
    }

    private var footerLinks: [KikiAccessPaywallLink] {
        [
            link(id: "privacy", title: "Privacy", value: config.privacyURL),
            link(id: "support", title: "Support", value: config.supportURL)
        ].compactMap { $0 }
    }

    private func link(id: String, title: String, value: String) -> KikiAccessPaywallLink? {
        guard let url = URL(string: value) else {
            return nil
        }
        return KikiAccessPaywallLink(id: id, title: title, url: url)
    }
}
