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
            // Writes the Settings window to a PNG without Screen Recording access:
            // --clipdrop-debug-snapshot-settings /path/to/file.png
            if let flagIndex = arguments.firstIndex(of: "--clipdrop-debug-snapshot-settings"),
               arguments.indices.contains(flagIndex + 1) {
                let path = arguments[flagIndex + 1]
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    Self.writeSnapshotOfKeySettingsWindow(to: URL(fileURLWithPath: path))
                }
            }
        } else if arguments.contains("--clipdrop-debug-open-onboarding") {
            DispatchQueue.main.async {
                composition.router.triggerOnboarding()
            }
        }
#endif
    }

#if DEBUG
    private static func writeSnapshotOfKeySettingsWindow(to url: URL) {
        let candidates = NSApp.windows.filter { $0.isVisible && $0.contentView != nil && $0.frame.height > 200 }
        guard let window = candidates.first(where: { $0.toolbar != nil }) ?? candidates.first,
              let frameView = window.contentView?.superview ?? window.contentView else {
            return
        }
        guard let bitmap = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) else { return }
        frameView.cacheDisplay(in: frameView.bounds, to: bitmap)
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
    }
#endif

    func applicationWillTerminate(_ notification: Notification) {
        composition.lifecycle.stop()
    }
}
