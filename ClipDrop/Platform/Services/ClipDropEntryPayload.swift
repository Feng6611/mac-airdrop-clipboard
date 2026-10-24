import AppKit
import Foundation

/// Rich system-entry content held until the content pipeline owns these cases.
enum ClipDropEntryPayload: Equatable {
    case text(String)
    case url(URL)
    case richText(NSAttributedString)
    case image(NSImage)
    case files([URL])

    /// Temporary compatibility bridge to the current Router contract.
    var temporaryRouterPayload: ClipDropPayload {
        switch self {
        case .text(let value):
            return .text(value)
        case .url(let value):
            return .url(value)
        case .richText(let value):
            return .text(value.string)
        case .image:
            return .text("Image")
        case .files(let urls):
            return .text(urls.map(\.lastPathComponent).joined(separator: "\n"))
        }
    }

    static func == (lhs: ClipDropEntryPayload, rhs: ClipDropEntryPayload) -> Bool {
        switch (lhs, rhs) {
        case let (.text(left), .text(right)):
            return left == right
        case let (.url(left), .url(right)):
            return left == right
        case let (.richText(left), .richText(right)):
            return left.isEqual(to: right)
        case let (.image(left), .image(right)):
            return left === right
        case let (.files(left), .files(right)):
            return left == right
        default:
            return false
        }
    }
}
