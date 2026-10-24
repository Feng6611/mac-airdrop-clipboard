import AppKit
import SwiftUI
import KikiOnboarding
import KikiSettings

@MainActor
final class ClipDropAppRouter {
    private let controller: ClipDropController
    private let reviewRequests: ClipDropReviewRequestCoordinator
    private let settingsCoordinator: KikiSettingsCoordinator<ClipDropSettingsTab>
    private let onboardingCoordinator: KikiOnboardingCoordinator
    private let quitApplication: () -> Void
    private var composePanels: [UUID: NSPanel] = [:]
    private var qrPanels: [UUID: NSPanel] = [:]
    private var panelCloseObservers: [UUID: ClipDropPanelCloseObserver] = [:]

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
        await send(payload, source: source, didEditContent: false)
    }

    private func send(
        _ payload: ClipDropPayload,
        source: ClipDropSendSource,
        didEditContent: Bool
    ) async -> ClipboardSendOutcome {
        if !didEditContent,
           ClipDropSendPreferences.current.editBeforeSending,
           let text = Self.editableText(for: payload) {
            guard let editedText = await presentComposeWindow(with: text) else { return .cancelled }
            return await send(Self.payload(fromEditedText: editedText), source: source, didEditContent: true)
        }
        return await performSend(payload, source: source)
    }

    private func performSend(_ payload: ClipDropPayload, source: ClipDropSendSource) async -> ClipboardSendOutcome {
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
        await sendHistoryItem(item, source: .history)
    }

    func sendHistoryItem(_ item: ClipboardHistoryItem, source: ClipDropSendSource) async -> ClipboardSendOutcome {
        await send(Self.payload(for: item), source: source)
    }

    func editAndSendHistoryItem(_ item: ClipboardHistoryItem) async -> ClipboardSendOutcome {
        guard let text = Self.editableText(for: Self.payload(for: item)) else {
            return .failure(.emptyClipboard)
        }
        guard let editedText = await presentComposeWindow(with: text) else { return .cancelled }
        return await send(Self.payload(fromEditedText: editedText), source: .history, didEditContent: true)
    }

    func sendMergedItems(_ items: [ClipboardHistoryItem], source: ClipDropSendSource = .popover) async -> ClipboardSendOutcome {
        guard let text = ClipboardContentType.mergedText(from: items) else {
            return .failure(.emptyClipboard)
        }
        return await send(.text(text), source: source)
    }

    func showQRCode(for payload: ClipDropPayload) {
        guard let content = Self.qrText(for: payload) else { return }
        let identifier = UUID()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 430),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "QR Code"
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: ClipDropQRCodeView(content: content) { [weak self] in
            self?.copyTextToPasteboard(content)
        })
        let closeObserver = ClipDropPanelCloseObserver { [weak self] in
            self?.qrPanels.removeValue(forKey: identifier)
            self?.panelCloseObservers.removeValue(forKey: identifier)
        }
        panel.delegate = closeObserver
        qrPanels[identifier] = panel
        panelCloseObservers[identifier] = closeObserver
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showQRCode(for item: ClipboardHistoryItem) {
        showQRCode(for: Self.payload(for: item))
    }

    func copyHistoryItem(_ item: ClipboardHistoryItem) {
        controller.copyHistoryItem(item)
    }

    func copyTextToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
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

    private func presentComposeWindow(with text: String) async -> String? {
        await withCheckedContinuation { continuation in
            let identifier = UUID()
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .resizable, .utilityWindow],
                backing: .buffered,
                defer: false
            )
            panel.title = "Edit and Send"
            panel.isReleasedWhenClosed = false

            var didFinish = false
            let finish: (String?) -> Void = { [weak self] result in
                guard !didFinish else { return }
                didFinish = true
                self?.composePanels.removeValue(forKey: identifier)
                self?.panelCloseObservers.removeValue(forKey: identifier)
                continuation.resume(returning: result)
                panel.close()
            }
            panel.contentView = NSHostingView(rootView: ClipDropComposeView(
                text: text,
                send: { finish($0) },
                cancel: { finish(nil) }
            ))
            let closeObserver = ClipDropPanelCloseObserver { finish(nil) }
            panel.delegate = closeObserver
            composePanels[identifier] = panel
            panelCloseObservers[identifier] = closeObserver
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private static func payload(for item: ClipboardHistoryItem) -> ClipDropPayload {
        if item.contentType == .image, let imageData = item.imageData {
            return .image(imageData)
        }
        if item.contentType == .files, !item.fileURLs.isEmpty {
            return .files(item.fileURLs)
        }
        if item.contentType == .formattedText, let attributedText = item.attributedText {
            return .richText(attributedText, plain: item.text)
        }
        if item.contentType == .link,
           let url = ClipboardContentType.normalizedHTTPURL(from: item.text) {
            return .url(url)
        }
        return .text(item.text)
    }

    private static func editableText(for payload: ClipDropPayload) -> String? {
        switch payload {
        case .text(let text):
            return text
        case .url(let url):
            return url.absoluteString
        case .richText(_, let plain):
            return plain
        case .image, .files:
            return nil
        }
    }

    private static func payload(fromEditedText text: String) -> ClipDropPayload {
        if let url = ClipboardContentType.normalizedHTTPURL(from: text) {
            return .url(url)
        }
        return .text(text)
    }

    private static func qrText(for payload: ClipDropPayload) -> String? {
        switch payload {
        case .text(let text):
            return text
        case .url(let url):
            return url.absoluteString
        case .richText(_, let plain):
            return plain
        case .image, .files:
            return nil
        }
    }
}

@MainActor
private final class ClipDropPanelCloseObserver: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
