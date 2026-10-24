import AppKit
import KikiOnboarding
import KikiSettings

@MainActor
final class ClipDropAppRouter {
    private let controller: ClipDropController
    private let reviewRequests: ClipDropReviewRequestCoordinator
    private let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    private let onboardingCoordinator: KikiOnboardingCoordinator
    private let quitApplication: () -> Void

    init(
        controller: ClipDropController,
        reviewRequests: ClipDropReviewRequestCoordinator,
        settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>,
        onboardingCoordinator: KikiOnboardingCoordinator,
        quitApplication: (() -> Void)? = nil
    ) {
        self.controller = controller
        self.reviewRequests = reviewRequests
        self.settingsCoordinator = settingsCoordinator
        self.onboardingCoordinator = onboardingCoordinator
        self.quitApplication = quitApplication ?? { NSApp.terminate(nil) }
    }

    func send(_ payload: ClipDropPayload, source: ClipDropSendSource) async -> ClipboardSendOutcome {
        let outcome = await controller.send(payload)
        if case .success = outcome {
            reviewRequests.recordSuccessfulSend()
        }
        return outcome
    }

    func sendCurrentClipboard(source: ClipDropSendSource) async -> ClipboardSendOutcome {
        controller.refreshClipboardHistory()
        guard let item = controller.currentClipboardItem else {
            controller.reportMissingClipboard()
            return .failure(.emptyClipboard)
        }
        return await send(Self.payload(for: item), source: source)
    }

    func sendHistoryItem(_ item: ClipboardHistoryItem) async -> ClipboardSendOutcome {
        await send(Self.payload(for: item), source: .history)
    }

    func copyHistoryItem(_ item: ClipboardHistoryItem) {
        controller.copyHistoryItem(item)
    }

    func clearClipboardHistory() {
        controller.clearClipboardHistory()
    }

    func openSettings() {
        settingsCoordinator.open()
    }

    @discardableResult
    func showAutomaticOnboardingIfNeeded() -> Bool {
        guard onboardingCoordinator.isCompleted == false else { return false }
        onboardingCoordinator.start()
        return true
    }

    func triggerOnboarding() {
        onboardingCoordinator.resetCompletion()
        onboardingCoordinator.start()
    }

    func quit() {
        quitApplication()
    }

    private static func payload(for item: ClipboardHistoryItem) -> ClipDropPayload {
        if item.contentType == .link,
           let url = ClipboardContentType.normalizedHTTPURL(from: item.text) {
            return .url(url)
        }
        return .text(item.text)
    }
}
