import AppKit
import Foundation

enum ClipboardHistoryError: LocalizedError, Equatable {
    case pasteboardWriteFailed

    var errorDescription: String? {
        switch self {
        case .pasteboardWriteFailed:
            return "Clipboard Drop could not copy the selected item to the clipboard."
        }
    }
}

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    static let maxImageBytes = 20 * 1024 * 1024
    static let maxImageItemCount = 5

    @Published private(set) var items: [ClipboardHistoryItem] = []
    @Published private(set) var currentItem: ClipboardHistoryItem?

    private let pasteboard: NSPasteboard
    private let maxItemCount: Int
    private let maxImageByteCount: Int
    private let maxImageCount: Int
    private var lastChangeCount: Int
    private var suppressedChangeCount: Int?
    private var timer: DispatchSourceTimer?

    init(
        pasteboard: NSPasteboard = .general,
        maxItemCount: Int = ClipDropAppConfig.default.maxRecentItems,
        maxImageByteCount: Int = ClipboardHistoryStore.maxImageBytes,
        maxImageCount: Int = ClipboardHistoryStore.maxImageItemCount
    ) {
        self.pasteboard = pasteboard
        self.maxItemCount = maxItemCount
        self.maxImageByteCount = maxImageByteCount
        self.maxImageCount = maxImageCount
        self.lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring() {
        guard timer == nil else {
            return
        }

        syncCurrentClipboard()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 0.75, repeating: 0.75)
        timer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.captureCurrentClipboardIfNeeded()
            }
        }
        self.timer = timer
        timer.resume()
    }

    func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }

    func syncCurrentClipboard() {
        lastChangeCount = pasteboard.changeCount
        guard suppressedChangeCount != pasteboard.changeCount else {
            return
        }

        captureCurrentClipboard()
    }

    @discardableResult
    func record(
        _ text: String,
        contentType: ClipboardContentType = .text,
        attributedText: NSAttributedString? = nil,
        imageData: Data? = nil,
        fileURLs: [URL] = []
    ) -> ClipboardHistoryItem? {
        suppressedChangeCount = nil
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty || contentType == .image else {
            return nil
        }

        if contentType == .image {
            guard let imageData, imageData.count <= maxImageByteCount else {
                return nil
            }
            if let existing = items.first(where: { $0.contentType == .image && $0.imageData == imageData }) {
                if items.first?.id == existing.id {
                    return existing
                }
                items.removeAll { $0.id == existing.id }
            }
        } else if contentType == .files {
            guard !fileURLs.isEmpty else { return nil }
            if let existing = items.first(where: { $0.contentType == .files && $0.fileURLs == fileURLs }) {
                if items.first?.id == existing.id {
                    return existing
                }
                items.removeAll { $0.id == existing.id }
            }
        } else {
            if let first = items.first,
               first.contentType == contentType,
               first.text.trimmingCharacters(in: .whitespacesAndNewlines) == normalized {
                return first
            }
        }

        items.removeAll { item in
            if contentType == .image {
                return item.contentType == .image && item.imageData == imageData
            }
            if contentType == .files {
                return item.contentType == .files && item.fileURLs == fileURLs
            }
            return item.contentType == contentType &&
                (item.text == text || item.text.trimmingCharacters(in: .whitespacesAndNewlines) == normalized)
        }
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: text,
            contentType: contentType,
            createdAt: Date(),
            attributedText: attributedText,
            imageData: imageData,
            fileURLs: fileURLs
        )
        items.insert(item, at: 0)

        if contentType == .image {
            let imageIDsToRemove = items
                .filter { $0.contentType == .image }
                .dropFirst(maxImageCount)
                .map(\.id)
            items.removeAll { imageIDsToRemove.contains($0.id) }
        }

        if items.count > maxItemCount {
            items.removeLast(items.count - maxItemCount)
        }
        return item
    }

    func copy(_ item: ClipboardHistoryItem) throws {
        pasteboard.clearContents()
        let didWrite: Bool
        if let imageData = item.imageData {
            didWrite = pasteboard.setData(imageData, forType: .png)
        } else if !item.fileURLs.isEmpty {
            didWrite = pasteboard.writeObjects(item.fileURLs.map { $0 as NSURL })
        } else if let attributedText = item.attributedText {
            didWrite = pasteboard.writeObjects([attributedText])
        } else {
            didWrite = pasteboard.setString(item.text, forType: .string)
        }

        guard didWrite else {
            throw ClipboardHistoryError.pasteboardWriteFailed
        }

        lastChangeCount = pasteboard.changeCount
        currentItem = record(
            item.text,
            contentType: item.contentType,
            attributedText: item.attributedText,
            imageData: item.imageData,
            fileURLs: item.fileURLs
        )
    }

    func clear() {
        items.removeAll()
        currentItem = nil
        lastChangeCount = pasteboard.changeCount
        suppressedChangeCount = pasteboard.changeCount
    }

    private func captureCurrentClipboardIfNeeded() {
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = pasteboard.changeCount
        suppressedChangeCount = nil
        captureCurrentClipboard()
    }

    private func captureCurrentClipboard() {
        if let fileURLs = pasteboard.fileURLsForClipDrop(), !fileURLs.isEmpty {
            let names = fileURLs.map(\.lastPathComponent).joined(separator: ", ")
            currentItem = record(names, contentType: .files, fileURLs: fileURLs)
            return
        }

        if let imageData = pasteboard.pngImageRepresentationForClipDrop() {
            currentItem = record("Image", contentType: .image, imageData: imageData)
            if currentItem != nil { return }
        }

        let attributedText = pasteboard.attributedTextRepresentationForClipDrop()
        guard let text = pasteboard.string(forType: .string) ?? attributedText?.string else {
            currentItem = nil
            return
        }

        let item = record(
            text,
            contentType: ClipboardContentType.classify(
                text: text,
                hasFormattedRepresentation: attributedText != nil
            ),
            attributedText: attributedText
        )
        currentItem = item ?? matchingItem(for: text)
    }

    private func matchingItem(for text: String) -> ClipboardHistoryItem? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.first { item in
            item.text.trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }
    }
}

