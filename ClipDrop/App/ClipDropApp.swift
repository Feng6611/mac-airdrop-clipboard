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
                route: composition.settingsRoute
            )
        }
    }
}

@MainActor
final class ClipDropAppDelegate: NSObject, NSApplicationDelegate {
    let composition = ClipDropAppComposition()

    func applicationDidFinishLaunching(_ notification: Notification) {
        composition.lifecycle.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        composition.lifecycle.stop()
    }
}
