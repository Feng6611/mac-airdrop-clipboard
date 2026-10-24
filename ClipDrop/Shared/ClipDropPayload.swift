import Foundation

/// App-owned content contract for every send entry point.
/// Add new payload cases here as their content pipelines are introduced.
enum ClipDropPayload: Equatable {
    case text(String)
    case url(URL)
}

/// Identifies where a send request entered the app.
enum ClipDropSendSource: String, Equatable {
    case popover
    case history
    case hotkey
    case services
    case intent
    case drop
    case contextMenu
}
