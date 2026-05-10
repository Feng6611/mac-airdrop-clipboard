import AppKit
import Combine
import Foundation

@MainActor
final class ClipDropController: ObservableObject {
    @Published private(set) var statusSummary = "Ready"
    @Published private(set) var detailSummary = "Copy text or a link, then choose Send Clipboard via AirDrop."
    @Published private(set) var isSending = false
    @Published private(set) var historyItems: [ClipboardHistoryItem] = []

    private let sender: ClipboardSenderService
    private let historyStore: ClipboardHistoryStore
    private var cancellables: Set<AnyCancellable> = []

    init(
        sender: ClipboardSenderService? = nil,
        historyStore: ClipboardHistoryStore? = nil
    ) {
        self.sender = sender ?? ClipboardSenderService()
        self.historyStore = historyStore ?? ClipboardHistoryStore()
        self.historyItems = self.historyStore.items

        self.historyStore.$items
            .sink { [weak self] items in
                self?.historyItems = items
            }
            .store(in: &cancellables)
    }

    func startClipboardMonitoring() {
        historyStore.startMonitoring()
    }

    func stopClipboardMonitoring() {
        historyStore.stopMonitoring()
    }

    func refreshClipboardHistory() {
        historyStore.syncCurrentClipboard()
    }

    func sendClipboardViaAirDrop() {
        guard !isSending else {
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let result = try sender.sendClipboardViaAirDrop()
            statusSummary = result.status
            detailSummary = result.detail
            historyStore.syncCurrentClipboard()
        } catch {
            statusSummary = "Nothing sent"
            detailSummary = error.localizedDescription
            NSApp.presentError(error)
        }
    }

    func sendHistoryItemViaAirDrop(_ item: ClipboardHistoryItem) {
        guard !isSending else {
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let result = try sender.sendTextViaAirDrop(item.text)
            statusSummary = result.status
            detailSummary = result.detail
            historyStore.record(item.text, contentType: item.contentType, attributedText: item.attributedText)
        } catch {
            statusSummary = "Nothing sent"
            detailSummary = error.localizedDescription
            NSApp.presentError(error)
        }
    }

    func copyHistoryItem(_ item: ClipboardHistoryItem) {
        do {
            try historyStore.copy(item)
            statusSummary = "Copied"
            detailSummary = item.text
        } catch {
            statusSummary = "Copy failed"
            detailSummary = error.localizedDescription
            NSApp.presentError(error)
        }
    }

    static func versionSummary(version: String, build: String) -> String {
        "Clipboard Drop v\(version) (\(build))"
    }
}
