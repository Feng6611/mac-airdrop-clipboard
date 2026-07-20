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
    let onTriggerOnboarding: () -> Void
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

#if DEBUG
            debugTestingSection
#endif
        }
    }

#if DEBUG
    private var debugTestingSection: some View {
        Section {
            KikiSettingsDebugPreviewRow(
                "Paid access",
                selection: debugModeBinding,
                options: KikiAccessDebugMode.allCases,
                isOverrideActive: accessManager.debugProAccessOverride != nil,
                optionTitle: { $0.displayName }
            )

            KikiSettingsValueRow("Test flows", systemImage: "play.rectangle") {
                Button("Onboarding", action: onTriggerOnboarding)
                Button("Paywall") {
                    route.isPaywallSheetPresented = true
                }
            }
        } header: {
            Text("Developer Testing")
        } footer: {
            KikiSettingsHelperText("Debug only. Live clears the paid-access override.")
        }
    }

    private var debugModeBinding: Binding<KikiAccessDebugMode> {
        Binding(
            get: { accessManager.debugProAccessOverride ?? .live },
            set: { mode in
                if mode == .live {
                    accessManager.clearDebugProAccessOverride()
                } else {
                    accessManager.setDebugProAccessOverride(mode)
                }
            }
        )
    }
#endif

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
            tint: ClipDropDesignToken.Colors.proAccent
        )
    }

    private var accessStatusPresentation: KikiAccessStatusPresentation {
        switch accessManager.status {
        case .notStarted:
            return KikiAccessStatusPresentation(
                tone: .neutral,
                title: "Not Pro",
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
