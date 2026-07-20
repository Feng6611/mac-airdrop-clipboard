import Foundation
import KikiCommerceCore
import KikiRevenueCat

struct ClipDropAppDefinition {
    let config: ClipDropAppConfig
    let accessConfiguration: KikiAccessConfiguration
    let revenueCatConfiguration: RevenueCatConfiguration
    let settingsAutosaveName: String
    let statusItemAutosaveName: String
    let onboardingCompletionKey: String
    let onboardingWindowAutosaveName: String

    static let live = Self(
        config: .default,
        accessConfiguration: ClipDropRevenueCatConfiguration.accessConfiguration,
        revenueCatConfiguration: ClipDropRevenueCatConfiguration.revenueCatConfiguration,
        settingsAutosaveName: "ClipDrop.SettingsWindow",
        statusItemAutosaveName: "ClipDrop.StatusItem",
        onboardingCompletionKey: "ClipDrop.Onboarding.hasCompleted",
        onboardingWindowAutosaveName: "ClipDrop.OnboardingWindow"
    )
}
