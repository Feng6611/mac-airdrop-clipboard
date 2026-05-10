import KikiSettings
import SwiftUI

struct ClipDropSettingsView: View {
    let config: ClipDropAppConfig
    @StateObject private var navigation = KikiSettingsNavigationModel<ClipDropSettingsTab>(selectedTab: .general)
    @AppStorage(ClipDropPreferenceKeys.textFileFormat) private var textFileFormat = ClipDropSendPreferences.defaultTextFileFormat.rawValue
    @AppStorage(ClipDropPreferenceKeys.urlSendFormat) private var urlSendFormat = ClipDropSendPreferences.defaultURLSendFormat.rawValue

    var body: some View {
        KikiSettingsShell(
            selection: $navigation.selectedTab,
            tabs: ClipDropSettingsTab.kikiTabs
        ) { tab in
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

            Section("Send Format") {
                Picker("Text", selection: $textFileFormat) {
                    ForEach(ClipDropTextFileFormat.allCases) { format in
                        Text(format.title).tag(format.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Picker("URL", selection: $urlSendFormat) {
                    ForEach(ClipDropURLSendFormat.allCases) { format in
                        Text(format.title).tag(format.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var aboutPane: some View {
        KikiAboutPane(
            appName: config.appName,
            versionText: versionText
        ) {
            EmptyView()
        } links: {
            KikiSettingsCopyRow(
                title: "Email",
                value: config.contactEmailAddress,
                systemImage: "envelope"
            )
            KikiSettingsLinkRow(
                title: "GitHub",
                value: config.repositoryDisplayName,
                urlString: config.repositoryURL,
                systemImage: "chevron.left.forwardslash.chevron.right"
            )
        }
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return ClipDropController.versionSummary(version: version, build: build)
    }
}
