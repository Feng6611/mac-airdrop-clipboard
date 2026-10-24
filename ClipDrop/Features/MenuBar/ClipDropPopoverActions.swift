import Foundation

@MainActor
struct ClipDropPopoverActions {
    let sendClipboard: () -> Void
    let sendHistoryItem: (ClipboardHistoryItem) -> Void
    let editAndSendHistoryItem: (ClipboardHistoryItem) -> Void
    let showQRCode: (ClipboardHistoryItem) -> Void
    let sendMergedItems: ([ClipboardHistoryItem]) -> Void
    let copyHistoryItem: (ClipboardHistoryItem) -> Void
    let clearHistory: () -> Void
    let openSettings: () -> Void
    let quit: () -> Void
}
