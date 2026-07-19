import AppKit
import KikiCommerceCore
import KikiMenuBar

@MainActor
final class ClipDropLifecycleCoordinator {
    private let definition: ClipDropAppDefinition
    private let controller: ClipDropController
    private let accessManager: KikiAccessManager
    private let router: ClipDropAppRouter
    private var menuBarController: KikiMenuBarPopoverController<ClipDropMenuPopoverView>?
    private var didStart = false

    init(
        definition: ClipDropAppDefinition,
        controller: ClipDropController,
        accessManager: KikiAccessManager,
        router: ClipDropAppRouter
    ) {
        self.definition = definition
        self.controller = controller
        self.accessManager = accessManager
        self.router = router
    }

    func start() {
        guard !didStart else {
            return
        }
        didStart = true

        NSApp.setActivationPolicy(.accessory)
        controller.startClipboardMonitoring()
        menuBarController = KikiMenuBarPopoverController(
            title: definition.config.statusItemTitle,
            autosaveName: definition.statusItemAutosaveName,
            systemImageName: "paperplane.fill",
            accessibilityDescription: definition.config.appName,
            tooltip: definition.config.appName,
            popoverSize: CGSize(
                width: ClipDropDesignToken.Size.popoverWidth,
                height: ClipDropDesignToken.Size.popoverHeight
            ),
            onWillShow: { [weak self] in
                self?.controller.refreshClipboardHistory()
            }
        ) {
            ClipDropMenuPopoverView(
                config: self.definition.config,
                controller: self.controller,
                accessManager: self.accessManager,
                actions: ClipDropPopoverActions(
                    sendClipboard: { [weak self] in self?.router.sendClipboardViaAirDrop() },
                    sendHistoryItem: { [weak self] item in self?.router.sendHistoryItemViaAirDrop(item) },
                    copyHistoryItem: { [weak self] item in self?.router.copyHistoryItem(item) },
                    clearHistory: { [weak self] in self?.router.clearClipboardHistory() },
                    openSettings: { [weak self] in self?.router.openSettings() },
                    openPaywall: { [weak self] in self?.router.openPaywall() },
                    quit: { [weak self] in self?.router.quit() }
                )
            )
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.router.refreshAccess()
            self.router.showAutomaticOnboardingIfAllowed()
        }
    }

    func stop() {
        guard didStart else {
            return
        }
        didStart = false
        controller.stopClipboardMonitoring()
        menuBarController = nil
    }
}
