import Foundation
import KikiOnboarding
import KikiSettings

@MainActor
final class ClipDropAppComposition {
    let definition: ClipDropAppDefinition
    let controller: ClipDropController
    let reviewRequests: ClipDropReviewRequestCoordinator
    let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    let onboardingCoordinator: KikiOnboardingCoordinator
    let router: ClipDropAppRouter
    let lifecycle: ClipDropLifecycleCoordinator

    init(
        definition: ClipDropAppDefinition = .live,
        defaults: UserDefaults = .standard,
        sender: ClipboardSenderService? = nil,
        historyStore: ClipboardHistoryStore? = nil,
        reviewRequests: ClipDropReviewRequestCoordinator? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        let reviewRequests = reviewRequests ?? ClipDropReviewRequestCoordinator(defaults: defaults, now: now)
        self.definition = definition
        self.controller = ClipDropController(sender: sender, historyStore: historyStore)
        self.reviewRequests = reviewRequests
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
            completionStore: KikiOnboardingUserDefaultsCompletionStore(defaults: defaults)
        )

        self.router = ClipDropAppRouter(
            controller: controller,
            reviewRequests: reviewRequests,
            settingsCoordinator: settingsCoordinator,
            onboardingCoordinator: onboardingCoordinator
        )
        self.lifecycle = ClipDropLifecycleCoordinator(
            definition: definition,
            controller: controller,
            reviewRequests: reviewRequests,
            router: router
        )
    }
}
