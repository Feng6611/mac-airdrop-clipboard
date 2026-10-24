import Foundation

struct ClipDropAppDefinition {
    let config: ClipDropAppConfig
    let settingsAutosaveName: String
    let statusItemAutosaveName: String
    let onboardingCompletionKey: String
    let onboardingWindowAutosaveName: String

    static let live = Self(
        config: .default,
        settingsAutosaveName: "ClipDrop.SettingsWindow",
        statusItemAutosaveName: "ClipDrop.StatusItem",
        onboardingCompletionKey: "ClipDrop.Onboarding.hasCompleted",
        onboardingWindowAutosaveName: "ClipDrop.OnboardingWindow"
    )
}
