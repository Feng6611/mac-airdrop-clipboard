import Foundation

struct ClipDropAppConfig: Equatable {
    let appName: String
    let statusItemTitle: String
    let officialURL: String
    let officialDisplayName: String
    let supportURL: String
    let privacyURL: String
    let repositoryURL: String
    let contactEmailAddress: String
    let contactEmailURL: String
    let bundleID: String
    let maxRecentItems: Int

    static let `default` = ClipDropAppConfig(
        appName: "Clipboard Drop",
        statusItemTitle: "Clipboard Drop",
        officialURL: "https://github.com/Feng6611/mac_airdrop_clipboard",
        officialDisplayName: "github.com/Feng6611/mac_airdrop_clipboard",
        supportURL: "https://github.com/Feng6611/mac_airdrop_clipboard/issues",
        privacyURL: "https://github.com/Feng6611/mac_airdrop_clipboard/blob/main/PRIVACY.md",
        repositoryURL: "https://github.com/Feng6611/mac_airdrop_clipboard",
        contactEmailAddress: "fchen6611@gmail.com",
        contactEmailURL: "mailto:fchen6611@gmail.com",
        bundleID: "dev.kkuk.clipboarddrop",
        maxRecentItems: 5
    )
}
