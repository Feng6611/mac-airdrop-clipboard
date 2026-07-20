import AppKit
import KikiCommerceCore
import KikiOnboarding
import KikiSettings

@MainActor
final class ClipDropAppRouter {
    private let controller: ClipDropController
    private let accessManager: KikiAccessManager
    private let settingsRoute: ClipDropSettingsRouteModel
    private let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    private let onboardingCoordinator: KikiOnboardingCoordinator
    private let quitApplication: () -> Void
    private let presentAccessVerificationError: () -> Void
    private var accessRefreshTask: Task<Void, Never>?
    private var pendingProAction: (() -> Void)?

    init(
        controller: ClipDropController,
        accessManager: KikiAccessManager,
        settingsRoute: ClipDropSettingsRouteModel,
        settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>,
        onboardingCoordinator: KikiOnboardingCoordinator,
        quitApplication: (() -> Void)? = nil,
        presentAccessVerificationError: (() -> Void)? = nil
    ) {
        self.controller = controller
        self.accessManager = accessManager
        self.settingsRoute = settingsRoute
        self.settingsCoordinator = settingsCoordinator
        self.onboardingCoordinator = onboardingCoordinator
        self.quitApplication = quitApplication ?? { NSApp.terminate(nil) }
        self.presentAccessVerificationError = presentAccessVerificationError ?? Self.showAccessVerificationError
    }

    func sendClipboardViaAirDrop() {
        controller.refreshClipboardHistory()
        guard let currentItem = controller.currentClipboardItem else {
            controller.reportMissingClipboard()
            return
        }

        performProAction {
            self.controller.sendHistoryItemViaAirDrop(currentItem)
        }
    }

    func sendHistoryItemViaAirDrop(_ item: ClipboardHistoryItem) {
        performProAction {
            self.controller.sendHistoryItemViaAirDrop(item)
        }
    }

    func copyHistoryItem(_ item: ClipboardHistoryItem) {
        controller.copyHistoryItem(item)
    }

    func clearClipboardHistory() {
        pendingProAction = nil
        controller.clearClipboardHistory()
    }

    func openSettings() {
        settingsCoordinator.open()
    }

    func openPaywall() {
        settingsCoordinator.select(.about)
        settingsRoute.isPaywallSheetPresented = true
        settingsCoordinator.open()
    }

    @discardableResult
    func showAutomaticOnboardingIfAllowed() -> Bool {
        guard accessManager.readiness.allowsAutomaticPresentation,
              accessManager.status.isPro == false,
              onboardingCoordinator.isCompleted == false,
              settingsRoute.isPaywallSheetPresented == false else {
            return false
        }

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

    func refreshAccess() async {
        if let accessRefreshTask {
            await accessRefreshTask.value
            return
        }

        if accessManager.readiness == .ready {
            finishAccessRefresh()
            return
        }

        let accessManager = accessManager
        let task = Task { @MainActor [weak self] in
            await accessManager.refresh()
            self?.finishAccessRefresh()
        }
        accessRefreshTask = task
        await task.value
    }

    private func performProAction(_ action: @escaping () -> Void) {
        if accessManager.status.isActive {
            action()
            return
        }

        if accessManager.readiness == .ready {
            openPaywall()
            return
        }

        pendingProAction = action
        Task { @MainActor [weak self] in
            await self?.refreshAccess()
        }
    }

    private func finishAccessRefresh() {
        accessRefreshTask = nil
        guard let action = pendingProAction else {
            return
        }
        pendingProAction = nil

        if accessManager.status.isActive {
            action()
        } else if accessManager.readiness == .ready {
            openPaywall()
        } else {
            presentAccessVerificationError()
        }
    }

    private static func showAccessVerificationError() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t Verify Pro Access"
        alert.informativeText = "Check your internet connection and try again. Your purchase status has not been changed."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
