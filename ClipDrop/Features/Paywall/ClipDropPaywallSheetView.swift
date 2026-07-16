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
                title: "Unlock Clipboard Drop Pro",
                proSubtitle: "Send clipboard text and links via AirDrop whenever you need them.",
                trialSubtitle: "Try every Pro feature for two days on this Mac.",
                expiredSubtitle: "Your two-day trial has ended. Unlock Pro to keep sending.",
                notStartedSubtitle: "Send clipboard text and links via AirDrop from your menu bar.",
                features: [
                    "Send current clipboard via AirDrop",
                    "Send any recent clipboard item again",
                    "Keep your clipboard workflow local and private"
                ],
                purchaseActionTitle: "Unlock Pro",
                trialActionTitle: "Start 2-day trial",
                restoreActionTitle: "Restore purchases"
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
