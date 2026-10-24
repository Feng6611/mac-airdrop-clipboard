import AppKit
import KikiMenuBar

@MainActor
final class ClipDropLifecycleCoordinator {
    private let definition: ClipDropAppDefinition
    private let controller: ClipDropController
    private let reviewRequests: ClipDropReviewRequestCoordinator
    private let router: ClipDropAppRouter
    let shortcutCoordinator: ClipDropHotkeyCoordinator
    let dropHandler: ClipDropDropHandler
    private var menuBarController: KikiMenuBarPopoverController<ClipDropMenuPopoverView>?
    private var didStart = false

    init(
        definition: ClipDropAppDefinition,
        controller: ClipDropController,
        reviewRequests: ClipDropReviewRequestCoordinator,
        router: ClipDropAppRouter
    ) {
        self.definition = definition
        self.controller = controller
        self.reviewRequests = reviewRequests
        self.router = router
        self.shortcutCoordinator = ClipDropHotkeyCoordinator(
            sendClipboard: { [weak router] in
                guard let router else { return }
                Task { await router.sendCurrentClipboard(source: .hotkey) }
            },
            showQRCode: { [weak router] in router?.showQRCodeForCurrentClipboard() }
        )
        self.dropHandler = ClipDropDropHandler { [weak router] payload in
            guard let router else { return }
            _ = await router.send(payload.temporaryRouterPayload, source: .drop)
        }
    }

    func start() {
        guard !didStart else {
            return
        }
        didStart = true

        NSApp.setActivationPolicy(.accessory)
        controller.startClipboardMonitoring()
        shortcutCoordinator.start()
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
                self?.reviewRequests.requestIfEligibleAtNaturalMoment()
            },
            contextMenuItems: { [weak self] in
                guard let self else { return [] }
                return ClipDropContextMenuItems.make(
                    sendClipboard: { [weak self] in
                        guard let self else { return }
                        Task { await self.router.sendCurrentClipboard(source: .contextMenu) }
                    },
                    showQRCode: { [weak self] in self?.router.showQRCodeForCurrentClipboard() },
                    openSettings: { [weak self] in self?.router.openSettings() },
                    quit: { [weak self] in self?.router.quit() }
                )
            }
        ) {
            ClipDropMenuPopoverView(
                config: self.definition.config,
                controller: self.controller,
                actions: ClipDropPopoverActions(
                    sendClipboard: { [weak self] in
                        guard let self else { return }
                        Task { await self.router.sendCurrentClipboard(source: .popover) }
                    },
                    sendHistoryItem: { [weak self] item in
                        guard let self else { return }
                        Task { await self.router.sendHistoryItem(item) }
                    },
                    copyHistoryItem: { [weak self] item in self?.router.copyHistoryItem(item) },
                    clearHistory: { [weak self] in self?.router.clearClipboardHistory() },
                    openSettings: { [weak self] in self?.router.openSettings() },
                    quit: { [weak self] in self?.router.quit() }
                )
            )
        }
        router.showAutomaticOnboardingIfNeeded()
    }

    func stop() {
        guard didStart else {
            return
        }
        didStart = false
        shortcutCoordinator.stop()
        controller.stopClipboardMonitoring()
        controller.cleanupTemporarySendFiles()
        menuBarController = nil
    }
}

@MainActor
enum ClipDropContextMenuItems {
    static func make(
        sendClipboard: @escaping () -> Void,
        showQRCode: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        quit: @escaping () -> Void
    ) -> [KikiMenuItem] {
        [
            .action(title: "Send Clipboard", action: sendClipboard),
            .action(title: "Show QR Code for Clipboard", action: showQRCode),
            .separator,
            .settings(title: "Settings…", action: openSettings),
            .action(title: "Quit", shortcut: .quit, action: quit)
        ]
    }
}
