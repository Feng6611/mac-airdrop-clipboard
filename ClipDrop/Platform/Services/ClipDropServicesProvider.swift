import AppKit
import Foundation

enum ClipDropServicesPayloadReader {
    static func payload(from pasteboard: NSPasteboard) -> ClipDropEntryPayload? {
        let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )?.compactMap { $0 as? URL } ?? []
        if !fileURLs.isEmpty {
            return .files(fileURLs)
        }

        let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: false]
        )?.compactMap { $0 as? URL } ?? []
        if let url = urls.first(where: Self.isHTTPURL) {
            return .url(url)
        }

        if let image = pasteboard.readObjects(forClasses: [NSImage.self])?.first as? NSImage {
            return .image(image)
        }

        if let data = pasteboard.data(forType: NSPasteboard.PasteboardType("public.rtf")),
           let richText = try? NSAttributedString(
               data: data,
               options: [.documentType: NSAttributedString.DocumentType.rtf],
               documentAttributes: nil
           ) {
            return .richText(richText)
        }

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            return nil
        }
        if let url = URL(string: text), Self.isHTTPURL(url) {
            return .url(url)
        }
        return .text(text)
    }

    private static func isHTTPURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}

@MainActor
final class ClipDropServicesProvider: NSObject {
    private let sendPayload: (ClipDropEntryPayload) -> Void

    init(sendPayload: @escaping (ClipDropEntryPayload) -> Void) {
        self.sendPayload = sendPayload
    }

    @discardableResult
    func receive(_ pasteboard: NSPasteboard) -> Bool {
        guard let payload = ClipDropServicesPayloadReader.payload(from: pasteboard) else {
            return false
        }
        sendPayload(payload)
        return true
    }

    @objc(sendWithClipboardDrop:userData:error:)
    func sendWithClipboardDrop(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard receive(pasteboard) else {
            error.pointee = "No supported content found to send." as NSString
            return
        }
    }
}
