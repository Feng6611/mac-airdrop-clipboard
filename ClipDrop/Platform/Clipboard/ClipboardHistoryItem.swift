import AppKit
import Foundation

struct ClipboardHistoryItem: Identifiable, Equatable {
    let id: UUID
    let text: String
    let contentType: ClipboardContentType
    let createdAt: Date
    let attributedText: NSAttributedString?

    init(
        id: UUID,
        text: String,
        contentType: ClipboardContentType,
        createdAt: Date,
        attributedText: NSAttributedString? = nil
    ) {
        self.id = id
        self.text = text
        self.contentType = contentType
        self.createdAt = createdAt
        self.attributedText = attributedText
    }

    static func == (lhs: ClipboardHistoryItem, rhs: ClipboardHistoryItem) -> Bool {
        lhs.id == rhs.id &&
            lhs.text == rhs.text &&
            lhs.contentType == rhs.contentType &&
            lhs.createdAt == rhs.createdAt &&
            lhs.attributedText.isEqual(to: rhs.attributedText)
    }

    var preview: String {
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard singleLine.count > 70 else {
            return singleLine
        }

        return "\(singleLine.prefix(67))..."
    }
}

enum ClipboardContentType: String, CaseIterable, Equatable {
    case text
    case formattedText
    case link

    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .formattedText:
            return "Text (Formatted)"
        case .link:
            return "Link"
        }
    }

    static func classify(text: String, hasFormattedRepresentation: Bool) -> ClipboardContentType {
        if normalizedHTTPURL(from: text) != nil {
            return .link
        }

        if hasFormattedRepresentation {
            return .formattedText
        }

        return .text
    }

    static func normalizedHTTPURL(from text: String) -> URL? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let components = URLComponents(string: trimmedText),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            let url = components.url
        else {
            return nil
        }

        return url
    }
}

private extension Optional where Wrapped == NSAttributedString {
    func isEqual(to other: NSAttributedString?) -> Bool {
        switch (self, other) {
        case (.none, .none):
            return true
        case let (.some(lhs), .some(rhs)):
            return lhs.isEqual(to: rhs)
        default:
            return false
        }
    }
}
