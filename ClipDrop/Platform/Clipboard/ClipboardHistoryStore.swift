import AppKit
import Foundation

enum ClipboardHistoryError: LocalizedError, Equatable {
    case pasteboardWriteFailed

    var errorDescription: String? {
        switch self {
        case .pasteboardWriteFailed:
            return "Clipboard Drop could not write the selected text to the clipboard."
        }
    }
}

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardHistoryItem] = []

    private let pasteboard: NSPasteboard
    private let maxItemCount: Int
    private var lastChangeCount: Int
    private var suppressedChangeCount: Int?
    private var timer: DispatchSourceTimer?

    init(pasteboard: NSPasteboard = .general, maxItemCount: Int = ClipDropAppConfig.default.maxRecentItems) {
        self.pasteboard = pasteboard
        self.maxItemCount = maxItemCount
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

    func record(
        _ text: String,
        contentType: ClipboardContentType = .text,
        attributedText: NSAttributedString? = nil
    ) {
        suppressedChangeCount = nil
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return
        }

        guard items.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) != normalized else {
            return
        }

        items.removeAll { item in
            item.text == text || item.text.trimmingCharacters(in: .whitespacesAndNewlines) == normalized
        }
        items.insert(
            ClipboardHistoryItem(
                id: UUID(),
                text: text,
                contentType: contentType,
                createdAt: Date(),
                attributedText: attributedText
            ),
            at: 0
        )

        if items.count > maxItemCount {
            items.removeLast(items.count - maxItemCount)
        }
    }

    func copy(_ item: ClipboardHistoryItem) throws {
        pasteboard.clearContents()
        let didWrite: Bool
        if let attributedText = item.attributedText {
            didWrite = pasteboard.writeObjects([attributedText])
        } else {
            didWrite = pasteboard.setString(item.text, forType: .string)
        }

        guard didWrite else {
            throw ClipboardHistoryError.pasteboardWriteFailed
        }

        lastChangeCount = pasteboard.changeCount
        record(item.text, contentType: item.contentType, attributedText: item.attributedText)
    }

    func clear() {
        items.removeAll()
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
        guard let text = pasteboard.string(forType: .string) else {
            return
        }

        let attributedText = pasteboard.attributedTextRepresentation(for: text)
        record(
            text,
            contentType: ClipboardContentType.classify(
                text: text,
                hasFormattedRepresentation: attributedText != nil
            ),
            attributedText: attributedText
        )
    }
}

private extension NSPasteboard {
    func attributedTextRepresentation(for plainText: String) -> NSAttributedString? {
        if let rtfData = data(forType: .rtf),
           let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil),
           attributedString.isMeaningfullyFormatted(comparedTo: plainText) {
            return attributedString
        }

        if let htmlData = data(forType: .html),
           let attributedString = NSAttributedString(html: htmlData, documentAttributes: nil),
           attributedString.isMeaningfullyFormatted(comparedTo: plainText) {
            return attributedString
        }

        return nil
    }
}

private extension NSAttributedString {
    func isMeaningfullyFormatted(comparedTo plainText: String) -> Bool {
        guard string == plainText, length > 0 else {
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
