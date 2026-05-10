import Foundation

@MainActor
struct ClipDropPopoverActions {
    let sendClipboard: () -> Void
    let sendHistoryItem: (ClipboardHistoryItem) -> Void
    let copyHistoryItem: (ClipboardHistoryItem) -> Void
    let clearRecentItems: () -> Void
    let openSettings: () -> Void
    let quit: () -> Void
}
