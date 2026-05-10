import AppKit
import Foundation

enum ClipboardSenderError: LocalizedError, Equatable {
    case emptyClipboard
    case airDropUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "The clipboard does not contain text or a link."
        case .airDropUnavailable:
            return "AirDrop is not available on this Mac right now."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyClipboard:
            return "Copy a URL, command, code, address, or any text before sending."
        case .airDropUnavailable:
            return "Check Finder AirDrop settings and try again."
        }
    }
}

struct ClipboardSendResult: Equatable {
    let status: String
    let detail: String
    let fileURL: URL
    let kind: ClipboardTextKind
}

@MainActor
protocol ClipboardSharingProviding {
    func performAirDrop(with fileURL: URL) -> Bool
}

@MainActor
struct AirDropClipboardSharingProvider: ClipboardSharingProviding {
    func performAirDrop(with fileURL: URL) -> Bool {
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            return false
        }

        service.perform(withItems: [fileURL])
        return true
    }
}

@MainActor
final class ClipboardSenderService {
    private let pasteboard: NSPasteboard
    private let fileManager: FileManager
    private let sharingProvider: any ClipboardSharingProviding
    private let now: () -> Date
    private let preferences: () -> ClipDropSendPreferences

    init(
        pasteboard: NSPasteboard = .general,
        fileManager: FileManager = .default,
        sharingProvider: (any ClipboardSharingProviding)? = nil,
        now: @escaping () -> Date = Date.init,
        preferences: @escaping () -> ClipDropSendPreferences = { .current }
    ) {
        self.pasteboard = pasteboard
        self.fileManager = fileManager
        self.sharingProvider = sharingProvider ?? AirDropClipboardSharingProvider()
        self.now = now
        self.preferences = preferences
    }

    func sendClipboardViaAirDrop() throws -> ClipboardSendResult {
        let clipboardText = pasteboard.string(forType: .string) ?? ""
        return try sendTextViaAirDrop(clipboardText)
    }

    func sendTextViaAirDrop(_ clipboardText: String) throws -> ClipboardSendResult {
        let trimmedText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw ClipboardSenderError.emptyClipboard
        }

        let textFile = try writeTemporaryTextFile(for: clipboardText, normalizedText: trimmedText)
        guard sharingProvider.performAirDrop(with: textFile.fileURL) else {
            throw ClipboardSenderError.airDropUnavailable
        }

        return ClipboardSendResult(
            status: "Sending text via AirDrop",
            detail: "\(textFile.kind.statusName): \(textFile.fileURL.lastPathComponent)",
            fileURL: textFile.fileURL,
            kind: textFile.kind
        )
    }

    private func writeTemporaryTextFile(for clipboardText: String, normalizedText: String) throws -> ClipboardTextFile {
        let directory = fileManager.temporaryDirectory.appendingPathComponent("ClipboardDrop", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let timestamp = Self.timestamp(for: now())
        let baseURL = directory.appendingPathComponent("Clipboard-\(timestamp)")
        let kind: ClipboardTextKind
        let fileText: String
        let fileExtension: String
        let sendPreferences = preferences()

        if let url = ClipboardContentType.normalizedHTTPURL(from: normalizedText) {
            kind = .url
            fileExtension = sendPreferences.urlSendFormat.fileExtension
            fileText = Self.urlFileText(for: url, format: sendPreferences.urlSendFormat)
        } else {
            kind = .text
            fileExtension = sendPreferences.textFileFormat.fileExtension
            fileText = clipboardText
        }

        let fileURL = baseURL.appendingPathExtension(fileExtension)
        try fileText.write(to: fileURL, atomically: true, encoding: .utf8)

        return ClipboardTextFile(kind: kind, fileURL: fileURL)
    }

    private static func urlFileText(for url: URL, format: ClipDropURLSendFormat) -> String {
        switch format {
        case .urlFile:
            return "[InternetShortcut]\nURL=\(url.absoluteString)\n"
        case .plainText:
            return url.absoluteString
        }
    }

    private static func timestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "-")
    }
}

enum ClipboardTextKind: Equatable {
    case text
    case url

    var statusName: String {
        switch self {
        case .text:
            return "text"
        case .url:
            return "link"
        }
    }
}

private struct ClipboardTextFile {
    let kind: ClipboardTextKind
    let fileURL: URL
}
