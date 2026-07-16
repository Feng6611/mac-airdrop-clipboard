import Foundation
import KikiCommerceCore
import KikiSettings
import SwiftUI

@MainActor
final class ClipDropSettingsRouteModel: ObservableObject {
    @Published var isPaywallSheetPresented = false
}

struct ClipDropSettingsView: View {
    let config: ClipDropAppConfig
    let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    @ObservedObject var accessManager: KikiAccessManager
    @ObservedObject var route: ClipDropSettingsRouteModel
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
        .sheet(isPresented: $route.isPaywallSheetPresented) {
            ClipDropPaywallSheetView(
                accessManager: accessManager,
                context: .settings,
                config: config,
                onFinish: { route.isPaywallSheetPresented = false }
            )
        }
    }

    private var generalPane: some View {
        KikiSettingsPane {
            Section("Startup") {
                LaunchAtLogin.Toggle("Launch at Login")
            }

            Section("Send Format") {
                KikiSettingsHelperText(
                    "Clipboard Drop sends text as lightweight files. Rich text styling is not preserved."
                )

                KikiSettingsSegmentedPickerRow(
                    "Text file",
                    selection: $textFileFormat,
                    options: ClipDropTextFileFormat.allCases.map(\.rawValue),
                    systemImage: "doc.text",
                    controlWidth: 180
                ) { rawValue in
                    ClipDropTextFileFormat(rawValue: rawValue)?.title ?? rawValue
                }

                KikiSettingsSegmentedPickerRow(
                    "Link file",
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
            accessStatus: accessStatusPresentation,
            onAccessAction: { route.isPaywallSheetPresented = true },
            links: KikiStandardAboutLinks(
                website: URL(string: config.officialURL),
                feedback: URL(string: config.contactEmailURL),
                github: URL(string: config.repositoryURL)
            ),
            tint: ClipDropDesignToken.Colors.brand
        )
    }

    private var accessStatusPresentation: KikiAccessStatusPresentation {
        switch accessManager.status {
        case .notStarted:
            return KikiAccessStatusPresentation(
                tone: .neutral,
                title: "Pro inactive",
                subtitle: "Start a two-day trial or choose a lifetime unlock.",
                actionTitle: "View options"
            )
        case .trial(.time(let daysRemaining, _)):
            let dayLabel = daysRemaining == 1 ? "day" : "days"
            return KikiAccessStatusPresentation(
                tone: .trial,
                title: "\(daysRemaining) \(dayLabel) left",
                subtitle: "All Pro sending features are available during the trial.",
                actionTitle: "View plans"
            )
        case .trial(.usage):
            return KikiAccessStatusPresentation(
                tone: .trial,
                title: "Trial active",
                subtitle: "All Pro sending features are available during the trial.",
                actionTitle: "View plans"
            )
        case .expired:
            return KikiAccessStatusPresentation(
                tone: .expired,
                title: "Trial ended",
                subtitle: "Unlock Pro to keep sending clipboard items via AirDrop.",
                actionTitle: "Upgrade"
            )
        case .pro(let plan, _):
            return KikiAccessStatusPresentation(
                tone: .lifetime,
                title: plan.title,
                subtitle: plan.billingDetail,
                actionTitle: "View plans"
            )
        }
    }
}
