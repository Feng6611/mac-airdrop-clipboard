import AppKit
import SwiftUI

@main
struct ClipDropApp: App {
    @NSApplicationDelegateAdaptor(ClipDropAppDelegate.self) private var appDelegate

    init() {
        ClipDropAppShortcutsProvider.updateAppShortcutParameters()
    }

    var body: some Scene {
        Settings {
            let composition = appDelegate.composition
            ClipDropSettingsView(
                config: composition.definition.config,
                settingsCoordinator: composition.settingsCoordinator,
                shortcutCoordinator: composition.lifecycle.shortcutCoordinator
            )
        }
    }
}

@MainActor
final class ClipDropAppDelegate: NSObject, NSApplicationDelegate {
    let composition = ClipDropAppComposition()
    private var servicesProvider: ClipDropServicesProvider?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let router = composition.router
        let servicesProvider = ClipDropServicesProvider { payload in
            guard let routerPayload = payload.routerPayload else { return }
            Task { await router.send(routerPayload, source: .services) }
        }
        self.servicesProvider = servicesProvider
        NSApp.servicesProvider = servicesProvider
        composition.lifecycle.start()

#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let composition = composition
        if arguments.contains("--clipdrop-debug-settings-light") {
            NSApp.appearance = NSAppearance(named: .aqua)
        } else if arguments.contains("--clipdrop-debug-settings-dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        if arguments.contains("--clipdrop-debug-open-settings") {
            DispatchQueue.main.async {
                composition.router.openSettings()
            }
        } else if arguments.contains("--clipdrop-debug-open-onboarding") {
            DispatchQueue.main.async {
                composition.router.triggerOnboarding()
            }
        }
#endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        composition.lifecycle.stop()
    }
}
