import AppIntents
import AppKit
import Foundation

enum ClipDropIntentPayloadMapper {
    static func textPayload(_ text: String) -> ClipDropPayload {
        .text(text)
    }
}

@available(macOS 13.0, *)
struct SendTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Text"
    static var description = IntentDescription("Send text with Clipboard Drop.")
    static var openAppWhenRun = true

    @Parameter(title: "Text", description: "The text to send.")
    var text: String

    @Parameter(title: "Edit before sending", default: false)
    var editBeforeSending: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Send \(\.$text)") {
            \.$editBeforeSending
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let router = (NSApp.delegate as? ClipDropAppDelegate)?.composition.router else {
            return .result()
        }
        _ = await router.sendTextFromIntent(text, editBeforeSending: editBeforeSending)
        return .result()
    }
}

@available(macOS 13.0, *)
struct SendClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Clipboard"
    static var description = IntentDescription("Send the current clipboard with Clipboard Drop.")
    static var openAppWhenRun = true

    static var parameterSummary: some ParameterSummary {
        Summary("Send the current clipboard")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let router = (NSApp.delegate as? ClipDropAppDelegate)?.composition.router else {
            return .result()
        }
        _ = await router.sendCurrentClipboard(source: .intent)
        return .result()
    }
}

@available(macOS 13.0, *)
struct ShowQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Show QR Code"
    static var description = IntentDescription("Show a QR code for text with Clipboard Drop.")
    static var openAppWhenRun = true

    @Parameter(title: "Text", description: "The text to encode as a QR code.")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Show a QR code for \(\.$text)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let router = (NSApp.delegate as? ClipDropAppDelegate)?.composition.router else {
            return .result()
        }
        router.showQRCode(for: ClipDropIntentPayloadMapper.textPayload(text))
        return .result()
    }
}

@available(macOS 13.0, *)
struct ClipDropAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendClipboardIntent(),
            phrases: ["Send clipboard with \(.applicationName)"],
            shortTitle: "Send Clipboard",
            systemImageName: "paperplane"
        )
        AppShortcut(
            intent: SendTextIntent(),
            phrases: ["Send text with \(.applicationName)"],
            shortTitle: "Send Text",
            systemImageName: "text.page"
        )
        AppShortcut(
            intent: ShowQRCodeIntent(),
            phrases: ["Show a QR code with \(.applicationName)"],
            shortTitle: "Show QR Code",
            systemImageName: "qrcode"
        )
    }
}
