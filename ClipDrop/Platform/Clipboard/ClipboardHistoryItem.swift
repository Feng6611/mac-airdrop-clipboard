import AppKit
import Foundation

struct ClipboardHistoryItem: Identifiable, Equatable {
    let id: UUID
    let text: String
    let contentType: ClipboardContentType
    let createdAt: Date
    let attributedText: NSAttributedString?
    let imageData: Data?
    let fileURLs: [URL]

    init(
        id: UUID,
        text: String,
        contentType: ClipboardContentType,
        createdAt: Date,
        attributedText: NSAttributedString? = nil,
        imageData: Data? = nil,
        fileURLs: [URL] = []
    ) {
        self.id = id
        self.text = text
        self.contentType = contentType
        self.createdAt = createdAt
        self.attributedText = attributedText
        self.imageData = imageData
        self.fileURLs = fileURLs
    }

    static func == (lhs: ClipboardHistoryItem, rhs: ClipboardHistoryItem) -> Bool {
        lhs.id == rhs.id &&
            lhs.text == rhs.text &&
            lhs.contentType == rhs.contentType &&
            lhs.createdAt == rhs.createdAt &&
            lhs.attributedText.isEqual(to: rhs.attributedText) &&
            lhs.imageData == rhs.imageData &&
            lhs.fileURLs == rhs.fileURLs
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
    case image
    case files

    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .formattedText:
            return "Text (Formatted)"
        case .link:
            return "Link"
        case .image:
            return "Image"
        case .files:
            return "Files"
        }
    }

    static func classify(text: String, hasFormattedRepresentation: Bool) -> ClipboardContentType {
        if hasFormattedRepresentation {
            return .formattedText
        }

        if normalizedHTTPURL(from: text) != nil {
            return .link
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

    static func mergedText(from items: [ClipboardHistoryItem]) -> String? {
        guard !items.isEmpty,
              items.allSatisfy({ $0.contentType == .text || $0.contentType == .formattedText || $0.contentType == .link }) else {
            return nil
        }

        let chronologicalItems = items.enumerated().sorted { left, right in
            if left.element.createdAt == right.element.createdAt {
                return left.offset < right.offset
            }
            return left.element.createdAt < right.element.createdAt
        }

        let merged = chronologicalItems
            .map { $0.element.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        return merged.isEmpty ? nil : merged
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
