import AppKit
import KikiMenuBar
import KikiSettings
import SwiftUI

@main
struct ClipDropApp: App {
    @NSApplicationDelegateAdaptor(ClipDropAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            ClipDropSettingsView(
                config: appDelegate.config,
                controller: appDelegate.controller,
                accessStore: appDelegate.accessStore
            )
        }
    }
}

@MainActor
final class ClipDropAppDelegate: NSObject, NSApplicationDelegate {
    let config = ClipDropAppConfig.default
    let controller = ClipDropController()
    let accessStore = ClipDropAccessStore()

    private let settingsWindowController = KikiSettingsWindowController(
        frameAutosaveName: "ClipDrop.SettingsWindow",
        minimumContentSize: CGSize(
            width: KikiSettingsDefaults.minimumWindowWidth,
            height: KikiSettingsDefaults.minimumWindowHeight
        ),
        windowTitle: "Settings"
    )
    private lazy var settingsOpener = KikiSettingsOpener(windowController: settingsWindowController)
    private var statusItemController: KikiMenuBarPopoverController<ClipDropMenuPopoverView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.startClipboardMonitoring()

        statusItemController = KikiMenuBarPopoverController(
            title: config.statusItemTitle,
            autosaveName: "ClipDrop.StatusItem",
            systemImageName: "paperplane.fill",
            accessibilityDescription: config.appName,
            tooltip: config.appName,
            popoverSize: CGSize(width: 420, height: 500),
            onWillShow: { [weak self] in
                self?.controller.refreshClipboardHistory()
            }
        ) {
            ClipDropMenuPopoverView(
                config: self.config,
                controller: self.controller,
                accessStore: self.accessStore,
                actions: ClipDropPopoverActions(
                    sendClipboard: { [weak self] in self?.controller.sendClipboardViaAirDrop() },
                    sendHistoryItem: { [weak self] item in self?.controller.sendHistoryItemViaAirDrop(item) },
                    copyHistoryItem: { [weak self] item in self?.controller.copyHistoryItem(item) },
                    clearRecentItems: { [weak self] in self?.controller.clearRecentItems() },
                    openSettings: { [weak self] in self?.openSettings() },
                    quit: { NSApp.terminate(nil) }
                )
            )
        }
    }

    private func openSettings() {
        settingsOpener.open()
    }
}
