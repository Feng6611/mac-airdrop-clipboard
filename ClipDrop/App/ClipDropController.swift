import AppKit
import Combine
import Foundation

@MainActor
final class ClipDropController: ObservableObject {
    @Published private(set) var statusSummary = "Copy something to send"
    @Published private(set) var detailSummary = "Copy text or a link, then choose Send Clipboard via AirDrop."
    @Published private(set) var isSending = false
    @Published private(set) var sendNotice: String?
    @Published private(set) var historyItems: [ClipboardHistoryItem] = []
    @Published private(set) var currentClipboardItem: ClipboardHistoryItem?

    private let sender: ClipboardSenderService
    private let historyStore: ClipboardHistoryStore
    private let sendIndicatorTimeout: TimeInterval
    private var displayedSendIDs: Set<UUID> = []
    private var cancellables: Set<AnyCancellable> = []

    init(
        sender: ClipboardSenderService? = nil,
        historyStore: ClipboardHistoryStore? = nil,
        sendIndicatorTimeout: TimeInterval = 45
    ) {
        self.sender = sender ?? ClipboardSenderService()
        self.historyStore = historyStore ?? ClipboardHistoryStore()
        self.sendIndicatorTimeout = sendIndicatorTimeout
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

    func cleanupTemporarySendFiles() {
        sender.cleanupTemporaryFiles()
    }

    func send(_ payload: ClipDropPayload) async -> ClipboardSendOutcome {
        sendNotice = nil
        let sendID = UUID()
        displayedSendIDs.insert(sendID)
        isSending = true
        let indicatorTimeout = Task { [weak self] in
            let nanoseconds = UInt64(max(0, self?.sendIndicatorTimeout ?? 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.displayedSendIDs.remove(sendID)
            self?.isSending = self?.displayedSendIDs.isEmpty == false
        }

        let outcome = await sender.send(payload)
        indicatorTimeout.cancel()
        displayedSendIDs.remove(sendID)
        isSending = !displayedSendIDs.isEmpty
        switch outcome {
        case .success(let receipt):
            statusSummary = "Sent"
            detailSummary = receipt.usedFilenameFallback
                ? "AirDrop sent file names because the app couldn’t access the files."
                : "AirDrop confirmed the send."
            sendNotice = receipt.usedFilenameFallback ? detailSummary : nil
        case .cancelled:
            statusSummary = "Send canceled"
            detailSummary = "No item was sent."
        case .failure(let error):
            if error == .emptyClipboard {
                reportMissingClipboard()
                return outcome
            }
            statusSummary = "Nothing sent"
            detailSummary = error.localizedDescription
            NSApp.presentError(error)
        }
        return outcome
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
