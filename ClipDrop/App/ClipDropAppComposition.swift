import Foundation
import KikiCommerceCore
import KikiOnboarding
import KikiSettings

@MainActor
final class ClipDropAppComposition {
    let definition: ClipDropAppDefinition
    let controller: ClipDropController
    let accessManager: KikiAccessManager
    let settingsRoute: ClipDropSettingsRouteModel
    let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    let onboardingCoordinator: KikiOnboardingCoordinator
    let router: ClipDropAppRouter
    let lifecycle: ClipDropLifecycleCoordinator

    init(
        definition: ClipDropAppDefinition = .live,
        defaults: UserDefaults = .standard,
        commerceClient: (any CommerceClient)? = nil,
        sender: ClipboardSenderService? = nil,
        historyStore: ClipboardHistoryStore? = nil,
        presentAccessVerificationError: (() -> Void)? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.definition = definition
        self.controller = ClipDropController(sender: sender, historyStore: historyStore)

        if let commerceClient {
            self.accessManager = KikiAccessManager(
                configuration: definition.accessConfiguration,
                defaults: defaults,
                commerceClient: commerceClient,
                now: now
            )
        } else {
            self.accessManager = KikiAccessManager(
                configuration: definition.accessConfiguration,
                revenueCatConfiguration: definition.revenueCatConfiguration,
                defaults: defaults,
                now: now
            )
        }

        self.settingsRoute = ClipDropSettingsRouteModel()
        self.settingsCoordinator = KikiSettingsCoordinator(
            tabs: ClipDropSettingsTab.kikiTabs,
            initialTab: .general,
            windowController: KikiSettingsWindowController(
                frameAutosaveName: definition.settingsAutosaveName,
                minimumContentSize: CGSize(
                    width: KikiSettingsDefaults.minimumWindowWidth,
                    height: KikiSettingsDefaults.minimumWindowHeight
                )
            )
        )
        self.onboardingCoordinator = ClipDropOnboardingFlow.makeCoordinator(
            definition: definition,
            accessManager: accessManager,
            completionStore: KikiOnboardingUserDefaultsCompletionStore(defaults: defaults)
        )

        self.router = ClipDropAppRouter(
            controller: controller,
            accessManager: accessManager,
            settingsRoute: settingsRoute,
            settingsCoordinator: settingsCoordinator,
            onboardingCoordinator: onboardingCoordinator,
            presentAccessVerificationError: presentAccessVerificationError
        )
        self.lifecycle = ClipDropLifecycleCoordinator(
            definition: definition,
            controller: controller,
            accessManager: accessManager,
            router: router
        )
    }
}
