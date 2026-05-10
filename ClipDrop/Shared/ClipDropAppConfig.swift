import Foundation

struct ClipDropAppConfig: Equatable {
    let appName: String
    let statusItemTitle: String
    let supportURL: String
    let privacyURL: String
    let repositoryURL: String
    let repositoryDisplayName: String
    let contactEmailAddress: String
    let contactEmailURL: String
    let bundleID: String
    let maxRecentItems: Int

    static let `default` = ClipDropAppConfig(
        appName: "Clipboard Drop",
        statusItemTitle: "Clipboard Drop",
        supportURL: "https://github.com/Feng6611/mac-airdrop-clipboard/issues",
        privacyURL: "https://github.com/Feng6611/mac-airdrop-clipboard/blob/main/PRIVACY.md",
        repositoryURL: "https://github.com/Feng6611/mac-airdrop-clipboard",
        repositoryDisplayName: "Feng6611/mac-airdrop-clipboard",
        contactEmailAddress: "fchen6611@gmail.com",
        contactEmailURL: "mailto:fchen6611@gmail.com",
        bundleID: "dev.kkuk.clipboarddrop",
        maxRecentItems: 10
    )
}
