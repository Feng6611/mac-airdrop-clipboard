import AppKit
import Foundation

/// App-owned content contract for every send entry point.
/// Add new payload cases here as their content pipelines are introduced.
enum ClipDropPayload: Equatable {
    case text(String)
    case url(URL)
    case richText(NSAttributedString, plain: String)
    case image(Data)
    case files([URL])

    static func == (lhs: ClipDropPayload, rhs: ClipDropPayload) -> Bool {
        switch (lhs, rhs) {
        case let (.text(lhs), .text(rhs)):
            return lhs == rhs
        case let (.url(lhs), .url(rhs)):
            return lhs == rhs
        case let (.richText(lhsAttributed, lhsPlain), .richText(rhsAttributed, rhsPlain)):
            return lhsPlain == rhsPlain && lhsAttributed.isEqual(to: rhsAttributed)
        case let (.image(lhs), .image(rhs)):
            return lhs == rhs
        case let (.files(lhs), .files(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
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
