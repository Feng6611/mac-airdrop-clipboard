import AppKit
import Foundation

enum ClipDropDropItem {
    case text(String)
    case url(URL)
    case richText(NSAttributedString)
    case image(NSImage)
    case fileURL(URL)
}

enum ClipDropDropPayloadConverter {
    static func payload(for items: [ClipDropDropItem]) -> ClipDropEntryPayload? {
        let fileURLs = items.compactMap { item -> URL? in
            guard case .fileURL(let url) = item else { return nil }
            return url
        }
        if !fileURLs.isEmpty {
            return .files(fileURLs)
        }

        if let url = items.compactMap({ item -> URL? in
            guard case .url(let url) = item else { return nil }
            return url
        }).first(where: isHTTPURL) {
            return .url(url)
        }

        if let image = items.compactMap({ item -> NSImage? in
            guard case .image(let image) = item else { return nil }
            return image
        }).first {
            return .image(image)
        }

        if let richText = items.compactMap({ item -> NSAttributedString? in
            guard case .richText(let richText) = item else { return nil }
            return richText
        }).first {
            return .richText(richText)
        }

        if let text = items.compactMap({ item -> String? in
            guard case .text(let text) = item else { return nil }
            return text
        }).first(where: { !$0.isEmpty }) {
            if let url = URL(string: text), isHTTPURL(url) {
                return .url(url)
            }
            return .text(text)
        }
        return nil
    }

    private static func isHTTPURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}

enum ClipDropDropPasteboardReader {
    static func items(from pasteboard: NSPasteboard) -> [ClipDropDropItem] {
        var items: [ClipDropDropItem] = []
        let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: false]
        )?.compactMap { $0 as? URL } ?? []
        items.append(contentsOf: urls.map { $0.isFileURL ? .fileURL($0) : .url($0) })

        if let image = pasteboard.readObjects(forClasses: [NSImage.self])?.first as? NSImage {
            items.append(.image(image))
        }

        if let data = pasteboard.data(forType: NSPasteboard.PasteboardType("public.rtf")),
           let richText = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.rtf],
               documentAttributes: nil
           ) {
            items.append(.richText(richText))
        }

        if let text = pasteboard.string(forType: .string) {
            items.append(.text(text))
        }
        return items
    }
}

/// The app-owned connection point for Kiki's upcoming popover drop callback.
@MainActor
final class ClipDropDropHandler {
    private let send: (ClipDropEntryPayload) async -> Void

    init(send: @escaping (ClipDropEntryPayload) async -> Void) {
        self.send = send
    }

    func handle(_ pasteboard: NSPasteboard) {
        guard let payload = ClipDropDropPayloadConverter.payload(
            for: ClipDropDropPasteboardReader.items(from: pasteboard)
        ) else {
            return
        }
        Task {
            _ = await send(payload)
        }
    }
}
