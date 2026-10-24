import Foundation

struct ClipDropAppConfig: Equatable {
    let appName: String
    let statusItemTitle: String
    let repositoryURL: String
    let authorURL: String
    let appStoreReviewURL: String
    let commandReopenURL: String
    let privacyURL: String
    let supportURL: String
    let bundleID: String
    let maxRecentItems: Int

    static let `default` = ClipDropAppConfig(
        appName: "Clipboard Drop",
        statusItemTitle: "Clipboard Drop",
        repositoryURL: "https://github.com/Feng6611/mac-airdrop-clipboard",
        authorURL: "https://github.com/Feng6611",
        appStoreReviewURL: "macappstore://apps.apple.com/app/id6768068044?action=write-review",
        commandReopenURL: "https://apps.apple.com/app/id6757333924",
        privacyURL: "https://clipboarddrop.kkuk.dev/privacy",
        supportURL: "https://clipboarddrop.kkuk.dev/support",
        bundleID: "dev.kkuk.clipboarddrop",
        maxRecentItems: 10
    )
}
