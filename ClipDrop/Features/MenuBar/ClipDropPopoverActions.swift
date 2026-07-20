import Foundation

@MainActor
struct ClipDropPopoverActions {
    let sendClipboard: () -> Void
    let sendHistoryItem: (ClipboardHistoryItem) -> Void
    let copyHistoryItem: (ClipboardHistoryItem) -> Void
    let clearHistory: () -> Void
    let openSettings: () -> Void
    let openPaywall: () -> Void
    let quit: () -> Void
}
