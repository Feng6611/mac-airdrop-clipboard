import Foundation
import KikiSettings
import SwiftUI

struct ClipDropSettingsView: View {
    let config: ClipDropAppConfig
    let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    @AppStorage(ClipDropPreferenceKeys.textFileFormat) private var textFileFormat = ClipDropSendPreferences.defaultTextFileFormat.rawValue
    @AppStorage(ClipDropPreferenceKeys.urlSendFormat) private var urlSendFormat = ClipDropSendPreferences.defaultURLSendFormat.rawValue

    var body: some View {
        KikiSettingsCoordinatorView(coordinator: settingsCoordinator) { tab in
            switch tab {
            case .general:
                generalPane
            case .about:
                aboutPane
            }
        }
    }

    private var generalPane: some View {
        KikiSettingsPane {
            Section("Startup") {
                LaunchAtLogin.Toggle("Launch at Login")
            }

            Section("File Formats") {
                KikiSettingsHelperText(
                    "Clipboard Drop sends copied text and links as files. Rich text formatting isn’t preserved."
                )

                KikiSettingsSegmentedPickerRow(
                    "Copied text",
                    selection: $textFileFormat,
                    options: ClipDropTextFileFormat.allCases.map(\.rawValue),
                    systemImage: "doc.text",
                    controlWidth: 180
                ) { rawValue in
                    ClipDropTextFileFormat(rawValue: rawValue)?.title ?? rawValue
                }

                KikiSettingsSegmentedPickerRow(
                    "Copied link",
                    selection: $urlSendFormat,
                    options: ClipDropURLSendFormat.allCases.map(\.rawValue),
                    systemImage: "link",
                    controlWidth: 180
                ) { rawValue in
                    ClipDropURLSendFormat(rawValue: rawValue)?.title ?? rawValue
                }
            }
        }
    }

    private var aboutPane: some View {
        KikiStandardAboutPane(
            metadata: .bundle(),
            tint: ClipDropDesignToken.Colors.brand
        )
        .additionalLinks {
            KikiSettingsLinkRow(
                title: "Star on GitHub",
                value: "Feng6611/mac-airdrop-clipboard",
                urlString: config.repositoryURL,
                systemImage: "star",
                action: nil
            )
            KikiSettingsLinkRow(
                title: "Follow on GitHub",
                value: "Feng6611",
                urlString: config.authorURL,
                systemImage: "person.crop.circle",
                action: nil
            )
            KikiSettingsLinkRow(
                title: "Rate Clipboard Drop",
                value: "App Store",
                urlString: config.appStoreReviewURL,
                systemImage: "star.bubble",
                action: nil
            )
            KikiSettingsLinkRow(
                title: "Command Reopen",
                value: "App Store",
                urlString: config.commandReopenURL,
                systemImage: "arrow.uturn.backward.circle",
                action: nil
            )
            KikiSettingsLinkRow(
                title: "Privacy",
                value: "clipboarddrop.kkuk.dev",
                urlString: config.privacyURL,
                systemImage: "lock.shield",
                action: nil
            )
            KikiSettingsLinkRow(
                title: "Support",
                value: "clipboarddrop.kkuk.dev",
                urlString: config.supportURL,
                systemImage: "lifepreserver",
                action: nil
            )
        }
    }
}