private extension NSPasteboard {
    func fileURLsForClipDrop() -> [URL]? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        if let urls = readObjects(forClasses: [NSURL.self], options: options) as? [URL], !urls.isEmpty {
            return urls
        }

        let urls = (pasteboardItems ?? []).compactMap { item -> URL? in
            guard let value = item.string(forType: .fileURL),
                  let url = URL(string: value),
                  url.isFileURL else {
                return nil
            }
            return url
        }
        return urls.isEmpty ? nil : urls
    }

    func pngImageRepresentationForClipDrop() -> Data? {
        if let pngData = data(forType: .png) {
            return pngData
        }
        guard let tiffData = data(forType: .tiff),
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    func attributedTextRepresentationForClipDrop() -> NSAttributedString? {
        if let rtfData = data(forType: .rtf),
           let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil),
           attributedString.isMeaningfullyFormatted {
            return attributedString
        }

        if let rtfdData = data(forType: .rtfd),
           let attributedString = NSAttributedString(rtfd: rtfdData, documentAttributes: nil),
           attributedString.isMeaningfullyFormatted {
            return attributedString
        }

        if let htmlData = data(forType: .html),
           let attributedString = NSAttributedString(html: htmlData, documentAttributes: nil),
           attributedString.isMeaningfullyFormatted {
            return attributedString
        }

        return nil
    }
}

private extension NSAttributedString {
    var isMeaningfullyFormatted: Bool {
        guard length > 0 else {
            return false
        }

        var firstSignature: FormattingSignature?
        var hasDifferentSignature = false
        var hasExplicitFormatting = false

        enumerateAttributes(in: NSRange(location: 0, length: length)) { attributes, _, stop in
            if attributes[.link] != nil ||
                attributes[.attachment] != nil ||
                attributes[.underlineStyle] != nil ||
                attributes[.strikethroughStyle] != nil ||
                attributes[.backgroundColor] != nil {
                hasExplicitFormatting = true
                stop.pointee = true
                return
            }

            if let font = attributes[.font] as? NSFont {
                let traits = NSFontManager.shared.traits(of: font)
                if traits.contains(.boldFontMask) || traits.contains(.italicFontMask) {
                    hasExplicitFormatting = true
                    stop.pointee = true
                    return
                }
            }

            let signature = FormattingSignature(attributes: attributes)
            if let firstSignature, firstSignature != signature {
                hasDifferentSignature = true
                stop.pointee = true
            } else {
                firstSignature = signature
            }
        }

        return hasExplicitFormatting || hasDifferentSignature
    }
}

private struct FormattingSignature: Equatable {
    let fontName: String?
    let fontSize: CGFloat?
    let foregroundColor: String?

    init(attributes: [NSAttributedString.Key: Any]) {
        if let font = attributes[.font] as? NSFont {
            fontName = font.fontName
            fontSize = font.pointSize
        } else {
            fontName = nil
            fontSize = nil
        }

        if let color = attributes[.foregroundColor] as? NSColor {
            foregroundColor = color.usingColorSpace(.sRGB)?.description
        } else {
            foregroundColor = nil
        }
    }
}
