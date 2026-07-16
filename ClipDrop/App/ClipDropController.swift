import AppKit
import Combine
import Foundation

@MainActor
final class ClipDropController: ObservableObject {
    @Published private(set) var statusSummary = "Copy something to send"
    @Published private(set) var detailSummary = "Copy text or a link, then choose Send Clipboard via AirDrop."
    @Published private(set) var isSending = false
    @Published private(set) var historyItems: [ClipboardHistoryItem] = []
    @Published private(set) var currentClipboardItem: ClipboardHistoryItem?

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

        self.historyStore.$currentItem
            .sink { [weak self] item in
                self?.currentClipboardItem = item
                if item != nil, self?.statusSummary == "Copy something to send" {
                    self?.statusSummary = "Ready to send"
                }
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

    var hasSendableCurrentClipboard: Bool {
        currentClipboardItem != nil
    }

    func reportMissingClipboard() {
        statusSummary = "Nothing to send"
        detailSummary = ClipboardSenderError.emptyClipboard.localizedDescription
    }

    func sendClipboardViaAirDrop() {
        guard !isSending else {
            return
        }

        guard let currentClipboardItem else {
            reportMissingClipboard()
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let result = try sender.sendTextViaAirDrop(currentClipboardItem.text)
            statusSummary = result.status
            detailSummary = result.detail
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

    func clearClipboardHistory() {
        historyStore.clear()
        statusSummary = "History cleared"
        detailSummary = "Clipboard history is empty. New copied text will appear here."
    }

    static func versionSummary(version: String, build: String) -> String {
        "Version \(version) (\(build))"
    }
}
