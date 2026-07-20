import AppKit
import SwiftUI

@main
struct ClipDropApp: App {
    @NSApplicationDelegateAdaptor(ClipDropAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            let composition = appDelegate.composition
            ClipDropSettingsView(
                config: composition.definition.config,
                settingsCoordinator: composition.settingsCoordinator,
                accessManager: composition.accessManager,
                route: composition.settingsRoute,
                onTriggerOnboarding: composition.router.triggerOnboarding
            )
        }
    }
}

@MainActor
final class ClipDropAppDelegate: NSObject, NSApplicationDelegate {
    let composition = ClipDropAppComposition()

    func applicationDidFinishLaunching(_ notification: Notification) {
        composition.lifecycle.start()

#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let composition = composition
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
