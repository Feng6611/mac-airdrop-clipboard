import AppKit
import Foundation

/// Content read from system entry points (Services, drag and drop) before it becomes a router payload.
enum ClipDropEntryPayload: Equatable {
    case text(String)
    case url(URL)
    case richText(NSAttributedString)
    case image(NSImage)
    case files([URL])

    /// Router payload for this entry. Returns nil when an image can't be encoded as PNG.
    var routerPayload: ClipDropPayload? {
        switch self {
        case .text(let value):
            return .text(value)
        case .url(let value):
            return .url(value)
        case .richText(let value):
            return .richText(value, plain: value.string)
        case .image(let image):
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return nil
            }
            return .image(pngData)
        case .files(let urls):
            return .files(urls)
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
